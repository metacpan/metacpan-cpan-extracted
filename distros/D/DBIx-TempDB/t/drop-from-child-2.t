BEGIN { $ENV{DBIX_TEMP_DB_KILL_SLEEP_INTERVAL} = 1 }
use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

my $database_name = DBIx::TempDB->new($ENV{TEST_PG_DSN}, auto_create => 0)->_generate_database_name(0);

for (1 .. 2) {

  # Parent
  if (my $pid = fork // die "fork: $!") {
    waitpid $pid, 0;
    sleep 1;
    is $?, 0, "database_name=$database_name for $pid ($$)";
    next;
  }

  # Child
  my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN}, drop_from_child => 2);
  my $dbh   = DBI->connect($tmpdb->dsn);
  exit($dbh->{pg_db} eq $database_name ? 0 : 42);
}

done_testing;
