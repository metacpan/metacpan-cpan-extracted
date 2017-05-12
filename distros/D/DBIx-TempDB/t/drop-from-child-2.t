use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

my $database_name = DBIx::TempDB->new($ENV{TEST_PG_DSN}, auto_create => 0)->_generate_database_name(0);

for (1 .. 2) {
  defined(my $pid = fork) or die "fork: $!";

  # parent
  if ($pid) {
    waitpid $pid, 0;
    is $?, 0, "database_name=$database_name for $pid";
    next;
  }

  # child
  my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN}, drop_from_child => 2);
  my $dbh = DBI->connect($tmpdb->dsn);
  exit +($dbh->{pg_db} eq $database_name) ? 0 : 42;
}

done_testing;
