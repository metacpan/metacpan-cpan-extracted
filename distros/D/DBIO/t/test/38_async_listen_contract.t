use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config;
use File::Temp ();

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# karr core k219 / ADR 0056 -- LISTEN/NOTIFY is a core async contract. The public
# methods, the channel registry, the dedicated listen connection, self-healing
# and the fork guard live in DBIO::Storage::Async; a transport fills the listen
# seams. This file drives that machinery through a fake transport that
# implements every seam over DBIO::Test::Future, so the test decides when a
# connection opens, when a subscribe completes and when a backoff timer fires.
# No event loop, no database.
#
# What each block pins, and why it matters:
#   gate        -- the old refusal text, thrown before any state or seam is
#                  touched, and naming the public method; notify gated alone
#   registry    -- contract-order dispatch, drop for unknown channels, a second
#                  listen on a channel replaces the callback with no 2nd LISTEN
#   shared conn -- every channel rides ONE connection, opened and watched once
#   serialised  -- no second channel operation while one is in flight (the
#                  race dbio-postgresql-ev k15 fixed locally); listen's Future
#                  resolves only once the LISTEN is in effect AND watched
#   unlisten    -- non-last: UNLISTEN, connection stays; last: unwatch + close
#   heal        -- transport-reported death: close, error hook, backoff, then
#                  EVERY channel re-subscribed on the new connection, re-armed,
#                  reconnect hook -- in that order
#   backoff     -- bounded doubling, per-instance bounds, reset after success
#   probe       -- listen_alive's failing probe starts healing
#   reconnect   -- listen_reconnect rebuilds now and cuts a pending backoff
#   stale       -- reports about a replaced connection change nothing
#   no conn     -- an open resolving with nothing fails loud and heals
#   refused     -- a LISTEN the server rejects on a live connection drops that
#                  channel instead of reconnecting forever
#   dead LISTEN -- a LISTEN failing because the connection died heals and keeps
#                  the channel
#   callbacks   -- a dying callback is reported and delivery continues
#   loud        -- with no hook, errors are warned, never swallowed
#   notify      -- channel and payload reach the transport untouched
#   fork        -- a child never touches the parent's listen connection
#   override    -- a transport that overrides listen/unlisten/notify (the EV
#                  shape today) is not routed through the machinery
#   disconnect  -- ends listening and fails what still waited
#   schema      -- the contract is reachable as $schema->storage->async
#   awaitable   -- (k222) with seams that resolve on a later loop tick, every
#                  Future listen / unlisten / listen_reconnect hands out can be
#                  ->get'ed: it awaits through the transport's loop
#   watch order -- (k222) the connection counts as watched from the moment
#                  _listen_watch is called, so whatever happens inside it
#                  unwatches the connection it closes
#   report      -- (k227) _listen_error, the transport's way to report an error
#                  that does not end the connection: reported exactly like
#                  core's own errors, and nothing else happens -- no close, no
#                  reconnect, listen_alive unaffected; ignored when not
#                  listening, and in a forked child

# --- fake transport ---------------------------------------------------------------

{
  package K219::Conn;
  my $seq = 0;
  sub new { bless { id => ++$seq, alive => 1, closed => 0, watching => 0 }, $_[0] }
}

{
  package K219::Transport;
  use base 'DBIO::Storage::Async';

  sub future_class           { 'DBIO::Test::Future' }
  sub transport_capabilities { qw(listen notify) }

  sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{fake} = {
      log       => [],
      conns     => [],
      opens     => [],
      delays    => [],
      subs      => [],
      notified  => [],
      open_mode => 'auto',     # auto | hold | fail
      hold_sub  => 0,
      sub_fail  => {},
    };
    return $self;
  }

  sub _log { push @{ $_[0]{fake}{log} }, $_[1] }

  # Everything that touches a connection is also appended to a trace file when
  # one is set -- the fork test reads it back to see what a child did.
  sub _trace {
    my ($self, $what) = @_;
    my $file = $self->{fake}{trace_file} or return;
    open my $fh, '>>', $file or die "trace $file: $!";
    print {$fh} "$$ $what\n";
    close $fh;
  }

  sub _listen_open {
    my ($self) = @_;
    $self->_log('open');
    my $f = DBIO::Test::Future->new;
    push @{ $self->{fake}{opens} }, $f;
    my $mode = $self->{fake}{open_mode};
    return $f->fail('connection refused') if $mode eq 'fail';
    return $f if $mode eq 'hold';
    my $conn = K219::Conn->new;
    push @{ $self->{fake}{conns} }, $conn;
    return $f->done($conn);
  }

  sub _listen_close {
    my ($self, $c) = @_;
    $c->{closed}++;
    $self->_log("close \@$c->{id}");
    $self->_trace("close \@$c->{id}");
    return;
  }

  sub _listen_subscribe {
    my ($self, $c, $ch) = @_;
    $self->_log("LISTEN $ch \@$c->{id}");
    $self->_trace("LISTEN $ch \@$c->{id}");
    my $f = DBIO::Test::Future->new;
    push @{ $self->{fake}{subs} }, $f;
    return $f if $self->{fake}{hold_sub};
    if (defined(my $err = $self->{fake}{sub_fail}{$ch})) {
      return $f->fail($err);
    }
    return $f->done;
  }

  sub _listen_unsubscribe {
    my ($self, $c, $ch) = @_;
    $self->_log("UNLISTEN $ch \@$c->{id}");
    $self->_trace("UNLISTEN $ch \@$c->{id}");
    return DBIO::Test::Future->done;
  }

  sub _listen_watch {
    my ($self, $c) = @_;
    $c->{watching} = 1;
    $self->{fake}{on_watch}->() if $self->{fake}{on_watch};
    $self->_log("watch \@$c->{id}");
    return;
  }

  sub _listen_unwatch {
    my ($self, $c) = @_;
    $c->{watching} = 0;
    $self->_log("unwatch \@$c->{id}");
    $self->_trace("unwatch \@$c->{id}");
    return;
  }

  sub _listen_probe {
    my ($self, $c) = @_;
    $self->_log("probe \@$c->{id}");
    $self->_trace("probe \@$c->{id}");
    return $c->{alive};
  }

  sub _listen_delay {
    my ($self, $seconds) = @_;
    $self->_log("delay $seconds");
    my $f = DBIO::Test::Future->new;
    push @{ $self->{fake}{delays} }, $f;
    return $f;
  }

  sub _notify_send {
    my ($self, $ch, $payload) = @_;
    push @{ $self->{fake}{notified} }, [ $ch, $payload ];
    return DBIO::Test::Future->done('sent');
  }

  # Transports that differ only in what they declare.
  package K219::NoCaps;     our @ISA = ('K219::Transport'); sub transport_capabilities { () }
  package K219::ListenOnly; our @ISA = ('K219::Transport'); sub transport_capabilities { qw(listen) }
  package K219::NotifyOnly; our @ISA = ('K219::Transport'); sub transport_capabilities { qw(notify) }
}

{
  # The dbio-postgresql-ev shape today: listen/unlisten/notify overridden
  # wholesale, no listen seams at all.
  package K219::Overriding;
  use base 'DBIO::Storage::Async';
  sub future_class           { 'DBIO::Test::Future' }
  sub transport_capabilities { qw(listen notify) }
  sub listen   { push @{ $_[0]{own} }, [ listen   => $_[1] ]; 'own-listen' }
  sub unlisten { push @{ $_[0]{own} }, [ unlisten => $_[1] ]; 'own-unlisten' }
  sub notify   { push @{ $_[0]{own} }, [ notify   => $_[1] ]; 'own-notify' }
}

{
  # karr k222 -- a fake event loop, reduced to a queue of pending settlements:
  # run_once settles the oldest one, and dies when nothing is left to run, as
  # Future::IO's own loop refuses to sit idle.
  package K222::Loop;
  our @queue;
  sub later { push @queue, $_[0]; return }
  sub run_once {
    my $next = shift @queue
      or die "K222 fake loop: nothing left to run, the awaited Future can never be ready\n";
    $next->();
    return;
  }
}

{
  # The transport's own Future kind: pending, it awaits by running the loop
  # that settles it -- what Future::IO::_DefaultImpl::F and IO::Async::Future
  # do. DBIO::Test::Future, the future_class, refuses a pending ->get.
  package K222::LoopFuture;
  our @ISA = ('DBIO::Test::Future');
  sub await { my ($self) = @_; K222::Loop::run_once() until $self->is_ready; return $self }
  sub get   { my $self = shift; $self->await; return $self->SUPER::get(@_) }

  # The same over the real Future.pm, whose derived Futures are held weakly.
  package K222::RealLoopFuture;
  our @ISA = ('Future');   # used only when Future is installed
  sub await { my ($self) = @_; K222::Loop::run_once() until $self->is_ready; return $self }
}

{
  # The dbio-async shape (k22): future_class is a Future class that cannot
  # await, while every seam that does I/O answers with a pending Future of the
  # transport's own kind, settled on a later loop tick -- nothing completes
  # while listen() is still on the stack.
  package K222::Transport;
  our @ISA = ('K219::Transport');

  sub loop_future_class { 'K222::LoopFuture' }

  sub _eventually {
    my ($self, $ok, @values) = @_;
    my $f = $self->loop_future_class->new;
    K222::Loop::later(sub { $ok ? $f->done(@values) : $f->fail(@values) });
    return $f;
  }

  sub _listen_open {
    my ($self) = @_;
    $self->_log('open');
    return $self->_eventually(0, 'connection refused')
      if $self->{fake}{open_mode} eq 'fail';
    my $conn = K219::Conn->new;
    push @{ $self->{fake}{conns} }, $conn;
    return $self->_eventually(1, $conn);
  }

  sub _listen_subscribe {
    my ($self, $c, $ch) = @_;
    $self->_log("LISTEN $ch \@$c->{id}");
    return $self->_eventually(1);
  }

  sub _listen_unsubscribe {
    my ($self, $c, $ch) = @_;
    $self->_log("UNLISTEN $ch \@$c->{id}");
    return $self->_eventually(1);
  }

  sub _listen_delay {
    my ($self, $seconds) = @_;
    $self->_log("delay $seconds");
    return $self->_eventually(1);
  }

  # The same over real Future.pm: future_class 'Future', seams answering
  # K222::RealLoopFuture.
  package K222::RealTransport;
  our @ISA = ('K222::Transport');
  sub future_class      { 'Future' }
  sub loop_future_class { 'K222::RealLoopFuture' }
}

sub fresh {
  my ($class) = @_;
  my $s = ($class || 'K219::Transport')->new(undef);
  $s->{fake}{errors}     = [];
  $s->{fake}{reconnects} = 0;
  $s->on_listen_error(sub { push @{ $_[0]{fake}{errors} }, $_[1] });
  $s->on_listen_reconnect(sub { $_[0]{fake}{reconnects}++ });
  return $s;
}

sub log_of    { [ @{ $_[0]{fake}{log} } ] }
sub clear_log { @{ $_[0]{fake}{log} } = () }
sub conn_n    { $_[0]{fake}{conns}[ $_[1] ] }

# =================================================================================
subtest 'capability gate: the old refusal, before anything is touched' => sub {
  my $s = fresh('K219::NoCaps');
  my $refusal = qr/LISTEN\/NOTIFY not supported by this storage driver/;

  throws_ok { $s->listen(a => sub {}) } qr/::listen\(\): $refusal/,
    'listen refuses without the listen capability, naming listen()';
  throws_ok { $s->unlisten('a') } qr/::unlisten\(\): $refusal/,
    'unlisten refuses without the listen capability';
  throws_ok { $s->listen_alive } qr/::listen_alive\(\): $refusal/,
    'listen_alive refuses without the listen capability';
  throws_ok { $s->listen_reconnect } qr/::listen_reconnect\(\): $refusal/,
    'listen_reconnect refuses without the listen capability';
  throws_ok { $s->notify(a => 'x') } qr/::notify\(\): $refusal/,
    'notify refuses without the notify capability';
  isa_ok $@, 'DBIO::Exception', 'the refusal';

  ok !exists $s->{_listen}, 'a refused call creates no listen state';
  is_deeply log_of($s), [], 'a refused call reaches no listen seam';

  my $l = fresh('K219::ListenOnly');
  throws_ok { $l->notify(a => 'x') } $refusal,
    'declaring listen does not open notify';
  lives_ok { $l->listen(a => sub {})->get } 'listen works with listen alone';

  my $n = fresh('K219::NotifyOnly');
  throws_ok { $n->listen(a => sub {}) } $refusal,
    'declaring notify does not open listen';
  is $n->notify(a => 'x')->get, 'sent', 'notify works with notify alone';

  throws_ok { DBIO::Storage::Async->listen(a => sub {}) } $refusal,
    'the bare base still refuses as a class method';

  my $ok = fresh();
  throws_ok { $ok->listen('', sub {}) } qr/requires a channel name/,
    'an empty channel name is refused';
  throws_ok { $ok->listen(a => 'not code') } qr/requires a callback coderef/,
    'a non-coderef callback is refused';
  throws_ok { $ok->notify(undef, 'x') } qr/requires a channel name/,
    'notify refuses an undefined channel';
};

# =================================================================================
subtest 'registry: contract-order dispatch, one callback per channel' => sub {
  my $s = fresh();
  my @got;
  $s->listen(jobs => sub { push @got, [ first => @_ ] })->get;

  $s->_listen_dispatch('jobs', 'payload-1', 4242);
  is_deeply \@got, [ [ first => 'jobs', 'payload-1', 4242 ] ],
    'callback gets ($channel, $payload, $sender_pid), in that order';

  @got = ();
  $s->_listen_dispatch('unknown', 'x', 1);
  is_deeply \@got, [], 'a notification on an unregistered channel is dropped';

  clear_log($s);
  $s->listen(jobs => sub { push @got, [ second => @_ ] })->get;
  is_deeply log_of($s), [],
    'a second listen on a subscribed channel sends no second LISTEN';
  $s->_listen_dispatch('jobs', 'p2', undef);
  is_deeply \@got, [ [ second => 'jobs', 'p2', undef ] ],
    '... and its callback replaces the first';
};

# =================================================================================
subtest 'several channels share one dedicated connection' => sub {
  my $s = fresh();
  my %got;
  $s->listen(a => sub { push @{ $got{a} }, $_[1] })->get;
  $s->listen(b => sub { push @{ $got{b} }, $_[1] })->get;

  is_deeply log_of($s), [ 'open', 'LISTEN a @' . conn_n($s, 0)->{id},
    'watch @' . conn_n($s, 0)->{id}, 'LISTEN b @' . conn_n($s, 0)->{id} ],
    'one open, one watch; the second channel is subscribed on the same connection';
  is scalar @{ $s->{fake}{conns} }, 1, 'exactly one listen connection';

  $s->_listen_dispatch(a => 'to-a', 1);
  $s->_listen_dispatch(b => 'to-b', 1);
  is_deeply \%got, { a => ['to-a'], b => ['to-b'] },
    'each notification reaches its own channel callback';
  ok $s->listen_alive, 'listen_alive: connected, armed, probe ok';
};

# =================================================================================
subtest 'channel operations are serialised; listen resolves when in effect' => sub {
  my $s = fresh();
  $s->{fake}{hold_sub} = 1;

  my $fa;
  my @ready_at_watch;
  $s->{fake}{on_watch} = sub { push @ready_at_watch, $fa->is_ready ? 1 : 0 };
  $fa = $s->listen(a => sub {});
  my $id = conn_n($s, 0)->{id};
  ok !$fa->is_ready, 'listen(a) is pending while its LISTEN is in flight';
  ok !$s->listen_alive, 'not alive before the connection is armed';

  my $fb = $s->listen(b => sub {});
  is_deeply log_of($s), [ 'open', "LISTEN a \@$id" ],
    'LISTEN b is not sent while LISTEN a is still in flight';

  $s->{fake}{subs}[0]->done;
  is_deeply log_of($s), [ 'open', "LISTEN a \@$id", "watch \@$id", "LISTEN b \@$id" ],
    'once LISTEN a completes: the connection is armed, then LISTEN b goes out';
  ok $fa->is_ready && !$fa->is_failed, 'listen(a) resolves once subscribed and watched';
  is_deeply \@ready_at_watch, [ 0 ],
    '... and not before: it was still pending when watching started';
  ok !$fb->is_ready, 'listen(b) still waits for its own LISTEN';

  $s->{fake}{subs}[1]->done;
  ok $fb->is_ready && !$fb->is_failed, 'listen(b) resolves when LISTEN b completes';
};

# =================================================================================
subtest 'unlisten: last channel stops watching and closes' => sub {
  my $s = fresh();
  my @got;
  $s->listen(a => sub { push @got, 'a' })->get;
  $s->listen(b => sub { push @got, 'b' })->get;
  my $c = conn_n($s, 0);
  clear_log($s);

  $s->unlisten('a')->get;
  is_deeply log_of($s), [ "UNLISTEN a \@$c->{id}" ], 'unlisten(a) sends UNLISTEN on the listen connection';
  is $c->{closed}, 0, 'the connection stays open while a channel remains';
  $s->_listen_dispatch(a => 'late', 1);
  is_deeply \@got, [], 'a notification for the unlistened channel is dropped';

  lives_ok { $s->unlisten('never-listened')->get } 'unlisten of an unknown channel is a no-op';

  clear_log($s);
  $s->unlisten('b')->get;
  is_deeply log_of($s), [ "unwatch \@$c->{id}", "close \@$c->{id}" ],
    'unlisten of the last channel: unwatch, then close';
  is $c->{closed}, 1, 'closed exactly once';
  ok !$c->{watching}, 'no longer watched';
  ok !$s->listen_alive, 'listen_alive is false with nothing listened to';

  clear_log($s);
  $s->listen(c => sub {})->get;
  is_deeply [ grep { /^(open|LISTEN)/ } @{ log_of($s) } ],
    [ 'open', 'LISTEN c @' . conn_n($s, 1)->{id} ],
    'listening again opens a fresh connection with only the new channel';
};

# =================================================================================
subtest 'self-healing: close, backoff, re-subscribe EVERY channel, re-arm, hook' => sub {
  my $s = fresh();
  my @got;
  $s->listen($_ => sub { push @got, "$_[0]:$_[1]" })->get for qw(a b c);
  my $old = conn_n($s, 0);
  clear_log($s);

  $s->_listen_lost($old, 'server closed the connection');
  is_deeply log_of($s), [ "unwatch \@$old->{id}", "close \@$old->{id}", 'delay 1' ],
    'death: the old connection is unwatched and closed, a reconnect waits listen_backoff_initial';
  is_deeply $s->{fake}{errors}, [ 'server closed the connection' ],
    'on_listen_error got the reported error';
  ok !$s->listen_alive, 'not alive while the reconnect is pending';
  is $s->{fake}{reconnects}, 0, 'no reconnect hook yet';

  clear_log($s);
  $s->{fake}{delays}[0]->done;
  my $new = conn_n($s, 1);
  is_deeply log_of($s), [ 'open', map({ "LISTEN $_ \@$new->{id}" } qw(a b c)), "watch \@$new->{id}" ],
    'after the backoff: open, LISTEN every registered channel, then re-arm';
  is $s->{fake}{reconnects}, 1, 'on_listen_reconnect fired once, after re-arming';
  ok $s->listen_alive, 'alive again';

  $s->_listen_dispatch(b => 'after', 7);
  is_deeply \@got, [ 'b:after' ], 'callbacks survive the rebuild';
};

# =================================================================================
subtest 'backoff: bounded doubling, overridable, reset after success' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  $s->{fake}{open_mode} = 'fail';

  $s->_listen_lost(conn_n($s, 0), 'gone');
  $s->{fake}{delays}[$_]->done for 0 .. 5;
  is_deeply [ map { /^delay (.+)/ ? $1 : () } @{ log_of($s) } ],
    [ 1, 2, 4, 8, 16, 30, 30 ], 'delays double from 1 and cap at 30';
  is scalar(grep { /opening the listen connection failed: connection refused/ } @{ $s->{fake}{errors} }), 6,
    'every failed attempt is reported';

  $s->{fake}{open_mode} = 'auto';
  $s->{fake}{delays}[6]->done;
  ok $s->listen_alive, 'the seventh attempt succeeds';

  clear_log($s);
  $s->_listen_lost(conn_n($s, 1), 'gone again');
  is_deeply [ grep { /^delay/ } @{ log_of($s) } ], [ 'delay 1' ],
    'a success resets the backoff to listen_backoff_initial';

  my $t = fresh();
  $t->listen_backoff_initial(0.5);
  $t->listen_backoff_max(2);
  $t->listen(a => sub {})->get;
  $t->{fake}{open_mode} = 'fail';
  $t->_listen_lost(conn_n($t, 0), 'gone');
  $t->{fake}{delays}[$_]->done for 0 .. 2;
  is_deeply [ map { /^delay (.+)/ ? $1 : () } @{ log_of($t) } ], [ 0.5, 1, 2, 2 ],
    'instance bounds override the class defaults';
  is( DBIO::Storage::Async->listen_backoff_initial, 1, '... without touching the class default' );
};

# =================================================================================
subtest 'listen_alive: a failing probe starts healing' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  my $c = conn_n($s, 0);
  ok $s->listen_alive, 'alive while the probe answers';

  $c->{alive} = 0;
  clear_log($s);
  ok !$s->listen_alive, 'false once the probe fails';
  is_deeply log_of($s), [ "probe \@$c->{id}", "unwatch \@$c->{id}", "close \@$c->{id}", 'delay 1' ],
    'the failed probe is a death report: close and schedule a reconnect';
  like $s->{fake}{errors}[0], qr/probe failed/, 'and it is reported';

  $s->{fake}{delays}[0]->done;
  ok $s->listen_alive, 'healed';
};

# =================================================================================
subtest 'listen_reconnect: rebuild now, cut a pending backoff short' => sub {
  my $s = fresh();
  $s->listen($_ => sub {})->get for qw(a b);
  my $c1 = conn_n($s, 0);
  clear_log($s);

  my $f = $s->listen_reconnect;
  my $c2 = conn_n($s, 1);
  is_deeply log_of($s), [ "unwatch \@$c1->{id}", "close \@$c1->{id}", 'open',
    "LISTEN a \@$c2->{id}", "LISTEN b \@$c2->{id}", "watch \@$c2->{id}" ],
    'forced rebuild: close, open at once (no delay), re-subscribe every channel, re-arm';
  ok $f->is_ready && !$f->is_failed, 'its Future resolves once rebuilt';
  is $s->{fake}{reconnects}, 1, 'on_listen_reconnect fired';
  is_deeply $s->{fake}{errors}, [], 'a forced rebuild is not an error';

  # Now while a backoff is pending.
  $s->_listen_lost($c2, 'gone');
  is scalar @{ $s->{fake}{delays} }, 1, 'a backoff timer is pending';
  clear_log($s);
  $s->listen_reconnect;
  my $c3 = conn_n($s, 2);
  is_deeply [ grep { /^(open|delay)/ } @{ log_of($s) } ], [ 'open' ],
    'listen_reconnect during a backoff opens at once';
  ok $s->listen_alive, 'alive';

  clear_log($s);
  $s->{fake}{delays}[0]->done;
  is_deeply log_of($s), [], 'the superseded timer firing later opens nothing';
  ok $s->listen_alive && !$c3->{closed}, 'and leaves the rebuilt connection alone';

  # A forced rebuild restarts the backoff: after three failed attempts the
  # next wait would be 8s; a failing listen_reconnect waits the initial 1s.
  my $b = fresh();
  $b->listen(a => sub {})->get;
  $b->{fake}{open_mode} = 'fail';
  $b->_listen_lost(conn_n($b, 0), 'gone');
  $b->{fake}{delays}[$_]->done for 0 .. 1;
  clear_log($b);
  ok $b->listen_reconnect->is_failed, 'a forced rebuild that fails reports it';
  is_deeply [ grep { /^delay/ } @{ log_of($b) } ], [ 'delay 1' ],
    '... and healing resumes from listen_backoff_initial, not from 8';

  my $idle = fresh();
  ok $idle->listen_reconnect->is_ready, 'with nothing registered there is nothing to rebuild';
  is_deeply log_of($idle), [], '... and no connection is opened';
};

# =================================================================================
subtest 'stale reports and superseded attempts' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  my $c1 = conn_n($s, 0);
  $s->listen_reconnect->get;
  my $c2 = conn_n($s, 1);
  clear_log($s);

  $s->_listen_lost($c1, 'old socket hung up');
  is_deeply log_of($s), [], 'a death report for a replaced connection is ignored';
  ok $s->listen_alive && !$c2->{closed}, 'the current connection is untouched';

  # An attempt that is superseded while its open is still in flight.
  $s->{fake}{open_mode} = 'hold';
  $s->listen_reconnect;                      # attempt 1: open held
  $s->listen_reconnect;                      # attempt 2 supersedes it: open held
  is scalar @{ $s->{fake}{opens} }, 4, 'two held opens';
  my ($late, $current) = (K219::Conn->new, K219::Conn->new);
  $s->{fake}{opens}[3]->done($current);
  $s->{fake}{opens}[2]->done($late);
  is $late->{closed}, 1, 'the superseded attempt\'s connection is closed on arrival';
  is $current->{closed}, 0, 'the current attempt\'s connection is kept';
  ok $s->listen_alive, 'alive on the current connection';
};

# =================================================================================
subtest 'an open that resolves without a connection is a failed attempt' => sub {
  my $s = fresh();
  $s->{fake}{open_mode} = 'hold';
  my $f = $s->listen(a => sub {});
  $s->{fake}{opens}[0]->done(undef);
  ok $f->is_failed, 'listen fails instead of subscribing on nothing';
  like $s->{fake}{errors}[0], qr/without a connection/, 'the transport bug is reported';
  is scalar @{ $s->{fake}{delays} }, 1, 'and healing is scheduled';
};

# =================================================================================
subtest 'a LISTEN refused on a live connection drops that channel' => sub {
  my $s = fresh();
  $s->listen(good => sub {})->get;
  my $c = conn_n($s, 0);
  $s->{fake}{sub_fail}{bad} = 'permission denied';

  my $f = $s->listen(bad => sub {});
  ok $f->is_failed, 'listen(bad) fails';
  like scalar(eval { $f->get; 1 } ? '' : $@), qr/LISTEN on channel 'bad' failed: permission denied/,
    '... with the reason';
  like $s->{fake}{errors}[0], qr/permission denied/, 'the error hook saw it';
  is $c->{closed}, 0, 'the healthy connection is not closed';
  is scalar(grep { /^delay/ } @{ log_of($s) }), 0, 'and no reconnect is scheduled';

  $s->{fake}{sub_fail}{bad} = undef;
  $s->listen_reconnect->get;
  ok !grep({ /LISTEN bad/ } @{ log_of($s) }[ -4 .. -1 ]), 'the dropped channel is not re-subscribed';

  my $only = fresh();
  $only->{fake}{sub_fail}{bad} = 'syntax error';
  ok $only->listen(bad => sub {})->is_failed, 'the only channel refused';
  is conn_n($only, 0)->{closed}, 1, '... leaves no channel, so the connection is closed';
};

# =================================================================================
subtest 'a LISTEN failing on a dead connection heals and keeps the channel' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  my $c = conn_n($s, 0);
  $c->{alive} = 0;
  $s->{fake}{sub_fail}{b} = 'connection reset';

  my $f = $s->listen(b => sub {});
  ok $f->is_failed, 'listen(b) reports the failed attempt';
  is $c->{closed}, 1, 'the dead connection is closed';
  is scalar @{ $s->{fake}{delays} }, 1, 'a reconnect is scheduled';

  delete $s->{fake}{sub_fail}{b};
  clear_log($s);
  $s->{fake}{delays}[0]->done;
  my $n = conn_n($s, 1);
  is_deeply [ grep { /^LISTEN/ } @{ log_of($s) } ], [ "LISTEN a \@$n->{id}", "LISTEN b \@$n->{id}" ],
    'both channels, b included, are subscribed on the new connection';
};

# =================================================================================
subtest 'a dying callback is reported and delivery continues' => sub {
  my $s = fresh();
  my @got;
  $s->listen(a => sub { die "boom\n" if $_[1] eq 'bad'; push @got, $_[1] })->get;

  $s->_listen_dispatch(a => 'bad', 1);
  $s->_listen_dispatch(a => 'good', 1);
  is_deeply \@got, [ 'good' ], 'the next notification is still delivered';
  like $s->{fake}{errors}[0], qr/listen callback for channel 'a' died: boom/,
    'the dying callback went to on_listen_error';
  ok $s->listen_alive, 'the connection is unaffected';
};

# =================================================================================
subtest 'without a hook, errors are warned' => sub {
  my $s = K219::Transport->new(undef);
  $s->listen(a => sub {})->get;
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, $_[0] };
  $s->_listen_lost(conn_n($s, 0), 'socket gone');
  like "@warned", qr/DBIO LISTEN error: socket gone/, 'the lost connection is warned';
};

# =================================================================================
subtest 'notify hands channel and payload to the transport untouched' => sub {
  my $s = fresh();
  my $f = $s->notify(jobs => q{it's "quoted"; DROP TABLE x});
  is $f->get, 'sent', 'notify returns the transport\'s Future';
  $s->notify(jobs => undef);
  is_deeply $s->{fake}{notified}, [ [ jobs => q{it's "quoted"; DROP TABLE x} ], [ jobs => undef ] ],
    'the payload reaches _notify_send as given (binding it is the transport\'s job)';
  ok !exists $s->{_listen}, 'notify does not open the listen connection';
};

# =================================================================================
subtest 'disconnect ends listening' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  my $c = conn_n($s, 0);
  $s->{fake}{hold_sub} = 1;
  my $pending = $s->listen(b => sub {});

  $s->disconnect;
  is $c->{closed}, 1, 'the listen connection is closed';
  ok $pending->is_failed, 'a listen still waiting for its LISTEN fails';
  ok !$s->listen_alive, 'nothing is listened to afterwards';

  $s->{fake}{hold_sub} = 0;
  clear_log($s);
  $s->listen(c => sub {})->get;
  is_deeply [ grep { /^LISTEN/ } @{ log_of($s) } ], [ 'LISTEN c @' . conn_n($s, 1)->{id} ],
    'the registry was cleared: a new listen subscribes only its own channel';
};

# =================================================================================
subtest 'a transport that overrides the public methods is not routed through core' => sub {
  my $s = K219::Overriding->new(undef);
  is $s->listen('x'),   'own-listen',   'its listen wins';
  is $s->unlisten('x'), 'own-unlisten', 'its unlisten wins';
  is $s->notify('x'),   'own-notify',   'its notify wins';
  ok !exists $s->{_listen}, 'the core machinery never created state';
  ok !$s->listen_alive, 'core listen_alive knows no connection of its own';
  lives_ok { $s->disconnect } 'disconnect does not reach for listen seams it lacks';
};

# =================================================================================
subtest 'reachable as $schema->storage->async, torn down by the sync disconnect' => sub {
  DBIO::Storage::DBI->register_async_mode(k219_fake => 'K219::Transport');
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;
  $storage->_async_mode('k219_fake');
  delete $storage->{_async_storage_obj};

  my $async = $storage->async;
  isa_ok $async, 'K219::Transport', 'the embedded backend';
  my @got;
  $async->listen(jobs => sub { push @got, $_[1] })->get;
  $async->_listen_dispatch(jobs => 'hi', 1);
  is_deeply \@got, [ 'hi' ], 'notifications arrive through the schema\'s async backend';

  my $c = $async->{fake}{conns}[0];
  $storage->disconnect;
  is $c->{closed}, 1, 'the sync disconnect closes the listen connection';
};

# =================================================================================
# karr k222. Claim: every Future listen / unlisten / listen_reconnect hands to a
# caller can be waited on with ->get whenever the transport's own Futures can.
# ->get must drive the transport's loop until the operation is in effect and
# then return -- not die because the Future core settles knows no loop (a
# pending future_class Future: "is not yet complete and does not provide
# ->await" on Future.pm). Awaiting must not change WHEN it resolves: listen
# still returns only once the channel is subscribed and watched.
subtest 'k222: listen / unlisten / listen_reconnect ->get drive the transport loop' => sub {
  @K222::Loop::queue = ();
  my $s = fresh('K222::Transport');

  my $f = $s->listen(jobs => sub {});
  ok !$f->is_ready, 'listen returns while the open is still in flight';
  lives_ok { $f->get } 'listen(...)->get waits for the asynchronous open and LISTEN';
  my $id = conn_n($s, 0)->{id};
  is_deeply log_of($s), [ 'open', "LISTEN jobs \@$id", "watch \@$id" ],
    '... and returns once the channel is subscribed and watched';
  ok $s->listen_alive, 'the connection is up when get returns';
  is scalar @K222::Loop::queue, 0, 'get ran the loop exactly as far as needed';

  my $g = $s->listen(more => sub {});
  ok !$g->is_ready, 'a listen on the open connection waits for its own LISTEN';
  lives_ok { $g->get } '... and is awaitable too';
  is log_of($s)->[-1], "LISTEN more \@$id", 'its LISTEN went out on the same connection';

  my $u = $s->unlisten('more');
  ok !$u->is_ready, 'unlisten is pending while its UNLISTEN is in flight';
  lives_ok { $u->get } 'unlisten(...)->get waits for it';
  is log_of($s)->[-1], "UNLISTEN more \@$id", '... and returns once it has been sent';

  clear_log($s);
  my $r = $s->listen_reconnect;
  ok !$r->is_ready, 'listen_reconnect returns while the new open is in flight';
  lives_ok { $r->get } 'listen_reconnect->get waits for the rebuild';
  my $id2 = conn_n($s, 1)->{id};
  is_deeply log_of($s),
    [ "unwatch \@$id", "close \@$id", 'open', "LISTEN jobs \@$id2", "watch \@$id2" ],
    '... and returns once every channel is subscribed on the new connection and watched';
  is $s->{fake}{reconnects}, 1, 'on_listen_reconnect fired before get returned';
  ok $s->listen_alive, 'alive on the rebuilt connection';
};

# Claim: an awaited listen reports the attempt that carries it. When that
# attempt fails on a later tick, ->get dies with the reason instead of hanging,
# and the registration stays for self-healing (ADR 0056 Rationale: a daemon
# awaiting listen at startup learns at once that the database is down).
subtest 'k222: an awaited listen dies with the reason of the failed attempt' => sub {
  @K222::Loop::queue = ();
  my $s = fresh('K222::Transport');
  $s->{fake}{open_mode} = 'fail';

  my $f = $s->listen(jobs => sub {});
  throws_ok { $f->get } qr/opening the listen connection failed: connection refused/,
    'get dies with the failed attempt';
  is_deeply log_of($s), [ 'open', 'delay 1' ], 'and a reconnect is scheduled';

  $s->{fake}{open_mode} = 'auto';
  lives_ok { $s->listen(jobs => sub {})->get }
    'a listen during the backoff awaits the next attempt, timer included';
  ok $s->listen_alive, 'which succeeded';
};

# Claim: the same holds over the real Future.pm, which holds the Futures it
# derives only weakly -- the Future handed out, and the link core settles it
# through, must not get lost on the way ("lost a sequence Future").
subtest 'k222: awaitable over real Future.pm' => sub {
  plan skip_all => 'Future not installed' unless eval { require Future; 1 };
  @K222::Loop::queue = ();
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, $_[0] };
  my $s = fresh('K222::RealTransport');

  lives_ok { $s->listen(jobs => sub {})->get } 'listen(...)->get';
  lives_ok { $s->listen(more => sub {})->get } 'a second listen ->get';
  lives_ok { $s->unlisten('more')->get } 'unlisten(...)->get';
  lives_ok { $s->listen_reconnect->get } 'listen_reconnect->get';
  ok $s->listen_alive, 'alive on the rebuilt connection';
  is_deeply \@warned, [], 'no Future was lost on the way';
};

# Claim: the connection counts as watched from the moment _listen_watch is
# CALLED, not from when it returns. A transport may deliver at once (a first
# drain inside _listen_watch); a callback that then ends listening, or a
# transport that finds the connection dead right there, must have core
# unwatch the connection it closes -- otherwise the transport keeps watching a
# closed connection. And the arm step must not then mark a torn-down or
# replaced state as up.
subtest 'k222: watching is marked before _listen_watch runs' => sub {
  # 1. A notification delivered inside _listen_watch unlistens the last channel.
  my $t = fresh();
  my $early = 1;
  $t->{fake}{on_watch} = sub { $t->_listen_dispatch(a => 'early', 1) if $early-- > 0 };
  my $ft = $t->listen(a => sub { $t->unlisten('a') });
  my $tc = conn_n($t, 0);
  my @ops = grep { /^(unwatch|close)/ } @{ log_of($t) };
  is_deeply \@ops, [ "unwatch \@$tc->{id}", "close \@$tc->{id}" ],
    'unlistening the last channel from inside _listen_watch unwatches before closing';
  ok !$tc->{watching}, 'the transport is no longer watching the closed connection';
  ok !exists $t->{_listen}, 'listening has ended';
  ok $ft->is_failed, 'the listen that was being set up reports it did not take effect';
  ok !$t->listen_alive, 'nothing is alive afterwards';

  # 2. The transport finds the connection dead inside _listen_watch.
  my $d = fresh();
  my $dead = 1;
  $d->{fake}{on_watch} = sub {
    $d->_listen_lost(conn_n($d, 0), 'dead on arrival') if $dead-- > 0;
  };
  my $fd = $d->listen(a => sub {});
  my $dc = conn_n($d, 0);
  is_deeply [ grep { /^(unwatch|close|delay)/ } @{ log_of($d) } ],
    [ "unwatch \@$dc->{id}", "close \@$dc->{id}", 'delay 1' ],
    'a death reported from inside _listen_watch unwatches, closes and schedules a reconnect';
  ok !$dc->{watching}, 'the transport is no longer watching it';
  ok $fd->is_failed, 'the listen carried by that attempt fails';
  ok !$d->listen_alive, 'not alive while the reconnect is pending';

  $d->{fake}{open_mode} = 'fail';
  clear_log($d);
  $d->{fake}{delays}[0]->done;
  is_deeply [ grep { /^delay/ } @{ log_of($d) } ], [ 'delay 2' ],
    'the dead-on-arrival attempt counted as failed: the backoff keeps doubling';
  $d->{fake}{open_mode} = 'auto';
  $d->{fake}{delays}[1]->done;
  ok $d->listen_alive, 'and healing still succeeds';
  is $d->{fake}{reconnects}, 1, 'on_listen_reconnect fired once, for the real rebuild';

  # 3. _listen_watch throws: it started nothing, so nothing is unwatched.
  my $w = fresh();
  $w->{fake}{on_watch} = sub { die "no socket\n" };
  my $fw = $w->listen(a => sub {});
  my $wc = conn_n($w, 0);
  is_deeply [ grep { /^(unwatch|close|delay)/ } @{ log_of($w) } ],
    [ "close \@$wc->{id}", 'delay 1' ],
    'a watch that threw is closed without an unwatch, and healing is scheduled';
  like $w->{fake}{errors}[0], qr/starting to watch the listen connection failed: no socket/,
    'the failure is reported';
  ok $fw->is_failed, 'and the listen carried by it fails';
};

# =================================================================================
# karr k227. _listen_error is how a transport reports an error that does NOT end
# the listen connection -- the MySQL emulation's failed notify-table cleanup is
# the first. Without it, dbio-mysql rebuilt core's reporting rules in its own
# code. It has to report exactly the way core reports its own errors, and it
# must not do anything else.

# Claim: the error a transport reports reaches on_listen_error in the shape
# core's own reports have -- storage first, the text verbatim without its
# trailing newline -- so a consumer's handler cannot tell the two apart.
subtest 'k227: _listen_error hands the error to on_listen_error' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  my @seen;
  $s->on_listen_error(sub { push @seen, [ @_ ] });

  $s->_listen_error("cleaning up the notify table failed: lock wait timeout\n");
  is scalar @seen, 1, 'the hook ran once';
  is $seen[0][0], $s, 'with the storage first';
  is $seen[0][1], 'cleaning up the notify table failed: lock wait timeout',
    'and the error verbatim, trailing newline stripped';
};

# Claim: without a hook the error is warned, never dropped -- the rule core
# applies to its own errors (ADR 0056 section 3), with core's own prefix.
subtest 'k227: without a hook, a reported error is warned' => sub {
  my $s = K219::Transport->new(undef);
  $s->listen(a => sub {})->get;
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, $_[0] };

  $s->_listen_error('cleanup failed');
  is_deeply \@warned, [ "DBIO LISTEN error: cleanup failed\n" ], 'warned once';
};

# Claim: a hook that dies does not reach the transport -- its watch loop called
# _listen_error and has to carry on -- and the death is not lost either: it is
# warned.
subtest 'k227: a dying on_listen_error hook is warned, not thrown' => sub {
  my $s = fresh();
  $s->listen(a => sub {})->get;
  $s->on_listen_error(sub { die "log backend down\n" });
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, $_[0] };

  lives_ok { $s->_listen_error('cleanup failed') } '_listen_error returns normally';
  is_deeply \@warned, [ "DBIO on_listen_error hook died: log backend down\n" ],
    'the hook\'s death is warned';
};

# Claim: a reported error is not a death. Closing, probing or reconnecting
# would tear down a connection that works and heal it for nothing, which is
# why the transport did not call _listen_lost. So no seam runs at all, no
# backoff is scheduled, a listen still in flight keeps waiting, delivery goes
# on and listen_alive stays true.
subtest 'k227: a reported error leaves the listen connection up' => sub {
  my $s = fresh();
  my @got;
  $s->listen(a => sub { push @got, $_[1] })->get;
  my $c = conn_n($s, 0);
  $s->{fake}{hold_sub} = 1;
  my $pending = $s->listen(b => sub {});
  clear_log($s);

  $s->_listen_error('cleanup failed');

  is_deeply log_of($s), [], 'no seam was called: nothing closed, unwatched, probed or opened';
  is_deeply $s->{fake}{delays}, [], 'no reconnect is scheduled';
  is_deeply $s->{fake}{errors}, [ 'cleanup failed' ], 'the error itself is the only report';
  ok !$pending->is_ready, 'the listen still in flight is not failed by it';
  ok !$c->{closed} && $c->{watching}, 'the connection is open and still watched';
  $s->_listen_dispatch(a => 'after', 1);
  is_deeply \@got, [ 'after' ], 'notifications are still delivered';
  ok $s->listen_alive, 'listen_alive is unaffected';
  is $s->{fake}{reconnects}, 0, 'nothing was rebuilt';
};

# Claim: like _listen_dispatch, _listen_error is ignored when this process is
# not listening. A report cannot create listen state, and a straggler arriving
# after listening ended -- about a connection core has already closed --
# reaches no hook.
subtest 'k227: a report while nothing is listened to is ignored' => sub {
  my $s = fresh();
  $s->_listen_error('before any listen');
  ok !exists $s->{_listen}, 'it creates no listen state';

  $s->listen(a => sub {})->get;
  $s->unlisten('a');
  $s->_listen_error('after the last unlisten');
  ok !exists $s->{_listen}, 'nor does it bring ended listen state back';
  is_deeply $s->{fake}{errors}, [], 'neither report reached the hook';
};

# =================================================================================
SKIP: {
  skip 'fork not available on this platform', 7 unless $Config{d_fork};

  my ($tfh, $trace) = File::Temp::tempfile(UNLINK => 1);
  close $tfh;

  my $s = fresh();
  $s->{fake}{trace_file} = $trace;
  $s->listen(parent_ch => sub {})->get;
  my $pc = conn_n($s, 0);

  my $child_ops = sub {
    my $pid = shift;
    open my $r, '<', $trace or die "open $trace: $!";
    return grep { /^$pid / } <$r>;
  };

  # 1. A child that uses the API on the inherited storage, then disconnects.
  #    Exit codes: 0 clean, 2 parent state visible, 3 own listen wrong.
  {
    my $pid = fork;
    defined $pid or die "fork failed: $!";
    unless ($pid) {
      open STDOUT, '>', '/dev/null';
      my $code = 0;
      $code ||= 2 if $s->listen_alive;
      $s->_listen_lost($pc, 'child thinks it died');      # must be ignored
      $s->_listen_dispatch(parent_ch => 'x', 1);           # must be ignored
      $s->unlisten('parent_ch');                           # parent's channel: not ours
      @{ $s->{fake}{log} } = ();
      $s->listen(child_ch => sub {})->get;
      my @log = @{ $s->{fake}{log} };
      $code ||= 3 unless "@log" =~ /^open LISTEN child_ch \@(\d+)/ && $1 != $pc->{id};
      $code ||= 3 if grep { /parent_ch/ } @log;
      $s->disconnect;
      exit $code;
    }
    waitpid $pid, 0;
    is $? >> 8, 0, 'child: sees no parent listen state, and its own listen opens its own connection';
    my @ops = $child_ops->($pid);
    ok !grep({ /\@$pc->{id}\b/ } @ops),
      'child: never probed, unwatched, unlistened or closed the parent connection'
      or diag "child ops: @ops";
  }

  # 2. A child that just exits: global destruction runs the inherited DESTROY.
  {
    my $pid = fork;
    defined $pid or die "fork failed: $!";
    unless ($pid) {
      open STDOUT, '>', '/dev/null';
      exit 0;
    }
    waitpid $pid, 0;
    is $? >> 8, 0, 'child: global destruction of the inherited storage exits cleanly';
    my @ops = $child_ops->($pid);
    is_deeply \@ops, [], 'child: its DESTROY touched no listen connection';
  }

  # 3. (k227) The inherited transport reports a non-fatal error in the child.
  #    Claim: like the transport's other callbacks, the report belongs to the
  #    process that opened the connection. In a child it reaches no hook and
  #    leaves the inherited state and the parent's connection as they were.
  #    Exit codes: 0 clean, 4 the hook ran, 5 the inherited state changed.
  {
    my $pid = fork;
    defined $pid or die "fork failed: $!";
    unless ($pid) {
      open STDOUT, '>', '/dev/null';
      my $code = 0;
      my $L = $s->{_listen};
      my @before = ($L, @{$L}{qw(pid gen phase conn attempt)});
      @{ $s->{fake}{errors} } = ();
      $s->_listen_error('cleanup failed in the child');
      $code ||= 4 if @{ $s->{fake}{errors} };
      my $L2 = $s->{_listen};
      my @after = ($L2, @{$L2}{qw(pid gen phase conn attempt)});
      $code ||= 5 unless @after == @before
        && !grep { ($before[$_] // '') ne ($after[$_] // '') } 0 .. $#before;
      exit $code;
    }
    waitpid $pid, 0;
    is $? >> 8, 0, 'child: a reported error reaches no hook and changes no inherited state';
    my @ops = $child_ops->($pid);
    is_deeply \@ops, [], 'child: its report touched no listen connection';
  }

  ok $s->listen_alive && !$pc->{closed},
    'parent: its listen connection is still open and alive';
  $s->disconnect;
}

done_testing;
