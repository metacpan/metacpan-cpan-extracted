use strict;
use warnings;
use Test::More;

# LIVE, karr k88: a blocking storage call queued behind a connection the pool
# is still opening, made from inside that opening, against a real PostgreSQL
# with a real EV::Pg and a real re-entry. The live half of
# t/77-blocking-behind-spawn-mock.t.
#
# WHY: a pool opens a connection synchronously, inside acquire, and calls code
# on the way that may come back into the pool -- the AccessBroker asked for
# connect info, whose client may run the EV loop while it fetches, and the
# replay of on_connect_do, which runs the loop until the server has answered.
# Since core k277 the spawn holds its slot throughout, so a call made from
# inside is queued behind it; made blocking, it waits for a connection that is
# handed out only after the spawn has returned, and the spawn is below the wait
# on the call stack. The refusal of karr k71 looked at the pool's connections
# only and did not see it. Measured against PostgreSQL 18.6 with EV::Pg 0.07
# before the fix: with the storage's LISTEN connection open -- its watcher
# keeps the EV loop alive -- the wait HUNG, the caller queued, nothing sent, no
# error, no timeout, no CPU; without it the wait died with "... the EV loop has
# nothing left that could complete it". Every case below has that LISTEN
# connection open, so each of 1 to 4 is a hang without the fix.
#
# What this file claims:
#   1. pool of one, nothing open, the broker's answer itself makes a blocking
#      INSERT on the storage: refused at once with "Blocking wait refused",
#      naming the size of the pool and that the pool is opening one of them in
#      a call this one runs inside; taken out of the queue; no row is written,
#      then or later; the call whose connection was being opened completes and
#      the pool serves the next one;
#   2. the same when the broker's client fetches on a connection of its own and
#      runs the loop until the server has answered, and the blocking INSERT is
#      made by a timer callback that fires in that loop;
#   3. the same for the replacement of a connection whose backend was
#      terminated under a statement, opened for the caller queued behind it;
#   4. the same during the replay of an on_connect_do statement the server
#      takes a while to answer, through a schema: the connection counts by
#      then, and no callback holds it;
#   5. pool of two, one connection held by a running then callback, the other
#      being opened: refused, the text naming the one that is being opened --
#      it said that callbacks hold every one of them;
#   6. no refusal where the wait can end: pool of two, the other connection
#      busy with a statement in flight -- the blocking INSERT in the broker's
#      answer waits for it, runs on the backend it gave back, and its row is
#      there.
#
# Every wait is bounded. A wait that hangs sits in libev; the watchdog -- an EV
# timer with keepalive(0) -- fires there and fails every caller queued for a
# connection, so a hang shows up as failed assertions instead of a file that
# never ends. The alarm has no handler and is never cleared: should the
# watchdog not get a wait out, the signal ends the process.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::Pg;
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::ConnectInfo 'conninfo_string';

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

alarm 180;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF   = 'DBIO::PostgreSQL::EV::Future';
my $TAG   = "dbio_k88_spawn_$$";
my $TABLE = "dbio_k88_spawn_$$";
my $AMPLE = 5;   # seconds for a wait that must end: ample, so that only a hang exceeds it

my $REFUSED   = qr/\ABlocking wait refused: /;
my $ADVICE    = qr/\*_async.*->then.*pool_size/s;
my $CALLBACKS = qr/every one of them is held by a callback/;

# A server that is not there fails the file here, with a plan (karr k77). The
# observer writes nothing but the table the refused INSERTs must leave empty.
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
my %LOGIN    = LiveServer->conninfo;
$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->do("CREATE TABLE $TABLE (tag text NOT NULL)");
END { $observer->do("DROP TABLE IF EXISTS $TABLE") if $observer && $observer->ping }

# An AccessBroker whose answer takes a while: what the test puts in {during}
# happens while it "fetches", once, before it answers the test login.
{
  package K88::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for {
    my ($self) = @_;
    if (my $during = delete $self->{during}) { $during->() }
    return { %{ $self->{answer} } };
  }
}

sub wait_for {
  my ($f, $what) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: $what still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  return $f->get;
}

# Run the loop for a while, so anything that would fire late has fired.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.2, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The storage's LISTEN connection, open: what keeps the EV loop alive in a
# program that listens, and what made the wait a hang.
sub listening {
  my ($storage) = @_;
  wait_for($storage->listen("${TAG}_channel" => sub { }), 'listen');
  return $storage;
}

# The transport with a pool of $size that asks a broker for every connection,
# its LISTEN connection open. Attaching and listening ask the broker too,
# before the test puts anything in it.
sub with_broker {
  my ($size) = @_;
  my $broker  = K88::Broker->new({ %LOGIN, application_name => $TAG });
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ $broker, { pool_size => $size } ]);
  return (listening($storage), $broker);
}

sub conns  { @{ $_[0]->pool->{_connections} } }
sub queued { scalar @{ $_[0]->pool->{_waiters} } }

# What the pool counts: its connections, the idle ones, the spawns in flight
# (core k277) and the callers queued.
sub counts {
  my ($storage) = @_;
  my $pool = $storage->pool;
  return {
    size => $pool->size, available => $pool->available, queued => queued($storage),
    spawning => scalar keys %{ $pool->{_spawning} || {} },
  };
}

# One row naming the backend a call ran on and the call; a blocking INSERT of
# a row tagged $tag. Through the query seam -- the blocking storage methods are
# ->get on what it returns -- as the transport of 1 to 3 has no schema.
sub tagged { $_[0]->_query_async("SELECT pg_backend_pid(), '$_[1]'", []) }
sub insert_block {
  $_[0]->_query_async("INSERT INTO $TABLE (tag) VALUES (?) RETURNING tag", [ $_[1] ])->get;
}

sub rows_tagged {
  my ($tag) = @_;
  my ($n) = $observer->selectrow_array("SELECT count(*) FROM $TABLE WHERE tag = ?", undef, $tag);
  return $n;
}

# Run $code under the watchdog. Answers ok / error / result, and hung: the wait
# was still blocked after $AMPLE seconds, when the watchdog noted what the pool
# counted and failed every caller queued for a connection to get the wait out.
sub bounded {
  my ($storage, $code) = @_;
  my %r = (hung => 0);
  EV::now_update();
  my $dog = EV::timer($AMPLE, 0, sub {
    $r{hung} = 1;
    my $pool = $storage->{pool} or return;
    $r{counts} = counts($storage);
    $_->fail("watchdog: still blocked after ${AMPLE}s\n")
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
  ok !grep({ /lost a sequence Future/ } @warnings), "$label: no sequence Future was lost" or diag @warnings;
  @warnings = ();
}

# The blocking INSERT tagged $tag on $storage, made where the test puts it:
# what the pool counted as it was made, how the call ended, and who was queued
# right after.
sub blocking_insert {
  my ($storage, $seen, $tag) = @_;
  $seen->{at} = counts($storage);
  my @rows;
  my $ok = eval { @rows = insert_block($storage, $tag); 1 };
  $seen->{inner}        = { ok => $ok, error => $ok ? '' : "$@", result => \@rows };
  $seen->{queued_after} = queued($storage);
  return;
}

# The blocking INSERT did not hang: it was refused, told the size of the pool
# and that the pool is opening $opening of its connections in a call this one
# runs inside, left the queue, and wrote no row.
sub refused_behind_spawn {
  my ($label, $seen, $r, $tag, $size, $opening) = @_;
  my $inner = $seen->{inner} || { ok => 0, error => 'the blocking call was never made' };
  ok !$r->{hung}, "$label: the blocking call does not hang"
    or diag "still blocked after ${AMPLE}s; the pool counted "
          . join ', ', map { "$_ $r->{counts}{$_}" } sort keys %{ $r->{counts} || {} };
  ok !$inner->{ok}, "$label: it dies" or diag 'it returned';
  like $inner->{error}, $REFUSED, "$label: refused";
  like $inner->{error}, qr/\bpool of $size\b/, "$label: naming the size of the pool";
  like $inner->{error}, qr/\bthe pool is opening $opening of them in a call this one runs inside\b/,
    "$label: and what holds the connection it waits for -- a spawn it runs inside";
  unlike $inner->{error}, $CALLBACKS, "$label: not that callbacks hold every connection";
  like $inner->{error}, $ADVICE, "$label: and what to do instead -- the *_async methods with ->then, pool_size";
  is $seen->{queued_after}, 0, "$label: it was taken out of the pool's queue";
  is rows_tagged($tag), 0, "$label: and wrote no row";
  return;
}

# After a refusal: the pool has its $size connection(s), idle, nobody queued
# and no spawn in flight; it serves the next call; the refused INSERT has not
# run later either.
sub pool_serves {
  my ($label, $storage, $tag, $size) = @_;
  settle();
  is_deeply counts($storage), { size => $size, available => $size, queued => 0, spawning => 0 },
    "$label: afterwards the pool has $size connection(s), idle, nobody queued, no spawn in flight";
  my $next = bounded($storage, sub { tagged($storage, 'next')->get });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes"
    or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
  is $next->{ok} && $next->{result}[0][1], 'next', "$label: with its own row";
  settle();
  is rows_tagged($tag), 0, "$label: and the refused INSERT does not run later either";
  is $storage->pool->available, $size, "$label: idle again";
  no_callback_died($label);
}

# --- 1. the broker's answer makes the blocking call, pool of one ------------------

{
  my $label = "in the broker's answer, pool of one";
  my $tag   = 'k88-1';
  my ($storage, $broker) = with_broker(1);
  my %seen;
  $broker->{during} = sub { blocking_insert($storage, \%seen, $tag) };
  my $r = bounded($storage, sub { tagged($storage, 'outer')->get });

  is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
    "$label: the call is made with no connection open and the pool's one slot taken by the spawn";
  refused_behind_spawn($label, \%seen, $r, $tag, 1, 1);
  ok $r->{ok}, "$label: the call whose connection was being opened completes -- the broker answered after all"
    or diag $r->{error};
  is $r->{ok} && $r->{result}[0][1], 'outer', "$label: with its own row";
  pool_serves($label, $storage, $tag, 1);
  $storage->disconnect;
}

# --- 2. the broker runs the loop, a timer in it makes the blocking call -----------

{
  my $label = 'in a timer while the broker runs the loop, pool of one';
  my $tag   = 'k88-2';
  my ($storage, $broker) = with_broker(1);
  my (%seen, $fetched);
  $broker->{during} = sub {
    # The broker's client: a connection of its own, the loop run until the
    # server has answered it.
    my $up = 0;
    my $side = EV::Pg->new(
      conninfo   => conninfo_string({ %LOGIN, application_name => "${TAG}_broker" }),
      on_connect => sub { $up = 1 },
      on_error   => sub { $up = $fetched = "failed: $_[0]" },
    );
    EV::run(EV::RUN_ONCE()) until $up;
    $side->query('SELECT pg_sleep(0.3)', sub { $fetched ||= 'fetched' }) unless $fetched;
    my $app = EV::timer(0.05, 0, sub { blocking_insert($storage, \%seen, $tag) });
    EV::run(EV::RUN_ONCE()) until $fetched;
    $side->finish;
  };
  my $r = bounded($storage, sub { tagged($storage, 'outer')->get });

  is $fetched, 'fetched', "$label: (the broker's client got its answer from the server)";
  is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
    "$label: the call is made with no connection open and the pool's one slot taken by the spawn";
  refused_behind_spawn($label, \%seen, $r, $tag, 1, 1);
  ok $r->{ok}, "$label: the call whose connection was being opened completes" or diag $r->{error};
  is $r->{ok} && $r->{result}[0][1], 'outer', "$label: with its own row";
  pool_serves($label, $storage, $tag, 1);
  $storage->disconnect;
}

# --- 3. the replacement of a connection whose backend was terminated -------------

{
  my $label = "in the broker's answer for a replacement connection, pool of one";
  my $tag   = 'k88-3';
  my ($storage, $broker) = with_broker(1);
  my ($warm) = wait_for(tagged($storage, 'warm'), 'warming the pool');
  my $pid    = $warm->[0];
  settle();
  is_deeply [ map { $_->backend_pid } conns($storage) ], [ $pid ], "$label: (the pool's one backend is up)";

  my $first   = $storage->_query_async('SELECT pg_sleep(30)', []);
  my $waiting = tagged($storage, 'waiting');   # queued for the one connection
  settle();
  is queued($storage), 1, "$label: (a caller is queued behind the statement in flight)";
  my %seen;
  $broker->{during} = sub { blocking_insert($storage, \%seen, $tag) };
  # The pool's own backend, by the pid it reported.
  $observer->do('SELECT pg_terminate_backend(?)', undef, $pid);
  my $r = bounded($storage, sub { $waiting->get });

  ok $first->is_failed, "$label: the statement on the terminated backend fails";
  is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
    "$label: the call is made with the dead connection retired, the queued caller off the queue and its spawn in flight";
  refused_behind_spawn($label, \%seen, $r, $tag, 1, 1);
  ok $r->{ok}, "$label: the caller the replacement was opened for completes" or diag $r->{error};
  is $r->{ok} && $r->{result}[0][1], 'waiting', "$label: with its own row";
  isnt $r->{ok} && $r->{result}[0][0], $pid, "$label: on a new backend";
  @warnings = grep { !/terminating connection due to administrator command/ } @warnings;
  pool_serves($label, $storage, $tag, 1);
  $storage->disconnect;
}

# --- 4. during the replay of an on_connect_do statement ---------------------------

{
  my $label = "in a timer during the replay of on_connect_do, pool of one";
  my $tag   = 'k88-4';
  local $ENV{PGAPPNAME} = $TAG;
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => {
    pool_size => 1, on_connect_do => [ 'SELECT pg_sleep(0.4)' ],
  });
  my $storage = listening($h->async);
  my %seen;
  my $app = EV::timer(0.15, 0, sub {
    my ($conn) = conns($storage);
    $seen{pending} = $conn ? $conn->pending_count : 'no connection';
    blocking_insert($storage, \%seen, $tag);
  });
  my $r = bounded($storage, sub { tagged($storage, 'outer')->get });

  is_deeply $seen{at}, { size => 1, available => 0, queued => 0, spawning => 0 },
    "$label: the call is made with the new connection counted, not idle, and no longer listed as a spawn";
  is $seen{pending}, 1, "$label: its connect statement in flight";
  refused_behind_spawn($label, \%seen, $r, $tag, 1, 1);
  ok $r->{ok}, "$label: the call whose connection was being opened completes" or diag $r->{error};
  is $r->{ok} && $r->{result}[0][1], 'outer', "$label: with its own row";
  pool_serves($label, $storage, $tag, 1);
  $h->disconnect;
}

# --- 5. pool of two: one held by a callback, the other being opened ---------------

{
  my $label = "in the broker's answer, inside a then callback, pool of two";
  my $tag   = 'k88-5';
  my ($storage, $broker) = with_broker(2);
  my %seen;
  my $r = bounded($storage, sub {
    tagged($storage, 'outer')->then(sub {
      my @outer = @_;
      $broker->{during} = sub { blocking_insert($storage, \%seen, $tag) };
      $seen{middle} = [ tagged($storage, 'middle')->get ];   # opens the second connection
      return $EVF->done(@outer);
    })->get;
  });

  is_deeply $seen{at}, { size => 1, available => 0, queued => 0, spawning => 1 },
    "$label: the call is made with one connection held by the callback and the other slot taken by the spawn";
  refused_behind_spawn($label, \%seen, $r, $tag, 2, 1);
  ok $r->{ok}, "$label: the call whose callback it was completes" or diag $r->{error};
  is $r->{ok} && $r->{result}[0][1], 'outer', "$label: with its own row";
  is $seen{middle} && $seen{middle}[0][1], 'middle', "$label: and so does the one whose connection was being opened";
  pool_serves($label, $storage, $tag, 2);
  $storage->disconnect;
}

# --- 6. pool of two: the other connection has a statement in flight ---------------

{
  my $label = "in the broker's answer, pool of two, the other connection busy";
  my $tag   = 'k88-6';
  my ($storage, $broker) = with_broker(2);
  my ($warm) = wait_for(tagged($storage, 'warm'), 'warming the pool');
  my $pid    = $warm->[0];
  PoolReset->until_reset($storage);   # the warm call's reset is answered: its connection is the idle one (karr k99)
  my $slow   = $storage->_query_async("SELECT pg_backend_pid(), pg_sleep(0.5)", []);
  settle();   # on the server by now
  my %seen;
  $broker->{during} = sub {
    $seen{before} = $slow->is_ready ? 'ready' : 'pending';
    blocking_insert($storage, \%seen, $tag);
    $seen{after} = $slow->is_ready ? 'ready' : 'pending';
  };
  my $r = bounded($storage, sub { tagged($storage, 'outer')->get });

  is_deeply $seen{at}, { size => 1, available => 0, queued => 0, spawning => 1 },
    "$label: the call is made with one connection checked out and the other slot taken by the spawn";
  is $seen{before}, 'pending', "$label: the checked-out one by a statement in flight";
  ok !$r->{hung}, "$label: nothing hangs";
  ok $seen{inner} && $seen{inner}{ok}, "$label: the blocking INSERT returns"
    or diag $seen{inner} ? "it failed: $seen{inner}{error}" : 'it was never made';
  is $seen{after}, 'ready', "$label: after the statement it waited for";
  is rows_tagged($tag), 1, "$label: and its row is there";
  ok $r->{ok}, "$label: the call whose connection was being opened completes" or diag $r->{error};
  isnt $r->{ok} && $r->{result}[0][0], $pid, "$label: on the new backend";
  settle();
  is_deeply counts($storage), { size => 2, available => 2, queued => 0, spawning => 0 },
    "$label: both are idle again";
  no_callback_died($label);
  $storage->disconnect;
}

settle();
$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->disconnect;

done_testing;
