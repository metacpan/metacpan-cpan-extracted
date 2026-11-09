use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE test for karr k67 / k90 (point 5): shutting a pool down ends the
# SESSIONS of its connections on the server.
#
# WHY live: Pool::_shutdown_connection used to call $mdb->close_async without a
# callback, which EV::MariaDB 0.08 refuses; the error was swallowed and every
# session stayed open until the process ended. Only the server can say whether
# a session is gone. The test names its own sessions by CONNECTION_ID() and
# counts exactly those in information_schema.processlist -- another session of
# the same user (the owning sync storage, other suites) is none of its business.
#
# 1. N pooled connections are warm; their ids are read through each connection.
# 2. All N are in the processlist.
# 3. $async->disconnect shuts the pool down.
# 4. None of the N is in the processlist any more (a bounded wait of a few
#    seconds: the server notices a closed socket asynchronously).

use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

my $N = 3;

my $h = DBIO::MySQL::EV::TestHarness->new(connect_attrs => { pool_size => $N });

my @per_conn = $h->run_on_each_pooled_connection($N, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn, q{SELECT CONNECTION_ID()});
});
my @ids = map { $_->[0][0] } @per_conn;
is scalar(@ids), $N, "the ids of $N pooled sessions were read";
is scalar(keys %{ { map { $_ => 1 } @ids } }), $N, '... and they are distinct sessions';

my $dbh = $h->sync_storage->dbh;   # the observer: the owning sync storage's own session
my $in = join ',', map { int } @ids;
my $count = sub {
  return ($dbh->selectrow_array(
    "SELECT COUNT(*) FROM information_schema.processlist WHERE id IN ($in)"))[0];
};

is $count->(), $N, 'before the shutdown: all of them are sessions on the server';

# k98: a statement waiting behind one in flight (execute_when_idle) on a
# pooled connection is failed when the pool is shut down, not left open.
my $waiter;
{
  my $conn = $h->await($h->pool->acquire);
  my $exec = $h->async->_executor;
  $exec->execute($conn, 'SELECT SLEEP(5)', []);
  $waiter = $exec->execute_when_idle($conn, 'SELECT 1', []);
  ok !$waiter->is_ready, 'k98: the statement waits behind the one in flight';
}

$h->async->disconnect;

ok $waiter->is_failed, 'k98: after the shutdown the waiting statement is failed, not open';
isa_ok(($waiter->failure)[0], 'DBIO::Exception', 'k98: the failure');
like(($waiter->failure)[0] . '', qr/torn down/, 'k98: the message says the connection was torn down');

my $left = $count->();
for (1 .. 50) {
  last if !$left;
  Time::HiRes::sleep(0.1);
  $left = $count->();
}
is $left, 0, 'after the shutdown: none of them is a session on the server any more';

$h->disconnect;

done_testing;
