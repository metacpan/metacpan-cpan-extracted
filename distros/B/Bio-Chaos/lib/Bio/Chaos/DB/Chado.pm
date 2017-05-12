# $Id: DB::Chado.pm,v 1.7 2005/06/15 16:21:09 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::DB::Chado     - I/O from a chado db

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut

package Bio::Chaos::DB::Chado;

use strict;
use Data::Stag qw(:all);
use base qw(Bio::Chaos::Root Exporter);

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = bless {}, $class;
    $self->fetched_idh({});
    $self->srcfeature_idh({});

    return $self;
}

sub sdbh {
    my $self = shift;
    $self->{_sdbh} = shift if @_;
    return $self->{_sdbh};
}

sub chaos {
    my $self = shift;
    $self->{_chaos} = shift if @_;
    return $self->{_chaos};
}

sub fetched_idh {
    my $self = shift;
    $self->{_fetched_idh} = shift if @_;
    return $self->{_fetched_idh};
}

# track which feature_ids are source features
#  (reason: we do not wish to recurse down a src features parts)
sub srcfeature_idh {
    my $self = shift;
    $self->{_srcfeature_idh} = shift if @_;
    return $self->{_srcfeature_idh};
}

sub fetch_features {
    my $self = shift;
    my $constr = shift;

    my $where = _where($constr);
    my $fetched_idh = $self->fetched_idh;
    my $srcfeature_idh = $self->srcfeature_idh;
    my $sdbh = $self->sdbh;
    my $chaos = $self->chaos;

    my $fset = $sdbh->selectall_stag("SELECT * FROM feature $where");
    my @features = $fset->subnodes;
    my %featureh = map {(stag_sget($_,'feature_id')=>$_)} @features;
    my @ids = keys %featureh;
    my $in = _in(\@ids);
    my $fconstr = "feature_id in $in";

    # set types
    my @type_ids = map {stag_sget($_,'type_id')} @features;
    my $th = $self->resolve_type_ids([_uniq(@type_ids)]);
    for (my $i=0;$i<@features;$i++) {
        stag_set($features[$i],
                 'type',
                 $th->{$type_ids[$i]})
    }

    # get locations and attach
    my $flocs = $self->fetch_featurelocs($fconstr);
    foreach (@$flocs) {
        stag_add($featureh{stag_sget($_,'feature_id')},
                 'featureloc',
                 $_);
    }
    # get source features; later recursively fetch these
    my @srcfids = _uniq(map {stag_get($_,'srcfeature_id')} @$flocs);

    # remember which are srcfeatures, so we do not recurse down
    # to their parts
    $srcfeature_idh->{$_} = 1 foreach @srcfids;

    # get featureprops and attach
    my $fprops = $self->fetch_featureprops($fconstr);
    foreach (@$fprops) {
        stag_add($featureh{stag_sget($_,'feature_id')},
                 'featureprop',
                 $_);
    }

    # get feature relationships - do not attach
    #  (feature_relationships are nested under the root chaos element)

    # only fetch frels for non-srcfeatures
    my $frel_in =
      _in([grep { !$srcfeature_idh->{$_} } @ids]);
    my $frels = $self->fetch_feature_relationships("object_id in $frel_in");

    # attach to root chaos node
    $chaos->root->add('feature',$_) foreach @features;
    $chaos->root->add('feature_relationship',$_) foreach @$frels;

    # recursively fetch features - subfeatures and srcfeatures
    my @subj_ids = map {stag_sget($_,'subject_id')} @$frels;

    $fetched_idh->{$_} = 1 foreach @ids;
    my @next_ids = 
      grep {
          !$fetched_idh->{$_}
      } (@subj_ids,@srcfids);

    if (@next_ids) {
        $self->fetch_features("feature_id in "._in(\@next_ids));
    }

    return \@features;
}

sub fetch_featurelocs {
    my $self = shift;
    my $constr = shift;
    my $sdbh = $self->sdbh;
    my $where = _where($constr);
    my $lset = $sdbh->selectall_stag("SELECT * FROM featureloc $where");

    my @featurelocs =
      map {
          my ($nbeg,$nend) = stag_getl($_,'fmin','fmax');
          if (stag_get($_,'strand') < 0) {
              ($nbeg,$nend) = ($nend,$nbeg);
          }
          stag_set($_,'nbeg',$nbeg);
          stag_set($_,'nend',$nend);
          $_
      } $lset->subnodes;

    return \@featurelocs;
}

sub fetch_featureprops {
    my $self = shift;
    my $constr = shift;
    my $sdbh = $self->sdbh;
    my $where = _where($constr);
    my $fpset = $sdbh->selectall_stag("SELECT * FROM featureprop $where");

    my @featureprops = $fpset->subnodes;
    my @type_ids = _uniq(map {stag_sget($_,'type_id')} @featureprops);

    my $th = $self->resolve_type_ids(\@type_ids);
    foreach (@featureprops) {
        stag_set($_,'type',
                 $th->{stag_sget($_,'type_id')});
    }

    return \@featureprops;
}

sub fetch_feature_relationships {
    my $self = shift;
    my $constr = shift;
    my $sdbh = $self->sdbh;
    my $where = _where($constr);
    my $fpset = $sdbh->selectall_stag("SELECT * FROM feature_relationship $where");

    my @frels = $fpset->subnodes;
    my @type_ids = _uniq(map {stag_sget($_,'type_id')} @frels);
    my $th = $self->resolve_type_ids(\@type_ids);
    foreach (@frels) {
        stag_set($_,'type',$th->{stag_get($_,'type_id')});
    }

    return \@frels;
}

sub resolve_type_ids {
    my $self = shift;
    my $ids = shift;
    if (!$self->{_type_map}) {
        $self->{_type_map} = {};
    }
    my $map = $self->{_type_map};
    
    my @unresolved = grep {!$map->{$_}} @$ids;
    if (@unresolved) {
        my $in = _in(\@unresolved);
        if ($ENV{DBSTAG_TRACE}) {
            print STDERR "Fetching type_ids: $in\n";
        }
        my $rows = $self->sdbh->selectall_arrayref("SELECT cvterm_id,name FROM cvterm WHERE cvterm_id IN $in");
        foreach (@$rows) {
            $map->{$_->[0]} = $_->[1];
        }
    }
    return $map;
}

sub _in {
    my $ids = shift;
    sprintf("(%s)",join(',',_uniq(@$ids)));
}

sub _uniq {
    my %h = map{($_=>1)} @_;
    return keys %h;
}

# TODO: hash constraints
sub _where {
    return "WHERE @_";
}

1;

