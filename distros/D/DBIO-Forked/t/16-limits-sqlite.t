use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use Time::HiRes ();

# The two limits through core's real connect path, on a real SQLite handle
# (karr k27, part 2). Skips without the driver.
#
# WHY: t/15 drives the backend directly. What only a connect shows is that core
# keeps statement_timeout and max_in_flight out of DBI->connect (an unknown
# connect attribute is refused there) and hands them to the backend.

BEGIN {
  for my $mod (qw(DBD::SQLite DBIO::SQLite::Test DBIO::SQLite::Storage)) {
    eval "require $mod; 1"
      or plan skip_all => "$mod not installed -- skipping SQLite live tests";
  }
}

use DBIO::SQLite::Test;
use DBIO::Forked;

alarm 60;

my $schema = DBIO::SQLite::Test->init_schema(
  storage_type       => 'DBIO::SQLite::Storage',
  sqlite_use_file    => 1,
  no_populate        => 1,
  async              => 'forked',
  statement_timeout  => 30,
  max_in_flight      => 1,
);

my $backend = $schema->storage->async;
isa_ok $backend, 'DBIO::Forked::Storage', 'the connection resolves the forked backend';
is $backend->async_option('statement_timeout'), 30, 'statement_timeout reached the backend';
is $backend->async_option('max_in_flight'),      1, 'max_in_flight reached the backend';

my $held = $schema->storage->txn_do_async(sub { Time::HiRes::sleep(3); 'late' });
my $err = do { local $@; eval { $schema->storage->txn_do_async(sub { 1 }) }; $@ };
like $err, qr/max_in_flight reached/, 'a second concurrent call is refused';

$held->cancel;
is waitpid(-1, WNOHANG), -1, 'the held child is reaped';

is $schema->storage->txn_do_async(sub { 'ran' })->get, 'ran',
  'with the slot free, a call runs on the real handle';

done_testing;
