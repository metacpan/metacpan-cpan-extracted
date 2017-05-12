# $Id$

=head1 NAME

  Bio::Chaos              - utility class for handling Chaos-XML
   
=head1 SYNOPSIS

  use Bio::Chaos;
  my $C = Bio::Chaos->new;
  $C->parse('test.gff');
  $C->set_organism('Drosophila melanogaster');
  print $C->transform_to('chadoxml')->xml;
  
=cut

=head1 DESCRIPTION

This module contains some basic methods for manipulating a Chaos-XML
document stored in memory as a L<Data::Stag> tree. This class is
fairly minimal. One of the principal ideas being L<Bio::Chaos> is that
access to the data model should be directly through generic XML-based data accessors, such as those provided by L<Data::Stag>

For more advanced functionality, see L<Bio::Chaos::ChaosGraph> - this
augments the generic accessor methods with some sequence feature
semantics, and methods for graph traversal, location transformation etc

=cut

package Bio::Chaos;

use strict;
use base qw(Bio::Chaos::Root);
use Data::Stag;


=head2 root

 Usage   - my $cx = $C->root;
 Returns - L<Data::Stag> chaos node
 Args    -

returns the top-level of the Chaos-XML document as a stag tree

=cut

sub root {
    my $self = shift;
    $self->{_root} = shift if @_;
    return $self->{_root};
}


=head2 parse

 Usage   - my $cx = $C->parse('sample_data/Rab1.chaos');
 Usage   - my $cx = $C->parse('t/data/AE003744.gbk','genbank');
 Usage   - my $cx = $C->parse('t/data/test.chado','chado');
 Usage   - my $cx = $C->parse('t/data/foo.gff','gff3');
 Returns - L<Data::Stag> chaos node
 Args    - file str
           format str

parses from various formats into an in-memory chaos-xml file

see L<Bio::Chaos::Parser> for details of the parsing architecture

=cut

sub parse {
    my $self = shift;
    my ($file,$fmt) = @_;
    if (!$fmt) {
        if ($file =~ /\.(\w+)/) {
            $fmt = $1;
        }
    }
    if ($fmt eq 'gff') {
        $fmt = 'gff3';
    }

    my $handler;
    my $parser = 'xml';
    if ($fmt eq 'gff3') {
        $parser = "Bio::Chaos::Parser::gff3";
        $handler = Data::Stag->getformathandler("Bio::Chaos::Handler::gff3_to_chaos");
    }
    elsif ($fmt eq 'chado') {
        $parser = 'xml';
        $handler = Data::Stag->getformathandler("Bio::Chaos::Handler::gff3_to_chaos");
    }
    else {
        # default - chaos
    }
    
    my @parse_args = (-format=>$parser,
                      -handler=>$handler);
    if ($file eq '') {
        push(@parse_args,-fh=>\*STDIN);
    }
    else {
        push(@parse_args,-file=>$file);
    }

    Data::Stag->parse(@parse_args);

    $self->root($handler->stag);
    if ($self->root->element ne 'chaos') {
        $self->root->element('chaos');
            #$self->root(Data::Stag->new(chaos=>[$handler->stag]));
    }
    return $self->root;
}


=head2 transform_to

  Usage   - $C->transform_to('chadoxml');
  Returns -
  Args    - fmt str

applies a transformation to the chaos node in memory

=cut

sub transform_to {
    my $self = shift;
    my $fmt = shift;
    my $opt = shift || {};

    my @xsls = ();
    if ($fmt eq 'chadoxml') {
        @xsls = ("cx-chaos-to-chado");
        if ($opt->{expand_macros}) {
            push(@xsls,"chado-expand-macros");
        }
        if ($opt->{insert_macros}) {
            push(@xsls,"chado-insert-macros");
        }
    }

    my $mod = "Bio::Chaos::XSLTHelper";
    $self->load_module($mod);
    my $out = $mod->xsltchain_node($self->root,@xsls);
    return $out;
}

sub apply_to_features {
    my $self = shift;
    my $func = shift;
    my $root = $self->root;
    foreach ($root->get_feature) {
        $func->($_);
    }
    return;
}


=head2 set_organism

  Usage   - $C->set_organism('Drosophila melanogaster')
  Returns -
  Args    - org str

Sets organism_id for ALL features in the document

=cut

sub set_organism {
    my $self = shift;
    my $org = shift;
    $self->apply_to_features(sub {shift->set_organismstr($org)});
}

sub add_srcfeatures {
    my $self = shift;
    my $type = shift || 'chromosome';
    my $root = $self->root;
    my @ids = $root->get('feature/featureloc/srcfeature_id');
    my %uidh = map {$_=>1} @ids;
    @ids = keys %uidh;
    foreach my $id (@ids) {
        $root->add(feature=>[
                             [feature_id=>$id],
                             [name=>$id],
                             [uniquename=>$id],
                             [type=>$type],
                             ]);
    }
    return;
}


=head2 new_feature

 Usage   - my $f = Data::Stag->new_feature
 Returns - L<Data::Stag> feature node
 Args    -

=cut

sub new_feature {
    my $self = shift;
    my ($name,$type,$org) = @_;
    my $f =
      Data::Stag->new(feature=>[
                                [name=>$name],
                                [uniquename=>$name],
                                [type=>$type],
                                [organismstr=>$org]
                               ]);
}

sub fetch_from_chado {
    my $self = shift;
    my ($dbh,$constr) = @_;
    my $chado = $self->db_factory("Chado")->new;
    $self->root(Data::Stag->new(chaos=>[]));
    $chado->chaos($self);
    $chado->sdbh($dbh);
    $chado->fetch_features($constr);
}

sub db_factory {
    my $self = shift;
    my $name = shift;
    my $mod = "Bio::Chaos::DB::$name";
    $self->load_module($mod);
    $mod;
}

1;
