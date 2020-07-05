use strict;
use Test::More;
use DBIx::TempDB;
use Time::HiRes 'usleep';

plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

my ($database_name, @dsn);

{
  my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN}, drop_from_child => 1);
  my @dsn   = $tmpdb->dsn;
  my $dbh   = DBI->connect(@dsn);
  $database_name ||= $tmpdb->url->dbname;
  is $dbh->{pg_db}, $database_name, "pg_db is $database_name";
}

wait;    # drop database process
ok !eval { DBI->connect(@dsn); 1 }, 'database cleaned up';

for my $sig (qw(INT QUIT TERM)) {
  my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN}, drop_from_child => 1);
  usleep 10e3;
  kill $sig, $tmpdb->{guard}[1] or do { diag "Could not kill $sig, $tmpdb->{drop_pid}"; next };
  wait;
  local $@;
  eval { DBI->connect($tmpdb->dsn) };
  ok $@, "database killed on $sig";
}

done_testing;
