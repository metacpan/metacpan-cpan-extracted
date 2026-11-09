use strict;
use warnings;
use Test::More;

# LIVE regression for karr k48: a transaction whose coderef dies while one of
# its statements is still in flight on the pinned connection rolls back
# cleanly, and the connection comes back to the pool IDLE. t/43 proves the
# same claims against a stand-in EV::Pg; this file runs them against a real
# PostgreSQL, on a pool of one, driven through the async API as a consumer
# would.
#
# WHY: outside pipeline mode libpq runs one statement at a time on a
# connection, and EV::Pg refuses a second one while the first is in flight
# ("PQsendQueryParams failed: another command is already in progress"). A
# coderef that did `$ctx->insert_async(...); die` -- or whose blocking
# $ctx->insert k44 refuses -- left its INSERT in flight, and core's ROLLBACK
# was refused: txn_do failed with libpq's refusal instead of the coderef's
# error, and the connection went back to the pool with the transaction still
# open. The next call on it failed the same way or ran inside that
# transaction, and its locks blocked DDL from any other session -- a DROP
# TABLE over DBI hung (measured at k44, PostgreSQL 18.6, EV::Pg 0.07). The
# second of two unchained $ctx->*_async died the same way.
#
# What this file claims, for each of: a coderef that dies after
# $ctx->insert_async; one whose blocking $ctx->insert is refused; the same
# through the blocking txn_do:
#   1. the transaction fails with the coderef's own error, not a libpq refusal;
#   2. the row is not there -- not for another session, and not for the next
#      call on the pool, which would see it if it ran inside the transaction;
#   3. the connection comes back to the pool IDLE, and the next call runs on
#      the same backend: it was rolled back, not retired;
#   4. an ALTER TABLE from another session is not blocked (bounded by
#      lock_timeout, so a lock left behind fails the test instead of hanging
#      it);
# and
#   5. two unchained $ctx->insert_async in one coderef both commit, in order;
#   6. no callback of this transport dies out of EV::Pg.
#
# Before the fix 1-5 fail: the error is "another command is already in
# progress", the connection comes back in a transaction, the next call sees
# the uncommitted row and the ALTER TABLE runs into lock_timeout. Every wait on
# the EV loop is bounded by a watchdog, and alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
LiveServer->require_server;

use EV;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TABLE = 'dbio_karr48_inflight';

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

# Wait for $f: (1, @result) once it is done, (0, $error) once it failed. A
# Future still pending after 10 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the loop a little, so anything that would fire late has fired before the
# pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# Another session: the sync storage's own DBI connection, never the pool's.
# Its waits for a lock are bounded.
sub other_session {
  my ($h) = @_;
  my $dbh = $h->sync_storage->dbh;
  $dbh->do(q{SET lock_timeout = '3s'});
  $dbh->do(q{SET statement_timeout = '10s'});
  return $dbh;
}

# A pool of one with its connection up, over a fresh table.
sub fresh {
  my $h   = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
  my $dbh = other_session($h);
  $dbh->do("DROP TABLE IF EXISTS $TABLE");
  $dbh->do("CREATE TABLE $TABLE (id serial PRIMARY KEY, name text NOT NULL)");
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  die "warming the pool failed: $r[0]" unless $ok;
  return ($h, $r[0][0]);
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# Claims 2-4 after a transaction that must have rolled back $name.
sub rolled_back_cleanly {
  my ($label, $h, $pid, $name) = @_;
  settle();
  my $dbh = other_session($h);

  my ($seen) = $dbh->selectrow_array("SELECT count(*) FROM $TABLE WHERE name = ?", undef, $name);
  is $seen, 0, "$label: another session does not see the row";

  is $h->pool->size, 1, "$label: the pool still has its one connection";
  is $h->pool->available, 1, "$label: back in the pool";
  my $conn = $h->pool->{_connections}[0];
  is $conn && $conn->transaction_status, EV::Pg::PQTRANS_IDLE(),
    "$label: IDLE -- the transaction ended, nothing in flight";

  my ($ok, @rows) = wait_for($h->async->select_async($TABLE, ['name'], { name => $name }));
  ok $ok, "$label: the next call completes" or diag "it failed: $rows[0]";
  is scalar @rows, 0, "$label: and does not see the row -- it is not inside the transaction";

  my ($same, @r) = wait_for($h->async->select_async(@PID));
  is $same && $r[0][0], $pid, "$label: on the same backend -- rolled back, not retired";

  ok eval {
    $dbh->do("ALTER TABLE $TABLE ADD COLUMN k48_probe int");
    $dbh->do("ALTER TABLE $TABLE DROP COLUMN k48_probe");
    1;
  }, "$label: another session's ALTER TABLE is not blocked"
    or diag "it failed: $@";
  no_callback_died($label);
}

sub done_with {
  my ($h) = @_;
  $h->disconnect;
  other_session($h)->do("DROP TABLE IF EXISTS $TABLE");
  return;
}

# --- a coderef dies after $ctx->insert_async ---------------------------------

{
  my $label = 'die after insert_async';
  my ($h, $pid) = fresh();
  my ($ok, $err) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert_async($TABLE, { name => 'k48-died' });
    die "k48 coderef died\n";
  }));
  ok !$ok, "$label: the transaction fails";
  is $err, "k48 coderef died\n", "$label: with the coderef's error, not a libpq refusal";
  rolled_back_cleanly($label, $h, $pid, 'k48-died');
  done_with($h);
}

# --- a coderef whose blocking $ctx->insert is refused --------------------------

{
  my $label = 'refused blocking insert';
  my ($h, $pid) = fresh();
  my ($ok, $err) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert($TABLE, { name => 'k48-refused' });
    return 'not reached';
  }));
  ok !$ok, "$label: the transaction fails";
  like $err, qr/^Blocking wait refused/, "$label: with the refusal (karr k44), not a libpq refusal";
  rolled_back_cleanly($label, $h, $pid, 'k48-refused');
  done_with($h);
}

# --- the same through the blocking txn_do --------------------------------------

{
  my $label = 'blocking txn_do';
  my ($h, $pid) = fresh();
  # txn_do has no Future to hand a watchdog; a timeout of its own bounds it
  # instead, and leaves the file's alarm running (karr k88).
  my $ok = eval {
    GuardedWait->run(sub {
      $h->async->txn_do(sub {
        my ($ctx) = @_;
        $ctx->insert_async($TABLE, { name => 'k48-sync' });
        die "k48 sync coderef died\n";
      });
    }, 20, "watchdog: txn_do still blocked after 20s\n");
    1;
  };
  my $err = $@;
  ok !$ok, "$label: txn_do dies";
  is $err, "k48 sync coderef died\n", "$label: with the coderef's error, not a libpq refusal";
  rolled_back_cleanly($label, $h, $pid, 'k48-sync');
  done_with($h);
}

# --- two unchained statements ------------------------------------------------------

{
  my $label = 'two unchained';
  my ($h, $pid) = fresh();
  my ($ok, @r) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    my $one = $ctx->insert_async($TABLE, { name => 'k48-one' });
    my $two = $ctx->insert_async($TABLE, { name => 'k48-two' });
    return $ctx->storage->future_class->needs_all($one, $two);
  }));
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  settle();
  my $names = other_session($h)->selectcol_arrayref("SELECT name FROM $TABLE ORDER BY id");
  is_deeply $names, [qw( k48-one k48-two )], "$label: both rows committed, in order";
  my $conn = $h->pool->{_connections}[0];
  is $conn && $conn->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: the connection is back IDLE";
  is $h->pool->available, 1, "$label: in the pool";
  no_callback_died($label);
  done_with($h);
}

done_testing;
