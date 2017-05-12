package CPAN::Search::Lite::State;
use strict;
use warnings;
no warnings qw(redefine);
use CPAN::Search::Lite::DBI qw($dbh);
use CPAN::Search::Lite::DBI::Index;
use CPAN::Search::Lite::Util qw(has_data);
our $VERSION = 0.77;

my $no_ppm;
my %tbl2obj;
$tbl2obj{$_} = __PACKAGE__ . '::' . $_ for (qw(dists mods auths ppms));
my %obj2tbl = reverse %tbl2obj;

our $dbh = $CPAN::Search::Lite::DBI::dbh;

sub new {
  my ($class, %args) = @_;
  
  foreach (qw(db user passwd) ) {
    die "Must supply a '$_' argument" unless $args{$_};
  }
    
  if ($args{setup}) {
      die "No state information available under setup";
  }

  $no_ppm = $args{no_ppm};

  my $index = $args{index};
  my @tables = qw(dists mods auths);
  push @tables, 'ppms' unless $no_ppm;
  foreach my $table (@tables) {
      my $obj = $index->{$table};
      die "Please supply a CPAN::Search::Lite::Index::$table object"
          unless ($obj and ref($obj) eq "CPAN::Search::Lite::Index::$table");
  }
  my $cdbi = CPAN::Search::Lite::DBI::Index->new(%args);

  my $self = {index => $index,
              obj => {},
              cdbi => $cdbi,
              reindex => $args{reindex},
             };
  bless $self, $class;
}

sub state {
    my $self = shift;
    unless ($self->create_objs()) {
        print "Cannot create objects";
        return;
    }
    unless ($self->state_info()) {
        print "Getting state information failed";
        return;
    };
    return 1;
}

sub create_objs {
    my $self = shift;
    my @tables = qw(dists auths mods);
    push @tables, 'ppms' unless $no_ppm;

    foreach my $table (@tables) {
        my $obj;
        my $pack = $tbl2obj{$table};
        my $index = $self->{index}->{$table};
        if ($index and ref($index) eq "CPAN::Search::Lite::Index::$table") {
            my $info = $index->{info};
	    return unless has_data($info);
            $obj = $pack->new(info => $info, 
                              cdbi => $self->{cdbi}->{objs}->{$table});
        }
        else {
            $obj = $pack->new();
        }
        $self->{obj}->{$table} = $obj;
    }

    $self->{obj}->{dists}->{reindex} = 
      $self->{reindex} if defined $self->{reindex};

    foreach my $table (@tables) {
        my $obj = $self->{obj}->{$table};
        foreach (@tables) {
            next if ref($obj) eq $tbl2obj{$_};
            $obj->{obj}->{$_} = $self->{obj}->{$_};
        }
    }
    return 1;
}

sub state_info {
    my $self = shift;
    my @methods = qw(ids state);
    my @tables = qw(dists auths mods);
    push @tables, 'ppms' unless ($no_ppm or defined $self->{reindex});

    for my $method (@methods) {
        for my $table (@tables) {
            my $obj = $self->{obj}->{$table};
            unless ($obj->$method()) {
                if (my $error = $obj->{error_msg}) {
                    print "Fatal error from ", ref($obj), ": ", $error, $/;
                    return;
                }
                else {
                    my $info = $obj->{info_msg};
                    print "Info from ", ref($obj), ": ", $info, $/;
                }
            }
       }
    }
    return 1;
}

package CPAN::Search::Lite::State::auths;
use base qw(CPAN::Search::Lite::State);
use CPAN::Search::Lite::Util qw(has_data);

sub new {
  my ($class, %args) = @_;
  my $info = $args{info};
  die "No author info available" unless has_data($info);
  my $cdbi = $args{cdbi};
  die "No dbi object available"
    unless ($cdbi and ref($cdbi) eq 'CPAN::Search::Lite::DBI::Index::auths');
  my $self = {
              info => $info,
              insert => {},
              update => {},
              delete => {},
              ids => {},
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
             };
  bless $self, $class;
}

sub ids {
  my $self = shift;
  my $cdbi = $self->{cdbi};
  $self->{ids} = $cdbi->fetch_ids() or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub state {
  my $self = shift;
  my $auth_ids = $self->{ids};
  return unless my $dist_obj = $self->{obj}->{dists};
  my $dist_update = $dist_obj->{update};
  my $dist_insert = $dist_obj->{insert};
  my $dists = $dist_obj->{info};
  my ($update, $insert);
  if (has_data($dist_insert)) {
    foreach my $distname (keys %{$dist_insert}) {
      my $cpanid = $dists->{$distname}->{cpanid};
      if (my $auth_id = $auth_ids->{$cpanid}) {
        $update->{$cpanid} = $auth_id;
      }
      else {
        $insert->{$cpanid}++;
      }
    }
  }
  if (has_data($dist_update)) {
    foreach my $distname (keys %{$dist_update}) {
      my $cpanid = $dists->{$distname}->{cpanid};
      if (my $auth_id = $auth_ids->{$cpanid}) {
        $update->{$cpanid} = $auth_id;
      }
      else {
        $insert->{$cpanid}++;
      }
    }
  }
  $self->{update} = $update;
  $self->{insert} = $insert;
  return 1;
}

package CPAN::Search::Lite::State::dists;
use base qw(CPAN::Search::Lite::State);
use CPAN::Search::Lite::Util qw(vcmp has_data);

sub new {
  my ($class, %args) = @_;
  my $info = $args{info};
  die "No dist info available" unless has_data($info);
  my $cdbi = $args{cdbi};
  die "No dbi object available"
    unless ($cdbi and ref($cdbi) eq 'CPAN::Search::Lite::DBI::Index::dists');
  my $self = {
              info => $info,
              insert => {},
              update => {},
              delete => {},
              ids => {},
              versions => {},
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
              reindex => undef,
  };
  bless $self, $class;
}

sub ids {
  my $self = shift;
  my $cdbi = $self->{cdbi};
  ($self->{ids}, $self->{versions}) = $cdbi->fetch_ids() or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub state {
  my $self = shift;
  my $dist_versions = $self->{versions};
  my $dists = $self->{info};
  my $dist_ids = $self->{ids};
  my ($insert, $update, $delete);

  my $reindex = $self->{reindex};
  if (defined $reindex) {
    my @dists = ref($reindex) eq 'ARRAY' ? @$reindex : ($reindex);
    foreach my $distname(@dists) {
      my $id = $dist_ids->{$distname};
      if (not defined $id) {
        print STDERR qq{"$distname" does not have an id: reindexing ignored\n};
        next;
      }
      $update->{$distname} = $id;
    }
    $self->{update} = $update;
    return 1;
  }

  foreach my $distname (keys %$dists) {
    if (not defined $dist_versions->{$distname}) {
      $insert->{$distname}++;
    }
    elsif (vcmp($dists->{$distname}->{version}, 
                       $dist_versions->{$distname}) > 0) {
      $update->{$distname} = $dist_ids->{$distname};
    }
  }
  $self->{update} = $update;
  $self->{insert} = $insert;
  foreach my $distname(keys %$dist_versions) {
    next if $dists->{$distname};
    $delete->{$distname} = $dist_ids->{$distname};
    print "Will delete $distname\n";
  }
  $self->{delete} = $delete;
  return 1;
}

package CPAN::Search::Lite::State::mods;
use base qw(CPAN::Search::Lite::State);
use CPAN::Search::Lite::Util qw(has_data);

sub new {
  my ($class, %args) = @_;
  my $info = $args{info};
  die "No module info available" unless has_data($info);
  my $cdbi = $args{cdbi};
  die "No dbi object available"
    unless ($cdbi and ref($cdbi) eq 'CPAN::Search::Lite::DBI::Index::mods');
  my $self = {
              info => $info,
              insert => {},
              update => {},
              delete => {},
              ids => {},
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
             };
  bless $self, $class;
}

sub ids {
  my $self = shift;
  my $cdbi = $self->{cdbi};
  $self->{ids} = $cdbi->fetch_ids() or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub state {
  my $self = shift;
  my $mods = $self->{info};
  my $mod_ids = $self->{ids};
  return unless my $dist_obj = $self->{obj}->{dists};
  my $dists = $dist_obj->{info};
  my $dist_update = $dist_obj->{update};
  my $dist_insert = $dist_obj->{insert};
  my ($update, $insert, $delete);
  my $cdbi = $self->{cdbi};
  if (has_data($dist_insert)) {
    foreach my $distname (keys %{$dist_insert}) {
      foreach my $module(keys %{$dists->{$distname}->{modules}}) {
        $insert->{$module}++;
      }   
    }
  }
  if (has_data($dist_update)) {
    foreach my $distname (keys %{$dist_update}) {
      foreach my $module(keys %{$dists->{$distname}->{modules}}) {
        my $mod_id = $mod_ids->{$module};
        if ($mod_id) {
          $update->{$module} = $mod_id;
        }
        else {
          $insert->{$module}++;
        }
      }   
    }
  }

  if (has_data($dist_update)) {
    my $sql = q{SELECT mod_id,mod_name from mods,dists WHERE dists.dist_id = mods.dist_id and dists.dist_id = ?};
    my $sth = $dbh->prepare($sql) or do {
      $cdbi->db_error();
      $self->{error_msg} = $cdbi->{error_msg};
      return;
    };
    my $dist_ids = $dist_obj->{ids};
    foreach my $distname (keys %{$dist_update}) {
      my %mods = ();
      %mods = map {$_ => 1} keys %{$dists->{$distname}->{modules}};
      $sth->execute($dist_ids->{$distname}) or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
      while (my($mod_id, $mod_name) = $sth->fetchrow_array) {
        next if $mods{$mod_name};
        $delete->{$mod_name} = $mod_id;
      }
    }
    $sth->finish;
  }

  $self->{update} = $update;
  $self->{insert} = $insert;
  $self->{delete} = $delete;
  return 1;
}

package CPAN::Search::Lite::State::ppms;
use base qw(CPAN::Search::Lite::State);
use CPAN::Search::Lite::Util qw(vcmp has_data);

sub new {
  my ($class, %args) = @_;
  my $info = $args{info};
  die "No ppm info available" unless has_data($info);
  my $cdbi = $args{cdbi};
  die "No dbi object available"
    unless ($cdbi and ref($cdbi) eq 'CPAN::Search::Lite::DBI::Index::ppms');
  my $self = {
              info => $info,
              insert => {},
              update => {},
              delete => {},
              ids => {},
              versions => {},
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
             };
  bless $self, $class;
}

sub ids {
  my $self = shift;
  my $cdbi = $self->{cdbi};
  ($self->{ids}, $self->{versions}) = $cdbi->fetch_ids() or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub state {
  my $self = shift;
  my $ppm_versions = $self->{versions};
  my $ppms = $self->{info};
  my $ppm_ids = $self->{ids};
  my ($update, $insert, $delete);
  foreach my $id (keys %$ppms) {
      my $values = $ppms->{$id};
      next unless has_data($values);
      foreach my $package (keys %{$values}) {
          if (not defined $ppm_versions->{$id}->{$package}) {
              $insert->{$id}->{$package}->{version} =
                  $ppms->{$id}->{$package}->{version};
          }
          elsif (vcmp($ppms->{$id}->{$package}->{version}, 
                             $ppm_versions->{$id}->{$package}) > 0) {
              $update->{$id}->{$package} = 
              {dist_id => $ppm_ids->{$id}->{$package},
               ppm_vers => $ppms->{$id}->{$package}->{version}};
          }
      }
 }
  $self->{insert} = $insert;
  $self->{update} = $update;
   foreach my $id (keys %$ppm_versions) {
      next unless has_data($ppms->{$id});
      my $values = $ppm_versions->{$id};
      next unless has_data($values);
      foreach my $package (keys %{$values}) {
          next if $ppms->{$id}->{$package};
          $delete->{$id}->{$package} = 
              $ppm_ids->{$id}->{$package};
      }
  }
  $self->{delete} = $delete;
  return 1;
}

package CPAN::Search::Lite::State;

1;

__END__

=head1 NAME

CPAN::Search::Lite::State - get state information on the database

=head1 DESCRIPTION

This module gets information on the current state of the
database and compares it to that obtained from the CPAN
index files from I<CPAN::Search::Lite::Info> and from the
repositories from I<CPAN::Search::Lite::PPM>. For each of the
four tables I<dists>, I<mods>, I<auths>, and I<ppms>,
two methods are used to get this information:

=over 3

=item * C<ids>

This method gets the ids of the relevant names, and
versions, if applicable, in the table.

=item * C<state>

This method compares the information in the tables
obtained from the C<ids> method to that from the
CPAN indices and ppm repositories. One of three actions
is then decided, which is subsequently acted upon in 
I<CPAN::Search::Lite::Populate>.

=over 3

=item * C<insert>

If the information in the indices is not in the
database, this information is marked for insertion.

=item * C<update>

If the information in the database is older than that
form the indices (generally, this means an older version),
the information is marked for updating.

=item * C<delete>

If the information in the database is no longer present
in the indices, the information is marked for deletion.

=back

=back

=cut

