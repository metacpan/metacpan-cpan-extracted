use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw( refaddr weaken );
use Time::HiRes ();

use Future;
use Future::IO qw( POLLIN );
use DBIO::SQLMaker;          # the fake's sql_maker_class
use DBIO::Async::Storage;

# OFFLINE test for the Future::IO-generic listen seams (karr k22, ADR 0005,
# core ADR 0056): _listen_delay, the watch loop behind _listen_watch /
# _listen_unwatch, and the pooled _notify_send. Core owns the LISTEN machinery
# -- registry, dedicated connection, healing, fork guard -- and pins it in its
# own t/test/38_async_listen_contract.t with a fake transport that fakes these
# seams too. This file is the other half: it runs THIS dist's seams for real,
# under core's real machinery, through the public listen / unlisten / notify /
# listen_reconnect. No database, no event-loop dist: the listen "socket" is a
# real pipe(2), the loop is Future::IO's built-in implementation.
#
# What is fake: only the DB-specific seams a driver would supply -- open,
# close, subscribe, unsubscribe, probe, _conn_fileno, _listen_drain and
# _notify_sql. A notification on the wire is one "channel\tpayload\tpid\n"
# line. Section 0 pins that the fake overrides nothing of the transport. Core's
# two transport -> core methods, _listen_dispatch and _listen_lost, are wrapped
# by pass-through spies that record the call and hand it on unchanged.
#
# THE SPY. $Future::IO::IMPL is Future::IO's documented hook. ListenSpy
# records every poll and sleep the transport asks for, then hands the call to
# the built-in implementation (by localising the variable away), so the timer
# or poll that runs is the real one. It can also fail the next poll once. The
# test's own loop-driving sleeps are not recorded ($QUIET).

{
  package ListenSpy;
  our (@POLLS, @SLEEPS, $QUIET, $FAIL_POLL);

  sub poll {
    my ($class, $fh, $events) = @_;
    push @POLLS, Scalar::Util::refaddr($fh);
    local $Future::IO::IMPL;
    if (defined(my $err = $FAIL_POLL)) {
      undef $FAIL_POLL;
      return Future::IO->sleep(0)->then(sub { Future->fail($err) });
    }
    return Future::IO->poll($fh, $events);
  }

  sub sleep {
    my ($class, $seconds) = @_;
    push @SLEEPS, $seconds unless $QUIET;
    local $Future::IO::IMPL;
    return Future::IO->sleep($seconds);
  }
}
$Future::IO::IMPL = 'ListenSpy';

# --- the fake driver ---------------------------------------------------------

{
  package FakeListen;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use Scalar::Util ();

  sub transport_capabilities { qw(listen notify) }   # the FAKE declares, not the base

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }

  # A '?' -> '$N' dialect, so the test can see _notify_send's SQL was shaped.
  sub _transform_sql {
    my ($self, $sql) = @_;
    my $n = 0;
    $sql =~ s/\?/'$' . ++$n/ge;
    return $sql;
  }

  # -- the pooled side; only _notify_send uses it --

  sub _create_pool_connection {
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { r => $r, w => $w, pooled => 1 };
  }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w}; return }
  sub _conn_ready { 1 }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{fake}{wire} }, { sql => $sql, bind => [@$bind], pooled => $conn->{pooled} };
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([]);
  }

  sub _notify_sql {
    my ($self, $channel, $payload) = @_;
    return ('SELECT fake_notify(?, ?)', [ $channel, $payload ]);
  }

  # -- the listen side --

  sub _listen_open {
    my ($self) = @_;
    my $f = $self->{fake};
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    $r->blocking(0);
    my $conn = {
      id       => ++$f->{opened},
      r        => $r,
      w        => $w,
      buffered => delete $f->{preload} || [],   # what the client library already holds
      table    => [],                           # the timer fake's "notify table"
    };
    push @{ $f->{conns} }, $conn;
    Scalar::Util::weaken($f->{conns}[-1]);     # the fake keeps no connection alive
    push @{ $f->{log} }, "open \@$conn->{id}";
    return $conn;
  }

  sub _listen_close {
    my ($self, $conn) = @_;
    $conn->{closed} = 1;
    push @{ $self->{fake}{log} }, "close \@$conn->{id}";
    return;
  }

  sub _listen_subscribe   { push @{ $_[0]{fake}{log} }, "LISTEN $_[2] \@$_[1]{id}";   return 1 }
  sub _listen_unsubscribe { push @{ $_[0]{fake}{log} }, "UNLISTEN $_[2] \@$_[1]{id}"; return 1 }
  sub _listen_probe       { !$_[1]{closed} }

  sub _conn_fileno {
    my ($self, $conn) = @_;
    $self->{fake}{fileno_calls}++;
    return fileno $conn->{r};
  }

  # Never blocks: reads only what select says is there. End of file dies, as the
  # seam's POD requires of a socket driver.
  sub _listen_drain {
    my ($self, $conn) = @_;
    $self->{fake}{drains}{ $conn->{id} }++;
    return $self->{fake}{bad_drain} if exists $self->{fake}{bad_drain};
    my @out = splice @{ $conn->{buffered} };

    my $rin = '';
    vec($rin, fileno $conn->{r}, 1) = 1;
    if (select($rin, undef, undef, 0) > 0) {
      my $n = sysread $conn->{r}, my $buf, 65536;
      die "fake: reading connection $conn->{id} failed: $!\n" unless defined $n;
      die "fake: server closed connection $conn->{id}\n" if $n == 0;
      push @out, map { [ split /\t/, $_, 3 ] } split /\n/, $buf;
    }
    return \@out;
  }

  # Pass-through spy on the transport -> core call: records exactly what the
  # loop handed core, then lets core deliver.
  sub _listen_dispatch {
    my ($self, @n) = @_;
    push @{ $self->{fake}{dispatched} }, [@n];
    return $self->SUPER::_listen_dispatch(@n);
  }

  # The same for death reports: core ignores one about a connection it has
  # already let go of, so only a spy can see the loop sending one.
  sub _listen_lost {
    my ($self, $conn, $err) = @_;
    push @{ $self->{fake}{lost} }, $err;
    return $self->SUPER::_listen_lost($conn, $err);
  }
}

{
  # The emulation shape (a MySQL-style notify table): timer-driven, no socket.
  package FakeTimer;
  our @ISA = ('FakeListen');

  sub _listen_poll_interval { $_[0]{fake}{interval} }

  sub _conn_fileno {
    my ($self) = @_;
    $self->{fake}{fileno_calls}++;
    die "fake: the timer-driven loop asked for the socket\n";
  }

  # "Query the rows newer than the mark" = take what was committed to the table.
  # With future_drain the query is a Future resolving from the loop -- derived
  # with ->then, so nothing but the watch holds it.
  sub _listen_drain {
    my ($self, $conn) = @_;
    my $f = $self->{fake};
    $f->{drains}{ $conn->{id} }++;
    push @{ $f->{drain_at} }, Time::HiRes::time();
    my $fail = delete $f->{fail_drain};
    my @rows = splice @{ $conn->{table} };
    return \@rows unless $f->{future_drain};
    local $ListenSpy::QUIET = 1;
    return Future::IO->sleep(0)->then(sub {
      defined $fail ? Future->fail($fail) : Future->done(\@rows);
    });
  }
}

# --- helpers -------------------------------------------------------------------

sub fresh {
  my ($class, %fake) = @_;
  my $s = $class->new(undef);
  $s->connect_info([{ host => 'localhost', pool_size => 1 }]);
  $s->{fake} = {
    log => [], errors => [], reconnects => 0, drains => {}, dispatched => [],
    lost => [], wire => [], conns => [], opened => 0, fileno_calls => 0, %fake,
  };
  # Hooks take the storage as an argument, so they close over nothing.
  $s->on_listen_error(sub { push @{ $_[0]{fake}{errors} }, $_[1] });
  $s->on_listen_reconnect(sub { $_[0]{fake}{reconnects}++ });
  $s->listen_backoff_initial(0.01);
  $s->listen_backoff_max(0.01);
  @ListenSpy::POLLS  = ();
  @ListenSpy::SLEEPS = ();
  return $s;
}

sub conn_no { $_[0]{fake}{conns}[ $_[1] - 1 ] }   # the fake's weak list, 1-based
sub watch_of { $_[0]{_dbio_async_listen_watch} }

# Run the loop until $cond holds, bounded by a deadline -- never an open-ended
# sleep-and-hope. Only the tick itself is quiet: a timer the transport asks for
# while the loop runs is still recorded.
sub drive {
  my ($cond, $max) = @_;
  my $deadline = Time::HiRes::time() + ($max // 3);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    my $tick = do { local $ListenSpy::QUIET = 1; Future::IO->sleep(0.002) };
    $tick->get;
  }
  return 1;
}

# Let the loop run for a fixed while -- for "nothing more happens" claims.
sub settle {
  my ($seconds) = @_;
  my $tick = do { local $ListenSpy::QUIET = 1; Future::IO->sleep($seconds // 0.05) };
  $tick->get;
  return;
}

sub notify_on { syswrite $_[0]{w}, join '', map { join("\t", @$_) . "\n" } @_[1 .. $#_] }

# ---------------------------------------------------------------------------
# 0. The fake overrides the DB-specific seams and NOTHING of the transport.
#    Without this guard a later edit could stub a seam under test in the fake
#    and every assertion below would keep passing against the fake instead of
#    the transport. Code-ref identity is the only probe that tells an inherited
#    method from an overridden one (core ADR 0032 addendum 2026-07-27).
# ---------------------------------------------------------------------------

for my $class (qw( FakeListen FakeTimer )) {
  for my $seam (qw(
    _listen_watch _listen_unwatch _listen_delay _notify_send
    _await_readable _conn_poll_fh _query_async
    _watch_stop _watch_live _watch_await _watch_callback _watch_run _watch_lost
    _watch_elapsed _watch_polled _watch_drain _watch_drained _watch_deliver
    _watch_arm _watch_readable_now
  )) {
    is refaddr($class->can($seam)), refaddr(DBIO::Async::Storage->can($seam)),
      "$class does NOT override $seam -- the transport itself runs";
  }
}

# ---------------------------------------------------------------------------
# 1. What the BASE declares and demands. It implements the generic seams but
#    cannot drain anything, so it must not claim listen/notify: the capability
#    names are the concrete driver's to declare (core ADR 0056 section 2). That
#    the two new driver seams croak is pinned in t/01 with the others.
# ---------------------------------------------------------------------------

is_deeply [ DBIO::Async::Storage->transport_capabilities ], ['on_connect_replay'],
  'the base still declares exactly on_connect_replay -- no listen, no notify';

{
  my $base = DBIO::Async::Storage->new(undef);
  throws_ok { $base->listen(jobs => sub {}) }
    qr/LISTEN\/NOTIFY not supported by this storage driver/,
    'so core\'s gate refuses listen on the bare base';
  throws_ok { $base->notify(jobs => 'x') }
    qr/LISTEN\/NOTIFY not supported by this storage driver/,
    '... and notify';

  is $base->_listen_poll_interval, undef,
    '_listen_poll_interval defaults to undef: socket-driven';
}

# ---------------------------------------------------------------------------
# 2. _listen_delay. Core's backoff depends on three properties (core ADR 0056
#    section 5): it is PENDING on return (a synchronously resolved delay would
#    turn a persistent outage into unbounded recursion), it resolves from the
#    loop no earlier than asked, and CANCEL really drops the timer -- core
#    cancels it when listen_reconnect or a teardown cuts the wait short.
#    "Dropped" is measured, not assumed: a timer the loop still held would stay
#    alive after the test lets go of it. The control proves that measurement
#    can fail.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');

  my $t0 = Time::HiRes::time();
  my $f  = $s->_listen_delay(0.05);
  isa_ok $f, 'Future', '_listen_delay returns a Future';
  ok !$f->is_ready, '... pending on return -- never resolved synchronously';
  is_deeply \@ListenSpy::SLEEPS, [0.05], '... and it is a Future::IO sleep of that length';
  $f->get;
  cmp_ok Time::HiRes::time() - $t0, '>=', 0.049, '... resolved by the loop, not early';

  my $held = $s->_listen_delay(30);
  weaken(my $weak_held = $held);
  undef $held;
  ok defined $weak_held,
    'control: an uncancelled delay is held by the loop after the caller lets go';
  $weak_held->cancel;

  my $cut = $s->_listen_delay(30);
  $cut->cancel;
  ok $cut->is_cancelled, 'a delay can be cancelled';
  weaken(my $weak_cut = $cut);
  undef $cut;
  ok !defined $weak_cut,
    '... and cancelling drops it from the built-in implementation\'s timer list';
}

# ---------------------------------------------------------------------------
# 3. Socket mode, end to end through core's public listen(): a write to the
#    connection's fd reaches the channel callback in contract order
#    ($channel, $payload, $sender_pid), polled on the cached dup.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $c = conn_no($s, 1);

  is_deeply $s->{fake}{log}, [ 'open @1', 'LISTEN jobs @1' ],
    'listen opened one connection and subscribed it';
  is $s->{fake}{drains}{1} // 0, 0,
    'nothing was drained inside _listen_watch -- here it ran inside the '
    . 'listen() call, and a drain there would dispatch before listen() '
    . 'returned and before core fired on_listen_reconnect (section 4)';

  ok drive(sub { $s->{fake}{drains}{1} }), 'the first drain runs one loop tick later';
  ok watch_of($c)->{pending}, 'then the loop waits on the socket';
  is $ListenSpy::POLLS[-1], refaddr($c->{_dbio_async_poll_fh}),
    '... polling the dup cached on the connection';

  notify_on($c, [ jobs => 'hello', 4242 ]);
  ok drive(sub { @got }), 'a notification on the wire is delivered';
  is_deeply \@got, [ [ 'jobs', 'hello', '4242' ] ],
    'the callback gets ($channel, $payload, $sender_pid)';

  # Order, within one drain and across drains, over two channels on the one
  # connection core shares between them.
  $s->listen(alerts => sub { push @got, [@_] })->get;
  @got = ();
  my $drains = $s->{fake}{drains}{1};
  notify_on($c, [ jobs => 1, 7 ], [ alerts => 2, 7 ], [ jobs => 3, 7 ]);
  ok drive(sub { @got == 3 }), 'three notifications in one write';
  is $s->{fake}{drains}{1}, $drains + 1, '... came out of a single drain';
  notify_on($c, [ alerts => 4, 7 ]);
  ok drive(sub { @got == 4 }), 'a fourth, in a later drain';
  notify_on($c, [ jobs => 5, 7 ]);
  ok drive(sub { @got == 5 }), 'and a fifth';
  is_deeply [ map { "$_->[0]:$_->[1]" } @got ],
    [ 'jobs:1', 'alerts:2', 'jobs:3', 'alerts:4', 'jobs:5' ],
    'every notification was dispatched in arrival order, within and across drains';
}

# ---------------------------------------------------------------------------
# 4. Drain at watch start. libpq can hold notifications it read off the socket
#    during the LISTEN round trip; they will never make the socket readable
#    again. The loop must drain once before it first polls, or they sit there
#    until an unrelated notification happens to arrive.
#
#    That drain runs one loop tick after _listen_watch, never inside it. With
#    seams that resolve synchronously -- a blocking DBI connect, and this fake
#    -- core calls _listen_watch from inside listen() and listen_reconnect(),
#    and only after it returns does core fire on_listen_reconnect and settle
#    the Futures it hands out. A drain inside it would run a channel callback
#    before the API call returned, and only when something happened to be
#    buffered; on a rebuilt connection it would dispatch before
#    on_listen_reconnect, the hook where a consumer re-reads what the outage
#    cost it. Both are pinned here, the second on both rebuild paths.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen', preload => [ [ jobs => 'early', 7 ] ]);
  my @got;
  my $f = $s->listen(jobs => sub { push @got, [@_] });

  ok $f->is_done,
    'the seams resolved synchronously: listen() returned a done Future, so '
    . '_listen_watch ran inside the call';
  is scalar @got, 0,
    '... and the buffered notification was NOT dispatched from inside it -- '
    . 'no callback runs before listen() has returned';

  ok drive(sub { @got }), 'a notification buffered before watching began is delivered';
  is_deeply \@got, [ [ 'jobs', 'early', 7 ] ],
    '... without the socket ever becoming readable';
}

for my $rebuild (qw( listen_reconnect heal )) {
  my $s = fresh('FakeListen');
  my @log;   # one ordered log for the hook and the channel callback
  $s->on_listen_reconnect(sub { push @log, 'on_listen_reconnect' });
  $s->listen(jobs => sub { push @log, "dispatch $_[1]" })->get;
  ok drive(sub { $s->{fake}{drains}{1} }), "$rebuild: watching the first connection";

  $s->{fake}{preload} = [ [ jobs => 'buffered', 9 ] ];   # held at the NEXT open
  if ($rebuild eq 'listen_reconnect') {
    ok $s->listen_reconnect->is_done,
      'listen_reconnect: the rebuild resolved synchronously, inside the call';
    is_deeply \@log, ['on_listen_reconnect'],
      'listen_reconnect: ... the hook fired in it, the buffered notification '
      . 'was NOT dispatched from inside it';
  }
  else {
    close conn_no($s, 1)->{w};   # the server went away: EOF, backoff, rebuild
  }

  ok drive(sub { @log == 2 }),
    "$rebuild: the notification buffered at the new connection's open is delivered";
  is_deeply \@log, [ 'on_listen_reconnect', 'dispatch buffered' ],
    "$rebuild: on_listen_reconnect fired BEFORE it was dispatched -- the "
    . 'consumer learns the stream broke before it sees the new one';
}

# ---------------------------------------------------------------------------
# 5. The built-in Future::IO implementation does not select() while it has only
#    read pollers and no timer: it presumes every poll ready and clears
#    O_NONBLOCK while the callbacks run. A drain in that round on a quiet
#    socket would block in recv -- hanging whatever query the program was
#    really waiting for until a notification arrived. The loop must confirm
#    readability before draining. The fake drain never blocks either way, so a
#    missing guard shows up here as a drain count that moved, not as a hang.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $c = conn_no($s, 1);
  ok drive(sub { $s->{fake}{drains}{1} }), 'watching, the poll armed';

  pipe(my $or, my $ow) or die "pipe: $!";
  $ow->autoflush(1);
  $or->blocking(0);
  syswrite $ow, 'x';
  my $other = Future::IO->poll($or, POLLIN);
  my $presumed;
  $other->on_ready(sub { $presumed = $or->blocking });
  $other->get;    # one round with two read pollers and no timer

  ok $presumed,
    'precondition: that round was a presumed-ready one (O_NONBLOCK cleared)';
  is $s->{fake}{drains}{1}, 1,
    'the listen socket was presumed ready too, but was not drained -- it was quiet';
  ok watch_of($c)->{pending}, 'the loop re-armed instead';

  notify_on($c, [ jobs => 'still', 1 ]);
  ok drive(sub { @got }), 'and still delivers';
}

# ---------------------------------------------------------------------------
# 6. Timer mode -- the emulation shape. The drain is paced by a Future::IO
#    sleep of exactly the poll interval, cannot happen before it, repeats, and
#    the loop never asks for a socket: an emulating transport has none worth
#    watching.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeTimer', interval => 0.05);
  my @got;
  my $t0 = Time::HiRes::time();
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $c = conn_no($s, 1);

  is_deeply \@ListenSpy::SLEEPS, [0.05],
    'the watch waits a Future::IO sleep of exactly _listen_poll_interval';
  push @{ $c->{table} }, [ jobs => 't1', 11 ], [ jobs => 't2', 12 ];
  ok drive(sub { @got == 2 }), 'committed rows are delivered';
  is_deeply \@got, [ [ 'jobs', 't1', 11 ], [ 'jobs', 't2', 12 ] ], '... in order';
  cmp_ok $s->{fake}{drain_at}[0] - $t0, '>=', 0.049,
    '... and not before the first interval elapsed';

  ok drive(sub { $s->{fake}{drains}{1} >= 3 }), 'the loop keeps polling';
  is_deeply [ grep { $_ != 0.05 } @ListenSpy::SLEEPS ], [],
    '... every wait the poll interval';
  is $s->{fake}{fileno_calls}, 0, 'timer mode never asked for the socket fd';
  ok !exists $c->{_dbio_async_poll_fh}, '... and never dup\'d one';
  is scalar @ListenSpy::POLLS, 0, '... and never polled';
}

# ---------------------------------------------------------------------------
# 7. A drain that returns a Future -- what an emulating transport's drain query
#    is on this transport. The Future is derived with ->then, and a Future holds
#    its derived Futures only weakly: unless the loop holds it, it is lost and
#    its rows never arrive.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeTimer', interval => 0.01, future_drain => 1);
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  push @{ conn_no($s, 1)->{table} }, map { [ jobs => $_, 5 ] } 1 .. 3;

  ok drive(sub { @got == 3 }), 'rows from a Future-returning drain are delivered';
  is_deeply [ map { $_->[1] } @got ], [ 1, 2, 3 ], '... in order';
}

# ---------------------------------------------------------------------------
# 8. Unwatch stops the loop. The last unlisten runs _listen_unwatch then
#    _listen_close. The pending poll (socket) or timer (timer mode) must be
#    cancelled -- and freed, so the implementation no longer holds it and with
#    it the dup'd fd -- and nothing may be drained or dispatched for that
#    connection afterwards, even when the fd turns readable or time passes.
# ---------------------------------------------------------------------------

for my $case ([ FakeListen => () ], [ FakeTimer => (interval => 0.01) ]) {
  my ($class, %fake) = @$case;
  my $s = fresh($class, %fake);
  $s->listen(jobs => sub {})->get;
  my $c = conn_no($s, 1);
  ok drive(sub { $s->{fake}{drains}{1} }), "$class: watching";

  my $pending = watch_of($c)->{pending};
  weaken(my $weak_pending = $pending);
  my $drains = $s->{fake}{drains}{1};

  $s->unlisten('jobs')->get;
  ok $pending->is_cancelled, "$class: the pending wait was cancelled";
  is_deeply $s->{fake}{lost}, [],
    "$class: ... without the cancellation being reported as a death -- the "
    . 'watch state leaves the connection before the cancel runs its callback';
  undef $pending;
  ok !defined $weak_pending, "$class: ... and released by the loop";
  ok !exists $c->{_dbio_async_listen_watch}, "$class: the watch state is gone";
  is $s->{fake}{log}[-1], 'close @1', "$class: then core closed it";

  notify_on($c, [ jobs => 'late', 1 ]);
  push @{ $c->{table} }, [ jobs => 'late', 1 ];
  settle(0.05);
  is $s->{fake}{drains}{1}, $drains, "$class: no drain after unwatch";
  is scalar @{ $s->{fake}{dispatched} }, 0, "$class: no dispatch after unwatch";
}

# ---------------------------------------------------------------------------
# 9. Re-entrancy. A channel callback runs INSIDE the loop's dispatch batch, and
#    it may unlisten the last channel or call listen_reconnect -- both run
#    _listen_unwatch and _listen_close synchronously, mid-batch. The rest of
#    that batch must not be dispatched and the old connection must not be
#    re-armed. The reconnect case is the one that can tell: the channel stays
#    registered, so core WOULD deliver the leftover tuples if the loop kept
#    going. The pass-through spy on _listen_dispatch sees what the loop handed
#    core at all.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  weaken(my $ws = $s);
  my @got;
  $s->listen(jobs => sub { push @got, $_[1]; $ws->unlisten('jobs') if $_[1] eq '1' })->get;
  my $c = conn_no($s, 1);
  ok drive(sub { $s->{fake}{drains}{1} }), 'unlisten mid-batch: watching';

  notify_on($c, map { [ jobs => $_, 1 ] } 1 .. 3);
  ok drive(sub { @got }), 'the first notification of the batch arrived';
  settle(0.05);
  is_deeply [ map { $_->[1] } @{ $s->{fake}{dispatched} } ], ['1'],
    'the callback unlistened the last channel: the loop stopped the batch there';
  ok !exists $c->{_dbio_async_listen_watch}, '... and did not re-arm';

  my $drains = $s->{fake}{drains}{1};
  notify_on($c, [ jobs => 'late', 1 ]);
  settle(0.05);
  is $s->{fake}{drains}{1}, $drains, '... nothing polls the old connection any more';
}

{
  my $s = fresh('FakeListen');
  weaken(my $ws = $s);
  my @got;
  $s->listen(jobs => sub { push @got, $_[1]; $ws->listen_reconnect if $_[1] eq '1' })->get;
  my $old = conn_no($s, 1);
  ok drive(sub { $s->{fake}{drains}{1} }), 'listen_reconnect mid-batch: watching';

  notify_on($old, map { [ jobs => $_, 1 ] } 1 .. 3);
  ok drive(sub { $s->{fake}{reconnects} }), 'the callback rebuilt the connection';
  settle(0.05);
  is_deeply [ map { $_->[1] } @{ $s->{fake}{dispatched} } ], ['1'],
    'the rest of the old connection\'s batch was NOT dispatched, though the '
    . 'channel is still registered and core would have delivered it';
  ok !exists $old->{_dbio_async_listen_watch}, 'the old connection is not re-armed';

  my $new = conn_no($s, 2);
  ok watch_of($new), 'the new connection is watched';
  notify_on($old, [ jobs => 'stale', 1 ]);
  notify_on($new, [ jobs => 'fresh', 2 ]);
  ok drive(sub { @got == 2 }), 'a notification on the new connection arrives';
  settle(0.05);
  is_deeply \@got, [ '1', 'fresh' ], '... and nothing from the old one ever does';
}

# ---------------------------------------------------------------------------
# 10. Death reaches core. A drain that dies (here: end of file, which the seam
#     POD requires a socket driver to die on), a drain Future that fails, a
#     poll that fails, and a drain result of the wrong shape all go to
#     _listen_lost -- core's on_listen_error sees them and healing runs:
#     backoff through the REAL _listen_delay, a new connection, the channel
#     re-subscribed, on_listen_reconnect, delivery again.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  my @got;
  $s->listen(jobs => sub { push @got, $_[1] })->get;
  ok drive(sub { $s->{fake}{drains}{1} }), 'EOF: watching';
  @ListenSpy::SLEEPS = ();

  close conn_no($s, 1)->{w};    # the server went away
  ok drive(sub { $s->{fake}{reconnects} }), 'EOF: the connection healed';
  like $s->{fake}{errors}[0], qr/fake: server closed connection 1/,
    'EOF: on_listen_error saw the drain\'s death';
  ok scalar(grep { $_ == 0.01 } @ListenSpy::SLEEPS),
    'EOF: the backoff ran as a Future::IO sleep of listen_backoff_initial';
  is_deeply [ grep { /\@2/ } @{ $s->{fake}{log} } ], [ 'open @2', 'LISTEN jobs @2' ],
    'EOF: a new connection, the channel subscribed again';

  notify_on(conn_no($s, 2), [ jobs => 'healed', 1 ]);
  ok drive(sub { @got }), 'EOF: delivery resumes on the new connection';
}

{
  my $s = fresh('FakeTimer', interval => 0.01, future_drain => 1);
  $s->listen(jobs => sub {})->get;
  $s->{fake}{fail_drain} = "fake: drain query failed\n";
  ok drive(sub { $s->{fake}{reconnects} }), 'failed drain Future: healed';
  like $s->{fake}{errors}[0], qr/_listen_drain failed: fake: drain query failed/,
    'failed drain Future: on_listen_error saw it';
}

{
  my $s = fresh('FakeListen');
  $ListenSpy::FAIL_POLL = "poll exploded\n";    # the first poll, after the first drain
  $s->listen(jobs => sub {})->get;
  ok drive(sub { $s->{fake}{reconnects} }), 'failed poll: healed';
  like $s->{fake}{errors}[0], qr/polling the listen connection failed: poll exploded/,
    'failed poll: on_listen_error saw it';
}

{
  my $s = fresh('FakeListen', bad_drain => { not => 'an arrayref' });
  $s->listen(jobs => sub {})->get;
  ok drive(sub { @{ $s->{fake}{errors} } }), 'malformed drain result: reported';
  like $s->{fake}{errors}[0], qr/_listen_drain must return an arrayref/,
    'malformed drain result: loudly, naming the contract';
  $s->unlisten('jobs');
}

# ---------------------------------------------------------------------------
# 11. A zero or negative interval would spin the loop. It fails the arm
#     instead, which core reports (and keeps reporting while it heals).
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeTimer', interval => 0);
  my $f = $s->listen(jobs => sub {});
  ok $f->is_failed, 'interval 0: listen fails';
  like scalar $f->failure,
    qr/_listen_poll_interval must be undef \(socket-driven\) or a positive number/,
    'interval 0: with the reason';
  $s->unlisten('jobs');
}

# ---------------------------------------------------------------------------
# 12. Lifetime. A reconnect creates a new connection hashref, so the old one --
#     and the dup'd poll fd cached on it -- must actually be freed: a dup kept
#     alive keeps the old socket open at the OS level. Nothing the loop
#     registered may hold it: not the watch state, not the implementation's
#     poll, not a callback. Likewise a storage dropped while listening is
#     freed (callbacks hold it weakly) and its DESTROY stops the watch.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  $s->listen(jobs => sub {})->get;
  ok drive(sub { $s->{fake}{drains}{1} }), 'reconnect lifetime: watching, poll armed';

  my $old = conn_no($s, 1);
  ok $old->{_dbio_async_poll_fh}, 'the old connection has a cached poll dup';
  weaken(my $weak_fh      = $old->{_dbio_async_poll_fh});
  weaken(my $weak_pending = watch_of($old)->{pending});
  undef $old;

  $s->listen_reconnect->get;
  ok !defined conn_no($s, 1), 'the old connection hashref was freed';
  ok !defined $weak_fh, '... and with it its dup\'d poll filehandle';
  ok !defined $weak_pending, '... and the poll that was watching it';

  my $new = conn_no($s, 2);
  ok $new->{_dbio_async_poll_fh}, 'the new connection got a poll dup of its own';
}

{
  my $s = fresh('FakeListen');
  $s->listen(jobs => sub {})->get;
  ok drive(sub { $s->{fake}{drains}{1} }), 'storage lifetime: watching';
  weaken(my $weak_s       = $s);
  weaken(my $weak_conn    = conn_no($s, 1));
  weaken(my $weak_pending = watch_of(conn_no($s, 1))->{pending});

  undef $s;
  ok !defined $weak_s, 'a storage dropped while listening is freed';
  ok !defined $weak_conn, '... its listen connection too';
  ok !defined $weak_pending, '... and the pending poll is gone from the loop';
}

# ---------------------------------------------------------------------------
# 13. Fork guard. The watch records its pid. After fork, the child's copy of the
#     implementation still holds the parent's poll; if the child runs a loop
#     that fires it, the watch must not drain -- the child would steal the
#     parent's notifications off the shared socket. Simulated by a watch whose
#     recorded pid is not this process's.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  $s->listen(jobs => sub {})->get;
  my $c = conn_no($s, 1);
  ok drive(sub { $s->{fake}{drains}{1} }), 'fork guard: watching';

  watch_of($c)->{pid} = -1;    # "another process" created this watch
  notify_on($c, [ jobs => 'parent-only', 1 ]);
  settle(0.05);
  is $s->{fake}{drains}{1}, 1, 'fork guard: a foreign watch never drains';
  is scalar @{ $s->{fake}{dispatched} }, 0, 'fork guard: ... nor dispatches';
  $s->unlisten('jobs');
}

# ---------------------------------------------------------------------------
# 14. _notify_send. The payload travels ONLY as a bind value (ADR 0017 section 3,
#     core ADR 0056): a hostile payload must not appear in the SQL on the wire.
#     The SQL is _notify_sql's, shaped by _transform_sql inside _query_async,
#     on a POOLED connection -- notify never opens the listen connection.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeListen');
  my $payload = q{x'); DROP TABLE t; --};
  $s->notify(jobs => $payload)->get;

  my $wire = $s->{fake}{wire}[0];
  is $wire->{sql}, 'SELECT fake_notify($1, $2)',
    'notify sent _notify_sql\'s statement, shaped by _transform_sql';
  is_deeply $wire->{bind}, [ 'jobs', $payload ], 'channel and payload as binds';
  unlike $wire->{sql}, qr/DROP/, 'the payload is nowhere in the SQL';
  ok $wire->{pooled}, 'it ran on a pooled connection';
  is $s->{fake}{opened}, 0, 'no listen connection was opened';
  is $s->pool->available, 1, 'the pooled connection was released';

  $s->notify(jobs => undef)->get;
  is_deeply $s->{fake}{wire}[1]{bind}, [ 'jobs', undef ], 'an undef payload is an undef bind';
}

done_testing;
