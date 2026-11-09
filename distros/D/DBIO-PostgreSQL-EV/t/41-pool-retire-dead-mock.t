use strict;
use warnings;
use Test::More;
use Scalar::Util qw( weaken );

# OFFLINE regression for karr k49: a pooled connection that is gone is retired,
# never handed out again; one that only failed a statement is reused.
#
# WHY: the pool cannot see a connection die. Its only per-connection health
# signal is the readiness Future, which resolves once, when the connection
# first comes up, and stays resolved (core k230). So after a backend was
# terminated, the dead EV::Pg handle went back to the pool like any other, was
# handed out again, and every call on it failed with "not connected" -- for
# good (measured live against PostgreSQL 18.6 at k46). The transport has to
# report the death (DBIO::Storage::PoolBase::_mark_connection_dead): from the
# pooled handle's on_error, which EV::Pg calls only when the connection is gone
# and before it fails the statements queued on it; and on the way back from a
# failed statement, when EV::Pg no longer reports the handle connected. No
# error message is matched.
#
# What this file claims, for select_async, notify and copy_in:
#   a. a statement error the session survives -- a server error, a busy
#      connection's refusal -- fails the call and leaves the connection in the
#      pool: the next call runs on the SAME connection, nothing is spawned.
#      (Reporting it dead would throw healthy connections away.)
#   b. a backend lost while the statement is in flight fails the call, the
#      connection is retired, and the next call completes on a FRESH one.
#   c. the same when the handle's on_error was replaced by a caller, so the
#      pool heard nothing: the failed statement's own report retires it.
#   d. a handle closed behind the pool's back (a caller's finish: EV::Pg calls
#      no on_error for it) costs at most the call it was closed under:
#      - closed while it sat idle, it is not handed out again. The pool asks
#        EV::Pg about an idle connection before it hands it out (karr k72),
#        and the next call completes on a FRESH one, first time. Before k72
#        this file claimed the other outcome here: that call was handed the
#        dead handle, failed with "not connected", and the dispatch's own
#        report retired it;
#      - closed by the caller that holds it and handed back while another call
#        is queued, it goes straight from the release to that call -- the pool
#        asks about idle connections only. That call fails with "not
#        connected", the dispatch's own report retires the handle, and the
#        call after it completes on a FRESH connection. This is where the
#        dispatch's report is the only one;
#      - finished with a statement in flight, that statement fails, and its
#        callback still sees the handle connected: finish fails the statement
#        before it closes the handle. Nothing is reported, the handle goes
#        back idle -- and the next call completes on a FRESH one, first time
#        (before k72: one call later).
# And for the pool:
#   e. an idle connection whose backend dies is retired at once, when EV::Pg
#      reports it, and the next call completes on a fresh one, first time.
#   f. a connect error still fails the acquire and is retired by core's
#      readiness wiring: the report is added to that on_error, not put in its
#      place.
#   g. the report creates no cycle (karr core k235): a retired handle is freed,
#      and dropping the storage frees the pool and its handles.
#   h. no callback of this transport dies out of EV::Pg.
#
# Before the fix b-e fail: the dead connection stays in the pool and the next
# call fails with "not connected" -- and g's first claim with them, nothing
# being retired. a, f and the rest of g pass before and after: they are the
# controls that keep the fix from reporting too much, or leaking.
#
# THE ONE SUBSTITUTION is EV::Pg itself (as in t/38): a fake that the real
# pool builds through its real, fork-safe constructor, so the on_error the pool
# installs is the one under test. It follows Pg.xs, 0.02 and 0.07 alike: the
# connect completes on an EV timer; a dispatch croaks "not connected" on a
# handle that is not connected (REQUIRE_CONN), and an armed PQsend* failure
# otherwise; each queued callback completes on an EV timer and is called under
# an eval that only warns; COPY fires its callback twice. A lost connection is
# handle_conn_loss: the handle is torn down, on_error is called, then -- unless
# on_error closed the handle itself -- every queued callback but the one being
# delivered gets (undef, "connection lost"). finish calls no on_error.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @HANDLES;         # every handle made, in order (weak)
  our %NEXT;            # how the next statement to complete ends, once:
                        #   fail => $err   the server answers with an error
                        #   lose => $msg   the server closes the connection
  our %CROAK;           # op => message: the next call of that op croaks, once
  our $LOSE_AT_PUT;     # n: the n-th put_copy_data of the next COPY loses the
                        # connection, once
  our $CONNECT_ERROR;   # the next handle's connect fails with this

  my $PID = 7000;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      finished   => 0,
      queue      => [],
      pid        => ++$PID,
      rows       => 0,
      puts       => 0,
    }, $class;
    push @HANDLES, $self;
    Scalar::Util::weaken($HANDLES[-1]);

    my $connect_error = $CONNECT_ERROR;
    undef $CONNECT_ERROR;
    Scalar::Util::weaken(my $weak = $self);
    _later(sub {
      return unless $weak && !$weak->{finished};
      if (defined $connect_error) {
        $weak->{on_error}->($connect_error) if $weak->{on_error};
        return;
      }
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub on_error {
    my $s = shift;
    $s->{on_error} = $_[0] if @_;
    return $s->{on_error};
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub backend_pid   { $_[0]{pid} }
  sub socket        { -1 }

  # REQUIRE_CONN, then the armed PQsend* failure, whose message ends in
  # PQerrorMessage's newline.
  sub _send {
    my ($self, $op, $entry) = @_;
    Carp::croak('not connected') unless $self->{up};
    my $msg = delete $CROAK{$op};
    die $msg if defined $msg;
    push @{ $self->{queue} }, $entry;
    $self->_arm;
    return;
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    return $self->_send(query_params => { sql => $sql, cb => $cb });
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    my $copy = $sql =~ /^COPY /;
    if ($copy) { $self->{rows} = 0; $self->{puts} = 0 }
    return $self->_send(query => { sql => $sql, cb => $cb, copy => $copy });
  }

  sub put_copy_data {
    my ($self) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{rows}++;
    if (defined $LOSE_AT_PUT && ++$self->{puts} == $LOSE_AT_PUT) {
      undef $LOSE_AT_PUT;
      $self->t_lose("server closed the connection unexpectedly\n");
    }
    return 1;
  }

  sub put_copy_end {
    my ($self, $abort) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{queue}[0]{ended} = defined $abort ? "ERROR:  COPY from stdin failed: $abort" : '';
    $self->_arm;
    return 1;
  }

  # cancel_pending, then cleanup_connection: no on_error.
  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->_cancel_pending('connection finished');
    $self->{up} = 0;
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

  # --- the server's side ---

  # handle_conn_loss: torn down, on_error, then -- unless on_error closed the
  # handle -- every queued callback with "connection lost".
  sub t_lose {
    my ($self, $msg) = @_;
    my $finished = $self->{finished};
    $self->{up} = 0;
    $self->{on_error}->($msg) if $self->{on_error};
    $self->_cancel_pending('connection lost') if $self->{finished} == $finished;
    return;
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
    my $head = $self->{queue}[0] or return;

    if (defined(my $lost = delete $NEXT{lose})) {
      $self->t_lose($lost);
      return;
    }

    my @result;
    if (defined(my $err = delete $NEXT{fail})) {
      @result = (undef, $err);
    }
    elsif ($head->{copy} && !$head->{started}) {
      $head->{started} = 1;
      @result = ('COPY_IN');
    }
    elsif ($head->{copy}) {
      return unless defined $head->{ended};   # the server waits for COPY data
      @result = length $head->{ended} ? (undef, "$head->{ended}\n") : ("$self->{rows}");
    }
    else {
      @result = ([ [ 1, 'one' ] ]);
    }

    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};

    # Advanced only after the callback returned -- unless it was dropped
    # meanwhile, or it is a COPY's first firing, which stays at the head.
    if (@{ $self->{queue} } && $self->{queue}[0] == $head) {
      shift @{ $self->{queue} }
        unless $head->{copy} && defined $result[0] && $result[0] eq 'COPY_IN';
    }
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $two_rows = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  $put->([ 2, 'b' ]);
};

# Each path: how to call it, what it resolves to, the EV::Pg op it sends.
my %PATH = (
  select_async => {
    call   => sub { $_[0]->select_async('thing', [qw( id name )], {}) },
    expect => [ [ 1, 'one' ] ],
    op     => 'query_params',
    busy   => "PQsendQueryParams failed: another command is already in progress\n",
  },
  notify => {
    call   => sub { $_[0]->notify('chan', 'payload') },
    expect => [],
    op     => 'query_params',
    busy   => "PQsendQueryParams failed: another command is already in progress\n",
  },
  copy_in => {
    call   => sub { $_[0]->copy_in('thing', [qw( id name )], $two_rows) },
    expect => [ 2 ],
    op     => 'query',
    busy   => "PQsendQuery failed: another command is already in progress\n",
  },
);

my $SERVER_ERROR = qq{ERROR:  relation "thing" does not exist\n};
my $LOST         = "server closed the connection unexpectedly\n";

# A real storage and pool over the fake EV::Pg, with a pool of one.
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

# Let every timer the fake still has run out, so a callback that would fire
# late has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The pool's one connection.
sub the_conn { $_[0]->pool->{_connections}[0] }

sub made { scalar @EV::Pg::HANDLES }

# Spawn the pool's one connection with a first call, and return its backend
# pid.
sub warm {
  my ($storage, $path) = @_;
  my ($ok, @r) = wait_for($PATH{$path}{call}->($storage));
  die "warming the pool failed: $r[0]" unless $ok;
  return the_conn($storage)->backend_pid;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# a. The call fails, and the next one runs on the same connection.
sub reused {
  my ($label, $storage, $path, $pid, $f, $error) = @_;
  my $made = made();
  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: the call fails";
  like $r[0], $error, "$label: with its own error";
  settle();
  is $storage->pool->size, 1, "$label: the connection stays in the pool";
  is $storage->pool->available, 1, "$label: idle";

  my ($next_ok, @next) = wait_for($PATH{$path}{call}->($storage));
  ok $next_ok, "$label: the next call completes"
    or diag "it failed: $next[0]";
  is_deeply \@next, $PATH{$path}{expect}, "$label: with its result";
  is the_conn($storage)->backend_pid, $pid, "$label: on the same connection";
  is made(), $made, "$label: nothing was spawned";
  no_callback_died($label);
}

# b., c. The call fails, the connection is retired, and the next call gets a
# fresh one.
sub retired {
  my ($label, $storage, $path, $pid, $f, $error) = @_;
  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: the call fails";
  like $r[0], $error, "$label: with the connection's error";
  settle();
  is $storage->pool->size, 0, "$label: the dead connection is retired";
  fresh_next($label, $storage, $path, $pid);
}

sub fresh_next {
  my ($label, $storage, $path, $pid) = @_;
  my $made = made();
  my ($ok, @r) = wait_for($PATH{$path}{call}->($storage));
  ok $ok, "$label: the next call completes"
    or diag "it failed: $r[0]";
  is_deeply \@r, $PATH{$path}{expect}, "$label: with its result";
  is made(), $made + 1, "$label: on a freshly spawned connection";
  ok the_conn($storage) && the_conn($storage)->backend_pid != $pid,
    "$label: not the dead one";
  is $storage->pool->size, 1, "$label: which is the pool's one connection";
  no_callback_died($label);
}

for my $path (sort keys %PATH) {
  my $op = $PATH{$path}{op};

  # --- a. a server error: the session survives -------------------------------
  {
    my $label   = "$path, server error";
    my $storage = pool_of_one();
    my $pid     = warm($storage, $path);
    local $EV::Pg::NEXT{fail} = $SERVER_ERROR;
    reused($label, $storage, $path, $pid, $PATH{$path}{call}->($storage),
      qr/^\Q$SERVER_ERROR\E\z/);
  }

  # --- a. a busy connection refuses the dispatch ------------------------------
  {
    my $label   = "$path, busy refusal";
    my $storage = pool_of_one();
    my $pid     = warm($storage, $path);
    local $EV::Pg::CROAK{$op} = $PATH{$path}{busy};
    reused($label, $storage, $path, $pid, $PATH{$path}{call}->($storage),
      qr/^\Q$PATH{$path}{busy}\E\z/);
  }

  # --- b. the backend is lost while the statement is in flight ----------------
  {
    my $label   = "$path, backend lost in flight";
    my $storage = pool_of_one();
    my $pid     = warm($storage, $path);
    local $EV::Pg::NEXT{lose} = $LOST;
    retired($label, $storage, $path, $pid, $PATH{$path}{call}->($storage),
      qr/^connection lost at /);
  }

  # --- c. the same, but a caller replaced the handle's on_error ---------------
  {
    my $label   = "$path, backend lost, on_error replaced";
    my $storage = pool_of_one();
    my $pid     = warm($storage, $path);
    the_conn($storage)->on_error(undef);
    local $EV::Pg::NEXT{lose} = $LOST;
    retired($label, $storage, $path, $pid, $PATH{$path}{call}->($storage),
      qr/^connection lost at /);
  }

  # --- d. the idle handle is closed behind the pool's back --------------------
  #
  # Not handed out again: the pool asks before it hands out an idle
  # connection (karr k72). The dead handle is closed a second time, by the
  # pool that retires it.
  {
    my $label   = "$path, finished while idle";
    my $storage = pool_of_one();
    my $pid     = warm($storage, $path);
    settle();
    my $dead = the_conn($storage);
    $dead->finish;
    is $storage->pool->available, 1, "$label: (the pool still has the handle idle)";
    fresh_next($label, $storage, $path, $pid);
    is $dead->{finished}, 2, "$label: and the pool closed the dead handle as it retired it";
  }

  # --- d. closed by its holder, and handed straight to a queued call ----------
  #
  # A release hands the connection to the oldest queued caller without asking
  # about it, so the dispatch finds the handle not connected: its croak's
  # report is the only one there is.
  {
    my $label   = "$path, finished by its holder, handed to a queued call";
    my $storage = pool_of_one();
    my $pid     = warm($storage, $path);
    settle();
    my ($held, $pg) = wait_for($storage->pool->acquire);
    die "acquiring the pool's connection failed: $pg" unless $held;
    my $queued = $PATH{$path}{call}->($storage);
    ok !$queued->is_ready, "$label: (the call is queued for the pool's one connection)";
    $pg->finish;
    $storage->pool->release($pg);
    retired($label, $storage, $path, $pid, $queued, qr/^not connected\n\z/);
  }
}

# --- c. for COPY: lost during the data phase, on_error replaced -----------------
#
# The coderef's last put loses the connection; EV::Pg drops the COPY callback
# being delivered without its second firing, and put_copy_end croaks "not
# connected" -- that croak's report is the only one.

{
  my $label   = 'copy_in, lost on the last put, on_error replaced';
  my $storage = pool_of_one();
  my $pid     = warm($storage, 'copy_in');
  the_conn($storage)->on_error(undef);
  local $EV::Pg::LOSE_AT_PUT = 2;
  retired($label, $storage, 'copy_in', $pid, $PATH{copy_in}{call}->($storage),
    qr/^not connected\n\z/);
}

# --- d. for a statement in flight ------------------------------------------------
#
# EV::Pg's finish fails the statements queued on the handle BEFORE it closes
# it, so the statement's callback still sees it connected and nothing is
# reported: the connection goes back, idle. It is not handed out again -- the
# pool asks before it does (karr k72) -- and the next call completes on a
# fresh one. Before k72 that next call failed with "not connected" first.

{
  my $label   = 'select_async, finished in flight';
  my $storage = pool_of_one();
  my $pid     = warm($storage, 'select_async');
  my $f       = $PATH{select_async}{call}->($storage);
  my $dead    = the_conn($storage);
  $dead->finish;
  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: the call fails";
  like $r[0], qr/^connection finished at /, "$label: with EV::Pg's error";
  settle();
  is $storage->pool->available, 1,
    "$label: (its callback saw the handle connected: nothing was reported, and it is idle)";
  fresh_next($label, $storage, 'select_async', $pid);
  is $dead->{finished}, 2, "$label: and the pool closed the dead handle as it retired it";
}

# --- e. an idle connection's backend dies ---------------------------------------

{
  my $label   = 'idle connection lost';
  my $storage = pool_of_one();
  my $pid     = warm($storage, 'select_async');
  @warnings = ();

  the_conn($storage)->t_lose($LOST);
  is $storage->pool->size, 0, "$label: retired at once, when EV::Pg reports it";
  like join('', @warnings), qr/pool error: \Q$LOST\E/,
    "$label: and the pool's on_error still hears of it";
  @warnings = ();
  fresh_next($label, $storage, 'select_async', $pid);
}

# --- f. a connect error ----------------------------------------------------------

{
  my $label   = 'connect error';
  my $storage = pool_of_one();
  local $EV::Pg::CONNECT_ERROR = "could not connect to server\n";
  my ($ok, @r) = wait_for($PATH{select_async}{call}->($storage));
  ok !$ok, "$label: the call fails";
  like $r[0], qr/^could not connect to server/, "$label: with the connect error";
  is $storage->pool->size, 0, "$label: the connection is retired";
  @warnings = ();
  fresh_next($label, $storage, 'select_async', 0);
}

# --- g. no cycle ----------------------------------------------------------------

{
  my $storage = pool_of_one();
  warm($storage, 'select_async');
  weaken(my $dead = the_conn($storage));
  local $EV::Pg::NEXT{lose} = $LOST;
  wait_for($PATH{select_async}{call}->($storage));
  settle();
  ok !defined $dead, 'no cycle: a retired connection is freed';

  warm($storage, 'select_async');
  weaken(my $pool = $storage->pool);
  weaken(my $conn = the_conn($storage));
  undef $storage;
  settle();
  ok !defined $pool, 'no cycle: dropping the storage frees its pool';
  ok !defined $conn, 'no cycle: and its connection';
  @warnings = ();
}

done_testing;
