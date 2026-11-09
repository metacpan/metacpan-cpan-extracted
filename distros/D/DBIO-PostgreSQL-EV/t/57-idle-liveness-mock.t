use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k70 / k72: a pooled connection whose session ended
# while it sat idle, and what the next borrower gets.
#
# WHY: core's pool asks _idle_connection_alive about every idle connection it
# is about to hand out (DBIO::Storage::PoolBase, core k241), so that a session
# the server ended meanwhile -- a restart, idle_session_timeout,
# pg_terminate_backend -- does not cost a caller a failed statement first.
# Until karr k72 DBIO::PostgreSQL::EV::Pool did not fill that seam. What it had
# was EV::Pg's on_error, which the pool turns into a report (karr k49): EV::Pg
# keeps its read watcher on an idle connection, so the end of the session is
# read, and the connection retired, as soon as the EV loop runs. That reaches
# exactly as far as the loop does. A program that only ever blocks (select,
# insert, txn_do: each runs the loop for its own call and no longer) reads
# nothing between two calls, and the first call after the server ended the
# session was handed the dead connection, and failed.
#
# The seam now looks, without the loop: at EV::Pg's own view of the handle
# (is_connected), and at the socket -- not whether it has something to READ,
# which a live session's socket has as well (a notification, a notice), but
# whether the server's end of it is CLOSED (poll, POLLRDHUP), which the kernel
# knows with the server's last words still unread in front of the close.
#
# What this file claims, through the REAL storage and pool over a stand-in
# EV::Pg:
#   1. the session ends while the connection is idle and the EV loop runs
#      before the next borrow: the connection is retired then, closed once,
#      and the next call completes first time on a fresh one;
#   2. a healthy idle connection is handed out again: the same one, nothing
#      spawned, nothing closed -- also when the server has SENT it something
#      meanwhile (readable is not gone), and what was sent is still there for
#      the loop to read. The guard against a seam that is too eager;
#   3. however the dead connection is found, it is closed once and never sent
#      a second statement, and the pool serves on with a fresh one;
#   4. the session ended and the loop has NOT run since. EV::Pg still reports
#      the handle connected -- libpq learns of a lost connection only by
#      reading, and nothing has read. The statement is not sent on that
#      connection: the call completes first time on a fresh one, and the
#      pool's on_error hears nothing. With the server's last words on the
#      socket and without, over a Unix-domain and over a TCP socket;
#   5. the handle is no longer connected and the pool was not told -- EV::Pg
#      lost it with a caller's on_error in place of the pool's, or a caller
#      called finish on it: the call completes first time on a fresh
#      connection;
#   6. a statement of a caller's own in flight on the idle handle: the
#      connection is vouched for, whatever its socket says, so that no
#      callback runs inside the acquire;
#   7. the look itself, state by state on both kinds of socket: closed is seen
#      behind unread data, readable alone never counts; and it never waits,
#      sends nothing, reads nothing, asks again when a signal interrupts it,
#      and vouches where it cannot ask;
#   8. a look that dies does not throw out of the acquire: core reports it and
#      retires the connection.
# Before karr k72, 4 and 5 failed (held as TODO then): the call was handed the
# dead connection and failed with "connection lost" / "not connected".
# t/41-pool-retire-dead-mock.t claimed that outcome for 5 in its d; it claims
# this one now, and holds the dispatch's own report where it is still the
# only one.
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/41: a fake the real pool
# builds through its real, fork-safe constructor, so the on_error under test
# is the pool's own. What it takes from EV::Pg (Pg.xs, 0.02 and 0.07 alike --
# read there, not measured here; what an idle connection's end looks like
# from the pool is held against PostgreSQL in t/63-idle-liveness-live.t,
# karr k73):
#   - the read watcher on the socket is started when the connect completes and
#     stays active while the handle is connected; with no callback queued it
#     does not keep EV::run alive, but it fires whenever the loop runs
#     (update_idle_ref). Here: a real EV::io on a real socket;
#   - is_connected is libpq's PQstatus, which changes only when libpq reads or
#     writes: after the server closed, it stays true until the read watcher
#     has run. Nothing but that watcher makes libpq read (PQconsumeInput has
#     the one caller, io_read_cb);
#   - socket is libpq's descriptor (PQsocket), -1 without a connection;
#   - a failed read is handle_conn_loss: on_error is called -- the handle no
#     longer reports connected by then --, then, unless on_error closed the
#     handle itself, the connection is torn down and every queued callback
#     gets (undef, "connection lost");
#   - finish fails the queued callbacks ("connection finished"), closes, and
#     calls no on_error; a dispatch on a handle that is not connected croaks
#     "not connected" before it queues anything;
#   - a statement sent on a connection the server has closed is taken (libpq
#     defers a failed write to the next read) and never answered.
# The socket is real, and it is what the pool's look is made on: a
# Unix-domain socket pair, or a TCP connection over loopback ($EV::Pg::PAIR).
# The server ending a session is its last message and a close on its end --
# what a client socket sees of a backend that exits.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();
  use Socket ();
  use IO::Socket::INET ();

  our @BUILT;            # every handle made, in order (weak)
  our $PAIR = 'unix';    # the kind of socket the next handle is made on
  my $ID = 0;

  # A connected stream socket and its other end: ($ours, $servers), or nothing
  # when a TCP connection over loopback cannot be made here.
  sub t_pair {
    my ($kind) = @_;
    if ($kind eq 'unix') {
      socketpair(my $ours, my $servers, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
        or die "socketpair: $!";
      return ($ours, $servers);
    }
    my $listen = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp')
      or return;
    my $ours = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $listen->sockport, Proto => 'tcp')
      or return;
    my $servers = $listen->accept or return;
    return ($ours, $servers);
  }

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      id         => ++$ID,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      finished   => 0,
      queue      => [],
      wire       => [],   # the statements sent, by name
      read       => '',   # what the read watcher took off the socket
    }, $class;
    @$self{qw( sock server )} = t_pair($PAIR) or die "no $PAIR socket to be had";
    push @BUILT, $self;
    Scalar::Util::weaken($BUILT[-1]);
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak && $weak->{sock};
      $weak->{up} = 1;
      # start_reading: active from now on, whatever is or is not queued.
      $weak->{rio} = EV::io(fileno $weak->{sock}, EV::READ(), sub { $weak->_io_read if $weak });
      $weak->_idle_ref;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub on_error {
    my $self = shift;
    $self->{on_error} = $_[0] if @_;
    return $self->{on_error};
  }

  # update_idle_ref
  sub _idle_ref {
    my ($self) = @_;
    $self->{rio}->keepalive(@{ $self->{queue} } ? 1 : 0) if $self->{rio};
    return;
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { $_[0]{sock} ? fileno $_[0]{sock} : -1 }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    push @{ $self->{wire} }, $bind->[-1];
    push @{ $self->{queue} }, { name => $bind->[-1], cb => $cb };
    $self->_idle_ref;
    $self->_arm;
    return;
  }

  # cancel_pending, then cleanup_connection: no on_error.
  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->_cancel_pending('connection finished');
    $self->_cleanup;
    return;
  }

  sub _cancel_pending {
    my ($self, $msg) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, $msg); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    return;
  }

  sub _cleanup {
    my ($self) = @_;
    delete $self->{rio};
    close delete $self->{sock} if $self->{sock};
    $self->{up} = 0;
    return;
  }

  # io_read_cb: PQconsumeInput. What the server sent to an idle session is
  # taken; the end of file is the lost connection.
  sub _io_read {
    my ($self) = @_;
    my $sock = $self->{sock} or return;
    my $n = sysread $sock, my $buf, 4096;
    if ($n) {
      $self->{read} .= $buf;
      return;
    }
    # handle_conn_loss
    $self->{up} = 0;
    my $on_error = $self->{on_error};
    $on_error->("server closed the connection unexpectedly\n") if $on_error;
    return unless $self->{sock};   # on_error closed the handle itself
    $self->_cleanup;
    $self->_cancel_pending('connection lost');
    return;
  }

  # --- the server's side ---

  # The backend exits: its last message -- unless it goes without a word --
  # then its end of the socket closes. Nothing on the client's side changes
  # until something reads.
  sub t_server_ends_session {
    my ($self, %how) = @_;
    my $server = delete $self->{server} or Carp::croak('the session has ended already');
    syswrite $server, "FATAL:  terminating connection due to administrator command\n"
      unless $how{silent};
    close $server;
    return;
  }

  # The server sends a live session something nobody asked for: a
  # notification, a notice, a parameter change.
  sub t_server_sends {
    my ($self, $bytes) = @_;
    my $server = $self->{server} or Carp::croak('the session has ended');
    syswrite $server, $bytes;
    return;
  }

  # What has arrived at the server's end, without waiting for any.
  sub t_server_received {
    my ($self) = @_;
    my $server = $self->{server} or Carp::croak('the session has ended');
    return '' unless main::readable(fileno $server);
    sysread $server, my $buf, 4096;
    return $buf // '';
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    return unless $self->{server};   # no backend is left to answer
    my $head = $self->{queue}[0] or return;
    $self->{delivering} = $head;
    eval { $head->{cb}->([ [ 'row-of', $head->{name} ] ]); 1 }
      or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_idle_ref;
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use IO::Poll ();
use POSIX ();
use Time::HiRes ();
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Pool;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $POOL = 'DBIO::PostgreSQL::EV::Pool';

# Can this platform's poll be asked whether a peer has closed? Where it
# cannot, the pool vouches for a connection whose server end is closed, as it
# did before karr k72: 4 cannot hold there, and 7 claims the fallback instead.
my $rdhup = $POOL->can('_pg_rdhup');
ok $rdhup, 'the pool measures whether poll can be asked for a closed peer (_pg_rdhup)';
my $CAN_ASK = $rdhup ? $rdhup->() : 0x2000;
note $CAN_ASK
  ? sprintf('poll reports a closed peer here: bit 0x%x', $CAN_ASK)
  : 'poll has no flag for a closed peer here';
my $NO_FLAG = "this platform's poll has no flag for a closed peer: the pool vouches, as before karr k72";

my @KINDS = grep { my @pair = EV::Pg::t_pair($_); scalar @pair } qw( unix tcp );
note 'no TCP connection over loopback to be had: Unix-domain sockets only' unless @KINDS == 2;

# Has $fd something to read right now? select, not the EV loop: nothing is
# read, and no watcher runs.
sub readable {
  my ($fd) = @_;
  my $rin = '';
  vec($rin, $fd, 1) = 1;
  return select(my $rout = $rin, undef, undef, 0) > 0 ? 1 : 0;
}

sub pool_of_one {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the EV loop for a moment: every timer the fake has runs out, and every
# read watcher gets its turn.
sub run_loop {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub the_conn { $_[0]->pool->{_connections}[0] }
sub made     { scalar @EV::Pg::BUILT }
sub wire     { [ @{ $_[0]{wire} } ] }
sub in_pool  { my ($storage, $conn) = @_; scalar grep { $_ == $conn } @{ $storage->pool->{_connections} } }

sub select_named { $_[0]->select_async('thing', [qw( tag name )], { name => $_[1] }) }

# A pool of one whose connection is spawned, used once and idle.
sub warm {
  my $storage = pool_of_one();
  my ($ok, @r) = wait_for(select_named($storage, 'warm'));
  die "warming the pool failed: $r[0]" unless $ok;
  run_loop();
  my $conn = the_conn($storage);
  die 'the pool did not keep its connection idle' unless $conn && $storage->pool->available == 1;
  @warnings = ();
  return ($storage, $conn);
}

# No callback died out of EV::Pg, and the pool's look at an idle connection
# did not die either: core reports that one to on_error, which warns here.
sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg" or diag @died;
  my @look = grep { /liveness check failed/ } @warnings;
  is scalar @look, 0, "$label: and the look at the idle connection did not die" or diag @look;
  @warnings = ();
}

# 3. However the dead connection was found: it is out of the pool, closed
# $closed times, was sent nothing beyond @sent, and the pool's one connection
# is a fresh one that serves the next call.
sub dead_one_is_gone {
  my ($label, $storage, $dead, $closed, @sent) = @_;
  run_loop();
  ok !in_pool($storage, $dead), "$label: the dead connection is out of the pool";
  is $dead->{finished}, $closed, "$label: closed " . ($closed == 1 ? 'once' : "$closed times, once by the pool");
  is_deeply wire($dead), [ 'warm', @sent ], "$label: and sent nothing more";

  my ($ok, @r) = wait_for(select_named($storage, 'after'));
  ok $ok, "$label: the pool serves on" or diag "the call failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'after' ] ], "$label: with the call's own rows";
  run_loop();
  my $fresh = the_conn($storage);
  ok $fresh && $fresh != $dead && $fresh->{wire}[-1] eq 'after', "$label: on a fresh connection";
  is $storage->pool->size, 1, "$label: the pool's one connection";
  is $storage->pool->available, 1, "$label: idle";
  no_callback_died($label);
}

# --- 1. the session ends while idle, and the EV loop runs before the borrow -----

{
  my $label = 'ended while idle, loop ran';
  my ($storage, $conn) = warm();
  my $made = made();

  $conn->t_server_ends_session;
  is $storage->pool->available, 1, "$label: (until something reads, the pool still has it idle)";
  run_loop();
  is $storage->pool->size, 0, "$label: retired as soon as the loop read the end of the session";
  is $conn->{finished}, 1, "$label: and closed, once";
  like join('', @warnings), qr/pool error: server closed the connection unexpectedly/,
    "$label: the pool's on_error heard of it";
  is made(), $made, "$label: nothing is spawned before somebody asks";
  @warnings = ();

  my ($ok, @r) = wait_for(select_named($storage, 'first'));
  ok $ok, "$label: the next call completes, first time" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'first' ] ], "$label: with its own rows";
  is made(), $made + 1, "$label: on a freshly spawned connection";
  dead_one_is_gone($label, $storage, $conn, 1);
}

# --- 2. a healthy idle connection is handed out again ---------------------------

{
  my $label = 'healthy idle connection';
  my ($storage, $conn) = warm();
  my $made = made();
  run_loop();   # idle for a while, the loop running

  my ($ok, @r) = wait_for(select_named($storage, 'again'));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'again' ] ], "$label: with its own rows";
  is_deeply wire($conn), [qw( warm again )], "$label: on the same connection";
  is made(), $made, "$label: nothing was spawned";
  is $conn->{finished}, 0, "$label: nothing was closed";
  run_loop();
  is $storage->pool->available, 1, "$label: and it is idle again";
  no_callback_died($label);
}

# --- 2. ... also when the server has sent it something: readable is not gone ----
#
# A PostgreSQL server writes to a live idle session -- a notification on a
# channel it listens on, a notice, a parameter change. Its socket is readable
# then, exactly like that of a session that ended. No loop run between the
# server's message and the borrow.

for my $kind (@KINDS) {
  my $label = "live idle session, something to read ($kind)";
  local $EV::Pg::PAIR = $kind;
  my ($storage, $conn) = warm();
  my $made    = made();
  my $message = 'Async notification "still alive" received';

  $conn->t_server_sends($message);
  ok readable($conn->socket), "$label: (its socket is readable)";
  ok $conn->is_connected, "$label: (and EV::Pg reports the handle connected, which it is)";

  my $f = select_named($storage, 'again');
  is_deeply wire($conn), [qw( warm again )], "$label: the call is handed the same connection";
  is $conn->{read}, '', "$label: and nothing was read off its socket on the way";
  my ($ok, @r) = wait_for($f);
  ok $ok, "$label: the call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'again' ] ], "$label: with its own rows";
  is made(), $made, "$label: nothing was spawned";
  is $conn->{finished}, 0, "$label: nothing was closed";
  run_loop();
  is $conn->{read}, $message, "$label: what the server sent is read by the loop, whole";
  is $storage->pool->available, 1, "$label: and the connection is idle again";
  no_callback_died($label);
}

# --- 4. the session ended, and the loop has not run since -----------------------

for my $kind (@KINDS) {
  for my $how ('with its last words', 'without a word') {
    my $label = "ended while idle, loop did not run ($kind, $how)";
    local $EV::Pg::PAIR = $kind;
    my ($storage, $conn) = warm();
    my $made = made();

    $conn->t_server_ends_session(silent => $how =~ /^without/);
    ok $conn->is_connected, "$label: (EV::Pg still reports the handle connected: nothing has read the socket)";
    is $storage->pool->available, 1, "$label: (and the pool has it idle)";

    # No loop run between the end of the session and the borrow.
    my $f = select_named($storage, 'first');
    my ($ok, @r) = wait_for($f);

    SKIP: {
      skip $NO_FLAG, 1 unless $CAN_ASK;
      is_deeply wire($conn), ['warm'],
        "$label: the statement is not sent on the connection whose session has ended";
      ok $ok, "$label: the call completes, first time" or diag "it failed: $r[0]";
      is_deeply \@r, [ [ 'row-of', 'first' ] ], "$label: with its own rows";
      is made(), $made + 1, "$label: on a freshly spawned connection";
      is $conn->{read}, '', "$label: nothing was read off the dead connection's socket";
      unlike join('', @warnings), qr/pool error/,
        "$label: and the pool's on_error hears nothing: the connection is retired quietly";
    }
    @warnings = ();
    dead_one_is_gone($label, $storage, $conn, 1, grep { $_ eq 'first' } @{ wire($conn) });
  }
}

# --- 5. the handle is not connected any more, and the pool was not told ---------

for my $how ('lost, on_error replaced by a caller', 'finished by a caller') {
  my $label = "idle handle $how";
  my ($storage, $conn) = warm();
  my $made = made();
  my @heard;

  if ($how =~ /^lost/) {
    $conn->on_error(sub { push @heard, $_[0] });
    $conn->t_server_ends_session;
    run_loop();
    is scalar @heard, 1, "$label: (EV::Pg reported the loss to the caller's handler, not to the pool)";
  }
  else {
    $conn->finish;
  }
  ok !$conn->is_connected, "$label: EV::Pg no longer reports the handle connected";
  is $storage->pool->available, 1, "$label: and the pool still has it idle";

  my ($ok, @r) = wait_for(select_named($storage, 'first'));

  ok $ok, "$label: the call completes, first time" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'first' ] ], "$label: with its own rows";
  is made(), $made + 1, "$label: on a freshly spawned connection";
  @warnings = ();
  dead_one_is_gone($label, $storage, $conn, $how =~ /^lost/ ? 1 : 2);
}

# --- 6. a caller's own statement is in flight on the idle handle ----------------
#
# A caller that kept the handle (txn_pg) can leave a statement queued on a
# connection the pool has idle. Retiring the connection would fail that
# statement from inside the acquire -- finish calls its callback -- so the
# pool vouches without a look, and the handle's own read reports the loss.

{
  my $label = 'idle handle with a statement in flight, session ended';
  my ($storage, $conn) = warm();
  my @kept;
  $conn->query_params('SELECT $1', ['kept'], sub { push @kept, [@_] });
  $conn->t_server_ends_session;
  is $conn->pending_count, 1, "$label: (the statement is queued, and no backend is left to answer it)";

  my $f = select_named($storage, 'first');
  is scalar @kept, 0, "$label: no callback ran inside the acquire";
  is $conn->{finished}, 0, "$label: the connection was not closed there";
  is_deeply wire($conn), [qw( warm kept first )], "$label: the call was handed the connection, vouched for";

  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: the call fails, as the statement in front of it";
  like $ok ? '' : $r[0], qr/^connection lost/, "$label: with EV::Pg's error, once the loop read the end";
  is_deeply \@kept, [ [ undef, 'connection lost' ] ], "$label: the caller's statement heard it from EV::Pg, once";
  like join('', @warnings), qr/pool error: server closed the connection unexpectedly/,
    "$label: and the pool's on_error heard of the loss";
  @warnings = ();
  dead_one_is_gone($label, $storage, $conn, 1, qw( kept first ));
}

# --- 7. the look itself ----------------------------------------------------------
#
# Asked of the pool directly, about a handle that answers what EV::Pg's
# accessors answer and counts what it is asked.

{
  package t::Handle;
  sub new           { my ($class, %is) = @_; bless { up => 1, pending => 0, asked => 0, %is }, $class }
  sub is_connected  { $_[0]{up} }
  sub pending_count { $_[0]{pending} }
  sub socket        { $_[0]{asked}++; $_[0]{fd} }
}

my $pool = pool_of_one()->pool;

sub alive  { $pool->_idle_connection_alive($_[0]) ? 1 : 0 }
sub closed { $pool->_pg_peer_closed($_[0]) ? 1 : 0 }

# Every call of poll while $code runs: [ timeout, descriptor, events asked ].
sub polls_during {
  my ($code) = @_;
  my $real = \&IO::Poll::_poll;
  my @polls;
  no warnings 'redefine';
  local *IO::Poll::_poll = sub { push @polls, [ @_[0 .. 2] ]; goto &$real };
  $code->();
  return @polls;
}

# The states of a stream socket: what is done to (ours, the server's), and
# whether the server's end counts as closed.
my @STATES = (
  [ 'open, nothing sent',                     0, sub { } ],
  [ 'open, something to read',                0, sub { syswrite $_[1], 'N' x 100 } ],
  [ 'open, more to read than a buffer holds', 0, sub { $_[1]->blocking(0); 1 while syswrite $_[1], 'N' x 65536 } ],
  [ 'we shut down our own sending',           0, sub { shutdown $_[0], 1 } ],
  [ 'closed, nothing to read',                1, sub { close $_[1] } ],
  [ 'closed behind something to read',        1, sub { syswrite $_[1], 'FATAL'; close $_[1] } ],
  [ 'the server shut down its sending',       1, sub { shutdown $_[1], 1 } ],
  [ 'reset by the server',                    1, sub {
      setsockopt $_[1], Socket::SOL_SOCKET(), Socket::SO_LINGER(), pack('ii', 1, 0);
      close $_[1];
    } ],
);

for my $kind (@KINDS) {
  for my $state (@STATES) {
    my ($name, $is_closed, $make) = @$state;
    my $label = "the look, $kind socket $name";
    my ($ours, $servers) = EV::Pg::t_pair($kind);
    $make->($ours, $servers);
    my $handle = t::Handle->new(fd => fileno $ours);

    my $expect = $CAN_ASK ? $is_closed : 0;
    my ($closed, $alive);
    my @polls = polls_during(sub { $closed = closed($handle); $alive = alive($handle) });
    is $closed, $expect, "$label: " . ($expect ? 'the peer is closed' : 'the peer is not known to be closed');
    is $alive, $expect ? 0 : 1, "$label: " . ($expect ? 'the connection is not vouched for' : 'the connection is vouched for');
    is scalar(grep { $_->[0] != 0 } @polls), 0, "$label: poll is never given time to wait";
    cmp_ok scalar @polls, '<=', 2, "$label: and is asked once a look";
    is scalar(grep { $_->[2] & IO::Poll::POLLIN() } @polls), 0, "$label: never for something to read";
  }
}

SKIP: {
  skip $NO_FLAG, 1 unless $CAN_ASK;

  # What the kernel answers, bit by bit: the difference between the two kinds
  # of socket, and why the bit for a closed peer is the one that counts. Over
  # TCP a peer that closed leaves nothing else set -- no POLLHUP as long as
  # our own end is open.
  for my $kind (@KINDS) {
    my ($ours, $servers) = EV::Pg::t_pair($kind);
    syswrite $servers, 'FATAL';
    close $servers;
    my $asked = $CAN_ASK;
    my @ask   = (fileno $ours, $asked);
    IO::Poll::_poll(0, @ask);
    ok $ask[1] & $CAN_ASK, "the kernel, $kind socket closed behind unread data: the bit for a closed peer is set";
    is $ask[1] & IO::Poll::POLLHUP() ? 1 : 0, $kind eq 'tcp' ? 0 : 1,
      "the kernel, $kind socket closed behind unread data: POLLHUP is "
      . ($kind eq 'tcp' ? 'not set -- the closed peer is all there is to go by' : 'set as well');
  }
}

# The descriptor is not a socket any more, or not open at all.
{
  my ($ours, $servers) = EV::Pg::t_pair('unix');
  my $fd = fileno $ours;
  close $ours;
  my $handle = t::Handle->new(fd => $fd);
  SKIP: {
    skip $NO_FLAG, 1 unless $CAN_ASK;
    is closed($handle), 1, 'the look, a descriptor that is not open: closed';
    is alive($handle), 0, 'the look, a descriptor that is not open: not vouched for';
  }
}

# What EV::Pg's own accessors settle, before any look at the socket.
{
  my ($ours, $servers) = EV::Pg::t_pair('unix');
  close $servers;

  my $down = t::Handle->new(fd => fileno $ours, up => 0);
  my @polls = polls_during(sub { is alive($down), 0, 'the look, a handle EV::Pg reports not connected: not vouched for' });
  is $down->{asked}, 0, 'the look, a handle EV::Pg reports not connected: its socket is not asked for';
  is scalar @polls, 0, 'the look, a handle EV::Pg reports not connected: and nothing is polled';

  my $busy = t::Handle->new(fd => fileno $ours, pending => 1);
  @polls = polls_during(sub { is alive($busy), 1, 'the look, a handle with a statement in flight: vouched for, though its peer is closed' });
  is $busy->{asked}, 0, 'the look, a handle with a statement in flight: its socket is not asked for';
  is scalar @polls, 0, 'the look, a handle with a statement in flight: and nothing is polled';

  for my $none (-1, undef) {
    my $handle = t::Handle->new(fd => $none);
    my $what   = defined $none ? $none : 'undef';
    @polls = polls_during(sub {
      is closed($handle), 0, "the look, a connected handle whose socket is $what: not known to be closed";
      is alive($handle), 1, "the look, a connected handle whose socket is $what: vouched for";
    });
    is scalar @polls, 0, "the look, a connected handle whose socket is $what: nothing is polled";
  }
}

# It sends nothing and reads nothing, and it does not wait: asked many times
# about a live session that was sent something, and about one whose server is
# silent.
for my $kind (@KINDS) {
  local $EV::Pg::PAIR = $kind;
  my $label = "the look, many times ($kind)";
  my ($storage, $conn) = warm();
  my $message = 'something the server sent';
  my $looks   = 2000;
  my $live_pool = $storage->pool;

  my $vouched = 0;
  my $started = Time::HiRes::time();
  $vouched += $live_pool->_idle_connection_alive($conn) ? 1 : 0 for 1 .. $looks;
  $conn->t_server_sends($message);
  $vouched += $live_pool->_idle_connection_alive($conn) ? 1 : 0 for 1 .. $looks;
  my $took = Time::HiRes::time() - $started;

  is $vouched, 2 * $looks, "$label: a live session is vouched for every time, with nothing and with something to read";
  cmp_ok $took, '<', 5, sprintf('%s: %d looks do not wait (%.1f microseconds each)', $label, 2 * $looks, 1e6 * $took / (2 * $looks));
  is $conn->t_server_received, '', "$label: nothing was sent to the server";
  is $conn->{read}, '', "$label: nothing was read";
  is_deeply wire($conn), ['warm'], "$label: no statement was sent";
  run_loop();
  is $conn->{read}, $message, "$label: what the server sent is still there for the loop, whole";
  is $conn->{finished}, 0, "$label: and the connection was not closed";
  no_callback_died($label);
}

# A signal interrupts the poll: the kernel answers EINTR with nothing to
# report, which says nothing about the socket. Asked again.
for my $state ('closed', 'open') {
  my ($ours, $servers) = EV::Pg::t_pair('unix');
  close $servers if $state eq 'closed';
  my $handle = t::Handle->new(fd => fileno $ours);
  my $real   = \&IO::Poll::_poll;
  my $calls  = 0;
  my $closed;
  {
    no warnings 'redefine';
    local *IO::Poll::_poll = sub {
      if (++$calls <= 2) { $! = POSIX::EINTR(); return -1 }
      goto &$real;
    };
    $closed = closed($handle);
  }
  is $closed, $state eq 'closed' && $CAN_ASK ? 1 : 0,
    "the look, poll interrupted by a signal ($state peer): the answer is the socket's";
  SKIP: {
    skip $NO_FLAG, 1 unless $CAN_ASK;
    is $calls, 3, "the look, poll interrupted by a signal ($state peer): asked again until it answers";
  }
}

# poll fails for another reason: nothing is known about the socket. Vouched
# for -- and asked once, not for ever.
{
  my ($ours, $servers) = EV::Pg::t_pair('unix');
  close $servers;
  my $handle = t::Handle->new(fd => fileno $ours);
  my $calls  = 0;
  my ($closed, $alive);
  {
    no warnings 'redefine';
    local *IO::Poll::_poll = sub { $calls++; $! = POSIX::EINVAL(); return -1 };
    $closed = closed($handle);
    $alive  = alive($handle);
  }
  is $closed, 0, 'the look, poll fails: the peer is not known to be closed';
  is $alive, 1, 'the look, poll fails: the connection is vouched for';
  SKIP: {
    skip $NO_FLAG, 1 unless $CAN_ASK;
    is $calls, 2, 'the look, poll fails: asked once a look';
  }
}

# A platform whose poll has no flag for a closed peer: the pool vouches, as it
# did before karr k72, and polls nothing.
{
  my ($ours, $servers) = EV::Pg::t_pair('unix');
  syswrite $servers, 'FATAL';
  close $servers;
  my $handle = t::Handle->new(fd => fileno $ours);
  my ($closed, $alive);
  no warnings 'redefine';
  local *DBIO::PostgreSQL::EV::Pool::_pg_rdhup = sub { 0 };
  my @polls = polls_during(sub { $closed = closed($handle); $alive = alive($handle) });
  is $closed, 0, 'the look, no flag for a closed peer: not known to be closed';
  is $alive, 1, 'the look, no flag for a closed peer: the connection is vouched for';
  is scalar @polls, 0, 'the look, no flag for a closed peer: nothing is polled';
}

# The measurement behind the flag: the bit counts only if poll reports it for
# a closed peer and for nothing else.
SKIP: {
  skip 'the pool has no _pg_measure_rdhup', 1 unless $POOL->can('_pg_measure_rdhup');
  my $measure = $POOL->can('_pg_measure_rdhup');
  my $real    = \&IO::Poll::_poll;
  no warnings 'redefine';

  is $measure->(), $CAN_ASK, 'the measurement: answers what the pool goes by';
  {
    # A poll that reports the bit for every socket with something to read.
    local *IO::Poll::_poll = sub {
      my @ask = ($_[1], IO::Poll::POLLIN());
      my $n   = $real->(0, @ask);
      $_[2]   = $n > 0 ? 0x2000 : 0;
      return $n;
    };
    is $measure->(), 0, 'the measurement: a bit poll reports for a readable open socket is no flag for a closed peer';
  }
  {
    local *IO::Poll::_poll = sub { $_[2] = 0x2000; return 1 };
    is $measure->(), 0, 'the measurement: nor is a bit it reports for every socket';
  }
  {
    local *IO::Poll::_poll = sub { $_[2] = 0; return 0 };
    is $measure->(), 0, 'the measurement: nor one it never reports';
  }
  {
    local *IO::Poll::_poll = sub { die "poll: not implemented\n" };
    is $measure->(), 0, 'the measurement: a platform without poll has none, and the measurement does not die';
  }
}

# --- 8. a look that dies ---------------------------------------------------------
#
# Core's promise, held here for this pool's look: the acquire does not throw,
# the pool's on_error hears of it, and the connection is retired.

{
  my $label = 'the look dies';
  my ($storage, $conn) = warm();
  my $made = made();
  my ($f, $threw);
  {
    no warnings 'redefine';
    local *EV::Pg::socket = sub { die "the socket cannot be asked for\n" };
    $threw = eval { $f = select_named($storage, 'first'); 1 } ? '' : $@;
  }
  is $threw, '', "$label: the call does not throw";
  my ($ok, @r) = $f ? wait_for($f) : (0, 'no Future');
  ok $ok, "$label: the call completes" or diag "it failed: $r[0]";
  is made(), $made + 1, "$label: on a freshly spawned connection";
  like join('', @warnings), qr/pool error: Idle connection liveness check failed: the socket cannot be asked for/,
    "$label: the pool's on_error heard why";
  @warnings = ();
  dead_one_is_gone($label, $storage, $conn, 1);
}

done_testing;
