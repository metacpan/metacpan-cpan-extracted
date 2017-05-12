#!perl
use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';

my @cleanup;

END {
  &$_ foreach @cleanup;
}

sub setup {
  my ($dbh, $dbname) = @_;
  Class::Persist->dbh($dbh);
  eval {Class::Persist->destroy_DB_infrastructure()};
  ok (Class::Persist->setup_DB_infrastructure(), "Setup for $dbname");
  push @cleanup, sub {
    Class::Persist->dbh($dbh);
    Class::Persist->destroy_DB_infrastructure();
  }
}

{
  my %served;
  my %max = (MySQL => 1, Pg => 1);
  sub db_factory {
    my $dbname = shift;
    my $dbh;
    die "Only know how to generate $max{$dbname} $dbname"
      if defined $max{$dbname} and ($served{$dbname}||0) >= $max{$dbname};

    if ($dbname eq 'SQLite') {
      # Can we manage a SQLite DB?
      my (undef, $dbfile) = tempfile();
      push @cleanup, sub {unlink $dbfile if -e $dbfile };

      return DBI->connect("dbi:SQLite:dbname=$dbfile", '', '',
        { AutoCommit => 1,
          PrintError => 0,
          sqlite_handle_binary_nulls=>1
        });
    } elsif ($dbname eq 'MySQL') {
      $dbh = DBI->connect('DBI:mysql:database=test', '', '',
        {PrintError => 0});
    } elsif ($dbname eq 'Pg') {
      # Warn=>0 to silence those
      # "NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index ...
      # messages
      $dbh = DBI->connect("dbi:Pg:dbname=test", '', '',
        {PrintError => 0, Warn=>0});
    } else {
      die "Unknown DB name $dbname";
    }
    $served{$dbname}++;
    return $dbh;
  }
}

sub test_sub_with_dbs {
  my ($db_names, $sub) = @_;
  $db_names ||= [qw (SQLite Pg MySQL)];
  my $dbs;

  foreach my $name (@$db_names) {
    my $dbh = eval {db_factory($name)};

    if ($dbh) {
      $dbs++;
      setup ($dbh, $name);
      &$sub($dbh, $name);
    }
  }
  fail ("No DBs found to test with") unless $dbs;
}

1;
