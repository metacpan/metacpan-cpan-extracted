use strict;
use warnings;
use Test::More;

# LIVE regression for karr k46: a pooled call whose real EV::Pg dispatch
# croaks gives its connection back to the pool. t/32 proves the same claims
# against a stand-in; this file makes the real EV::Pg croak, against a real
# PostgreSQL, on a pool of one.
#
# Two real ways to make EV::Pg croak before it queues the callback:
#   * a busy connection. A statement is left in flight on the pool's only
#     connection and the connection is handed back idle -- what any path does
#     that releases too early (the k13 COPY bug did exactly this). The next
#     dispatch on it croaks "PQsendQueryParams failed: another command is
#     already in progress" (query: "PQsendQuery failed: ..."). The connection
#     is healthy again once the statement is done, so the next call completes.
#   * a lost connection. The backend is terminated from a second session
#     (pg_terminate_backend -- only this file's own sessions). Once EV::Pg has
#     noticed, every dispatch croaks "not connected". Inside a COPY the loss is
#     noticed by put_copy_data's flush: EV::Pg drops the COPY callback without
#     its second firing, the next put croaks, and so does put_copy_end.
#     Outside a COPY a pool no longer gets there: since karr k49 it retires a
#     connection the moment EV::Pg reports it lost, so the next call gets a
#     fresh connection instead of the dead one (t/42-pool-retire-dead-live.t).
#     A dispatch on a lost connection is pinned offline (t/32, t/41).
#
# Since the pool resets a connection when a borrow ends (karr k99, core k398) a
# connection cannot be handed back busy by a release: DISCARD ALL cannot go out
# on it, the reset fails and the connection is retired. So the busy cases lend
# the busy connection from the pool's acquire, the one place left where a
# dispatch can meet a statement in flight, and claim what follows: the call
# fails with EV::Pg's croak, nothing is left checked out, the busy connection is
# retired by the reset that cannot run on it (not idled), and the next call
# completes on a fresh one. A temporary table does not outlive its borrow, so
# the COPY cases use a table of the file's own.
#
# What this file claims, per path (select_async, notify, copy_in):
#   a. the call fails with EV::Pg's own error;
#   b. nothing is left checked out, and a pool of one does not list its one
#      connection twice;
#   c. the next acquire resolves -- and on a healthy connection the next call
#      completes;
#   d. no callback of this transport dies out of EV::Pg.
#
# Before the fix b and c failed: the connection stayed checked out and the
# next call died with "... is pending and the EV loop has nothing left that
# could complete it" (the EV Future's own guard, karr k44); the COPY Future
# never settled at all. Every wait here is bounded by a watchdog, and alarm is
# the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;
use DBIO::PostgreSQL::EV::Pool;
use PoolReset;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my @SELECT = ('pg_namespace', ['nspname'], { nspname => 'pg_catalog' });

sub harness {
  return DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
}

# A pool that lends a connection with a statement in flight on it, once, when
# armed: the statement runs on the connection the acquire resolves with.
{
  package T33::BusyPool;
  our @ISA = ('DBIO::PostgreSQL::EV::Pool');
  our ($ARMED, $DONE);
  sub acquire {
    my $self = shift;
    my $f = $self->SUPER::acquire(@_);
    if ($ARMED) {
      $ARMED = 0;
      $f->on_done(sub { $_[0]->query('SELECT pg_sleep(0.3)', sub { $DONE = 1 }) });
    }
    return $f;
  }
}

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

# Run the loop until $cond is true, 10 seconds at most.
sub run_until {
  my ($cond) = @_;
  my $expired = 0;
  EV::now_update();
  my $dog = EV::timer(10, 0, sub { $expired = 1 });
  EV::run(EV::RUN_ONCE()) until $cond->() || $expired;
  return !$expired;
}

# Run the loop a little, so anything that would fire late -- a second release
# -- has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The pool's one connection, borrowed for $code and handed back.
sub with_conn {
  my ($h, $code) = @_;
  my ($ok, $pg) = wait_for($h->pool->acquire);
  die "acquire failed: $pg" unless $ok;
  my @r = $code->($pg);
  $h->pool->release($pg);
  return @r;
}

# The next connection the pool lends has a statement in flight on it. Returns
# a coderef that waits until that statement is over -- finished, or cut off when
# the connection is closed.
sub lend_busy {
  my ($h) = @_;
  bless $h->pool, 'T33::BusyPool' unless $h->pool->isa('T33::BusyPool');
  ($T33::BusyPool::ARMED, $T33::BusyPool::DONE) = (1, 0);
  return sub { run_until(sub { $T33::BusyPool::DONE }) or die "the in-flight statement never ended\n" };
}

sub terminate {
  my ($h, $pid) = @_;
  my ($ok) = $h->sync_storage->dbh->selectrow_array(
    'SELECT pg_terminate_backend(?, 5000)', undef, $pid,
  );
  return $ok;
}

# The table the COPY cases load: a table of the file's own, dropped at the
# end. (A temporary table would be gone with the borrow that made it.)
my $COPY_TABLE = "k46_copy_$$";
my @TABLES;
END { for my $h (@TABLES) { local $@; eval { $h->sync_storage->dbh->do("DROP TABLE IF EXISTS $COPY_TABLE"); 1 } } }

sub copy_table {
  my ($h) = @_;
  $h->sync_storage->dbh->do("DROP TABLE IF EXISTS $COPY_TABLE");
  $h->sync_storage->dbh->do("CREATE TABLE $COPY_TABLE (id int, name text)");
  push @TABLES, $h;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# a. + b. for a connection that was busy when it was lent: the call fails with
# EV::Pg's croak, and the busy connection is retired by its reset (DISCARD ALL
# cannot go out on it), so nothing is checked out and nothing is idled busy.
sub fails_and_is_retired {
  my ($label, $h, $f, $error) = @_;
  my ($ok, $err) = wait_for($f);
  ok !$ok, "$label: the call fails";
  like $err, $error, "$label: with EV::Pg's croak";
  PoolReset->until_reset($h->async);
  settle();
  my $pool = $h->pool;
  is $pool->available, $pool->size, "$label: nothing is left checked out";
  cmp_ok $pool->size, '<=', 1, "$label: and the busy connection is not kept: at most the pool's one is there";
}

# a. + b. + c. for a lost connection.
sub fails_and_nothing_checked_out {
  my ($label, $h, $f, $error) = @_;
  my ($ok, $err) = wait_for($f);
  ok !$ok, "$label: the call fails";
  like $err, $error, "$label: with EV::Pg's croak";
  settle();
  my $pool = $h->pool;
  is $pool->available, $pool->size, "$label: nothing is left checked out";
  cmp_ok $pool->available, '<=', 1, "$label: and the connection is not listed twice";
  my ($acquired, $conn) = wait_for($pool->acquire);
  ok $acquired, "$label: the next acquire on the pool of one resolves"
    or diag "it failed: $conn";
  $pool->release($conn) if $acquired;
}

my $BUSY_PARAMS = qr/^PQsendQueryParams failed: another command is already in progress/;
my $BUSY_QUERY  = qr/^PQsendQuery failed: another command is already in progress/;
my $LOST        = qr/^not connected\n\z/;

# --- select_async (_dispatch_query) on a busy connection ---------------------

{
  my $h = harness();
  my ($warm) = wait_for($h->async->select_async(@SELECT));
  ok $warm, 'select_async: the connection is up';

  my $finish = lend_busy($h);
  fails_and_is_retired('select_async, busy', $h, $h->async->select_async(@SELECT), $BUSY_PARAMS);
  $finish->();
  my ($ok, @rows) = wait_for($h->async->select_async(@SELECT));
  ok $ok, 'select_async, busy: the next call gets a connection';
  is_deeply \@rows, [ [ 'pg_catalog' ] ], 'select_async, busy: and completes';
  no_callback_died('select_async, busy');
  $h->disconnect;
}

# --- notify (_dispatch_notify) on a busy connection ---------------------------

{
  my $h = harness();
  my ($warm) = wait_for($h->async->notify('k46_live', 'warm'));
  ok $warm, 'notify: the connection is up';

  my $finish = lend_busy($h);
  fails_and_is_retired('notify, busy', $h, $h->async->notify('k46_live', 'x'), $BUSY_PARAMS);
  $finish->();
  my ($ok) = wait_for($h->async->notify('k46_live', 'y'));
  ok $ok, 'notify, busy: the next call completes';
  no_callback_died('notify, busy');
  $h->disconnect;
}

# --- copy_in: the COPY command on a busy connection ---------------------------

my $two_rows = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  $put->([ 2, 'b' ]);
};

{
  my $h = harness();
  copy_table($h);

  my $finish = lend_busy($h);
  fails_and_is_retired('copy_in, busy', $h, $h->async->copy_in($COPY_TABLE, [qw( id name )], $two_rows), $BUSY_QUERY);
  $finish->();
  my ($ok, @r) = wait_for($h->async->copy_in($COPY_TABLE, [qw( id name )], $two_rows));
  ok $ok, 'copy_in, busy: the next COPY completes'
    or diag "it failed: $r[0]";
  is_deeply \@r, [ 2 ], 'copy_in, busy: and loads its rows';
  no_callback_died('copy_in, busy');
  $h->disconnect;
}

# --- copy_in: the backend is terminated inside the coderef --------------------
#
# The loss surfaces in put_copy_data, which then croaks "not connected"; the
# coderef dies with that, and put_copy_end croaks too, inside the COPY_IN
# firing.

{
  my $h = harness();
  copy_table($h);
  my ($pid) = with_conn($h, sub { $_[0]->backend_pid });

  my $f = $h->async->copy_in($COPY_TABLE, [qw( id name )], sub {
    my ($put) = @_;
    terminate($h, $pid) or die "pg_terminate_backend($pid) failed\n";
    select undef, undef, undef, 0.2;
    $put->([ $_, 'x' x 200 ]) for 1 .. 20_000;
  });
  fails_and_nothing_checked_out('copy_in, terminated during the COPY', $h, $f, $LOST);
  no_callback_died('copy_in, terminated during the COPY');
  $h->disconnect;
}

done_testing;
