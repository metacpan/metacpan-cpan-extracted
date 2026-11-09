use strict;
use warnings;
use Test::More;

# LIVE, karr k87: a txn_do coderef that RETURNS the Future of a call on the
# STORAGE -- `$storage->txn_do(sub { $storage->select_async(...) })` instead of
# a call on $ctx -- against a real PostgreSQL with a real EV::Pg. The live half
# of t/70-txn-coderef-queued-call-mock.t.
#
# WHY: with a pool of one the call is queued for the connection the transaction
# holds, and the transaction waits for its Future before it sends COMMIT.
# Nothing blocks, so the refusals of karr k71 never looked at it: top level,
# txn_do died with "... nothing left that could complete it" and the
# transaction stayed open on a pinned connection (the pool stuck); in a callback
# it hung. Core k334 made the Future the coderef returned a seam
# (_txn_inner_future); this transport answers it with _refuse_queued, so the
# queued call is taken out of the pool's queue and failed, the coderef's Future
# fails, the transaction rolls back and txn_do dies with the refusal.
#
# What this file claims:
#   1. pool of one, top level, select_async returned: txn_do dies with
#      "Blocking wait refused"; the server holds no transaction afterwards
#      (no session "idle in transaction"), the pool is idle with nobody queued,
#      and the next query runs on the one connection;
#   2. the same with an insert_async: no row is written, then or later;
#   3. pool of one, txn_do_async started in a then callback of the pool's one
#      connection: the transaction starts once the callback has returned, and
#      fails the same way, rolled back, the pool idle;
#   4. pool of one, the legitimate case -- the Future of a call on $ctx is
#      returned: untouched, the row is committed;
#   5. pool of two, top level (MEASURED, not defined): the call finds the second
#      connection idle and RUNS ON IT -- no refusal, the transaction commits
#      with the Future's result, on a backend other than the transaction's. The
#      call is no part of the transaction;
#   6. pool of two, the other connection busy with a statement in flight
#      (MEASURED): the call is queued for the pool, and core refuses it
#      whatever else the pool holds (core k397: a Future the coderef returns
#      that waits in the queue of the transaction's own pool is refused, the
#      transaction rolls back). This transport used to let it wait for the busy
#      connection and commit; it keeps core's default now (_txn_inner_future
#      calls next::method), so the call that waited is refused, not run;
#   7. pool of two, in a then callback of one connection, the transaction on the
#      other (MEASURED): every connection is held by a callback, so the call is
#      refused as in 1 -- a blocking txn_do there dies with the refusal where it
#      hung before.
#
# Every wait is bounded by a watchdog: an EV timer with keepalive(0) that fails
# every caller queued for a connection, so a hang shows up as failed
# assertions instead of a file that never ends.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::EV::Storage;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TAG   = "dbio_k87_$$";
my $TABLE = "dbio_k87_$$";
my $AMPLE = 5;
my @COLS  = qw( tag );

my $REFUSED = qr/\ABlocking wait refused: /;

my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
my %LOGIN    = LiveServer->conninfo;
$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->do("CREATE TABLE $TABLE (tag text NOT NULL)");
$observer->do("INSERT INTO $TABLE (tag) VALUES ('seed')");
END { $observer->do("DROP TABLE IF EXISTS $TABLE") if $observer && $observer->ping }

sub build_storage {
  my ($size) = @_;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { %LOGIN, application_name => $TAG, pool_size => $size }, {} ]);
  return $storage;
}

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.2, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub queued { scalar @{ $_[0]->pool->{_waiters} } }

# Run $code under the watchdog. Answers ok / error / result / hung.
sub bounded {
  my ($storage, $code) = @_;
  my %r = (hung => 0);
  EV::now_update();
  my $dog = EV::timer($AMPLE, 0, sub {
    $r{hung} = 1;
    my $pool = $storage->{pool} or return;
    $_->fail("watchdog: still blocked after ${AMPLE}s\n")
      for grep { !$_->is_ready } splice @{ $pool->{_waiters} };
  });
  $dog->keepalive(0);
  my @result;
  my $ok = eval { @result = $code->(); 1 };
  @r{qw( ok error result )} = ($ok, $ok ? '' : "$@", \@result);
  return \%r;
}

# A Future, waited for with a bound.
sub wait_future {
  my ($storage, $f) = @_;
  return bounded($storage, sub { $f->get });
}

sub select_tag { $_[0]->select_async($TABLE, \@COLS, { tag => $_[1] }) }

sub rows_tagged {
  my ($tag) = @_;
  my ($n) = $observer->selectrow_array("SELECT count(*) FROM $TABLE WHERE tag = ?", undef, $tag);
  return $n;
}

# Sessions of this file's storages the server counts as inside a transaction.
sub open_transactions {
  my ($n) = $observer->selectrow_array(
    "SELECT count(*) FROM pg_stat_activity WHERE application_name = ? AND state LIKE 'idle in transaction%'",
    undef, $TAG);
  return $n;
}

sub nothing_warned {
  my ($label) = @_;
  my @died = grep { /exception in callback|lost a sequence Future/ } @warnings;
  is scalar @died, 0, "$label: no callback died, no sequence Future was lost" or diag @died;
  @warnings = ();
}

# The pool idle with $size connections, the next query running on it.
sub pool_serves {
  my ($label, $storage, $size) = @_;
  settle();
  is open_transactions(), 0, "$label: the server holds no open transaction";
  is queued($storage), 0, "$label: nobody is queued";
  is $storage->pool->available, $size, "$label: the pool is idle";
  my $next = wait_future($storage, select_tag($storage, 'seed'));
  ok $next->{ok} && !$next->{hung}, "$label: the next query completes"
    or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
  is $next->{ok} && scalar @{ $next->{result}[0] }, 1, "$label: with its row";
  nothing_warned($label);
}

# --- 1. pool of one, top level, select_async returned ----------------------------

{
  my $label   = 'pool of one, top level, a select_async returned';
  my $storage = build_storage(1);
  my $r = bounded($storage, sub {
    $storage->txn_do(sub { select_tag($storage, 'seed') });
  });

  ok !$r->{hung}, "$label: it does not hang";
  ok !$r->{ok}, "$label: txn_do dies";
  like $r->{error}, $REFUSED, "$label: with the refusal of the queued call";
  like $r->{error}, qr/\*_async.*->then.*\$ctx->select_async.*pool_size/s,
    "$label: which names the way out";
  pool_serves($label, $storage, 1);
  $storage->disconnect;
}

# --- 2. the same with an insert_async ---------------------------------------------

{
  my $label   = 'pool of one, top level, an insert_async returned';
  my $storage = build_storage(1);
  my $r = bounded($storage, sub {
    $storage->txn_do(sub { $storage->insert_async($TABLE, { tag => 'k87-2' }) });
  });

  ok !$r->{hung}, "$label: it does not hang";
  like $r->{error}, $REFUSED, "$label: txn_do dies with the refusal";
  is rows_tagged('k87-2'), 0, "$label: no row is written";
  settle();
  is rows_tagged('k87-2'), 0, "$label: and none later either";
  pool_serves($label, $storage, 1);
  $storage->disconnect;
}

# --- 3. pool of one, txn_do_async started in a then callback -----------------------

{
  my $label   = 'pool of one, txn_do_async in a then callback';
  my $storage = build_storage(1);
  my $f = select_tag($storage, 'seed')->then(sub {
    return $storage->txn_do_async(sub { select_tag($storage, 'seed') });
  });
  my $r = wait_future($storage, $f);

  ok !$r->{hung}, "$label: it does not hang";
  ok !$r->{ok}, "$label: the transaction fails";
  like $r->{error}, $REFUSED, "$label: with the refusal of the queued call";
  pool_serves($label, $storage, 1);
  $storage->disconnect;
}

# --- 4. the legitimate case: a call on $ctx ----------------------------------------

{
  my $label   = 'pool of one, the Future of a call on $ctx returned';
  my $storage = build_storage(1);
  my $r = bounded($storage, sub {
    $storage->txn_do(sub {
      $_[0]->insert_async($TABLE, { tag => 'k87-4' });
    });
  });

  ok $r->{ok} && !$r->{hung}, "$label: the transaction commits" or diag $r->{error};
  is rows_tagged('k87-4'), 1, "$label: and the row is there";
  pool_serves($label, $storage, 1);
  $storage->disconnect;
}

# --- 5. pool of two, top level: the call runs on the second connection -------------

{
  my $label   = 'pool of two, top level (measured)';
  my $storage = build_storage(2);
  # Warm the pool so that the second connection is open and idle.
  my @both = map { $storage->_query_async('SELECT pg_sleep(0.2), pg_backend_pid()', []) } 1 .. 2;
  wait_future($storage, $_) for @both;
  settle();
  is $storage->pool->size, 2, "$label: (both connections are open)";

  my (%pid);
  my $r = bounded($storage, sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      my $txn_pid = $ctx->txn_conn->backend_pid;
      $pid{txn} = $txn_pid;
      return $storage->insert_async($TABLE, { tag => 'k87-5' })->then(sub {
        return $storage->_query_async('SELECT pg_backend_pid()', []);
      })->then(sub {
        $pid{call} = $_[0];
        return 'from the storage call';
      });
    });
  });

  ok !$r->{hung}, "$label: it does not hang";
  ok $r->{ok}, "$label: the transaction commits, no refusal" or diag $r->{error};
  is $r->{ok} && $r->{result}[0], 'from the storage call', "$label: with the Future's result";
  isnt $pid{call}, $pid{txn}, "$label: the call ran on the other connection";
  is rows_tagged('k87-5'), 1, "$label: and its row is there";
  pool_serves($label, $storage, 2);
  $storage->disconnect;
}

# --- 6. pool of two, the other connection busy with a statement in flight ----------

{
  my $label   = 'pool of two, the other connection busy (measured)';
  my $storage = build_storage(2);
  my @both = map { $storage->_query_async('SELECT pg_backend_pid()', []) } 1 .. 2;
  wait_future($storage, $_) for @both;
  settle();
  is $storage->pool->size, 2, "$label: (both connections are open)";

  my $slow = $storage->_query_async('SELECT pg_sleep(0.5)', []);
  my $txn  = $storage->txn_do_async(sub { select_tag($storage, 'seed') });
  my $r    = wait_future($storage, $txn);
  wait_future($storage, $slow);

  ok !$r->{hung}, "$label: it does not hang";
  ok !$r->{ok}, "$label: the transaction fails" or diag 'it committed';
  like $r->{error}, qr/the coderef returned a Future queued for this transaction's own pool; call it on the context/,
    "$label: with core's refusal of a Future queued for the transaction's own pool";
  is open_transactions(), 0, "$label: it was rolled back, the server holds no open transaction";
  pool_serves($label, $storage, 2);
  $storage->disconnect;
}

# --- 7. pool of two, in a then callback of one connection, transaction on the other -

{
  my $label   = 'pool of two, blocking txn_do in a then callback (measured)';
  my $storage = build_storage(2);
  my %seen;
  my $r = bounded($storage, sub {
    select_tag($storage, 'seed')->then(sub {
      my $ok = eval {
        $storage->txn_do(sub { select_tag($storage, 'seed') });
        1;
      };
      $seen{error} = $ok ? 'it returned' : "$@";
      return $storage->future_class->done('outer');
    })->get;
  });

  ok !$r->{hung}, "$label: it does not hang";
  ok $r->{ok}, "$label: the outer call completes" or diag $r->{error};
  like $seen{error}, $REFUSED, "$label: txn_do dies with the refusal";
  pool_serves($label, $storage, 2);
  $storage->disconnect;
}

settle();
$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->disconnect;

done_testing;
