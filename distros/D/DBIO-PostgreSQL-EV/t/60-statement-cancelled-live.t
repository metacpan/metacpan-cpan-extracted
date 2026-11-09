use strict;
use warnings;
use Test::More;

# LIVE, karr k62: a statement the server cancels through statement_timeout
# (SQLSTATE 57014, query_canceled), on a real PostgreSQL, through the three
# paths a statement of this transport takes: pooled, pinned, and inside
# txn_do_async.
#
# WHY: DBD::Pg does not die for an async statement cancelled this way -- it
# only sets the handle's state to 57014 -- and the future_io transport had to
# learn to look (dbio-postgresql k83). A cancelled statement that resolves its
# Future is the worst answer a storage can give: the caller takes "no rows"
# for the result, and inside a transaction goes on to COMMIT what PostgreSQL
# has already aborted. By reading EV::Pg's Pg.xs this transport cannot do
# that: a PGRES_FATAL_ERROR result reaches the callback as (undef, $message)
# and the storage fails the Future. The offline files hold that against a
# stand-in EV::Pg (t/41, t/43, t/37, t/21-mock). Whether a real server's
# cancel arrives as such a result, and what state it leaves the connection in,
# only a real server says.
#
# What this file claims, for a `SELECT pg_sleep(1)` under a statement_timeout
# of 50 ms:
#   1. the statement's Future FAILS, with the server's "canceling statement due
#      to statement timeout" -- never a result;
#   2. what it fails with is ONE DBIO::Exception::Server (karr k74, decision
#      (b), ADR 0062 in core) that answers sqlstate 57014 and stringifies to
#      libpq's text, and the SQLSTATE is in the connection's error_fields at
#      the moment the Future fails -- which is where the object takes it from;
#   3. pooled: the connection goes back to the pool, IDLE, and the next call
#      runs on the same backend, with the session its connect gave it -- a
#      cancel is a statement error the session survives, it does not cost the
#      connection (karr k49). The timeout is a connect action (on_connect_do):
#      every borrow's session has its own, since the pool resets the session
#      when a borrow ends and replays the connect actions (karr k99, core k398);
#   4. pinned: the connection stays with its caller, the statement queued
#      behind the cancelled one is sent and answered (karr k48), and the caller
#      hands back a usable connection;
#   5. txn_do_async: the transaction fails with the statement's error. The
#      server has aborted it (INERROR) when the statement fails -- nothing
#      written in it can be committed any more, and its locks are gone,
#      whatever the client does. What is left to the client is to END it: core
#      sends ROLLBACK, and the connection is back in the pool IDLE -- the
#      server lists its backend as "idle", not "idle in transaction (aborted)"
#      -- on the same backend, the transaction's SET LOCAL gone with it;
#   6. no callback of this transport dies out of EV::Pg.
#
# WHAT THE FUTURE FAILS WITH (karr k62, decided under karr k74): one object,
# never a second element and never a string with the code in it. On the pooled
# path a caller holds the Future and never the connection (this file reaches
# it because its pool has one), so the object's sqlstate is all a caller has
# to tell a cancel from any other error -- and the message is the server's, in
# its lc_messages (7 measures that). error_fields is the connection's and is
# the LAST error's: a statement that succeeds afterwards does not clear it. The
# transport therefore builds the object only for an error that is the
# server's -- its text begins with severity and primary of error_fields -- and
# a failure that is not (connection lost) stays a string without a SQLSTATE,
# whatever error_fields still says (8).
#
#   7. where the server has German messages and the role may set lc_messages:
#      the cancel's message is another text, and the SQLSTATE is the same --
#      on the object, not only in error_fields;
#   8. a connection lost after such an error fails with a string that carries
#      no SQLSTATE, although error_fields still holds 57014.
#
# The timeout is set for the session or the transaction only (SET, set_config,
# SET LOCAL) and ends with it; nothing is left on the role or the database. The
# text assertions take the server's messages to be English. Every wait on the
# EV loop is bounded by a watchdog, and alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;
use Scalar::Util ();
use PoolReset;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TIMEOUT_MS = 50;
my $CANCELLED  = qr/canceling statement due to statement timeout/;
# What the failure stringifies to: libpq's rendering of the error, as before
# the Future failed with an object (karr k74).
my $LIBPQ_TEXT = "ERROR:  canceling statement due to statement timeout\n";

# A SELECT of SQL expressions through the async API, as a consumer writes it:
# one row of pg_namespace, each expression as literal SQL.
sub exprs {
  my @sql = @_;
  return ('pg_namespace', [ map { \$_ } @sql ], { nspname => 'pg_catalog' });
}

my @PID   = exprs('pg_backend_pid()');
my @SLEEP = exprs('pg_sleep(1)');

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

# A pool of one with its connection up, and that connection's backend pid.
sub fresh {
  my (%attrs) = @_;
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1, %attrs });
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

# The SQLSTATE of the last error on $pg, as EV::Pg has it.
sub sqlstate_of {
  my ($pg) = @_;
  return undef unless $pg && $pg->can('error_fields');
  my $fields = $pg->error_fields;
  return $fields && $fields->{sqlstate};
}

sub is_57014 {
  my ($got, $name) = @_;
  SKIP: {
    skip 'this EV::Pg has no error_fields', 1 unless EV::Pg->can('error_fields');
    is $got, '57014', $name;
  }
}

# What $conn_of->() says at the moment $f fails: recorded from an on_fail of
# $f, which runs inside EV::Pg's callback for the statement's result.
sub at_failure {
  my ($f, $conn_of) = @_;
  my %at;
  $f->on_fail(sub {
    my $pg = $conn_of->();
    %at = (sqlstate => sqlstate_of($pg), status => $pg->transaction_status);
  });
  return \%at;
}

# Claims 1 and 2, for a Future that has been waited for.
sub failed_as_cancelled {
  my ($label, $f) = @_;
  my $failed  = $f && $f->is_ready && $f->is_failed;
  my @failure = $failed ? $f->failure : ();
  ok $failed, "$label fails -- a cancelled statement is not a result"
    or diag $f ? 'it is ' . ($f->is_ready ? 'done' : 'pending') : 'it was never issued';
  like $failure[0] // '', $CANCELLED, "$label fails with the server's error";

  is scalar @failure, 1, "$label: with one value, nothing beside it";
  my $error = $failure[0];
  ok Scalar::Util::blessed($error) && $error->isa('DBIO::Exception::Server'),
    "$label: a DBIO::Exception::Server" or diag explain $error;
  is Scalar::Util::blessed($error) ? $error->sqlstate : undef, '57014',
    "$label: the object says SQLSTATE 57014";
  is "$error", $LIBPQ_TEXT, "$label: and stringifies to libpq's text, as the string was";
  return;
}

# --- pooled ---------------------------------------------------------------------

{
  my $label = 'pooled';
  my ($h, $pid) = fresh(on_connect_do => [ "SET statement_timeout = $TIMEOUT_MS" ]);
  my $conn = sub { $h->pool->{_connections}[0] };

  my ($set, @was) = wait_for($h->async->select_async(exprs("current_setting('statement_timeout')")));
  is $set ? $was[0][0] : undef, "${TIMEOUT_MS}ms", "$label: statement_timeout is set on the pool's one session (on_connect_do)"
    or diag $set ? () : "it failed: $was[0]";

  my $f  = $h->async->select_async(@SLEEP);
  my $at = at_failure($f, $conn);
  wait_for($f);
  failed_as_cancelled("$label: the statement", $f);
  is_57014 $at->{sqlstate}, "$label: error_fields has SQLSTATE 57014 as the Future fails";
  is_57014 sqlstate_of($conn->()), "$label: and afterwards";

  PoolReset->until_reset($h->async);
  settle();
  is $h->pool->size, 1, "$label: the pool still has its one connection";
  is $h->pool->available, 1, "$label: back in the pool";
  ok $conn->() && $conn->()->is_connected, "$label: connected";
  is $conn->() && $conn->()->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: IDLE";

  # One statement for all three: it runs under the timeout it reads and ends.
  my ($ok, @r) = wait_for($h->async->select_async(exprs(
    'pg_backend_pid()',
    "current_setting('statement_timeout')",
    "set_config('statement_timeout', '0', false)",
  )));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is $ok ? $r[0][0] : undef, $pid, "$label: on the same backend -- the cancel did not cost the connection";
  is $ok ? $r[0][1] : undef, "${TIMEOUT_MS}ms", "$label: with the session its connect gave it -- its statement_timeout is set again";

  is_57014 sqlstate_of($conn->()),
    "$label: error_fields is the last error's, a statement that succeeded does not clear it (what the freshness check is for)";
  no_callback_died($label);
  $h->disconnect;
}

# --- pinned -----------------------------------------------------------------------

{
  my $label = 'pinned';
  my ($h, $pid) = fresh();
  my ($got, $pg) = wait_for($h->pool->acquire);
  die "acquiring the pool's connection failed: $pg" unless $got;

  my ($set, $set_err) = wait_for($h->query_on($pg, "SET statement_timeout = $TIMEOUT_MS"));
  ok $set, "$label: statement_timeout is set on the session" or diag "it failed: $set_err";

  my $f      = $h->query_on($pg, 'SELECT pg_sleep(1)');
  my $at     = at_failure($f, sub { $pg });
  my $behind = $h->query_on($pg, 'SELECT pg_backend_pid()');
  wait_for($f);
  failed_as_cancelled("$label: the statement", $f);
  is_57014 $at->{sqlstate}, "$label: error_fields has SQLSTATE 57014 as the Future fails";

  my ($ok, @r) = wait_for($behind);
  ok $ok, "$label: the statement queued behind it is sent and answered" or diag "it failed: $r[0]";
  is $ok ? $r[0][0] : undef, $pid, "$label: on the same backend";
  is_57014 sqlstate_of($pg),
    "$label: error_fields is the last error's, a statement that succeeded does not clear it (what the freshness check is for)";

  is $h->pool->available, 0, "$label: the failure did not release the connection -- it is its caller's";
  my ($reset, $reset_err) = wait_for($h->query_on($pg, 'RESET statement_timeout'));
  ok $reset, "$label: the caller's next statement completes" or diag "it failed: $reset_err";
  is $pg->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: IDLE";
  $h->pool->release($pg);
  PoolReset->until_reset($h->async);   # idle once its reset is answered (karr k99)
  is $h->pool->available, 1, "$label: handed back, it is in the pool";

  my ($again, @p) = wait_for($h->async->select_async(@PID));
  is $again ? $p[0][0] : undef, $pid, "$label: and the next pooled call runs on it";
  no_callback_died($label);
  $h->disconnect;
}

# --- txn_do_async ---------------------------------------------------------------

{
  my $label = 'txn_do_async';
  my ($h, $pid) = fresh();
  my @TIMEOUT = exprs("current_setting('statement_timeout')");
  my ($base, @b) = wait_for($h->async->select_async(@TIMEOUT));
  die "reading statement_timeout failed: $b[0]" unless $base;

  my ($stmt, $at);
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async(
      exprs("set_config('statement_timeout', '$TIMEOUT_MS', true)"),
    )->then(sub {
      $stmt = $ctx->select_async(@SLEEP);
      $at   = at_failure($stmt, sub { $ctx->txn_conn });
      return $stmt;
    });
  });
  wait_for($txn);
  failed_as_cancelled("$label: the statement", $stmt);
  failed_as_cancelled("$label: the transaction", $txn);
  is_57014 $at->{sqlstate}, "$label: error_fields has SQLSTATE 57014 as the statement's Future fails";
  is $at->{status}, EV::Pg::PQTRANS_INERROR(),
    "$label: the server has aborted the transaction by then (INERROR)";

  PoolReset->until_reset($h->async);
  settle();
  # Asked from another session: the sync storage's own DBI connection.
  my ($state) = $h->sync_storage->dbh->selectrow_array(
    'SELECT state FROM pg_stat_activity WHERE pid = ?', undef, $pid,
  );
  is $state, 'idle', "$label: the server lists the backend as idle, not idle in transaction (aborted)";

  is $h->pool->size, 1, "$label: the pool still has its one connection";
  is $h->pool->available, 1, "$label: back in the pool";
  my $conn = $h->pool->{_connections}[0];
  is $conn && $conn->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: IDLE -- the transaction ended";
  is_57014 sqlstate_of($conn),
    "$label: error_fields is the last error's, the ROLLBACK that succeeded does not clear it (what the freshness check is for)";

  my ($ok, @r) = wait_for($h->async->select_async(exprs('pg_backend_pid()', "current_setting('statement_timeout')")));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is $ok ? $r[0][0] : undef, $pid, "$label: on the same backend -- rolled back, not retired";
  is $ok ? $r[0][1] : undef, $b[0][0], "$label: with the session's own statement_timeout -- the SET LOCAL ended with the transaction";
  no_callback_died($label);
  $h->disconnect;
}

# --- 7. the message is the server's, in its lc_messages -------------------------

{
  my $label = 'lc_messages de_DE';
  my ($h, $pid) = fresh();
  my ($got, $pg) = wait_for($h->pool->acquire);
  die "acquiring the pool's connection failed: $pg" unless $got;

  SKIP: {
    my ($lc, $lc_err) = wait_for($h->query_on($pg, q{SET lc_messages = 'de_DE.UTF-8'}));
    skip "the server refuses lc_messages de_DE.UTF-8 for this role: $lc_err", 5 unless $lc;
    my ($set) = wait_for($h->query_on($pg, "SET statement_timeout = $TIMEOUT_MS"));
    skip 'statement_timeout could not be set', 5 unless $set;

    my $f = $h->query_on($pg, 'SELECT pg_sleep(1)');
    my ($ok, $err) = wait_for($f);
    ok !$ok, "$label: the statement fails";
    skip 'the server has no German messages', 4 if !$ok && "$err" =~ $CANCELLED;
    note "  with: $err";
    is_57014 sqlstate_of($pg), "$label: with SQLSTATE 57014 in error_fields, whatever the message says";
    my $error = $ok ? undef : $f->failure;
    ok Scalar::Util::blessed($error) && $error->isa('DBIO::Exception::Server'),
      "$label: the Future failed with a DBIO::Exception::Server" or diag explain $error;
    is Scalar::Util::blessed($error) ? $error->sqlstate : undef, '57014',
      "$label: and its sqlstate is 57014, in the server's own language";
  }
  $h->pool->release($pg);
  no_callback_died($label);
  $h->disconnect;
}

# --- 8. a connection lost after an error carries no SQLSTATE --------------------
# error_fields still holds the cancel's 57014 when the connection goes: EV::Pg
# sets it for a server's error result only. The Future of the statement that
# the loss ends fails with a string -- not with an object that would tell the
# caller its statement was cancelled.

{
  my $label = 'connection lost';
  our $KEEP;
  my ($h, $pid) = fresh();

  # One borrow, pinned: the timeout is the borrow's session, set for the
  # cancelled statement and lifted for the one the loss ends. (The session of a
  # pooled call ends with the call, karr k99.)
  my ($got, $pg) = wait_for($h->pool->acquire);
  die "acquiring the pool's connection failed: $pg" unless $got;
  my ($set) = wait_for($h->query_on($pg, "SET statement_timeout = $TIMEOUT_MS"));
  my $cancelled = $h->query_on($pg, 'SELECT pg_sleep(1)');
  wait_for($cancelled);
  failed_as_cancelled("$label: the statement before", $cancelled);
  is_57014 sqlstate_of($pg), "$label: the connection holds SQLSTATE 57014 in error_fields";

  my ($reset) = wait_for($h->query_on($pg, 'RESET statement_timeout'));
  ok $set && $reset, "$label: the timeout is set and lifted on the session";

  # A statement in flight, and the connection ends under it: its socket is shut
  # down on our side, so libpq reads end-of-file and EV::Pg answers every
  # statement queued on it with "connection lost".
  my $fd   = $pg->socket;
  my $f    = $h->query_on($pg, 'SELECT pg_sleep(5)');
  my $kill = EV::timer(0.2, 0, sub {
    open my $sock, '+<&=', $fd or die "fdopen $fd: $!";
    shutdown($sock, 2);
    # the descriptor is libpq's: this handle is kept, never closed by us
    $KEEP = $sock;
  });
  my ($ok, $err) = wait_for($f);
  ok !$ok, "$label: the statement fails";
  ok !ref $err, "$label: with a string, not an object" or diag explain $err;
  unlike "$err", qr/\b57014\b|SQLSTATE/, "$label: without the earlier cancel's SQLSTATE in it";
  is $pg->error_fields && $pg->error_fields->{sqlstate}, '57014',
    "$label: while error_fields of the lost connection still says 57014"
    if $pg->can('error_fields');
  note "  with: $err";

  # the caller hands the lost connection back; the pool retires it
  $h->pool->release($pg);
  settle();
  # the next call completes on a new one
  my ($next, @r) = wait_for($h->async->select_async(@PID));
  ok $next, "$label: the next call completes" or diag "it failed: $r[0]";
  isnt $next ? $r[0][0] : undef, $pid, "$label: on a new backend";
  no_callback_died($label);
  $h->disconnect;
}

done_testing;
