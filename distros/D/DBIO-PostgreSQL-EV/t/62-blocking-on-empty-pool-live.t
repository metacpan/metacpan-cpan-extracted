use strict;
use warnings;
use Test::More;

# LIVE, karr k73 (c) / karr k71: a blocking storage call made inside a callback
# that holds the pool's last connection, against a real PostgreSQL. The live
# half of t/56-blocking-on-empty-pool-mock.t.
#
# WHY: every blocking storage method is ->get on its *_async sibling, and
# DBIO::PostgreSQL::EV::Future's get runs the EV loop until the Future is
# ready. A then callback on a pooled statement runs while that statement's
# connection is still checked out, and a txn_do coderef runs inside the BEGIN's
# callback on the connection the transaction keeps. A blocking call on the
# STORAGE there needs another connection; with a pool of one it is queued for
# the connection its own caller holds. Until karr k71 that wait HUNG -- it
# neither returned nor died: EV::Pg's read watcher keeps the loop alive while
# the callback being delivered is still counted, so the loop does not run dry
# and the way out "the EV loop has nothing left that could complete it" is not
# taken. This file measured that against PostgreSQL before the fix (karr k73:
# still blocked after a second, queued, nothing sent, the server listing the
# backend as idle). A program that hangs with nothing in flight is the worst
# outcome: no error, no timeout, no CPU. Since karr k71 the wait is refused.
#
# What this file claims:
#   1. the case is the one meant: in a then callback on a pooled statement, and
#      in a txn_do coderef, the pool of one has nothing idle and is at its
#      size; EV::Pg still counts the callback it is delivering to
#      (pending_count 1), and libpq has nothing in flight; the call whose
#      callback it is keeps its own row;
#   2. the blocking call is refused: it dies at once with "Blocking wait
#      refused", naming the size of the pool. It is taken out of the pool's
#      queue as it is refused and nothing is sent for it -- EV::Pg still counts
#      the delivering callback only, and the server lists the backend with its
#      caller's own statement as the last one. It is never sent later either,
#      nobody is left queued, and the pool serves the next call on the same
#      backend. Also with a pool of two, when the call is made in a then
#      callback that runs inside the blocking wait of another then callback:
#      the call chain holds both backends;
#   3. no refusal where the wait can end:
#      a. top level, pool of one: a blocking call queued behind a statement in
#         flight returns once that statement has given the connection back;
#      b. pool of two: a blocking call in a then callback runs on the other
#         backend and returns;
#      c. pool of one: a call in a then callback that is NOT waited for
#         (*_async) is queued and runs once the callback has returned;
#      d. pool of two, in a then callback, the other backend busy with a
#         statement in flight: the blocking call waits for it and returns;
#   4. no callback of this transport dies out of EV::Pg;
#   5. (sections 6, 7 below) a wait given up on any other way takes the queued
#      caller out of the queue too: karr k85 -- a blocking INSERT on the
#      storage after a $ctx statement in flight in a txn_do coderef is refused
#      (k44) and writes no row, in the transaction or outside it; karr k86 --
#      the loop running dry under a queued blocking call leaves nobody queued,
#      the pool gets its connection back and serves the next call.
#
# 5 measures EV::Pg alone, and nothing in lib/ can turn it red: with the pool's
# connection idle, EV::run returns at once -- the read watcher does not keep
# the loop alive when no callback is queued. That is the other half of what
# t/56 stands on, and why a hang inside a callback is not a hang at top level.
#
# Every wait is bounded. A wait that hangs sits in libev; the watchdog -- an EV
# timer with keepalive(0) -- fires there, looks at the pool and the server, and
# fails every caller queued for a connection, so a hang shows up as failed
# assertions instead of a file that never ends. The alarm has no handler:
# should the watchdog not get a wait out, the signal ends the process.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PoolReset;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF   = 'DBIO::PostgreSQL::EV::Future';
my $TAG   = "dbio_k73_block_$$";
my $LIMIT = 1;   # seconds after which EV::run counts as kept alive, in 5
my $AMPLE = 5;   # seconds for a wait that must end: ample, so that only a hang exceeds it

# 2: the refusal.
my $REFUSED = qr/\ABlocking wait refused: /;

# The server's view, from a connection that belongs to no pool.
# A server that is not there fails the file here, with a plan (karr k77).
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
{
  my ($seen_as) = $observer->selectrow_array(
    'SELECT application_name FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
  );
  plan skip_all => 'the test DSN sets an application_name of its own; this file tells its backends apart by PGAPPNAME'
    unless defined $seen_as && $seen_as eq "${TAG}_observer";
}
$ENV{PGAPPNAME} = $TAG;   # every connection a harness opens from here on

# The record of what ran (see tagged). Dropped at the end.
$observer->do("DROP TABLE IF EXISTS public.k73_log_$$");
$observer->do("CREATE TABLE public.k73_log_$$ (n serial PRIMARY KEY, pid int NOT NULL, tag text NOT NULL)");
$observer->do(qq{CREATE OR REPLACE FUNCTION public.k73_tag_$$(text) RETURNS text LANGUAGE plpgsql AS \$\$
  BEGIN INSERT INTO public.k73_log_$$ (pid, tag) VALUES (pg_backend_pid(), \$1); RETURN \$1; END \$\$});
END {
  if ($observer) {
    local ($@, $?);
    eval { $observer->do("DROP TABLE IF EXISTS public.k73_log_$$"); 1 };
    eval { $observer->do("DROP FUNCTION IF EXISTS public.k73_tag_$$(text)"); 1 };
  }
}

# A SELECT of SQL expressions through the async API, as a consumer writes it:
# one row of pg_namespace, each expression as literal SQL.
sub exprs {
  my @sql = @_;
  return ('pg_namespace', [ map { \$_ } @sql ], { nspname => 'pg_catalog' });
}

my @PID = exprs('pg_backend_pid()');

# One row naming the backend it ran on and the call it belongs to. The tag goes
# through a function of the file's own that records it in a table: what a
# backend ran is read there. (The last statement of a backend in
# pg_stat_activity is the pool's reset, DISCARD ALL, once its borrow is over --
# karr k99.)
sub tagged { exprs('pg_backend_pid()', "public.k73_tag_$$('$_[0]')") }

# The tags the server has run, in order, optionally of one backend.
sub ran {
  my ($pid) = @_;
  return @{ $observer->selectcol_arrayref(
    'SELECT tag FROM public.k73_log_' . $$ . ' WHERE (?::int IS NULL OR pid = ?::int) ORDER BY n', undef, $pid, $pid,
  ) };
}

sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the loop for a while, so anything that would fire late has fired.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub conns  { @{ $_[0]->pool->{_connections} } }
sub queued { scalar @{ $_[0]->pool->{_waiters} } }

# A pool of $size with one connection up and idle: the harness, the backend of
# that connection, and the connection.
sub fresh {
  my ($size, %attrs) = @_;
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => $size, %attrs });
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  die "warming the pool failed: $r[0]" unless $ok;
  PoolReset->until_reset($h->async);
  settle();
  $observer->do("DELETE FROM public.k73_log_$$");
  return ($h, $r[0][0], (conns($h))[0]);
}

# What the server says of backend $pid; a hash of empty strings once it is gone.
sub backend {
  my ($pid) = @_;
  my $row = $observer->selectrow_hashref(
    'SELECT state, query FROM pg_catalog.pg_stat_activity WHERE pid = ?', undef, $pid,
  );
  return { map { $_ => $row ? $row->{$_} // '' : '' } qw( state query ) };
}

# The backends the server has for the pool of $h: the owner's DBI connection,
# which carries the same application_name, left out.
sub pool_backends {
  my ($h) = @_;
  my $owner = $h->sync_storage->dbh->{pg_pid};
  return [ grep { $_ != $owner } @{ $observer->selectcol_arrayref(
    'SELECT pid FROM pg_catalog.pg_stat_activity WHERE application_name = ? ORDER BY pid', undef, $TAG,
  ) } ];
}

# Run $code under the watchdog. Answers ok / error / result, and hung: the wait
# was still blocked after $limit seconds. The watchdog then notes what it finds
# -- who is queued, what EV::Pg counts, what the server lists for the pool's
# first backend -- and fails every caller queued for a connection to get the
# wait out.
sub bounded {
  my ($h, $limit, $code) = @_;
  my %r = (hung => 0);
  EV::now_update();
  my $dog = EV::timer($limit, 0, sub {
    my $pool   = $h->pool;
    my ($conn) = @{ $pool->{_connections} };
    $r{hung}    = 1;
    $r{queued}  = scalar @{ $pool->{_waiters} };
    $r{pending} = $conn ? $conn->pending_count : undef;
    $r{server}  = backend($conn ? $conn->backend_pid : 0);
    $_->fail("watchdog: still blocked after ${limit}s\n")
      for grep { !$_->is_ready } splice @{ $pool->{_waiters} };
  });
  $dog->keepalive(0);
  my @result;
  my $ok = eval { @result = $code->(); 1 };
  @r{qw( ok error result )} = ($ok, $ok ? '' : "$@", \@result);
  return \%r;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg" or diag @died;
  @warnings = ();
}

# What the callback that made the blocking call finds right after it came back:
# who is queued, what EV::Pg counts on the callback's connection, and what the
# server lists for its backend.
sub after_the_call {
  my ($h, $conn, $pid) = @_;
  return (queued => queued($h), pending => $conn->pending_count, server => backend($pid));
}

# 2. The blocking call was refused. $r is what bounded found, $error what the
# call died with, $after what after_the_call found, $size the size of the
# pool, and $server_state / $last_query what the server must list for the
# backend whose callback made the call.
sub refused {
  my ($label, $r, $error, $after, $size, $server_state, $last_query) = @_;
  ok !$r->{hung}, "$label: the blocking call does not hang"
    or diag "still blocked after ${AMPLE}s: queued $r->{queued}, EV::Pg counts $r->{pending}, "
          . "the server lists the backend as $r->{server}{state}";
  like $error, $REFUSED, "$label: it dies, refused";
  like $error, qr/\bpool of $size\b/, "$label: naming the size of the pool";
  is $after->{queued}, 0, "$label: it was taken out of the pool's queue as it was refused";
  is $after->{pending}, 1, "$label: nothing was sent for it -- EV::Pg counts the delivering callback only";
  is $after->{server}{state}, $server_state, "$label: and the server lists the backend as $server_state";
  like $after->{server}{query}, $last_query, "$label: its last statement the caller's own";
  return;
}

# 2. The refused call is never sent later either, nobody is left queued, and
# the pool serves the next call on the same backend.
sub pool_serves_on {
  my ($label, $h, $pid, $last_query) = @_;
  PoolReset->until_reset($h->async);
  settle();
  is queued($h), 0, "$label: nobody is left queued for a connection";
  is $h->pool->size, 1, "$label: the pool still has its one connection";
  is $h->pool->available, 1, "$label: idle";
  is scalar(grep { $_ eq 'inner' } ran()), 0, "$label: the refused call was never sent";

  my $next = bounded($h, $AMPLE, sub { $h->async->select(tagged('next')) });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes"
    or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
  is_deeply $next->{result}, [ [ $pid, 'next' ] ], "$label: with its own row, on the same backend";
  settle();
  is scalar(grep { $_ eq 'inner' } ran()), 0, "$label: and the refused call does not run later either";
  is((ran())[-1], 'next', "$label: the last call the server ran is the next one");
  PoolReset->until_reset($h->async);
  is $h->pool->available, 1, "$label: idle again";
  is_deeply pool_backends($h), [ $pid ], "$label: and the server has that one backend for the pool";
  no_callback_died($label);
}

# --- 1. in a then callback on a pooled statement, pool of one --------------------

{
  my $label = 'then callback, pool of one';
  my ($h, $pid, $conn) = fresh(1);
  my $async = $h->async;
  my %seen;
  my $r = bounded($h, $AMPLE, sub {
    $async->select_async(tagged('outer'))->then(sub {
      my @outer = @_;
      @seen{qw( size available pending status )}
        = ($h->pool->size, $h->pool->available, $conn->pending_count, $conn->transaction_status);
      my $ok = eval { $async->select(tagged('inner')); 1 };
      $seen{inner} = $ok ? 'it returned' : "$@";
      $seen{after} = { after_the_call($h, $conn, $pid) };
      return $EVF->done(@outer);
    })->get;
  });

  is_deeply [ @seen{qw( size available )} ], [ 1, 0 ],
    "$label: the callback runs with the pool's one connection checked out -- nothing idle, nothing to spawn";
  is $seen{pending}, 1, "$label: EV::Pg still counts the callback it is delivering to";
  is $seen{status}, EV::Pg::PQTRANS_IDLE(), "$label: and libpq has nothing in flight on it";

  refused($label, $r, $seen{inner} // 'the callback never ran', $seen{after}, 1, 'idle', qr/'outer'/);

  ok $r->{ok}, "$label: the call whose callback it was completes" or diag $r->{error};
  is_deeply $r->{result}, [ [ $pid, 'outer' ] ], "$label: with its own row";
  pool_serves_on($label, $h, $pid, qr/'outer'/);
  $h->disconnect;
}

# --- 1. in a txn_do coderef, pool of one -------------------------------------------

{
  my $label = 'txn_do coderef, pool of one';
  my ($h, $pid, $conn) = fresh(1);
  my $async = $h->async;
  my %seen;
  my $r = bounded($h, $AMPLE, sub {
    $async->txn_do(sub {
      @seen{qw( size available pending status )}
        = ($h->pool->size, $h->pool->available, $conn->pending_count, $conn->transaction_status);
      my $ok  = eval { $async->select(tagged('inner')); 1 };   # on the storage, not on the context
      my $err = $@;
      $seen{after} = { after_the_call($h, $conn, $pid) };
      die $err unless $ok;
      $seen{returned} = 1;
      return 'committed';
    });
  });

  is_deeply [ @seen{qw( size available )} ], [ 1, 0 ],
    "$label: the coderef runs with the pool's one connection pinned -- nothing idle, nothing to spawn";
  is $seen{pending}, 1, "$label: EV::Pg still counts the BEGIN's callback, which the coderef runs in";
  is $seen{status}, EV::Pg::PQTRANS_INTRANS(), "$label: and libpq has nothing in flight, inside the transaction";

  ok !$seen{returned}, "$label: the blocking call did not return to the coderef";
  ok !$r->{ok}, "$label: txn_do dies";
  # with what its coderef died with
  refused($label, $r, $r->{error}, $seen{after}, 1, 'idle in transaction', qr/^BEGIN$/);
  pool_serves_on($label, $h, $pid, qr/^ROLLBACK$/);
  $h->disconnect;
}

# --- 2. pool of two: the call chain holds both backends -----------------------------

{
  my $label = 'then callback inside the blocking wait of a then callback, pool of two';
  my ($h, $pid, $conn) = fresh(2);
  my $async = $h->async;
  my %seen;
  my $r = bounded($h, $AMPLE, sub {
    $async->select_async(tagged('outer'))->then(sub {
      my @outer = @_;
      # Blocks inside the callback of the first backend, for the second: fine.
      $seen{middle} = [ $async->select_async(tagged('middle'))->then(sub {
        my @middle = @_;
        @seen{qw( size available pending )} = ($h->pool->size, $h->pool->available,
          join ' ', map { $_->pending_count } conns($h));
        my $ok = eval { $async->select(tagged('inner')); 1 };
        $seen{inner} = $ok ? 'it returned' : "$@";
        $seen{after} = { after_the_call($h, $conn, $pid) };
        return $EVF->done(@middle);
      })->get ];
      return $EVF->done(@outer);
    })->get;
  });

  is_deeply [ @seen{qw( size available )} ], [ 2, 0 ],
    "$label: the inner callback runs with both connections checked out -- nothing idle, nothing to spawn";
  is $seen{pending}, '1 1', "$label: EV::Pg still counts the callback it is delivering to, on each";

  refused($label, $r, $seen{inner} // 'the callback never ran', $seen{after}, 2, 'idle', qr/'outer'/);

  ok $r->{ok}, "$label: the outer call completes" or diag $r->{error};
  is_deeply $r->{result}, [ [ $pid, 'outer' ] ], "$label: with its own row";
  my ($middle) = @{ $seen{middle} || [] };
  is $middle && $middle->[1], 'middle', "$label: and so does the one it blocked on";
  my $other = $middle ? $middle->[0] : 0;
  ok $other && $other != $pid, "$label: on the other backend";

  # The call each backend ran last, by the tag it recorded.
  my $last = sub { [ map { my @t = ran($_); @t ? $t[-1] : '?' } $pid, $other ] };

  settle();
  is queued($h), 0, "$label: nobody is left queued for a connection";
  is $h->pool->available, 2, "$label: both connections are idle";
  is_deeply $last->(), [qw( outer middle )], "$label: the refused call was never sent, to either backend";
  my $next = bounded($h, $AMPLE, sub { $async->select(tagged('next')) });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes"
    or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
  settle();
  my @last = @{ $last->() };
  is_deeply [ grep { $_ ne 'next' } @last ], [ $last[0] eq 'next' ? 'middle' : 'outer' ],
    "$label: on one of them, and the refused call does not run later either"
    or diag "the backends ran last: @last";
  is $h->pool->available, 2, "$label: both are idle again";
  is_deeply pool_backends($h), [ sort { $a <=> $b } $pid, $other ],
    "$label: and the server has those two backends for the pool";
  no_callback_died($label);
  $h->disconnect;
}

# --- 3a. top level: queued behind a statement in flight ----------------------------

{
  my $label = 'top level, behind a statement in flight';
  my ($h, $pid) = fresh(1);
  my $first = $h->async->select_async(exprs('pg_backend_pid()', 'pg_sleep(0.2)'));
  is queued($h), 0, "$label: (the first call has the connection)";
  my $r = bounded($h, $AMPLE, sub { $h->async->select(tagged('second')) });
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call queued for the busy connection returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is_deeply $r->{result}, [ [ $pid, 'second' ] ], "$label: with its own row, on the connection that statement gave back";
  ok $first->is_done, "$label: after the statement it waited for";
  settle();
  is $h->pool->available, 1, "$label: which is idle again";
  no_callback_died($label);
  $h->disconnect;
}

# --- 3b. pool of two: the callback's call gets the other connection ----------------

{
  my $label = 'then callback, pool of two';
  my ($h, $pid) = fresh(2);
  my $async = $h->async;
  my %seen;
  my $r = bounded($h, $AMPLE, sub {
    $async->select_async(tagged('outer'))->then(sub {
      @seen{qw( size available )} = ($h->pool->size, $h->pool->available);
      my @rows = $async->select(tagged('inner'));
      return $EVF->done(@rows);
    })->get;
  });
  is_deeply [ @seen{qw( size available )} ], [ 1, 0 ],
    "$label: the callback runs with its connection checked out, and the pool has room for one more";
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call in the callback returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  my ($row) = @{ $r->{result} };
  is $row && $row->[1], 'inner', "$label: with its own row";
  ok $row && $row->[0] != $pid, "$label: from another backend, not the one being delivered";
  settle();
  is $h->pool->available, 2, "$label: both connections are idle again";
  is_deeply pool_backends($h), [ sort { $a <=> $b } $pid, $row ? $row->[0] : () ],
    "$label: and the server has those two backends for the pool";
  no_callback_died($label);
  $h->disconnect;
}

# --- 3c. pool of one: a call in the callback that is not waited for ----------------

{
  my $label = 'then callback, pool of one, *_async';
  my ($h, $pid) = fresh(1);
  my $async = $h->async;
  my $inner;
  my $r = bounded($h, $AMPLE, sub {
    $async->select_async(tagged('outer'))->then(sub {
      $inner = $async->select_async(tagged('inner'));
      return $EVF->done(queued($h), $inner->is_ready ? 'ready' : 'pending');
    })->get;
  });
  ok $r->{ok} && !$r->{hung}, "$label: the outer call completes" or diag $r->{error};
  is_deeply $r->{result}, [ 1, 'pending' ],
    "$label: the callback's own call was queued for the connection the callback holds";
  my $got = bounded($h, $AMPLE, sub { $inner->get });
  ok $got->{ok} && !$got->{hung}, "$label: and runs once the callback has returned"
    or diag $got->{hung} ? 'it hung' : "it failed: $got->{error}";
  is_deeply $got->{result}, [ [ $pid, 'inner' ] ], "$label: with its own row, on that same backend";
  settle();
  is $h->pool->available, 1, "$label: which is idle again";
  no_callback_died($label);
  $h->disconnect;
}

# --- 3d. pool of two: the other backend has a statement in flight -------------------

{
  my $label = 'then callback, pool of two, the other connection busy';
  my ($h) = fresh(2);
  my $async = $h->async;
  # Both connections up before the case starts, so that the statement in
  # flight is not raced by a connect.
  my ($warm) = wait_for($EVF->needs_all($async->select_async(@PID), $async->select_async(@PID)));
  settle();
  is $h->pool->available, 2, "$label: (both connections are up and idle)" or diag $warm ? '' : 'warming failed';

  my $slow = $async->select_async(exprs('pg_backend_pid()', 'pg_sleep(0.5)'));
  my %seen;
  my $r = bounded($h, $AMPLE, sub {
    $async->select_async(tagged('outer'))->then(sub {
      @seen{qw( size available before )}
        = ($h->pool->size, $h->pool->available, $slow->is_ready ? 'ready' : 'pending');
      my @rows = $async->select(tagged('inner'));
      $seen{after} = $slow->is_ready ? 'ready' : 'pending';
      return $EVF->done(@rows);
    })->get;
  });
  is_deeply [ @seen{qw( size available before )} ], [ 2, 0, 'pending' ],
    "$label: the callback runs with both connections checked out, the other one by a statement in flight";
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call in the callback returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is $seen{after}, 'ready', "$label: after the statement it waited for";
  my ($row)    = @{ $r->{result} };
  my ($slept)  = $slow->is_done ? $slow->get : ();
  is $row && $row->[1], 'inner', "$label: with its own row";
  ok $row && $slept && $row->[0] == $slept->[0], "$label: from the backend that statement gave back";
  settle();
  is $h->pool->available, 2, "$label: both connections are idle again";
  no_callback_died($label);
  $h->disconnect;
}

# --- 6. karr k85: the k44 refusal takes a queued caller out of the queue -----------
#
# A txn_do coderef sends a $ctx statement and then makes a blocking INSERT on
# the STORAGE. A result is due on the pinned connection, so the k44 refusal
# speaks -- and the INSERT is queued for that very connection. It must not be
# handed the connection once the transaction has ended, and write its row
# outside the transaction after its caller was told it was refused.

for my $variant (
  [ 'the coderef commits', 0 ],
  [ 'the coderef dies with the refusal', 1 ],
) {
  my ($what, $dies) = @$variant;
  my $label = "k85, blocking insert after a \$ctx statement in flight, $what";
  my ($h, $pid) = fresh(1);
  my $table = "dbio_k85_block_$$";
  $observer->do("DROP TABLE IF EXISTS $table");
  $observer->do("CREATE TABLE $table (id serial PRIMARY KEY, name text NOT NULL)");
  my $async = $h->async;
  my %seen;
  my $r = bounded($h, $AMPLE, sub {
    $async->txn_do(sub {
      my ($ctx) = @_;
      my $flying = $ctx->select_async(exprs('pg_backend_pid()', 'pg_sleep(0.3)'));
      my $ok = eval { $async->insert($table, { name => 'k85-refused' }); 1 };
      $seen{error}  = $ok ? 'it returned' : "$@";
      $seen{queued} = queued($h);
      die $seen{error} if $dies;
      return $flying;
    });
  });
  ok !$r->{hung}, "$label: nothing hangs"
    or diag "still blocked: queued $r->{queued}, EV::Pg counts $r->{pending}";
  like $seen{error}, qr/\ABlocking wait refused: .*more result\(s\) due/s, "$label: the INSERT is refused (k44)";
  is $seen{queued}, 0, "$label: and taken out of the pool's queue as it is refused";
  is !$r->{ok}, !!$dies, "$label: txn_do " . ($dies ? 'dies with the refusal' : 'commits')
    or diag $r->{error};
  settle();
  settle();
  my ($rows) = $observer->selectrow_array("SELECT count(*) FROM $table");
  is $rows, 0, "$label: the refused INSERT wrote no row, in the transaction or outside it";
  is queued($h), 0, "$label: nobody is left queued";
  is $h->pool->available, 1, "$label: the connection is back in the pool, idle";
  my $next = bounded($h, $AMPLE, sub { $h->async->select(tagged('next')) });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes" or diag $next->{error};
  is_deeply $next->{result}, [ [ $pid, 'next' ] ], "$label: on the same backend";
  ($rows) = $observer->selectrow_array("SELECT count(*) FROM $table");
  is $rows, 0, "$label: and still no row";
  ok !grep({ /lost a sequence Future/ } @warnings), "$label: no sequence Future was lost" or diag @warnings;
  no_callback_died($label);
  $h->disconnect;
  $observer->do("DROP TABLE IF EXISTS $table");
}

# --- 7. karr k86: the loop runs dry under a queued blocking call ---------------------
#
# A transaction holds the pool's one connection, its coderef returned a Future
# that is not settled yet, nothing is in flight and no callback runs. A
# blocking call is queued, the loop has nothing left, and the wait dies. The
# caller must not stay queued: the next release would hand it the connection
# of a chain nobody holds.

{
  my $label = 'k86, the loop runs dry under a queued blocking call, pool of one';
  # Dry needs a loop with no timer in it: core's acquire_timeout (default 30
  # seconds, core k397) arms one for the queued caller, so the dry loop is asked
  # for with acquire_timeout => 0.
  my ($h, $pid) = fresh(1, acquire_timeout => 0);
  my $async = $h->async;
  my $gate  = $EVF->new;
  my $txn   = $async->txn_do_async(sub { return $gate });
  settle();   # BEGIN is answered and the coderef has returned
  my $r = bounded($h, $AMPLE, sub { $async->select(tagged('inner')) });
  ok !$r->{hung}, "$label: the blocking call does not hang";
  like $r->{error}, qr/is pending and the EV loop has nothing left that could complete it/,
    "$label: it dies, the loop has nothing left";
  is queued($h), 0, "$label: nobody is left queued for the connection";

  $gate->done('committed');
  my ($ok, @res) = wait_for($txn);
  ok $ok, "$label: the transaction ends once its Future is settled" or diag $res[0];
  settle();
  is queued($h), 0, "$label: nobody is queued";
  is $h->pool->available, 1, "$label: the connection came back, idle";
  my $next = bounded($h, $AMPLE, sub { $async->select(tagged('next')) });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes" or diag $next->{error};
  is_deeply $next->{result}, [ [ $pid, 'next' ] ], "$label: on the same backend";
  settle();
  is scalar(grep { $_ eq 'inner' } ran()), 0, "$label: and the dropped call never ran";
  ok !grep({ /lost a sequence Future/ } @warnings), "$label: no sequence Future was lost" or diag @warnings;
  no_callback_died($label);
  $h->disconnect;
}

# --- 5. MEASURED, EV::Pg alone: an idle connection does not keep the loop alive ----

{
  my $label = 'measured, EV::Pg';
  my ($h, $pid) = fresh(1);
  is $h->pool->available, 1, "$label: (the pool's one connection is up and idle)";
  my $broke = 0;
  EV::now_update();
  my $dog = EV::timer($LIMIT, 0, sub { $broke = 1; EV::break() });
  $dog->keepalive(0);
  EV::run();
  ok !$broke, "$label: with nothing in flight EV::run returns at once -- the idle connection's read watcher does not keep the loop alive";
  undef $dog;
  $h->disconnect;
}

$observer->disconnect;

done_testing;
