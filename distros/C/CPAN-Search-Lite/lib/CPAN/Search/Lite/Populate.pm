package CPAN::Search::Lite::Populate;
use strict;
use warnings;
no warnings qw(redefine);
use CPAN::Search::Lite::Util qw($table_id has_data);
use CPAN::Search::Lite::DBI::Index;
use CPAN::Search::Lite::DBI qw($dbh);
use File::Find;
use File::Basename;
use File::Spec::Functions;
use File::Path;
use AI::Categorizer;
use AI::Categorizer::Learner::NaiveBayes;
use AI::Categorizer::Document;
use AI::Categorizer::KnowledgeSet;
use Lingua::StopWords;

our $dbh = $CPAN::Search::Lite::DBI::dbh;

my ($setup, $no_ppm);
my $DEBUG = 1;
our $VERSION = 0.77;

my %tbl2obj;
$tbl2obj{$_} = __PACKAGE__ . '::' . $_ 
    for (qw(dists mods auths ppms chaps reqs));
my %obj2tbl  = reverse %tbl2obj;

sub new {
  my ($class, %args) = @_;
  
  foreach (qw(db user passwd) ) {
    die "Must supply a '$_' argument" unless defined $args{$_};
  }
    
  $setup = $args{setup};
  $no_ppm = $args{no_ppm};

  my $index = $args{index};
  my @tables = qw(dists mods auths);
  push @tables, 'ppms' unless $no_ppm;
  foreach my $table (@tables) {
      my $obj = $index->{$table};
      die "Please supply a CPAN::Search::Lite::Index::$table object"
          unless ($obj and ref($obj) eq "CPAN::Search::Lite::Index::$table");
  }
  my $state = $args{state};
  unless ($setup) {
      die "Please supply a CPAN::Search::Lite::State object"
          unless ($state and ref($state) eq 'CPAN::Search::Lite::State');
  }

  my $cdbi = CPAN::Search::Lite::DBI::Index->new(%args);

  my $no_mirror = $args{no_mirror};
  my $html_root = $args{html_root};
  my $pod_root = $args{pod_root};
  my $cat_threshold = $args{cat_threshold} || 0.998;
  my $no_cat = $args{no_cat};

  unless ($no_mirror) {
      die "Please supply the html root" unless $html_root;
      die "Please supply the pod root" unless $pod_root;
  }
  my $self = {index => $index,
              state => $state,
              obj => {},
              no_mirror => $no_mirror,
              html_root => $html_root,
              pod_root => $pod_root,
              cat_threshold => $cat_threshold,
              no_cat => $no_cat,
              cdbi => $cdbi,
             };
  bless $self, $class;
}

sub populate {
    my $self = shift;

    if ($setup) {
        unless ($self->{cdbi}->create_tables(setup => $setup)) {
            warn "Creating tables failed";
            return;
        }
    }
    unless ($self->create_objs()) {
        warn "Cannot create objects";
        return;
    }
    unless ($self->populate_tables()) {
        warn "Populating tables failed";
        return;
    }
    return 1;
}

sub create_objs {
    my $self = shift;
    my @tables = qw(dists auths mods reqs chaps);
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
            $obj = $pack->new(cdbi => $self->{cdbi}->{objs}->{$table});
        }
        $self->{obj}->{$table} = $obj;
    }
    foreach my $table (@tables) {
        my $obj = $self->{obj}->{$table};
        foreach (@tables) {
            next if ref($obj) eq $tbl2obj{$_};
            $obj->{obj}->{$_} = $self->{obj}->{$_};
        }
    }

    my $pack = __PACKAGE__ . '::cat';
    my $obj = $pack->new(cat_threshold => $self->{cat_threshold});
    foreach (qw(dists auths mods)) {
        $obj->{obj}->{$_} = $self->{obj}->{$_};
    }
    $self->{obj}->{cat} = $obj;

    unless ($setup) {
        my $state = $self->{state};
        my @tables = qw(auths dists mods);
        push @tables, 'ppms' unless $no_ppm;
        my @data = qw(ids insert update delete);

        foreach my $table (@tables) {
            my $state_obj = $state->{obj}->{$table};
            my $pop_obj = $self->{obj}->{$table};
            $pop_obj->{$_} = $state_obj->{$_} for (@data);
        }
    }
    return 1;
}

sub populate_tables {
    my $self = shift;
    my @methods = $setup ? qw(insert) : qw(insert update delete);
    my @tables = qw(auths dists mods reqs chaps);
    push @tables, 'ppms' unless $no_ppm;
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

    unless ($self->{no_cat}) {
        my $cat = $self->{obj}->{cat};
        unless ($cat->categorize()) {
            if (my $error = $cat->{error_msg}) {
                print "Fatal error from ", ref($cat), ": ", $error, $/;
                return;
            }
            else {
                my $info = $cat->{info_msg};
                print "Info from ", ref($cat), ": ", $info, $/;
            }
        }
    }

    return 1;
}

package CPAN::Search::Lite::Populate::auths;
use base qw(CPAN::Search::Lite::Populate);
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

sub insert {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $info = $self->{info};
  my $cdbi = $self->{cdbi};
  my $data = $setup ? $info : $self->{insert};
  unless (has_data($data)) {
    $self->{info_msg} = q{No author data to insert};
    return;
  }
  my $auth_ids = $self->{ids};
  my @fields = qw(cpanid email fullname);
  my $sth = $cdbi->sth_insert(\@fields) or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  foreach my $cpanid (keys %$data) {
    my $values = $info->{$cpanid};
    next unless ($values and $cpanid);
    print "Inserting author $cpanid\n";
    $sth->execute($cpanid, $values->{email}, $values->{fullname})
      or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    $auth_ids->{$cpanid} = $sth->{mysql_insertid};
  }
  $dbh->commit or do {
    $cdbi->db_error($sth);
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  $sth->finish();
  return 1;
}

sub update {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $data = $self->{update};
  my $cdbi = $self->{cdbi};
  unless (has_data($data)) {
    $self->{info_msg} = q{No author data to update};
    return;
  }
  
  my $info = $self->{info};
  
  my @fields = qw(cpanid email fullname);
  foreach my $cpanid (keys %$data) {
    print "Updating author $cpanid\n";
    next unless $data->{$cpanid};
    my $sth = $cdbi->sth_update(\@fields, $data->{$cpanid});
    my $values = $info->{$cpanid};
    next unless ($cpanid and $values);
    $sth->execute($cpanid, $values->{email}, $values->{fullname})
      or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    $sth->finish();
  }
  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub delete {
  my $self = shift;
  $self->{info_msg} = q{No author data to delete};
  return;
}

package CPAN::Search::Lite::Populate::dists;
use base qw(CPAN::Search::Lite::Populate);
use CPAN::Search::Lite::Util qw(has_data);

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
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
  };
  bless $self, $class;
}

sub insert {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  return unless my $auth_obj = $self->{obj}->{auths};
  my $cdbi = $self->{cdbi};
  my $auth_ids = $auth_obj->{ids};
  my $dists = $self->{info};
  my $data = $setup ? $dists : $self->{insert};
  unless (has_data($data)) {
    $self->{info_msg} = q{No dist data to insert};
    return;
  }
  unless ($dists and $auth_ids) {
    $self->{error_msg}->{index} = q{No dist index data available};
    return;
  }
  
  my $dist_ids = $self->{ids};
  my @fields = qw(auth_id dist_name dist_file dist_vers
                  dist_abs size birth readme changes meta install md5);
  my $sth = $cdbi->sth_insert(\@fields) or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  foreach my $distname (keys %$data) {
    my $values = $dists->{$distname};
    my $cpanid = $values->{cpanid};
    next unless ($values and $cpanid and $auth_ids->{$cpanid});
    print "Inserting $distname of $cpanid\n";
    $sth->execute($auth_ids->{$cpanid}, $distname, 
                  $values->{filename}, $values->{version}, 
                  $values->{description}, $values->{size}, 
                  $values->{date}, $values->{readme}, 
                  $values->{changes}, $values->{meta},
                  $values->{install}, $values->{md5}) 
      or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    $dist_ids->{$distname} = $sth->{mysql_insertid};
  }
  $dbh->commit or do {
      $cdbi->db_error($sth);
      $self->{error_msg} = $cdbi->{error_msg};
      return;
  };
  $sth->finish();
  return 1;
}

sub update {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $cdbi = $self->{cdbi};
  my $data = $self->{update};
  unless (has_data($data)) {
    $self->{info_msg} = q{No dist data to update};
    return;
  }
  return unless my $auth_obj = $self->{obj}->{auths};
  my $auth_ids = $auth_obj->{ids};
  my $dists = $self->{info};
  unless ($dists and $auth_ids) {
    $self->{error_msg} = q{No dist index data available};
    return;
  }
  
  my @fields = qw(auth_id dist_name dist_file dist_vers
                  dist_abs size birth readme changes meta install md5);
  foreach my $distname (keys %$data) {
      next unless $data->{$distname};
      my $sth = $cdbi->sth_update(\@fields, $data->{$distname});
      my $values = $dists->{$distname};
      my $cpanid = $values->{cpanid};
      next unless ($values and $cpanid and $auth_ids->{$cpanid});
      print "Updating $distname of $cpanid\n";
      $sth->execute($auth_ids->{$values->{cpanid}}, $distname, 
                    $values->{filename}, $values->{version}, 
                    $values->{description}, $values->{size}, 
                    $values->{date}, $values->{readme}, 
                    $values->{changes}, $values->{meta},
                    $values->{install}, $values->{md5}) 
          or do {
              $cdbi->db_error($sth);
              $self->{error_msg} = $cdbi->{error_msg};
              return;
          };
      $sth->finish();
  }
  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub delete {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $cdbi = $self->{cdbi};
  my $data = $self->{delete};
  unless (has_data($data)) {
    $self->{info_msg} = q{No dist data to delete};
    return;
  }
  
  my $sth = $cdbi->sth_delete('dist_id');
  foreach my $distname(keys %$data) {
    print "Deleting $distname\n";
    $sth->execute($data->{$distname}) or do {
      $cdbi->db_error($sth);
      $self->{error_msg} = $cdbi->{error_msg};
      return;
    };
  }
  $sth->finish();
  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

package CPAN::Search::Lite::Populate::mods;
use base qw(CPAN::Search::Lite::Populate);
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

sub insert {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  my $cdbi = $self->{cdbi};
  my $dist_ids = $dist_obj->{ids};
  my $mods = $self->{info};
  my $data = $setup ? $mods : $self->{insert};
  unless (has_data($data)) {
    $self->{info_msg} = q{No module data to insert};
    return;
  }
  unless ($mods and $dist_ids) {
    $self->{error_msg} = q{No module index data available};
    return;
  }
  
  my $mod_ids = $self->{ids};
  my @fields = qw(dist_id mod_name mod_abs doc src
                  mod_vers dslip chapterid);
  my $sth = $cdbi->sth_insert(\@fields) or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  foreach my $modname(keys %$data) {
    my $values = $mods->{$modname};
    next unless ($values and $dist_ids->{$values->{dist}});
    $sth->execute($dist_ids->{$values->{dist}}, $modname,
                  $values->{description}, $values->{doc},
                  $values->{src}, $values->{version},
                  $values->{dslip}, $values->{chapterid})
      or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    $mod_ids->{$modname} = $sth->{mysql_insertid};
  }
  $dbh->commit or do {
    $cdbi->db_error($sth);
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  $sth->finish();
  return 1;
}

sub update {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $cdbi = $self->{cdbi};
  my $data = $self->{update};
  unless (has_data($data)) {
    $self->{info_msg} = q{No module data to update};
    return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  my $dist_ids = $dist_obj->{ids};
  my $mods = $self->{info};
  unless ($dist_ids and $mods) {
    $self->{error_msg} = q{No module index data available};
    return;
  }
  
  my @fields = qw(dist_id mod_name mod_abs doc src
                  mod_vers dslip chapterid);
  foreach my $modname (keys %$data) {
      next unless $data->{$modname};
      print "Updating $modname\n";
      my $sth = $cdbi->sth_update(\@fields, $data->{$modname});
      my $values = $mods->{$modname};
      next unless ($values and $dist_ids->{$values->{dist}});
      $sth->execute($dist_ids->{$values->{dist}}, $modname,
                    $values->{description}, $values->{doc},
                    $values->{src}, $values->{version},
                    $values->{dslip}, $values->{chapterid})
          or do {
              $cdbi->db_error($sth);
              $self->{error_msg} = $cdbi->{error_msg};
              return;
          };
      $sth->finish();
  }
  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

sub delete {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
        return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  my $cdbi = $self->{cdbi};
  my $data = $dist_obj->{delete};
  if (has_data($data)) {
    my $sth = $cdbi->sth_delete('dist_id');
    foreach my $distname(keys %$data) {
      $sth->execute($data->{$distname}) or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    }
    $sth->finish();
  }

  $data = $self->{delete};
  if (has_data($data)) {
    my $sth = $cdbi->sth_delete('mod_id');
    foreach my $modname(keys %$data) {
      $sth->execute($data->{$modname}) or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
      print "Deleting $modname\n";
    }
  }

  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

package CPAN::Search::Lite::Populate::chaps;
use base qw(CPAN::Search::Lite::Populate);
use CPAN::Search::Lite::Util qw(has_data);

sub new {
  my ($class, %args) = @_;
  my $cdbi = $args{cdbi};
  die "No dbi object available"
    unless ($cdbi and ref($cdbi) eq 'CPAN::Search::Lite::DBI::Index::chaps');
  my $self = {
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
             };
  bless $self, $class;
}

sub insert {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  my $cdbi = $self->{cdbi};
  my $dist_insert = $dist_obj->{insert};
  my $dists = $dist_obj->{info};
  my $dist_ids = $dist_obj->{ids};
  my $data = $setup ? $dists : $dist_insert;
  unless (has_data($data)) {
    $self->{info_msg} = q{No chap data to insert};
    return;
  }
  unless ($dists and $dist_ids) {
    $self->{error_msg} = q{No chap index data available};
    return;
  }
  
  my @fields = qw(chapterid dist_id subchapter);
  my $sth = $cdbi->sth_insert(\@fields) or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  foreach my $dist (keys %$data) {
    my $values = $dists->{$dist};
    next unless defined $values->{chapterid};
    foreach my $chap_id(keys %{$values->{chapterid}}) {
      foreach my $sub_chap(keys %{$values->{chapterid}->{$chap_id}}) {
        next unless $dist_ids->{$dist};
        $sth->execute($chap_id, $dist_ids->{$dist}, $sub_chap)
          or do {
            $cdbi->db_error($sth);
            $self->{error_msg} = $cdbi->{error_msg};
            return;
          };
      }
    }
  }
  $dbh->commit or do {
    $cdbi->db_error($sth);
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  $sth->finish();
  return 1;
}

sub update {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $cdbi = $self->{cdbi};
  return unless my $dist_obj = $self->{obj}->{dists};
  my $dists = $dist_obj->{info};
  my $dist_ids = $dist_obj->{ids};
  my $data = $dist_obj->{update};
  unless (has_data($data)) {
    $self->{info_msg} = q{No chap data to update};
    return;
  }
  unless ($dist_ids and $dists) {
    $self->{error_msg} = q{No chap index data available};
    return;
  }
  
  my $sth = $cdbi->sth_delete('dist_id');
  foreach my $distname(keys %$data) {
      next unless $data->{$distname};
      $sth->execute($data->{$distname}) or do {
          $cdbi->db_error($sth);
          $self->{error_msg} = $cdbi->{error_msg};
          return;
      };
  }
  $sth->finish();
  
  my @fields = qw(chapterid dist_id subchapter);
  $sth = $cdbi->sth_insert(\@fields);
  foreach my $dist (keys %$data) {
    my $values = $dists->{$dist};
    next unless defined $values->{chapterid};
    foreach my $chap_id(keys %{$values->{chapterid}}) {
      foreach my $sub_chap(keys %{$values->{chapterid}->{$chap_id}}) {
        next unless $dist_ids->{$dist};
        $sth->execute($chap_id, $dist_ids->{$dist}, $sub_chap)
          or do {
            $cdbi->db_error($sth);
            $self->{error_msg} = $cdbi->{error_msg};
            return;
          };
      }
    }
  }
  $dbh->commit or do {
    $cdbi->db_error($sth);
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  $sth->finish();
  return 1;
}

sub delete {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
        return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  my $cdbi = $self->{cdbi};
  my $data = $dist_obj->{delete};
  unless (has_data($data)) {
    $self->{info_msg} = q{No chap data to delete};
    return;
  }
  
  my $sth = $cdbi->sth_delete('dist_id');
  foreach my $distname(keys %$data) {
    $sth->execute($data->{$distname}) or do {
      $cdbi->db_error($sth);
      $self->{error_msg} = $cdbi->{error_msg};
      return;
    };
  }
  $sth->finish();
  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

package CPAN::Search::Lite::Populate::reqs;
use base qw(CPAN::Search::Lite::Populate);
use CPAN::Search::Lite::Util qw(has_data);

sub new {
  my ($class, %args) = @_;
  my $cdbi = $args{cdbi};
  die "No dbi object available"
    unless ($cdbi and ref($cdbi) eq 'CPAN::Search::Lite::DBI::Index::reqs');
  my $self = {
              obj => {},
              error_msg => '',
              info_msg => '',
              cdbi => $cdbi,
             };
  bless $self, $class;
}

sub insert {
    my $self = shift;
    unless ($dbh) {
        $self->{error_msg} = q{No db handle available};
        return;
    }
    return unless my $dist_obj = $self->{obj}->{dists};
    return unless my $mod_obj = $self->{obj}->{mods};
    my $cdbi = $self->{cdbi};
    my $dist_insert = $dist_obj->{insert};
    my $dists = $dist_obj->{info};
    my $dist_ids = $dist_obj->{ids};
    my $mod_ids = $mod_obj->{ids};
    my $data = $setup ? $dists : $dist_insert;
    unless (has_data($data)) {
        $self->{info_msg} = q{No req data to insert};
        return;
    }
    unless ($dist_ids and $mod_ids and $dists) {
        $self->{error_msg} = q{No req index data available};
        return;
    }
    
    my @fields = qw(dist_id mod_id req_vers);
    my $sth = $cdbi->sth_insert(\@fields) or do {
        $self->{error_msg} = $cdbi->{error_msg};
        return;
    };
    foreach my $dist (keys %$data) {
        my $values = $dists->{$dist};
        my $requires = $values->{requires};
        next unless (defined $requires);
        if ( ref($requires) eq 'HASH')  {
            foreach my $module (keys %{$requires}) {
                next unless ($dist_ids->{$dist} and $mod_ids->{$module});
                $sth->execute($dist_ids->{$dist}, $mod_ids->{$module}, 
                              $requires->{$module})
                    or do {
                        $cdbi->db_error($sth);
                        $self->{error_msg} = $cdbi->{error_msg};
                        return;
                    };
            }
        }
        else {
            my $module = $requires;
            next unless ($dist_ids->{$dist} and $mod_ids->{$module});
            $sth->execute($dist_ids->{$dist}, $mod_ids->{$module}, 0)
                or do {
                    $cdbi->db_error($sth);
                    $self->{error_msg} = $cdbi->{error_msg};
                    return;
                };
        }
    }
    $dbh->commit or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
    };
    $sth->finish();
    return 1;
}

sub update {
    my $self = shift;
    unless ($dbh) {
        $self->{error_msg} = q{No db handle available};
        return;
    }
    my $cdbi = $self->{cdbi};
    return unless my $dist_obj = $self->{obj}->{dists};
    return unless my $mod_obj = $self->{obj}->{mods};
    my $dists = $dist_obj->{info};
    my $dist_ids = $dist_obj->{ids};
    my $mod_ids = $mod_obj->{ids};
    my $data = $dist_obj->{update};
    unless (has_data($data)) {
        $self->{info_msg} = q{No req data to update};
        return;
    }
    unless ($dist_ids and $mod_ids and $dists) {
        $self->{error_msg} = q{No author index data available};
        return;
    }
    
    my $sth = $cdbi->sth_delete('dist_id');
    foreach my $distname(keys %$data) {
        next unless $data->{$distname};
        $sth->execute($data->{$distname}) or do {
            $cdbi->db_error($sth);
            $self->{error_msg} = $cdbi->{error_msg};
            return;
        };
    }
    $sth->finish();
    
    my @fields = qw(dist_id mod_id req_vers);
    $sth = $cdbi->sth_insert(\@fields);
    foreach my $dist (keys %$data) {
        my $values = $dists->{$dist};
        my $requires = $values->{requires};
        next unless defined $requires;
        if (ref($requires) eq 'HASH') {
            foreach my $module (keys %{$requires}) {
                next unless ($dist_ids->{$dist} and $mod_ids->{$module});
                $sth->execute($dist_ids->{$dist}, $mod_ids->{$module},
                              $requires->{$module})
                    or do {
                        $cdbi->db_error($sth);
                        $self->{error_msg} = $cdbi->{error_msg};
                        return;
                    };
            }
        }
        else {
            my $module = $requires;
            next unless ($dist_ids->{$dist} and $mod_ids->{$module});
            $sth->execute($dist_ids->{$dist}, $mod_ids->{$module}, 0)
                or do {
                    $cdbi->db_error($sth);
                    $self->{error_msg} = $cdbi->{error_msg};
                    return;
                };
        }
    }
    $dbh->commit or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
    };
    $sth->finish();
    return 1;
}

sub delete {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  return unless my $mod_obj = $self->{obj}->{mods};
  my $cdbi = $self->{cdbi};
  my $data = $dist_obj->{delete};
  if (has_data($data)) {  
    my $sth = $cdbi->sth_delete('dist_id');
    foreach my $distname(keys %$data) {
      $sth->execute($data->{$distname}) or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    }
    $sth->finish();
  }

  $data = $mod_obj->{delete};
  if (has_data($data)) {
    my $sth = $cdbi->sth_delete('mod_id');
    foreach my $modname(keys %$data) {
      $sth->execute($data->{$modname}) or do {
        $cdbi->db_error($sth);
        $self->{error_msg} = $cdbi->{error_msg};
        return;
      };
    }
  }

  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

package CPAN::Search::Lite::Populate::ppms;
use base qw(CPAN::Search::Lite::Populate);
use CPAN::Search::Lite::Util qw(has_data);

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
              obj => {},
              cdbi => $cdbi,
              error_msg => '',
              info_msg => '',
             };
  bless $self, $class;
}

sub insert {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  return unless my $dist_obj = $self->{obj}->{dists};
  my $cdbi = $self->{cdbi};
  my $dist_ids = $dist_obj->{ids};
  my $ppms = $self->{info};
  my $data = $setup ? $ppms : $self->{insert};
  unless (has_data($data)) {
    $self->{info_msg} = q{No ppm data to insert};
    return;
  }
  unless ($ppms and $dist_ids) {
      $self->{error_msg} = q{No ppm index data available};
      return;
  }
  
  my @fields = qw(dist_id rep_id ppm_vers);
  my $sth = $cdbi->sth_insert(\@fields) or do {
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  foreach my $rep_id (keys %$data) {
      my $values = $data->{$rep_id};
      unless (has_data($values)) {
	print "No data to insert for rep_id=$rep_id\n";
	next;
      }
      foreach my $package (keys %{$values}) {
          print "Inserting $package for rep_id=$rep_id\n";
          $sth->execute($dist_ids->{$package}, 
                        $rep_id, 
                        $values->{$package}->{version})
              or do {
                  $cdbi->db_error($sth);
                  $self->{error_msg} = $cdbi->{error_msg};
                  return;
              };
      }
  }
  $dbh->commit or do {
    $cdbi->db_error($sth);
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  $sth->finish();
  return 1;
}

sub update {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $cdbi = $self->{cdbi};
  my $data = $self->{update};
  unless (has_data($data)) {
    $self->{info_msg} = q{No ppm data to update};
    return;
  }
  foreach my $rep_id (keys %$data) {
    my $values = $data->{$rep_id};
    unless (has_data($values)) {
      print "No data to update for rep_id=$rep_id\n";
      next;
    }
    foreach my $package (keys %{$values}) {
      print "Updating $package for rep_id=$rep_id\n";
      my $dist_id = $values->{$package}->{dist_id};
      my $ppm_vers = $values->{$package}->{ppm_vers};
      next unless ($dist_id and $rep_id);
      my $sql = q{UPDATE LOW_PRIORITY } .
        q{ ppms SET ppm_vers = ? } .
          qq{ WHERE dist_id = $dist_id } .
            qq { AND rep_id = $rep_id };
      my $sth = $dbh->prepare($sql) or do {
        $self->db_error();
        return;
      };
      $sth->execute($ppm_vers) or do {
        $self->db_error($sth);
        return;
      };
      $sth->finish;
    }
  }
  $dbh->commit or do {
    $self->db_error();
    return;
  };
  return 1;
}

sub delete {
  my $self = shift;
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $cdbi = $self->{cdbi};
  my $data = $self->{delete};
  unless (has_data($data)) {
    $self->{info_msg} = q{No ppm data to delete};
    return;
  }
  foreach my $rep_id (keys %$data) {
      next unless $rep_id;
      my $values = $data->{$rep_id};
      unless (has_data($values)) {
	print "No data to delete for rep_id=$rep_id\n";
	next;
      }
      my $sth = $cdbi->sth_delete('dist_id', $rep_id);
      foreach my $package (keys %{$values}) {
          print "Deleting $package from rep_id=$rep_id\n";
          $sth->execute($values->{$package}) or do {
              $cdbi->db_error($sth);
              $self->{error_msg} = $cdbi->{error_msg};
              return;
          };
      }
      $sth->finish();
  }
  $dbh->commit or do {
    $cdbi->db_error();
    $self->{error_msg} = $cdbi->{error_msg};
    return;
  };
  return 1;
}

package CPAN::Search::Lite::Populate::cat;
use base qw(CPAN::Search::Lite::Populate);
use CPAN::Search::Lite::Util qw(has_data);

my %features = (content_weights => {
                                    subject => 2,
                                    body => 1,
                                   },
                stopwords => Lingua::StopWords::getStopWords('en'),
                stemming => 'porter',
               );

my $chaps = {
  2 => {subject => q{Perl Core Modules},
        body => q{Perl Core Modules},
       },
  3 => {subject => q{Development Support},
        body => q{Development Support},
       },
  4 => {subject => q{Operating System Interfaces},
        body => q{Operating System Interfaces},
       },
  5 => {subject => q{Networking Devices IPC},
        body => q{Network Devices IPC FTP Socket},
       },
  6 => {subject => q{Data Type Utilities},
        body => q{Data Type Utilities Date Time Math Tie List Tree Class Algorithm Sort Statistics},
       },
  7 => {subject => q{Database Interfaces},
        body => q{Database Interfaces DBD DBI SQL},
       },
  8 => {subject => q{User Interfaces},
        body => q{User Interfaces Tk Term Curses Dialogue Log},
       },
  9 => {subject => q{Language Interfaces},
        body => q{Language Interfaces},
       },
  10 => {subject => q{File Names Systems Locking},
         body => q{File Name System Locking Directory Dir Stat cwd},
        },
  11 => {subject => q{String Lang Text Proc},
         body => q{String Language Text Processing XML Parse},
        },
  12 => {subject => q{Opt Arg Param Proc},
         body => q{Option Argument Parameters Processing Argv Config Getopt},
        },
  13 => {subject => q{Internationalization Locale},
         body => q{Internationalization Locale Unicode I18N},
        },
  14 => {subject => q{Security and Encryption},
         body => q{Security Encryption Authentication Authen Crypt Digest PGP Des},
        },
  15 => {subject => q{World Wide Web HTML HTTP CGI},
         body => q{World Wide Web HTML HTTP CGI WWW Apache MIME Kwiki URI URL},
        },
  16 => {subject => q{Server and Daemon Utilities},
         body => q{Server Daemon Utilties Event},
        },
  17 => {subject => q{Archiving and Compression},
         body => q{Archive Compress File tar gzip gz zip bzip},
        },
  18 => {subject => q{Images Pixmaps Bitmaps},
         body => q{Image Pixmap Bitmap Chart Graph Graphic},
        },
  19 => {subject => q{Mail and Usenet News},
         body => q{Mail Usenet News Sendmail NNTP SMTP IMAP POP3 MIME},
        },
  20 => {subject => q{Control Flow Utilities},
         body => q{Control Flow Utilities callback exception hook},
        },
  21 => {subject => q{File Handle Input Output},
         body => q{File Handle Input Output Dir Directory Log IO},
        },
  22 => {subject => q{Microsoft Windows Modules},
         body => q{Microsoft Windows Modules Win32 Win32API},
        },
  23 => {subject => q{Miscellaneous Modules},
         body => q{Miscellaneous Modules},
        },
  24 => {subject => q{Commercial Software Interfaces},
         body => q{Commercial Software Interfaces},
        },
  26 => {subject => q{Documentation},
         body => q{Documentation},
        },
  27 => {subject => q{Pragma},
         body => q{Pragma},
        },
  28 => {subject => q{Perl6},
         body => q{Perl6},
        },
  99 => {subject => q{Not In Modulelist},
         body => q{Not In Modulelist},
        },
};

sub new {
  my ($class, %args) = @_;
  my $self = {
              obj => {},
              error_msg => '',
              info_msg => '',
              learner => {},
              missing => {},
              cat_threshold => $args{cat_threshold},
             };
  bless $self, $class;
}

sub categorize {
    my $self = shift;
    $self->train() or return;
    $self->missing() or return;
    $self->insert_and_update() or return;
    return 1;
}

sub train {
    my $self = shift;
    return unless my $mod_obj = $self->{obj}->{mods};
    my $mod_info = $mod_obj->{info};
    my ($docs);

    foreach my $mod_name (%$mod_info) {
        (my $subject = $mod_name) =~ s{::}{ }g;
        my $body = '';
        my $abs = $mod_info->{$mod_name}->{description};
        ($body = $abs) =~ s{::}{ }g if $abs;
        my $chapterid = $mod_info->{$mod_name}->{chapterid};
        if ($chapterid) {
            $docs->{$mod_name} = {categories => [$chapterid],
                                  content => {subject => $subject,
                                              body => $body,
                                             },
                                 };
        }
    }

    foreach my $cat(keys %$chaps) {
        $docs->{$cat} = {categories => [$cat],
                         content => {subject => $chaps->{$cat}->{subject},
                                     body => $chaps->{$cat}->{body},
                                    },
                        };
    }
    my $c = 
        AI::Categorizer->new(
                             knowledge_set => 
                             AI::Categorizer::KnowledgeSet->new( name => 'CSL',
                                                               ),
                             verbose => 1,
                            );
    while (my ($name, $data) = each %$docs) {
        $c->knowledge_set->make_document(name => $name, %$data, %features);
    }

    my $learner = $c->learner;
    $learner->train;
    $self->{learner} = $learner;
    return 1;
}

sub missing {
    my $self = shift;
    unless ($dbh) {
        $self->{error_msg} = q{No db handle available};
        return;
    }
    return unless my $dist_obj = $self->{obj}->{dists};
    my $dist_info = $dist_obj->{info};
    my $missing_mods;
    my $sql = 'SELECT mod_name,mod_id,mod_abs,dist_id ' .
        ' FROM mods WHERE chapterid IS NULL ';
    my $sth = $dbh->prepare($sql) or do {
        $self->db_error();
        return;
    };
    $sth->execute() or do {
        $self->db_error($sth);
        return;
    };
    while (my ($mod_name,$mod_id,$mod_abs,$dist_id,$dist_name) = 
           $sth->fetchrow_array) {
        (my $subject = $mod_name) =~ s{::}{ }g;
        my $body = '';
        ($body = $mod_abs) =~ s{::}{ }g if $mod_abs;
        $missing_mods->{$mod_name} = {content => {subject => $subject,
                                                  body => $body,
                                                 },
                                      dist_id => $dist_id,
                                      mod_id => $mod_id,
                                 };
    }
    $sth->finish;

    my $cat_dists;
    $sql = 'SELECT chapterid,dist_id,subchapter FROM chaps';
    $sth = $dbh->prepare($sql) or do {
        $self->db_error();
        return;
    };
    $sth->execute() or do {
        $self->db_error($sth);
        return;
    };
    while (my ($chapterid, $dist_id, $subchapter) = $sth->fetchrow_array) {
        $cat_dists->{$dist_id}->{$chapterid}->{$subchapter}++;
    }
    $sth->finish;

    my $learner = $self->{learner};
    my $insert_mods;
    my $cat_threshold = $self->{cat_threshold};
    while (my ($name, $data) = each %$missing_mods) {
        my $doc = AI::Categorizer::Document->new( name => $name,
                                                  content => $data->{content},
                                                  %features);
        my $r = $learner->categorize($doc);
        my $b = $r->best_category;
        next unless ($b and $r->scores($b) > $cat_threshold);
        $insert_mods->{$name} = {chapterid => $b,
                                 dist_id => $data->{dist_id},
                                 mod_id => $data->{mod_id},
                                };
    }

    my $insert_dists;
    foreach my $dist (keys %$dist_info) {
        my $dist_id;
        foreach my $module (keys %{$dist_info->{$dist}->{modules}}) {
            my $chapterid = $insert_mods->{$module}->{chapterid};
            next unless defined $chapterid;
            $dist_id = $insert_mods->{$module}->{dist_id};
            next unless defined $dist_id;
            (my $subchapter = $module) =~ s!^([^:]+).*!$1!;
            next unless $subchapter;
            next if $cat_dists->{$dist_id}->{$chapterid}->{$subchapter};
            $insert_dists->{$dist_id}->{$chapterid}->{$subchapter}++;
        }
    }
    $self->{missing} = {mods => $insert_mods, dists => $insert_dists};
    return 1;
}

sub insert_and_update {
    my $self = shift;
    unless ($dbh) {
        $self->{error_msg} = q{No db handle available};
        return;
    }
    return unless my $mod_obj = $self->{obj}->{mods};
    my $mod_ids = $mod_obj->{ids};
    return unless my $dist_obj = $self->{obj}->{dists};
    my $dist_ids = $dist_obj->{ids};
    my %dist_names = reverse %$dist_ids;

    my $update = $self->{missing}->{mods};
    foreach my $module (keys %$update) {
        next unless $update->{$module};
        next unless (my $chapterid = $update->{$module}->{chapterid});
        next unless (my $mod_id = $update->{$module}->{mod_id});
        my $sql = q{UPDATE LOW_PRIORITY } .
            qq{ mods SET chapterid = $chapterid } .
                qq{ WHERE mod_id = $mod_id };
        my $sth = $dbh->prepare($sql) or do {
            $self->db_error();
            return;
        };
        $sth->execute() or do {
            $self->db_error($sth);
            return;
        };
        print "Inserting chapterid = $chapterid for $module\n";
        $sth->finish;
    }
    $dbh->commit or do {
        $self->db_error();
        return;
    };

    my $insert = $self->{missing}->{dists};
    my @fields = qw(chapterid dist_id subchapter);
    my $flds = join ',', @fields;
    my $vals = join ',', map '?', @fields;
    my $sql = q{INSERT LOW_PRIORITY INTO chaps } .
        qq{ ($flds) VALUES ($vals) };
    my $sth = $dbh->prepare($sql) or do {
        $self->db_error();
        return;
    };
    foreach my $dist_id (keys %$insert) {
        foreach my $chapterid (keys %{$insert->{$dist_id}} ) {
            foreach my $subchapter (keys %{$insert->{$dist_id}->{$chapterid}}) {
                $sth->execute($chapterid, $dist_id, $subchapter)
                    or do {
                        $self->db_error($sth);
                        return;
                    };
                print "Inserting chapter info: $chapterid/$subchapter for $dist_names{$dist_id}\n";
            }
        }
    }
    $dbh->commit or do {
        $self->db_error($sth);
        return;
    };
    $sth->finish();
    return 1;
}

package CPAN::Search::Lite::Populate;
use CPAN::Search::Lite::Util qw(has_data);

sub db_error {
  my ($obj, $sth) = @_;
  return unless $dbh;
  $sth->finish if $sth;
  $obj->{error_msg} = q{Database error: } . $dbh->errstr;
}

1;

__END__

=head1 NAME

CPAN::Search::Lite::Populate - create and populate database tables

=head1 DESCRIPTION

This module is responsible for creating the tables
(if C<setup> is passed as an option) and then for 
inserting, updating, or deleting (as appropriate) the
relevant information from the indices of
I<CPAN::Search::Lite::Info> and I<CPAN::Search::Lite::PPM> and the
state information from I<CPAN::Search::Lite::State>. It does
this through the C<insert>, C<update>, and C<delete>
methods associated with each table.

Note that the tables are created with the C<setup> argument
passed into the C<new> method when creating the
C<CPAN::Search::Lite::Index> object; existing tables will be
dropped.

=head1 TABLES

The tables used are described below.

=head2 mods

This table contains module information, and is created as

  mod_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
  dist_id SMALLINT UNSIGNED NOT NULL
  mod_name VARCHAR(100) NOT NULL
  mod_abs TINYTEXT
  doc bool
  mod_vers VARCHAR(10)
  dslip CHAR(5)
  chapterid TINYINT(2) UNSIGNED
  PRIMARY KEY (mod_id)
  FULLTEXT (mod_abs)
  KEY (dist_id)
  KEY (mod_name(100))

=over 3

=item * mod_id

This is the primary (unique) key of the table.

=item * dist_id

This key corresponds to the id of the associated distribution
in the C<dists> table.

=item * mod_name

This is the module's name.

=item * mod_abs

This is a description, if available, of the module.

=item * doc

This value, if true, signifies that documentation for the
module exists, and is located, eg, in F<dist_name/Foo/Bar.pm>
for a module C<Foo::Bar> in the C<dist_name> distribution.

=item * src

This value, if true, signifies that the source code for the
module exists, and is located, eg, in F<dist_name/Foo/Bar.pm>
for a module C<Foo::Bar> in the C<dist_name> distribution.

=item * mod_vers

This value, if present, gives the version of the module.

=item * dslip

This is a 5 character string expressing the dslip
(development, support, language, interface, public
license) information.

=item * chapterid

This number corresponds to the chapter id of the module,
if present.

=back

=head2 dists

This table contains distribution information, and is created as

  dist_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
  stamp TIMESTAMP(8)
  auth_id SMALLINT UNSIGNED NOT NULL
  dist_name VARCHAR(90) NOT NULL
  dist_file VARCHAR(110) NOT NULL
  dist_vers VARCHAR(20)
  dist_abs TINYTEXT
  size MEDIUMINT UNSIGNED NOT NULL
  birth DATE NOT NULL
  readme bool
  changes bool
  meta bool
  install bool
  PRIMARY KEY (dist_id)
  FULLTEXT (dist_abs)
  KEY (auth_id)
  KEY (dist_name(90))

=over 3

=item * dist_id

This is the primary (unique) key of the table.

=item * stamp

This is a timestamp for the table indicating when the
entry was either inserted or last updated.

=item * auth_id

This corresponds to the CPAN author id of the distribution
in the C<auths> table.

=item * dist_name

This corresponds to the distribution name (eg, for
F<My-Distname-0.22.tar.gz>, C<dist_name> will be C<My-Distname>).

=item * dist_file

This corresponds to the CPAN file name.

=item * dist_vers

This is the version of the CPAN file (eg, for
F<My-Distname-0.22.tar.gz>, C<dist_vers> will be C<0.22>).

=item * dist_abs

This is a description of the distribtion. If not directly
supplied, the description for, eg, C<Foo::Bar>, if present, will 
be used for the C<Foo-Bar> distribution.

=item * size

This corresponds to the size of the distribution, in bytes.

=item * birth

This corresponds to the last modified time
of the distribution, in the form I<YYYY/MM/DD>.

=item * readme

This value, if true, indicates that a F<README> file for
the distribution is available.

=item * changes

This value, if true, indicates that a F<Changes> file for
the distribution is available.

=item * meta

This value, if true, indicates that a F<META.yml> file for
the distribution is available.

=item * install

This value, if true, indicates that an F<INSTALL> file for
the distribution is available.

=back

=head2 auths

This table contains CPAN author information, and is created as

  auth_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
  cpanid VARCHAR(20) NOT NULL
  fullname VARCHAR(40) NOT NULL
  email TINYTEXT
  PRIMARY KEY (auth_id)
  FULLTEXT (fullname)
  KEY (cpanid(20))

=over 3

=item * auth_id

This is the primary (unique) key of the table.

=item * cpanid

This gives the CPAN author id.

=item * fullname

This is the full name of the author.

=item * email

This is the supplied email address of the author.

=back

=head2 chaps

This table contains chapter information associated with
distributions. PAUSE allows one, when registering modules,
to associate a chapter id with each module (see the C<mods>
table). This information is used here to associate chapters
(and subchapters) with distributions in the following manner.
Suppose a distribution C<Quantum-Theory> contains a module
C<Beta::Decay> with chapter id C<55>, and
another module C<Laser> with chapter id C<87>. The
C<Quantum-Theory> distribution will then have two
entries in this table - C<chapterid> of I<55> and
C<subchapter> of I<Beta>, and C<chapterid> of I<87> and
C<subchapter> of I<Laser>.

The table is created as follows.

  chap_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
  chapterid TINYINT UNSIGNED NOT NULL
  dist_id SMALLINT UNSIGNED NOT NULL
  subchapter TINYTEXT
  KEY (dist_id)

=over 3

=item * chap_id

This is the primary (unique) key of the table.

=item * chapterid

This number corresponds to the chapter id.

=item * dist_id

This is the id corresponding to the distribution in the
C<dists> table.

=item * subchapter

This is the subchapter.

=back

=head2 reqs

This table lists the prerequisites of the distribution,
as found in the F<META.yml> file (if supplied - note that
only relatively recent versions of C<ExtUtils::MakeMaker>
or C<Module::Build> generate this file when making a
distribution). The table is created as

  req_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
  dist_id SMALLINT UNSIGNED NOT NULL
  mod_id SMALLINT UNSIGNED NOT NULL
  req_vers VARCHAR(10)
  KEY (dist_id)

=over 3

=item * req_id

This is the primary (unique) key of the table.

=item * dist_id

This corresponds to the id of the distribution in the
C<dists> table.

=item * mod_id

This corresponds to the id of the prerequisite module
in the C<mods> table.

=item * req_vers

This is the version of the prerequisite module, if specified.

=back

=head2 ppms

This table contains information on Win32 ppm
packages available in the repositories specified
in C<$repositories> of L<CPAN::Search::Lite::Util>.
The table is created as

  ppm_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
  dist_id SMALLINT UNSIGNED NOT NULL
  rep_id TINYINT(2) UNSIGNED NOT NULL
  ppm_vers VARCHAR(20)
  KEY (dist_id)

=over 3

=item * ppm_id

This is the primary (unique) key of the table.

=item * dist_id

This is the id of the distribution appearing in the
C<dists> table.

=item * rep_id

This is the id of the repository appearing in the
C<$repositories> data structure.

=item * ppm_vers

This is the version of the ppm package found.

=back

=head2 reps

This table contains information on the Win32 ppm
repositories specified in C<$repositories> of 
L<CPAN::Search::Lite::Util>.
The table is created as

  rep_id SMALLINT UNSIGNED NOT NULL
  abs TINYTEXT
  browse TINYTEXT
  perl VARCHAR(10)
  alias VARCHAR(20)
  KEY (rep_id)

=over 3

=item * rep_id

This is the primary (unique) key of the table, and
corresponds to the C<rep_id> of the C<ppms> table.

=item * abs

This is a description of the repository.

=item * browse

This is a URL where one can browse the repository.

=item * perl

This specifies the perl version the repository corresponds to.

=item * alias

This specifies a short alias for the repository.

=back

=head2 chapters

This contains information on the chapters.
The table is created as

  chapterid SMALLINT UNSIGNED NOT NULL
  chap_link TINYTEXT
  KEY (chapterid)

=over 3

=item * chapterid

This is the id of the distribution appearing in the
C<dists> table.

This is the primary (unique) key of the table, and
corresponds to the C<chapterid> of the C<dists>, C<mods>,
and C<chaps> table.

=item * chap_link

This is a description of the chapter that C<chapterid> corresponds
to (eg, C<File_Handle_Input_Output>).

=back

=head1 CATEGORIES

When uploading a module to PAUSE, there exists an option
to assign it to one of 24 broad categories. However, many
modules have not been assigned such a category, for one
reason or another. When populating the tables, the
I<AI::Categorizer> module is used to guess a possible
category for those modules that haven't been assigned one,
based on a training set based on the modules that have been
assigned a category (see <AI::Categorizer> for general
details). If this guess is above a configurable
threshold (see L<CPAN::Search::Lite::Index>, the guess is
accepted and subsequently inserted into the database, as
well as updating the categories associated with the
module's distribution.

=head1 SEE ALSO

L<CPAN::Search::Lite::Index>

=cut
