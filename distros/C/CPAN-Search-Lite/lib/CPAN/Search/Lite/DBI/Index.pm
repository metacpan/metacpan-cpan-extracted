package CPAN::Search::Lite::DBI::Index;
use CPAN::Search::Lite::DBI qw($dbh);
use base qw(CPAN::Search::Lite::DBI);

use strict;
use warnings;
our $VERSION = 0.77;

package CPAN::Search::Lite::DBI::Index::reps;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);
use CPAN::Search::Lite::Util qw($repositories);
use HTTP::Date;

sub populate {
  my $self = shift;

  my %months = ('Jan' => '01',
                'Feb' => '02',
                'Mar' => '03',
                'Apr' => '04',
                'May' => '05',
                'Jun' => '06',
                'Jul' => '07',
                'Aug' => '08',
                'Sep' => '09',
                'Oct' => '10',
                'Nov' => '11',
                'Dec' => '12',
               );
  my $string = time2str(time);
  my ($wday, $day, $month, $year, $time, $tz) = split ' ', $string;
  my $stamp = qq{$year-$months{$month}-$day $time};

  my @fields = qw(rep_id abs browse perl alias mtime);
  my $sth = $self->sth_insert(\@fields) or do {
    $self->db_error();
    return;
  };

  foreach my $rep_id(keys %$repositories) {
    my $value = $repositories->{$rep_id};
    $sth->execute($rep_id, $value->{desc}, $value->{browse},
                  $value->{PerlV}, $value->{alias}, $stamp)
      or do {
        $self->db_error($sth);
        return;
      };
  }
  $dbh->commit or do {
    $self->db_error($sth);
    return;
  };
  $sth->finish();
  return 1;
}

package CPAN::Search::Lite::DBI::Index::chapters;
use CPAN::Search::Lite::DBI qw($dbh);
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::Util qw(%chaps);

sub populate {
  my $self = shift;
  my @fields = qw(chapterid chap_link);
  my $sth = $self->sth_insert(\@fields) or do {
    $self->db_error();
    return;
  };

  foreach my $chapterid(keys %chaps) {
    $sth->execute($chapterid, $chaps{$chapterid})
      or do {
        $self->db_error($sth);
        return;
      };
  }
  $dbh->commit or do {
    $self->db_error($sth);
    return;
  };
  $sth->finish();
  return 1;
}

package CPAN::Search::Lite::DBI::Index::ppms;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);

sub fetch_ids {
  my $self = shift;
  my ($ppm_ids, $ppm_versions);
  my $sql = q{SELECT rep_id,dist_name,dists.dist_id,ppm_vers} .
    q{ FROM dists,ppms} .
      q{ WHERE ppms.dist_id = dists.dist_id};
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  while (my ($rep_id, $distname, $dist_id, $ppm_vers) = 
         $sth->fetchrow_array()) {
    $ppm_ids->{$rep_id}->{$distname} = $dist_id;
    $ppm_versions->{$rep_id}->{$distname} = $ppm_vers;
  }
  $sth->finish();
  return ($ppm_ids, $ppm_versions);
}

package CPAN::Search::Lite::DBI::Index::chaps;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Index::reqs;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Index::mods;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Index::dists;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);

sub fetch_ids {
  my $self = shift;
  my $sql = sprintf(qq{SELECT %s,%s,%s FROM %s},
                    $self->{id}, $self->{name}, 'dist_vers',
                    $self->{table});
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  my ($ids, $versions);
  while (my ($id, $key, $vers) = $sth->fetchrow_array()) {
    $ids->{$key} = $id;
    $versions->{$key} = $vers;
  }
  $sth->finish;
  return ($ids, $versions);
}

package CPAN::Search::Lite::DBI::Index::auths;
use base qw(CPAN::Search::Lite::DBI::Index);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Index;
use CPAN::Search::Lite::DBI qw($tables);
use CPAN::Search::Lite::DBI qw($dbh);

sub fetch_ids {
  my $self = shift;
  my $sql = sprintf(qq{SELECT %s,%s from %s},
                    $self->{id}, $self->{name}, $self->{table});
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  my $ids;
  while (my ($id, $key) = $sth->fetchrow_array()) {
    $ids->{$key} = $id;
  }
  $sth->finish;
  return $ids;
}

sub schema {
  my ($self, $data) = @_;
  my $schema = '';
  foreach my $type (qw(primary other)) {
    foreach my $column (keys %{$data->{$type}}) {
      $schema .= $column . ' ' . $data->{$type}->{$column} . ", ";
    }
  }
  my $key = $data->{key};
  if (defined $key and ref($key) eq 'ARRAY') {
    $schema .= "KEY ($_), " foreach (@$key);
  }
  my $text = $data->{text};
  if (defined $text and ref($text) eq 'ARRAY') {
    $schema .= "FULLTEXT ($_), " foreach (@$text);
  }
  $schema =~ s{, $}{};
  return $schema;
}

sub drop_table {
  my $self = shift;
  my $sql = q{DROP TABLE if exists } . $self->{table};
  my $sth = $dbh->prepare($sql);
  $dbh->do($sql) or do {
    $self->db_error($sth);
    return;
  };
  return 1;
}

sub create_table {
  my ($self, $schema) = @_;
  return unless $schema;
  my $sql = sprintf(qq{CREATE TABLE %s (%s)}, $self->{table}, $schema);
  my $sth = $dbh->prepare($sql);
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  return 1;
}

sub create_tables {
  my ($self, %args) = @_;
  return unless $args{setup};
  my $objs = $self->{objs};
  foreach my $table(keys %$objs) {
    next unless my $schema = $self->schema($tables->{$table});
    my $obj = $objs->{$table};
    $obj->drop_table or return;
    $obj->create_table($schema) or return;
  }
  foreach my $table(qw(chapters reps)) {
    my $obj = $objs->{$table};
    $obj->populate or return;
  }
  return 1;
}

sub sth_insert {
  my ($self, $fields) = @_;
  my $flds = join ',', @$fields;
  my $vals = join ',', map '?', @$fields; 
  my $sql = sprintf(qq{INSERT LOW_PRIORITY INTO %s (%s) VALUES (%s)},
                    $self->{table}, $flds, $vals);
  
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  return $sth;
}

sub sth_update {
  my ($self, $fields, $id, $rep_id) = @_;
  my $set = join ',', map "$_=?", @$fields;
  my $sql = sprintf(qq{UPDATE LOW_PRIORITY %s SET %s WHERE %s = %s},
                    $self->{table}, $set, $self->{id}, $id);
  $sql .= qq { AND rep_id = $rep_id } if ($rep_id);
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  return $sth;
}

sub sth_delete {
  my ($self, $table_id, $rep_id) = @_;
  my $sql = sprintf(qq{DELETE LOW_PRIORITY FROM %s where %s = ?},
                    $self->{table}, $table_id);
  $sql .= qq { AND rep_id = $rep_id } if ($rep_id);
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  return $sth;
}

1;
