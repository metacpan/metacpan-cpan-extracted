package DBIO::Storage::PoolBase;
# ABSTRACT: Shared connection pool mechanics for async DBIO drivers

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Storage::Pool';

use Carp 'croak';
use Scalar::Util ();
use Time::HiRes ();
use DBIO::Componentised ();
use DBIO::Exception ();
use DBIO::Util ();
use Devel::GlobalDestruction;
use namespace::clean;



sub new {
  my ($class, %args) = @_;
  croak('conninfo or conninfo_provider required')
    unless $args{conninfo} || $args{conninfo_provider};

  # A size that is false is no size: the default. Any other has to be a
  # positive integer. acquire spawns while the pool counts fewer connections
  # than max_size, so a negative or non-numeric one never spawns: every acquire
  # is queued for a release nobody can make (karr core k270).
  my $size = $args{size} || 5;
  unless (!ref $size && $size =~ /\A[1-9][0-9]*\z/) {
    my $got = ref $size                                ? 'a ' . ref($size) . ' reference'
            : Scalar::Util::looks_like_number($size)   ? $size
            :                                            'a value that is no number';
    DBIO::Exception->throw("Pool size must be a positive integer, got $got");
  }

  my $storage = $args{storage};
  my %limits;
  for my $name (qw( acquire_timeout max_waiters reset_timeout )) {
    my $given = exists $args{$name}                                     ? $args{$name}
              : Scalar::Util::blessed($storage) && $storage->can('async_option')
                                                                        ? $storage->async_option($name)
              :                                                           undef;
    $class->assert_limit_option($name => $given) if defined $given;
    $limits{$name} = $given;
  }

  my $self = bless {
    conninfo          => $args{conninfo},
    conninfo_provider => $args{conninfo_provider},
    max_size          => $size,
    on_error          => $args{on_error} || sub { warn "Pool error: $_[0]\n" },
    _connections      => [],
    _idle             => [],
    _waiters          => [],
    _spawning         => {},
    _leases           => {},
    _lease_seq        => 0,
    _shutdown         => 0,
    _owner_pid        => $$,
    acquire_timeout   => $limits{acquire_timeout} // 30,
    max_waiters       => $limits{max_waiters},
    reset_timeout     => $limits{reset_timeout} // 10,
    _resetting        => {},
  }, $class;

  $self->{future_class} = $args{future_class} if $args{future_class};
  my $fc = $self->future_class;
  # A name that is no class name throws before anything is loaded.
  DBIO::Util::assert_class_name($fc);
  eval { DBIO::Componentised->ensure_class_loaded($fc); 1 }
    or croak "Cannot load future class $fc: $@";

  # Optional back-reference to the owning DBIO::Storage::Async, held
  # weakly (the storage owns the pool, not the other way round). When present,
  # the pool replays the storage's configured on_connect / on_disconnect actions
  # against every freshly-spawned / torn-down connection -- see the connect-action
  # hooks in L</_spawn_connection> and L</shutdown>. A pool used standalone, or an
  # async pool whose owner does not wire it, simply carries no {storage} and skips
  # the hooks entirely.
  if (defined $args{storage}) {
    $self->{storage} = $args{storage};
    Scalar::Util::weaken($self->{storage}) if ref $self->{storage};
  }

  DBIO::Exception->throw(
    'acquire_timeout needs a timer, and this pool has no owning storage to '
  . 'ask for one (storage => $async_storage): give it acquire_timeout 0'
  ) if defined $limits{acquire_timeout} && $limits{acquire_timeout} > 0
    && !$self->_has_timer;

  return $self;
}


sub assert_limit_option {
  my ($class, $name, $value) = @_;

  my $takes = $name eq 'max_waiters'     ? 'a positive integer'
            : $name eq 'acquire_timeout' ? 'a number of seconds, 0 or more (0 turns the timeout off)'
            : $name eq 'reset_timeout'   ? 'a number of seconds, 0 or more (0 turns the timeout off)'
            : $name eq 'txn_timeout'     ? 'a number of seconds above 0'
            : DBIO::Exception->throw("Unknown limit option '$name'");

  my $number = defined $value && !ref $value
    && Scalar::Util::looks_like_number($value)
    && $value == $value && abs($value) != 9**9**9;
  my $valid = $name eq 'max_waiters'     ? (defined $value && !ref $value && $value =~ /\A[1-9][0-9]*\z/)
            : $name eq 'acquire_timeout' ? ($number && $value >= 0)
            : $name eq 'reset_timeout'   ? ($number && $value >= 0)
            :                              ($number && $value > 0);

  DBIO::Exception->throw("Connect option '$name' takes $takes")
    unless $valid;
  return 1;
}


sub _delay {
  my ($self, $seconds) = @_;
  my $storage = $self->{storage};
  DBIO::Exception->throw('This pool has no owning storage to ask for a timer')
    unless Scalar::Util::blessed($storage) && $storage->can('_delay');
  return $storage->_delay($seconds);
}

# True when _delay has a timer to ask. Overridden together with _delay.
sub _has_timer {
  my ($self) = @_;
  my $storage = $self->{storage};
  return Scalar::Util::blessed($storage) && $storage->can('_delay') ? 1 : 0;
}


sub future_class { $_[0]->{future_class} || 'Future' }


sub acquire {
  my ($self) = @_;
  return $self->_shutdown_failure if $self->{_shutdown};
  $self->_verify_pid;

  # What this caller's timeout is counted from, shared by the stages of its
  # wait: the queue, then a connection coming up (karr core k397).
  my $wait = {};

  return $self->_acquire_slot($wait)->then(sub {
    my $conn = shift;
    my ($ready, $error);
    unless (eval { $ready = $self->_connection_ready_future($conn); 1 }) {
      $error = $@;
      return $self->_retire_readiness_failure($conn, $error);
    }

    # The seam is not the pool's code. A pool shut down from inside it closed
    # $conn with the rest: there is nothing to hand out (karr core k277).
    return $self->_shutdown_failure if $self->{_shutdown};

    return $ready->then(
      sub { $self->future_class->done($conn) },
      sub { $self->_retire_readiness_failure($conn, $_[0]) },
    ) if $ready->is_ready;

    return $self->_hand_over_when_ready($conn, $ready, $wait);
  });
}

# A connection still coming up is handed to its caller through a Future of the
# caller's own, never through a ->then off the readiness Future: Future.pm
# carries a cancel down a ->then chain, so a caller that gave up -- a cancel, a
# wait_any timeout -- cancelled the pool's readiness Future, and the connection,
# counted against max_size, was never idle and never handed out; in a pool of
# one, for good (karr core k258). The pool holds the chain off the readiness
# Future until it settles. Done: the connection
# goes to the caller if it still waits, else where release sends one -- to the
# next caller still waiting, or back to idle. Failed: the connection is retired
# and its slot handed on (_retire_unready_connection), and the failure reaches
# the caller if it still waits. The caller's Future is of the class a ->then
# off the readiness Future would have been.
#
# What the chain acts for -- the caller and the connection -- it reaches only
# through $state, which the pool can empty: a chain cannot be taken off the
# readiness Future again, but it can be left with nothing to act for (karr core
# k261, _park_hand_over).
sub _hand_over_when_ready {
  my ($self, $conn, $ready, $wait) = @_;

  my $caller = $ready->new;
  # The connection coming up is part of the caller's wait: the remainder of
  # its acquire_timeout runs on the caller's Future (karr core k397). A timer
  # that cannot be armed is reported; the connection is handed over untimed.
  if (defined(my $timer_error = $self->_arm_acquire_timer($wait ||= {}, $caller))) {
    _report_hand_over_death($self, $timer_error, 'the acquire timeout could not be armed');
  }
  my $answer = $ready->new;    # what the chain's callback returns, either way
  my $state  = { caller => $caller, conn => $conn };
  my $key    = ++$self->{_hand_over_seq};
  my $pool   = $self;
  Scalar::Util::weaken($pool);

  # The hand-over names its connection, weakly: shutdown has to know a
  # connection an acquire still waits on from one that came up (karr core
  # k262), and the pool's connection list is what keeps a connection alive.
  my $handover = $self->{_ready_handovers}{$key} = [ $caller ];
  Scalar::Util::weaken( $handover->[2] = $conn );
  @$handover[ 3, 4 ] = ($state, $ready);
  $handover->[1] = my $chain = $ready->then(
    sub {
      my ($caller, $conn) = delete @$state{qw(caller conn)};
      _forget_hand_over($pool, $key);
      return $answer->done unless defined $caller;    # let go of meanwhile
      eval {
        if    (!$caller->is_ready) { $caller->done($conn) }
        elsif ($pool)              { $pool->_release_unused($conn) }
        1;
      } or _report_hand_over_death($pool, $@);
      return $answer->done;
    },
    sub {
      my ($error) = @_;
      my ($caller, $conn) = delete @$state{qw(caller conn)};
      my $retired = delete $state->{retired};
      _forget_hand_over($pool, $key);
      if (defined $caller) {
        $pool->_retire_unready_connection($conn) if $pool;
        eval { $caller->fail($error) unless $caller->is_ready; 1 }
          or _report_hand_over_death($pool, $@);
      }
      elsif ($retired && $pool) {
        # Retired while it was coming up, and now the connect has failed as
        # well: the slot is offered to the oldest caller still waiting, as
        # after any connect that failed (karr core k260).
        $pool->_spawn_for_next_waiter;
      }
      return $answer->done;
    },
  );

  # The callbacks above forget the hand-over, and with it the only reference
  # the pool has to $chain, while $chain's own callback is running. Future::XS
  # does not hold a Future during its callback itself, so the chain is kept
  # here until it has settled -- after its callback returned.
  if ($chain->can('on_ready')) {
    $self->{_hand_over_chains}{$key} = $chain;
    $chain->on_ready(sub { delete $pool->{_hand_over_chains}{$key} if $pool });
  }
  return $caller;
}

# A plain function, as the chain holds the pool weakly: the hand-over is over,
# whichever table the pool kept it in.
sub _forget_hand_over {
  my ($pool, $key) = @_;
  return unless $pool;
  delete $pool->{_ready_handovers}{$key};
  delete $pool->{_parked_handovers}{$key};
  return;
}

# Let go of a hand-over whose connection left the pool before it came up --
# retired, or dropped as inherited in a forked child (karr core k261). The
# chain stays on the readiness Future, which may still settle: it is left with
# nothing to act for, so that settling hands nobody a connection the pool no
# longer holds, and the connection and the caller's Future are held by nothing
# of the pool's any more. The chain itself, and the readiness Future it was
# made off, are parked until that Future settles: Future.pm warns of a
# sequence Future it lost when a chain is gone before its Future settles, and
# DBIO::Test::Future keeps a readiness Future only from where it is held.
# Returns the caller's Future, for whoever has something to tell it.
sub _park_hand_over {
  my ($self, $key) = @_;
  my $handover = delete $self->{_ready_handovers}{$key} or return;

  my ($caller, $chain, undef, $state, $ready) = @$handover;
  %$state = () if ref $state;
  $self->{_parked_handovers}{$key} = [ $chain, $ready, $state ];
  return $caller;
}

# _retire_connection for a connection an acquire still waits on. That caller
# waited for a connection that was gone, until shutdown (karr core k261): it
# fails here, unless it gave up already. Not during shutdown, which fails
# every caller itself.
sub _let_go_of_hand_overs_for {
  my ($self, $conn) = @_;
  my $handovers = $self->{_ready_handovers} or return;

  my $addr = Scalar::Util::refaddr($conn);
  for my $key (sort { $a <=> $b } keys %$handovers) {
    my $handover = $handovers->{$key} or next;    # gone in a callback meanwhile
    my $named    = $handover->[2];
    next unless defined $named && Scalar::Util::refaddr($named) == $addr;

    my $caller = $self->_park_hand_over($key);
    $self->{_parked_handovers}{$key}[2]{retired} = 1;
    eval {
      $caller->fail('Connection was retired while it was coming up')
        if defined $caller && !$caller->is_ready;
      1;
    } or _report_hand_over_death($self, $@,
      'a caller was told that its connection was retired while it was coming up');
  }
  return;
}

# The hand-over runs under the ->then off the readiness Future, where a death
# becomes the failure of a Future nobody reads. A callback that dies there --
# on the caller's Future, or on that of the waiter release hands the connection
# on to -- used to reach whoever settled the readiness Future; it goes to
# on_error instead of nowhere. An on_error that dies in turn is warned with the
# report it was given, as in _idle_connection_usable. A plain function, not a
# method: the hand-over holds the pool weakly.
#
# The same holds wherever the pool settles a Future that is somebody else's --
# release, _spawn_for_next_waiter, shutdown (karr core k279). A Future runs its
# callbacks as it is settled, so the callback of one caller runs inside the
# pool method another caller called, and its death was thrown at that caller.
# Each such place says in $as what it was doing, for the report.
sub _report_hand_over_death {
  my ($pool, $err, $as) = @_;
  $as //= 'the outcome of a connect was handed over';
  my $report = "A callback died as $as: " . ($err || 'unknown error');
  return if $pool && eval { $pool->{on_error}->($report); 1 };

  chomp(my $died = $pool ? $@ || 'unknown error' : 'the pool is gone');
  chomp $report;
  warn "DBIO pool on_error died ($died) while reporting: $report\n";
  return;
}

sub _shutdown_failure {
  my ($self) = @_;
  return $self->future_class->fail('Connection pool has been shut down');
}

sub _retire_readiness_failure {
  my ($self, $conn, $error) = @_;

  # The reason a connection is retired for is masked like the spawn's error,
  # with what the pool knows of its connect info (karr k400).
  $error = $self->_mask_connect_error($error, $self->{conninfo})
    if defined $self->{conninfo};
  $self->_retire_unready_connection($conn);
  return $self->future_class->fail($error);
}

# A connection that did not become ready is retired the way a checked-out one
# is, through _retire_in_use_connection: its slot is what a queued caller waits
# for. _retire_connection alone leaves the queue alone, and that caller then
# waited for a release nobody was left to make -- in a pool of one, for good
# (karr core k260). The slot goes to the oldest caller still waiting, on a
# fresh spawn or with that spawn's error. A callback that dies as it is handed
# on is reported like any other death in a hand-over.
sub _mask_connect_error {
  my ($self, $error, @conninfo) = @_;
  my @known = map {
    ref $_ eq 'HASH'
      ? ( [ undef, undef, $_->{password} // $_->{Password} ] )
      : ( defined $_ && !ref $_ ? [ $_ ] : () )
  } @conninfo;
  $error = DBIO::Util::mask_connect_secrets($error);
  $error = DBIO::Util::mask_connect_secrets($error, $_) for @known;
  return $error;
}

sub _retire_unready_connection {
  my ($self, $conn) = @_;
  eval { $self->_retire_in_use_connection($conn); 1 }
    or _report_hand_over_death($self, $@);
  return;
}

# Raw pool-slot acquisition: idle reuse / capacity spawn / waiter queue, WITHOUT
# readiness gating. Returns a Future resolving to a connection object (or a
# pending waiter Future that resolves to one on release). acquire() wraps this in
# the _connection_ready_future seam so all three paths are gated identically and
# in exactly one place -- an async subclass overrides the seam, never this or
# acquire(). Kept as a distinct method so a subclass can still reach
# the un-gated slot logic if it ever needs to.
sub _acquire_slot {
  my ($self, $wait) = @_;

  while (@{ $self->{_idle} }) {
    # FIFO: hand out the connection that has been idle longest (the one at
    # the front of the queue). Release pushes onto the tail, so shift takes
    # from the head — this cycles every conn through instead of always
    # reusing the most-recently-released one (LIFO), which caused 1 hot
    # conn and N-1 cold conns under bursty load. One that died while idle
    # is retired and the next is tried; with none left, spawn below.
    my $conn = shift @{ $self->{_idle} };
    my $usable = $self->_idle_connection_usable($conn);

    # The liveness seam and on_error are not the pool's code. A pool shut down
    # from inside either closed $conn with the rest, and nothing is handed out
    # or spawned after it (karr core k277).
    return $self->_shutdown_failure if $self->{_shutdown};
    return $self->future_class->done($conn) if $usable;
  }

  if ($self->_has_room) {
    # Spawning is synchronous, and it replays the owning storage's
    # on_connect_do / on_connect_call against the fresh connection -- a server
    # refusing one of those dies right here. acquire() is contracted to return a
    # Future, and every other failure on this path (query error, connect
    # timeout, txn failure) reaches the caller as a failed one; letting this
    # single case escape as an exception meant the ->on_fail a Future-based API
    # teaches you to write was the one place the error could never arrive, and
    # every *_async call would have needed a defensive eval around it.
    my $conn;
    unless (eval { $conn = $self->_spawn_connection; 1 }) {
      my $error = $@ || 'Connection spawn failed';

      # The spawn held its slot while it ran, and a caller that came in from
      # inside it was queued behind it. The spawn took no slot after all, so
      # that caller gets it -- nobody is left to release one (karr core k277).
      eval { $self->_spawn_for_next_waiter; 1 }
        or _report_hand_over_death($self, $@);
      return $self->future_class->fail($error);
    }

    # No connection and no error: the pool was shut down under the spawn.
    return $self->_shutdown_failure unless defined $conn;
    return $self->future_class->done($conn);
  }

  # A full queue refuses the caller before anything of it is made or held
  # (karr core k397). Waiters settled by somebody else without being withdrawn
  # do not count: they are passed over at release (karr k255).
  my $max = $self->{max_waiters};
  if (defined $max && @{ $self->{_waiters} } >= $max) {
    @{ $self->{_waiters} } = grep { defined $_ && !$_->is_ready } @{ $self->{_waiters} };
    return $self->future_class->fail(
      _exception("pool exhausted: $max callers waiting")
    ) if @{ $self->{_waiters} } >= $max;
  }

  # Queue the caller. Its Future is the transport's to make (_new_waiter) and
  # the pool's to queue and settle; a seam that fails to make one fails the
  # acquire, which never throws, and queues nothing (karr core k256).
  my $waiter;
  unless (eval { $waiter = $self->_new_waiter; 1 }) {
    return $self->future_class->fail($@ || '_new_waiter died');
  }
  my $is_future = Scalar::Util::blessed($waiter)
    && $waiter->can('then') && $waiter->can('is_ready');
  unless ($is_future && !$waiter->is_ready) {
    return $self->future_class->fail(
      (ref($self) || $self) . '->_new_waiter returned '
    . ( !defined $waiter ? 'undef, not a Future'
      : !$is_future      ? 'no Future'
      :                    'a Future that is not pending' )
    );
  }

  # A pool shut down from inside the seam failed everyone queued by then; a
  # caller queued now would wait for good (karr core k277).
  return $self->_shutdown_failure if $self->{_shutdown};

  # The caller's wait is timed from here. A timer that cannot be armed fails
  # the acquire and queues nothing: the caller is never left to wait untimed
  # by a pool that was asked to time it.
  if (defined(my $timer_error = $self->_arm_acquire_timer($wait ||= {}, $waiter))) {
    return $self->future_class->fail($timer_error);
  }

  push @{ $self->{_waiters} }, $waiter;
  push @{ $self->{_collecting_queued} }, $waiter if $self->{_collecting_queued};
  $self->_withdraw_on_cancel($waiter);
  return $waiter;
}

# The failure a pool hands a caller: a DBIO::Exception, as every error of the
# core is.
sub _exception {
  my ($message) = @_;
  local $@;
  eval { DBIO::Exception->throw($message); 1 };
  return $@;
}

# Arm the timer of the caller's acquire_timeout on $target, the Future the
# caller waits on right now -- the queued waiter, or the caller's Future of a
# connection coming up. $wait is shared by the stages of one acquire: the
# deadline is set at the first stage, and a later stage gets what is left of
# it. The timer is stopped when $target is decided, however it is. Returns
# undef, or the error of a timer that could not be made (karr core k397).
sub _arm_acquire_timer {
  my ($self, $wait, $target) = @_;

  my $timeout = $self->{acquire_timeout} or return undef;
  return undef unless $self->_has_timer;

  my $now      = Time::HiRes::time;
  my $deadline = $wait->{deadline} //= $now + $timeout;
  my $left     = $deadline - $now;
  $left = 0 if $left < 0;

  my $timer;
  {
    local $@;
    my $ok = eval { $timer = $self->_delay($left); 1 };
    return $@ || '_delay died' unless $ok;
  }
  return _exception(
    ref($self) . '->_delay returned '
  . ( !defined $timer ? 'undef, not a Future' : 'no Future' )
  ) unless Scalar::Util::blessed($timer) && $timer->can('then') && $timer->can('is_ready');

  my $pool = $self;
  Scalar::Util::weaken($pool);
  my $chain = $timer->then(
    sub {
      $pool->_acquire_timed_out($target, $timeout) if $pool;
      return;
    },
    sub {
      _report_hand_over_death($pool, $_[0], 'the acquire timeout timer failed') if $pool;
      return;
    },
  );
  $chain->retain if $chain->can('retain');

  my $stop = sub { $timer->cancel if !$timer->is_ready && $timer->can('cancel'); return };
  if ($target->can('on_ready')) { $target->on_ready($stop) }
  else                          { $target->then($stop, $stop) }
  return undef;
}

# The caller's acquire_timeout ran out while $target was what it waited on. A
# queued waiter leaves the queue before it fails, so no release hands it a
# connection; the Future of a connection coming up is failed, and the
# connection goes where release sends one when it is up (karr core k397).
sub _acquire_timed_out {
  my ($self, $target, $timeout) = @_;
  return if $target->is_ready;

  $self->_withdraw_waiter($target);
  eval { $target->fail(_exception("no pool connection within $timeout seconds")); 1 }
    or _report_hand_over_death($self, $@,
      'a caller was told that no pool connection came within its acquire_timeout');
  return;
}

# A caller that cancels its Future stops waiting: withdraw its waiter at once,
# so the queue holds only callers still waiting. Only a Future class that can
# be cancelled (Future.pm and its subclasses) is wired; DBIO::Test::Future is
# not. The hook holds the pool and the waiter weakly -- the pool holds the
# waiter, and the waiter holds the hook.
sub _withdraw_on_cancel {
  my ($self, $waiter) = @_;
  return unless $waiter->can('on_cancel');

  my ($pool, $weak_waiter) = ($self, $waiter);
  Scalar::Util::weaken($pool);
  Scalar::Util::weaken($weak_waiter);
  $waiter->on_cancel(sub {
    $pool->_withdraw_waiter($weak_waiter) if $pool && $weak_waiter;
  });
  return;
}


sub _new_waiter { $_[0]->future_class->new }


sub _withdraw_waiter {
  my ($self, $waiter) = @_;
  return 0 unless defined $waiter;

  my $addr    = Scalar::Util::refaddr($waiter);
  my $waiters = $self->{_waiters};
  for my $i (0 .. $#$waiters) {
    next unless defined $waiters->[$i]
      && Scalar::Util::refaddr($waiters->[$i]) == $addr;
    splice @$waiters, $i, 1;
    return 1;
  }
  return 0;
}


sub _collect_queued {
  my ($self, $code) = @_;
  my $outer = $self->{_collecting_queued};
  my ($result, @waiters);
  {
    local $self->{_collecting_queued} = [];
    $result  = $code->();
    @waiters = grep { defined $_ && !$_->is_ready } @{ $self->{_collecting_queued} };
  }

  # A collection inside another one is part of it: what the inner call left
  # waiting is waiting for the outer call too.
  push @$outer, @waiters if $outer;
  return ($result, @waiters);
}


sub _note_queued_for {
  my ($self, $future, @waiters) = @_;
  return unless Scalar::Util::blessed($future) && @waiters;

  my $noted = $self->{_queued_for} ||= {};

  # Entries of Futures that are gone or decided are swept when the table has
  # doubled since the last sweep, so noting stays cheap under a long queue.
  if (keys %$noted > ($self->{_queued_for_swept} // 0) * 2 + 16) {
    for my $addr (keys %$noted) {
      my $entry = $noted->{$addr};
      delete $noted->{$addr} unless defined $entry->[0] && !$entry->[0]->is_ready;
    }
    $self->{_queued_for_swept} = keys %$noted;
  }

  my $entry = [ $future, @waiters ];
  Scalar::Util::weaken($_) for @$entry;
  $noted->{ Scalar::Util::refaddr($future) } = $entry;
  return;
}


sub _queued_waiters_for {
  my ($self, $future) = @_;

  my (%seen, @found);
  my @todo = ($future);
  while (defined(my $f = shift @todo)) {
    next unless Scalar::Util::blessed($f);
    next if $seen{ Scalar::Util::refaddr($f) }++;
    next if $f->can('is_ready') && $f->is_ready;

    if (my $entry = $self->{_queued_for} && $self->{_queued_for}{ Scalar::Util::refaddr($f) }) {
      push @found, grep { defined $_ && !$_->is_ready } @$entry[ 1 .. $#$entry ]
        if defined $entry->[0] && Scalar::Util::refaddr($entry->[0]) == Scalar::Util::refaddr($f);
    }
    if ($f->can('pending_futures')) {
      local $@;
      push @todo, eval { $f->pending_futures };
    }
  }

  my %queued = map { Scalar::Util::refaddr($_) => 1 } grep { defined $_ } @{ $self->{_waiters} };
  return grep { $queued{ Scalar::Util::refaddr($_) } } @found;
}


sub _refuse_queued_for {
  my ($self, $future, $message) = @_;

  my $refused = 0;
  for my $waiter ($self->_queued_waiters_for($future)) {
    next unless $self->_withdraw_waiter($waiter);
    $refused++;
    eval { $waiter->fail(_exception($message)) unless $waiter->is_ready; 1 }
      or _report_hand_over_death($self, $@, 'a queued caller was refused');
  }
  return $refused;
}

# Ask _idle_connection_alive about an idle connection about to be handed out.
# One it does not vouch for is retired, never handed out; a throw counts as
# not vouching, and goes to on_error so a broken check is not silent (it
# would otherwise just turn every borrow into a spawn). An on_error that dies
# may not throw out of acquire, which never throws -- but its death is warned
# with the report it was given, not swallowed, as a dying on_listen_error hook
# is (karr core k252).
sub _idle_connection_usable {
  my ($self, $conn) = @_;

  my $alive;
  unless (eval { $alive = $self->_idle_connection_alive($conn); 1 }) {
    my $err    = $@ || 'unknown error';
    my $report = "Idle connection liveness check failed: $err";
    unless (eval { $self->{on_error}->($report); 1 }) {
      chomp(my $died = $@ || 'unknown error');
      chomp $report;
      warn "DBIO pool on_error died ($died) while reporting: $report\n";
    }
    $alive = 0;
  }
  return 1 if $alive;

  $self->_retire_connection($conn);
  return 0;
}


sub _idle_connection_alive { 1 }


sub _connection_ready_future {
  my ($self, $conn) = @_;

  return $self->future_class->done($conn)
    if Scalar::Util::blessed($conn)
    && $conn->can('is_connected')
    && $conn->is_connected;

  return $self->_connection_ready_lookup($conn)
      || $self->future_class->done($conn);
}


sub _create_ready_connection {
  my ($self, @args) = @_;

  my $ready    = $self->future_class->new;
  my $on_error = $self->{on_error};

  # A connection error the transport raises later comes through on_error and
  # the readiness Future, not through the spawn's die: it is masked here with
  # the connect info this connection was made from (karr k400).
  my @conninfo = @{ $self->{_spawn_conninfo} || [ $self->{conninfo} ] };

  # The transport keeps these callbacks for as long as the connection lives, so
  # they hold the connection and its readiness Future weakly (karr core k235).
  # Held strongly, each closes a cycle -- connection -> on_connect ->
  # connection, and once on_connect has resolved the Future with the
  # connection, connection -> on_error -> Future -> connection -- and no
  # connection built here is ever freed, retired or not. The pool's holds are
  # the strong ones: _connections for the connection, the readiness table for
  # the Future.
  #
  # The pool is held weakly too, for the one thing the callbacks tell it: a
  # callback somebody hung on the readiness Future that dies as it is settled.
  # Thrown from here it reached the transport, and in on_error cut the pool's
  # on_error off from the transport's error (karr core k261, left open by
  # k279). The Future is held for the length of the call: settling it can
  # take the last other hold on it away.
  my ($weak_conn, $weak_ready);
  Scalar::Util::weaken($weak_ready = $ready);
  Scalar::Util::weaken(my $pool = $self);
  my $conn = $self->_new_connection(
    @args,
    on_connect => sub {
      my $settling = $weak_ready;
      eval { $settling->done($weak_conn) if $settling && !$settling->is_ready; 1 }
        or _report_hand_over_death($pool, $@,
          'the readiness of a connection that came up was settled');
    },
    on_error   => sub {
      my ($error, @rest) = @_;
      $error = $pool->_mask_connect_error($error, @conninfo) if $pool;
      my $settling = $weak_ready;
      eval { $settling->fail($error) if $settling && !$settling->is_ready; 1 }
        or _report_hand_over_death($pool, $@,
          'the readiness of a connection that failed to come up was settled');
      $on_error->($error, @rest);
    },
  );
  Scalar::Util::weaken($weak_conn = $conn);
  $self->_register_connection_ready($conn, $ready);
  return $conn;
}


sub _new_connection {
  croak 'Subclass must override _new_connection to use _create_ready_connection';
}


sub _register_connection_ready {
  my ($self, $conn, $ready) = @_;
  $self->{_ready}{ Scalar::Util::refaddr($conn) } = $ready;
  return $ready;
}


sub _connection_ready_lookup {
  my ($self, $conn) = @_;
  return unless $self->{_ready} && defined $conn;
  return $self->{_ready}{ Scalar::Util::refaddr($conn) };
}


sub _clear_connection_ready {
  my ($self, $conn) = @_;
  return unless $self->{_ready} && defined $conn;
  delete $self->{_ready}{ Scalar::Util::refaddr($conn) };
}


sub acquire_txn {
  my $self = shift;
  return $self->acquire;  # same behavior, caller manages lifecycle
}


sub release {
  my ($self, $conn, $lease) = @_;
  return if $self->{_shutdown};
  $self->_verify_pid;
  return unless $self->_holds_connection($conn);

  # Released already and still idle: taken a second time, it would be on the
  # idle list twice and go to two callers at once (karr core k270).
  return if $self->_connection_is_idle($conn);

  # Being reset: handed back already, and the reset decides where it goes.
  return if $self->_connection_is_resetting($conn);

  # A lease that is not the connection's current one belongs to an earlier
  # borrow: the connection went on since, and this is not its holder's release
  # (karr core k275). Silent, like every other release that is not taken.
  if (defined $lease) {
    my $current = $self->{_leases}{ Scalar::Util::refaddr($conn) };
    return unless defined $current && $current eq $lease;
  }

  return $self->_retire_in_use_connection($conn)
    if $self->_connection_is_dead($conn);

  # This borrow is over; whoever has the connection next asks for a lease of
  # its own.
  delete $self->{_leases}{ Scalar::Util::refaddr($conn) };

  # Never handed out, so nothing to reset (_release_unused).
  return $self->_hand_on($conn) if delete $self->{_unused}{ Scalar::Util::refaddr($conn) };

  return $self->_reset_then_hand_on($conn);
}

# A connection that was never handed out -- one that came up for a caller who
# gave up meanwhile -- carries no session state: it goes where release sends a
# connection, without the reset.
sub _release_unused {
  my ($self, $conn) = @_;
  return unless defined $conn;
  my $addr = Scalar::Util::refaddr($conn);
  $self->{_unused}{$addr} = 1;
  my $ok = eval { $self->release($conn); 1 };
  my $error = $@;
  delete $self->{_unused}{$addr};
  die $error unless $ok;
  return;
}

# The connection goes to the oldest queued caller still waiting, or to the idle
# list.
sub _hand_on {
  my ($self, $conn) = @_;

  if (my $waiter = $self->_next_waiter) {
    # The waiter's callbacks run here, and they are another caller's. One that
    # dies does not reach whoever released (karr core k279). The connection is
    # the waiter's either way: its Future was settled before its callbacks ran.
    eval { $waiter->done($conn); 1 }
      or _report_hand_over_death($self, $@,
        'a released connection was handed to a queued caller');
    return;
  }

  push @{ $self->{_idle} }, $conn;
  return;
}

# The session of a released connection is reset before anyone else gets it
# (karr core k398). The owning storage's _reset_pool_connection answers a Future;
# until it is done the connection is `resetting`: it counts against max_size, is
# neither idle nor leased, and a release of it is a no-op. A pool without an
# owning storage that has the seam is not a session pool and hands on as before.
sub _reset_then_hand_on {
  my ($self, $conn) = @_;

  my $storage = $self->{storage};
  return $self->_hand_on($conn)
    unless Scalar::Util::blessed($storage) && $storage->can('_reset_pool_connection');

  my $state = { conn => $conn };
  $self->{_resetting}{ Scalar::Util::refaddr($conn) } = $state;

  my $future;
  my $ok = eval { $future = $storage->_reset_pool_connection($conn); 1 };
  unless ($ok && Scalar::Util::blessed($future) && $future->can('then') && $future->can('is_ready')) {
    $state->{void} = 1;
    delete $self->{_resetting}{ Scalar::Util::refaddr($conn) };
    return $self->_retire_in_use_connection($conn);
  }
  $state->{future} = $future;

  my $pool = $self;
  Scalar::Util::weaken($pool);

  # Bounded: a reset that never answers retires the connection.
  my $timeout = $self->{reset_timeout};
  if ($timeout && $self->_has_timer && !$future->is_ready) {
    my $timer;
    if (eval { $timer = $self->_delay($timeout); 1 }) {
      if (Scalar::Util::blessed($timer) && $timer->can('then') && $timer->can('is_ready')) {
        $state->{timer} = $timer;
        my $chain = $timer->then(sub {
          _reset_ended($pool, $state, 'timeout') if $pool;
          return;
        }, sub { return });
        $chain->retain if $chain->can('retain');
      }
    }
    else {
      _report_hand_over_death($self, $@ || '_delay died',
        'the reset timeout could not be armed');
    }
  }

  my $decided = sub {
    my ($f) = @_;
    my $done = $f->is_failed ? 0
             : ($f->can('is_cancelled') && $f->is_cancelled) ? 0
             : 1;
    _reset_ended($pool, $state, $done ? 'done' : 'failed') if $pool;
    return;
  };
  if ($future->can('on_ready')) { $future->on_ready($decided) }
  else                          { $future->then(sub { $decided->($future) }, sub { $decided->($future) }) }
  return;
}

# The end of a reset: its Future decided, or its timer ran out. A reset that was
# voided meanwhile -- shutdown, a fork, a retirement -- is over already and
# changes nothing.
sub _reset_ended {
  my ($pool, $state, $how) = @_;
  return if $state->{void}++;
  my $conn = $state->{conn};
  delete $pool->{_resetting}{ Scalar::Util::refaddr($conn) };
  _stop_reset($state, $how ne 'timeout', $how eq 'timeout');

  return if $pool->{_shutdown};
  return $pool->_retire_in_use_connection($conn) unless $how eq 'done';
  return $pool->_retire_in_use_connection($conn) if $pool->_connection_is_dead($conn);
  return $pool->_hand_on($conn);
}

# Stop the timer and, when the reset is cut short, the reset itself.
sub _stop_reset {
  my ($state, $stop_timer, $stop_future) = @_;
  my $timer = delete $state->{timer};
  eval { $timer->cancel if $stop_timer && $timer && !$timer->is_ready && $timer->can('cancel'); 1 };
  my $future = delete $state->{future};
  eval { $future->cancel if $stop_future && $future && !$future->is_ready && $future->can('cancel'); 1 };
  return;
}

# Voids the reset of $conn, if one runs: its callbacks change nothing from now
# on. The connection is being retired, shut down or dropped by the caller.
sub _void_reset {
  my ($self, $conn, $cancel) = @_;
  my $state = delete $self->{_resetting}{ Scalar::Util::refaddr($conn) } or return;
  return if $state->{void}++;
  _stop_reset($state, 1, $cancel && !in_global_destruction);
  return;
}

# Every reset still running is voided; the owner's are cancelled, an
# inherited one belongs to the parent and is only forgotten.
sub _drop_resets {
  my ($self, $cancel) = @_;
  my @states = values %{ $self->{_resetting} || {} };
  $self->{_resetting} = {};
  for my $state (@states) {
    next if $state->{void}++;
    _stop_reset($state, $cancel, $cancel && !in_global_destruction);
  }
  return;
}

sub _connection_is_resetting {
  my ($self, $conn) = @_;
  return defined $conn && $self->{_resetting}
    && $self->{_resetting}{ Scalar::Util::refaddr($conn) } ? 1 : 0;
}


sub _lease {
  my ($self, $conn) = @_;
  return if $self->{_shutdown};
  $self->_verify_pid;
  return unless $self->_holds_connection($conn);
  return $self->{_leases}{ Scalar::Util::refaddr($conn) } //= ++$self->{_lease_seq};
}

# Take the oldest queued caller that is still waiting off the queue, or return
# nothing. A waiter that is already ready was given up on -- cancelled (Future.pm
# carries a cancel down the ->then chain to it) or settled from outside -- and
# is dropped on the way: ->done on a cancelled Future.pm does nothing, so a
# connection handed to it would be lost, and on a settled one it dies (karr
# core k255).
sub _next_waiter {
  my ($self) = @_;
  while (@{ $self->{_waiters} }) {
    my $waiter = shift @{ $self->{_waiters} };
    return $waiter if defined $waiter && !$waiter->is_ready;
  }
  return;
}


sub size { scalar @{ $_[0]->{_connections} } }


sub available { scalar @{ $_[0]->{_idle} } }


sub max_size { $_[0]->{max_size} }


sub is_shutdown { return $_[0]->{_shutdown} ? 1 : 0 }


sub shutdown {
  my $self = shift;
  return 1 if $self->{_shutdown};
  $self->_verify_pid;
  $self->{_shutdown} = 1;

  # In global destruction nothing is settled (karr core k254): a waiter freed
  # ahead of the pool is undef here, and failing one whose caller's derived
  # Future was freed first makes Future.pm carp "lost a sequence Future".
  my $settle = !in_global_destruction;

  my @waiters = @{ $self->{_waiters} };
  $self->{_waiters} = [];
  # A callback that dies as its Future is failed -- here, and at every Future
  # failed below -- may not end the shutdown: everyone behind it would stay
  # unsettled and every connection open, in a pool that takes no second
  # shutdown (karr core k279).
  if ($settle) {
    for my $waiter (@waiters) {
      eval {
        $waiter->fail('Connection pool has been shut down')
          unless $waiter->is_ready;
        1;
      } or _report_hand_over_death($self, $@, 'the shutdown failed a queued caller');
    }
  }

  # Fork safety (classic DBI InactiveDestroy): the physical connections belong to
  # the process that opened them. A forked child that inherited the pool must NOT
  # disconnect the parent's live connections, nor settle the parent's queued
  # waiters -- during the child's own teardown (typically global destruction)
  # _verify_pid above has already dropped both unsettled, without any physical
  # close, and made the child the owner of the emptied pool (karr core k234).
  # The child's copies of the sockets are reclaimed by the OS when it
  # exits. _teardown_belongs_here() is false when the owner PID was reclaimed
  # before us during global destruction, which fails safe the same way.
  if ($self->_teardown_belongs_here) {
    my @connections = @{ $self->{_connections} };
    for my $conn (@connections) {
      # Global destruction can reclaim a connection's SV before the pool's own,
      # so a slot may already be undef by the time DESTROY reaches shutdown --
      # skip it rather than run it through refaddr (which warns on undef).
      next unless defined $conn;

      my $ready = $self->_connection_ready_lookup($conn);
      if ($ready && !$ready->is_ready) {
        if ($settle) {
          eval { $ready->fail('Connection pool has been shut down'); 1 }
            or _report_hand_over_death($self, $@,
              'the shutdown failed the readiness of a connection still coming up');
        }
        $self->_retire_connection($conn);
        next;
      }

      # Cold as well: a connection an acquire still waits on, behind a
      # readiness Future the transport's own seam made. The readiness table
      # does not know that Future; the hand-over held for the acquire knows
      # the connection (karr core k262).
      if ($self->_hand_over_pending($conn)) {
        $self->_retire_connection($conn);
        next;
      }

      # Being reset: its session is mid-reset, so no disconnect actions go out
      # beside it. The reset is voided and the connection closed (karr core k398).
      if ($self->_connection_is_resetting($conn)) {
        $self->_retire_connection($conn);
        next;
      }

      my $addr = Scalar::Util::refaddr($conn);
      next unless grep {
        defined($_) && Scalar::Util::refaddr($_) == $addr
      } @{ $self->{_connections} };
      $self->_shutdown_ready_connection($conn);
    }
  }

  # An acquire still waiting for its connection to come up that the loop above
  # did not fail -- its readiness Future is one the transport's own seam made,
  # not one registered for a connection the pool holds -- fails here all the
  # same. The pool held the chain off that readiness Future for the caller and
  # lets go of it now, cancelling it where its class can be (karr core k258).
  my $handovers = $self->{_ready_handovers} || {};
  $self->{_ready_handovers} = {};
  if ($settle) {
    for my $handover (values %$handovers) {
      my ($caller, $chain, undef, $state) = @$handover;

      # A chain that cannot be cancelled stays on its readiness Future, and
      # held the connection for as long as that Future was (karr core k261).
      %$state = () if ref $state;
      eval {
        $caller->fail('Connection pool has been shut down')
          if defined $caller && !$caller->is_ready;
        1;
      } or _report_hand_over_death($self, $@,
        'the shutdown failed a caller waiting for its connection to come up');
      eval { $chain->cancel if defined $chain && $chain->can('cancel'); 1 }
        or _report_hand_over_death($self, $@,
          'the shutdown cancelled the wait for a connection to come up');
    }
  }

  $self->_drop_resets($settle);
  $self->{_connections} = [];
  $self->{_idle}        = [];
  $self->{_waiters}     = [];
  $self->{_ready}       = {};
  $self->{_leases}      = {};
  return 1;
}

# Fork safety: may THIS process physically tear down the pool's connections?
# True only in the process that owns the pool: the one that created it, or a
# forked child that has since used it and so, through _verify_pid, dropped the
# parent's connections and taken the pool over with connections of its own. A
# forked child that inherited the pool object and never used it (a different
# PID) must leave the parent's live connections alone -- closing them here would
# disconnect the owner. Tracked once per pool rather than per connection: every
# connection the pool holds belongs to its one owner, and a single scalar
# survives global-destruction SV reclamation better than a per-connection side
# table would. A pool whose owner PID is already gone (blessed directly in a
# test, or reclaimed ahead of us during global destruction) is treated as NOT
# ours, which fails safe: the worst case is a connection left for the OS to
# reclaim at process exit, never the owner's connection closed from under it.
sub _teardown_belongs_here {
  my ($self) = @_;
  return 0 unless defined $self->{_owner_pid};
  return $self->{_owner_pid} == $$ ? 1 : 0;
}


sub _verify_pid {
  my ($self) = @_;
  my $pid = $self->{_owner_pid};
  return unless defined $pid && $pid != $$;

  # The inherited hand-overs are let go of, not cancelled and not just
  # forgotten (karr core k261): a chain forgotten with its caller still in
  # hand settled the parent's caller here when its readiness Future did, and
  # cancelling one would run the parent's on_cancel callbacks.
  $self->_park_hand_over($_) for keys %{ $self->{_ready_handovers} || {} };

  $self->{_connections} = [];
  $self->{_idle}        = [];
  $self->{_waiters}     = [];
  $self->{_spawning}    = {};
  $self->{_ready}       = {};
  $self->{_leases}      = {};
  $self->{_ready_handovers} = {};
  $self->_drop_resets(0);
  $self->{_owner_pid}   = $$;
  return;
}

# Does the pool hold $conn -- is it one of the connections it counts against
# max_size? A connection it retired, or dropped as inherited, is not.
sub _holds_connection {
  my ($self, $conn) = @_;
  return 0 unless defined $conn;
  my $addr = Scalar::Util::refaddr($conn);
  return scalar grep {
    defined($_) && Scalar::Util::refaddr($_) == $addr
  } @{ $self->{_connections} };
}

# Is an acquire still waiting for $conn to come up -- does the pool hold a
# hand-over for it (_hand_over_when_ready)? An entry may be gone already in
# global destruction, hence the guards.
sub _hand_over_pending {
  my ($self, $conn) = @_;
  my $addr = Scalar::Util::refaddr($conn);
  return scalar grep {
    ref $_ && defined $_->[2] && Scalar::Util::refaddr($_->[2]) == $addr
  } values %{ $self->{_ready_handovers} || {} };
}

# Is $conn on the idle list -- released, and not handed out since?
sub _connection_is_idle {
  my ($self, $conn) = @_;
  my $addr = Scalar::Util::refaddr($conn);
  return scalar grep {
    defined($_) && Scalar::Util::refaddr($_) == $addr
  } @{ $self->{_idle} };
}

sub _shutdown_ready_connection {
  my ($self, $conn) = @_;
  return unless $self->_detach_connection($conn);

  # on_disconnect_do / on_disconnect_call run against a connection that reached
  # readiness, while it is still live and before it is closed. Both steps remain
  # best-effort.
  eval { $self->_dbio_run_pool_disconnect_actions($conn) };
  eval { $self->_shutdown_connection($conn) };
  $self->_clear_connection_ready($conn);
  return;
}


sub set_conninfo_provider {
  my ($self, $provider) = @_;
  croak('set_conninfo_provider requires a coderef')
    unless ref $provider eq 'CODE';
  $self->{conninfo_provider} = $provider;
  delete $self->{conninfo};
  return $self;
}

# Room for one more connection? A spawn in flight counts: it holds its slot
# from before the first code it calls that is not the pool's (karr core k277).
sub _has_room {
  my ($self) = @_;
  return @{ $self->{_connections} } + scalar( keys %{ $self->{_spawning} || {} } )
       < $self->{max_size};
}

# Returns the connection, dies with the error of a spawn that failed -- masked
# of connect secrets, for every transport (karr k305) -- or returns nothing when
# the pool was shut down under it.
sub _spawn_connection {
  my $self = shift;

  # Everything a spawn calls before its connection counts is code that is not
  # the pool's -- the provider (an AccessBroker's answer), the transport's
  # seams -- and may come back into the pool: a client that runs the event
  # loop while it fetches, a transport that reports an error from its
  # constructor. So the slot is taken before any of it runs, and whoever comes
  # in from inside finds it taken. Counted only once it existed, the connection
  # left its slot to an acquire made from inside: two connections in a pool of
  # one (karr core k277). The reservation is this spawn's own entry, so letting
  # go of it after _verify_pid dropped it with the rest in a forked child takes
  # nothing from another spawn.
  my $slot = ++$self->{_spawn_seq};
  $self->{_spawning}{$slot} = 1;

  my ($conn, $conninfo, @conninfo);
  my $made = eval {
    $conninfo = $self->{conninfo_provider}
      ? $self->{conninfo_provider}->()
      : $self->{conninfo};
    @conninfo = $self->_transform_conninfo($conninfo);

    # What an error of this connection, raised later by the transport, is
    # masked with (_create_ready_connection, karr k400).
    local $self->{_spawn_conninfo} = [ $conninfo, @conninfo ];

    # Shut down from inside one of the two: no connection is made.
    $conn = $self->_create_connection(@conninfo) unless $self->{_shutdown};
    1;
  };
  my $error = $@;

  # From here the connection counts, or the spawn took no slot (karr core
  # k260).
  delete $self->{_spawning}{$slot};

  # A client library may quote the connection string it was given in the error
  # it raises, a password in it. The core masks the error here for every
  # transport (karr k305) -- the one place that does, through the one function
  # that knows how. What the pool knows of the connect info goes along: a
  # string conninfo as the DSN slot, a hash with a password as the password
  # slot. A reference (an exception object) goes through as it came.
  die $self->_mask_connect_error($error, $conninfo, @conninfo) unless $made;

  # Shut down from inside _create_connection: the connection was born into a
  # pool that is gone. shutdown never saw it, so it is closed here, like every
  # cold connection -- once, no on_disconnect_* -- and not counted.
  if ($self->{_shutdown}) {
    if (defined $conn) {
      eval { $self->_shutdown_connection($conn) };
      $self->_clear_connection_ready($conn);
    }
    return;
  }

  push @{ $self->{_connections} }, $conn;

  # A freshly spawned physical connection must receive the same
  # session setup (on_connect_do / on_connect_call) the owning sync storage was
  # configured with, before it is ever served to a caller -- otherwise pooled
  # async connections diverge silently from the sync path. Runs exactly once per
  # physical connection (idle reuse goes through acquire, not spawn).
  #
  # The connection is registered above, before its session setup
  # runs. One whose setup was refused is never handed out and never will be, so
  # retire it before rethrowing -- otherwise it keeps counting against max_size
  # and a pool that goes on being refused leaks one slot per attempt, until it
  # is "full" of connections that do not exist and acquire() only ever returns
  # pending waiters.
  unless (eval { $self->_dbio_run_pool_connect_actions($conn); 1 }) {
    my $err = $@;
    $self->_retire_connection($conn);
    die $err;
  }

  # Shut down from inside the connect actions: the connection counted by then,
  # so shutdown closed it with the rest.
  return if $self->{_shutdown};

  return $conn;
}


sub _retire_connection {
  my ($self, $conn) = @_;
  $self->_verify_pid;
  return unless $self->_detach_connection($conn);

  eval { $self->_shutdown_connection($conn) };
  $self->_clear_connection_ready($conn);
  delete $self->{_dead}{ Scalar::Util::refaddr($conn) } if $self->{_dead};
  $self->_let_go_of_hand_overs_for($conn) unless $self->{_shutdown};

  return;
}


sub _retire_in_use_connection {
  my ($self, $conn) = @_;
  return if $self->{_shutdown};

  $self->_retire_connection($conn);
  $self->_spawn_for_next_waiter;
  return;
}

# A free slot goes to the oldest caller still waiting, on a fresh spawn. A
# spawn that dies fails the waiter it was made for and leaves the slot free,
# so the slot goes on to the next one (karr core k260).
sub _spawn_for_next_waiter {
  my ($self) = @_;

  while (!$self->{_shutdown} && $self->_has_room) {
    my $waiter = $self->_next_waiter or return;

    my $fresh;
    # The waiter is another caller's Future, wherever it is settled below: a
    # callback of it that dies goes to on_error, not to whoever is handing the
    # slot on, and the slot goes on to the next waiter all the same (karr core
    # k279).
    unless (eval { $fresh = $self->_spawn_connection; 1 }) {
      my $error = $@ || 'Connection spawn failed';
      eval { $waiter->fail($error) unless $waiter->is_ready; 1 }
        or _report_hand_over_death($self, $@,
          "a spawn's failure was handed to a queued caller");
      next;
    }

    # The spawn ran code that is not the pool's while its waiter was off the
    # queue (karr core k277). A pool shut down from inside failed everyone
    # still queued, and this caller fails the same way. A caller that gave up
    # from inside -- cancelled, or settled by somebody else -- is passed over
    # as release passes it over (karr core k255): its connection goes where
    # release sends one, to the next caller still waiting or to the idle list.
    unless (defined $fresh) {
      eval {
        $waiter->fail('Connection pool has been shut down') unless $waiter->is_ready;
        1;
      } or _report_hand_over_death($self, $@, 'the shutdown failed a queued caller');
      return;
    }
    return $self->_release_unused($fresh) if $waiter->is_ready;

    eval { $waiter->done($fresh); 1 }
      or _report_hand_over_death($self, $@,
        'a new connection was handed to a queued caller');
    return;
  }
  return;
}


sub _mark_connection_dead {
  my ($self, $conn) = @_;
  return if $self->{_shutdown};
  return unless defined $conn && $self->_holds_connection($conn);

  my $addr = Scalar::Util::refaddr($conn);
  if (grep { defined($_) && Scalar::Util::refaddr($_) == $addr } @{ $self->{_idle} }) {
    $self->_retire_connection($conn);
    return;
  }

  Scalar::Util::weaken( $self->{_dead}{$addr} = $conn );
  return;
}

# Was $conn reported dead through _mark_connection_dead? The mark is a weak
# reference to the connection itself, so it is gone once that connection is.
sub _connection_is_dead {
  my ($self, $conn) = @_;
  return 0 unless $self->{_dead} && defined $conn;
  return defined $self->{_dead}{ Scalar::Util::refaddr($conn) } ? 1 : 0;
}

sub _detach_connection {
  my ($self, $conn) = @_;
  return unless defined $conn;

  my $addr = Scalar::Util::refaddr($conn);
  return unless grep {
    defined($_) && Scalar::Util::refaddr($_) == $addr
  } @{ $self->{_connections} };

  delete $self->{_leases}{$addr};
  $self->_void_reset($conn, 1);
  $self->{_connections} = [
    grep { defined($_) && Scalar::Util::refaddr($_) != $addr } @{ $self->{_connections} }
  ];
  $self->{_idle} = [
    grep { defined($_) && Scalar::Util::refaddr($_) != $addr } @{ $self->{_idle} }
  ];
  return 1;
}

# Bridge the central pool-spawn / shutdown path to the owning async
# storage's connect-action seam (DBIO::Storage::Async::_setup_pool_connection /
# _teardown_pool_connection). No-op unless an async storage back-ref is wired
# and exposes the seam, so non-async pools and un-wired pools are unaffected.
sub _dbio_run_pool_connect_actions {
  my ($self, $conn) = @_;
  my $storage = $self->{storage} or return;
  return unless $storage->can('_setup_pool_connection');
  $storage->_setup_pool_connection($conn);
}

sub _dbio_run_pool_disconnect_actions {
  my ($self, $conn) = @_;
  my $storage = $self->{storage} or return;
  return unless $storage->can('_teardown_pool_connection');
  $storage->_teardown_pool_connection($conn);
}


sub _create_connection { croak 'Subclass must override _create_connection' }


sub _shutdown_connection {}


sub _transform_conninfo { $_[1] }

sub DESTROY {
  my $self = shift;
  $self->shutdown;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::PoolBase - Shared connection pool mechanics for async DBIO drivers

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  package DBIO::PostgreSQL::EV::Pool;
  use base 'DBIO::Storage::PoolBase';

  # An event-loop transport: EV::Pg->new returns BEFORE the connect
  # finishes, so build the connection through the readiness wiring and
  # inherit the gate (no _connection_ready_future override needed).
  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection { my $self = shift; require EV::Pg; EV::Pg->new(@_) }

  sub _shutdown_connection { $_[1]->finish }

  sub _transform_conninfo { conninfo_string($_[1]) }

See F<t/storage/pool_base.t> and F<t/storage/pool_ready_wiring.t> for
runnable examples.

=head1 DESCRIPTION

Concrete implementation of the L<DBIO::Storage::Pool> contract hosting
the pool mechanics shared by all async drivers: idle-pool handling,
capacity-bounded connection creation, the waiter queue and shutdown.

Drivers subclass this and supply only the engine seam:

=over 4

=item *

L</_create_connection> -- build one driver connection (required)

=item *

L</_shutdown_connection> -- close one driver connection (optional,
defaults to a no-op)

=item *

L</_transform_conninfo> -- adapt the stored connect info into whatever
shape the driver's connection constructor expects (optional, defaults
to passing it through unchanged)

=item *

L</_new_connection> -- build the raw transport handle from named arguments,
for a driver that takes the readiness wiring from
L</_create_ready_connection> instead of writing its own
L</_create_connection> (optional)

=item *

L</_connection_ready_future> -- gate L</acquire> until a connection is
actually ready for queries (optional: the default honours a readiness Future
registered by L</_create_ready_connection>, and is an immediate C<done> for a
synchronous pool that registers none; override only for a transport whose
readiness is not expressible that way -- see the method for why, and for the
C<dbio-mysql-ev> footgun)

=item *

L</_idle_connection_alive> -- tell whether an idle connection's session is
still there before L</acquire> hands it out, without a round trip (optional,
defaults to not checking)

=item *

L</future_class> -- the Future implementation used for L</acquire>
(optional, defaults to L<Future>)

=item *

L</_new_waiter> -- make the pending Future a queued caller waits on
(optional, defaults to a new L</future_class>)

=back

In the other direction, a driver reports a connection it found dead through
L</_mark_connection_dead>, so the pool retires it instead of handing it out
again, and takes a queued caller that stopped waiting out of the queue through
L</_withdraw_waiter>.

=head1 METHODS

=head2 new

  my $pool = Driver::Pool->new(
      conninfo => 'dbname=myapp',
      size     => 10,
      on_error => sub { warn $_[0] },
  );

Requires C<conninfo> or C<conninfo_provider> (a coderef returning fresh
connect info per connection). The provider is called for every connection the
pool opens, as it opens it; what holds when it comes back into the pool from
there is said under L</acquire>. C<size> caps the pool: a positive integer,
default 5 -- also for a size that is false. Any other size throws: a pool
with a negative or non-numeric size would spawn nothing and queue every
L</acquire> for good.
C<future_class> overrides the Future implementation per instance.

C<storage> (optional) is the owning L<DBIO::Storage::Async>, held weakly. When
given, the pool replays that storage's C<on_connect_do> / C<on_connect_call>
(and the C<on_disconnect_*> counterparts) against each physical connection at
spawn / shutdown.

Two options bound what a caller waits for:

=over 4

=item * C<acquire_timeout> -- seconds a caller may wait in L</acquire> for a
usable connection, default 30; C<0> turns the timeout off. It spans the whole
wait: the time in the queue and the time a new connection takes to come up.

=item * C<max_waiters> -- the number of callers that may be queued at once, a
positive integer. Without it the queue has no limit.

=back

A third option bounds the reset of a released connection (L</release>):
C<reset_timeout> -- seconds the storage's C<_reset_pool_connection> may take,
default 10; C<0> turns the timeout off.

All three are given to the constructor, or else read from the owning C<storage>
(L<DBIO::Storage::Async/async_option>), which takes them as connect options.
A value that is no number of seconds, or no positive integer, throws; the
message names the option and never its value. The timeout is measured by the
owning storage's timer (L<DBIO::Storage::Async/_delay>). A pool with no owning
storage has no timer: it works with the timeout off, and a positive
C<acquire_timeout> given to it throws. The default of 30 seconds applies
wherever a timer exists.

=head2 assert_limit_option

  DBIO::Storage::PoolBase->assert_limit_option(acquire_timeout => $value);

Throws unless C<$value> is a valid setting of the named limit option:
C<acquire_timeout> and C<reset_timeout> a number of seconds, C<0> or more; C<txn_timeout> a number
of seconds above C<0>; C<max_waiters> a positive integer. The message names the
option and what it takes, never the value. It is the one check behind the
constructor and the connect options of L<DBIO::Storage::Async>.

=head2 _delay

  my $f = $pool->_delay($seconds);

The timer behind C<acquire_timeout>: a Future that resolves after C<$seconds>,
from the owning storage's L<DBIO::Storage::Async/_delay>. A pool with no owning
storage throws. Override it to give a pool a timer of its own.

=head2 future_class

The Future implementation backing L</acquire>. Defaults to L<Future>;
override in a subclass or pass C<future_class> to L</new>.

=head2 acquire

Returns a connection wrapped in a Future. Hands out an idle connection if
one is available, otherwise creates a new connection if the pool has
capacity; if all connections are busy and the pool is at max size, queues
the request and returns a pending Future that resolves on the next
L</release>. Once L</shutdown> starts, the same pool instance is terminal:
C<acquire> returns a failed Future with C<Connection pool has been shut down>
and never creates or queues another connection.

Whichever of those three paths supplies the connection, C<acquire> ALWAYS
chains the result through the L</_connection_ready_future> seam before it
resolves. For synchronous pools that seam is a no-op — the
connection is usable the instant it exists — so the returned Future is
ready immediately and behaviour is unchanged. For async transports whose
connection is not usable until a background connect completes, the seam is
the single place where the Future is held pending until the connection is
actually ready; see L</_connection_ready_future>.

C<acquire> B<never throws> -- a spawn that fails, including a connect action
the server refuses, comes back as a B<failed Future> like every other failure
on the async path. Spawning is synchronous and runs outside any Future, so
C<acquire> catches what it throws and hands it back as the failed Future -- the
C<< ->on_fail >> a Future-based API teaches you to write is where every error
arrives. A connection whose connect actions failed is retired
(L</_retire_connection>) rather than left counting against L</max_size>.

A connection that does not become ready -- its L</_connection_ready_future>
fails, or the seam dies -- is retired too, and the caller gets that error. Its
slot goes on the way L</_retire_in_use_connection> hands one on: the oldest
caller queued behind it gets a fresh connection, or that spawn's error, instead
of waiting for a release nobody is left to make.

In a forked child that inherited the pool, C<acquire> never hands out one of
the parent's connections: the first call there drops the inherited state and
the child spawns connections of its own (L</_verify_pid>).

An idle connection is handed out only if L</_idle_connection_alive> vouches
for it; one it does not is retired and the next one tried, then a fresh one
spawned. By default it vouches for every connection.

A queued caller waits on a Future made by L</_new_waiter>, and the Future
C<acquire> returns is chained off it. Cancelling that Future -- with a Future
class that can be cancelled, such as L<Future> -- takes the caller out of the
queue (L</_withdraw_waiter>).

Cancelling it while the connection is still coming up -- the
L</_connection_ready_future> seam still pending -- does not lose the
connection: the caller waits on a Future of its own, not on one chained off
the readiness Future, so the cancel stops there. When the connection comes up
it goes to the next queued caller or to the idle list, and when it fails to it
is retired. A callback on the caller's Future that dies as the
connection is handed over is reported through the pool's C<on_error>.

Letting go of that Future without cancelling it is not giving up, as far as
the pool can tell: the connection comes up, is handed to a Future nobody
reads, and stays checked out -- counted, never idle, never handed out again.
Cancel the Future of an C<acquire> you stop waiting for.

Between reading the pool's books and writing into them, C<acquire> calls code
that is not the pool's: the C<conninfo_provider>, L</_transform_conninfo>,
L</_create_connection> and the owning storage's connect actions when it spawns;
L</_idle_connection_alive> and C<on_error> before it hands out an idle
connection; L</_new_waiter> before it queues the caller;
L</_connection_ready_future> before it hands a connection over. Any of it may
come back into the pool -- an AccessBroker whose client runs the event loop
while it fetches, a transport that reports an error from its constructor -- and
two things hold then:

=over 4

=item * B<A spawn holds its slot from before the first of them.> An C<acquire>
made from inside a spawn finds that slot taken: in a pool of one it is queued
behind the spawn and gets the connection once it is released, and the pool
never counts more connections than L</max_size>. A spawn that fails gives the
slot up, and the oldest caller queued behind it gets it, on a spawn of its own.
A caller that waits for its Future, blocking, from inside the spawn it is
queued behind waits for a spawn that cannot finish first.

=item * B<A shutdown from inside any of them is as final as one before.> The
C<acquire> that was in it fails with C<Connection pool has been shut down>, and
nothing is made, counted, queued or handed out after it. A connection that was
being made is closed, once, without C<on_disconnect_*>, like every connection
that did not come up. A spawn that died fails its C<acquire> with its own error,
shut down or not -- masked by the core: a client library may quote the
connection string it was given, password included, so the error of the
provider, L</_transform_conninfo> and L</_create_connection> goes through
L<DBIO::Util/mask_connect_secrets> before it is passed on, with the pool's
conninfo as what is known (a string as the DSN, a hash's C<password> /
C<Password> as the password). A transport does not have to mask its errors
itself; an exception object is passed on as it is. The error a
transport raises later, through C<on_connect>/C<on_error> of
L</_create_ready_connection>, is masked the same way before it settles the
readiness Future, reaches the pool's C<on_error> or becomes the reason a
connection is retired.

=back

B<A caller waits for a bounded time, and the queue is bounded if you say so>.
C<acquire_timeout> (L</new>, default 30 seconds, C<0> for no timeout) covers
the caller's whole wait for a usable connection: the time in the queue and the
time a new connection takes to come up, counted from the call. When it runs
out the caller's waiter is taken out of the queue (L</_withdraw_waiter>) and
fails with C<no pool connection within N seconds>; a connection that comes up
after that goes to the next queued caller or to the idle list, and nobody
orphaned is handed one. A caller that gets its connection without waiting arms
no timer. C<max_waiters> bounds the queue: with that many callers queued, the
next L</acquire> returns a failed Future at once, C<pool exhausted: N callers
waiting>, and queues nothing. Neither message carries the SQL or the binds of
the refused caller.

=head2 _new_waiter

  sub _new_waiter {
    my ($self) = @_;
    my $waiter = My::Transport::Future->new;   # knows the transport's loop
    return $waiter;
  }

Waiter seam (ADR 0047 addendum 2026-09-28). L</acquire> (and
with it L</acquire_txn>) calls it when it has to queue the caller -- no idle
connection it can hand out, the pool at L</max_size> -- once per queued caller,
and never otherwise. It returns the new, B<pending> Future the caller waits on:
the pool queues it, and L</release> (or L</_retire_in_use_connection>) settles
it with a connection, L</shutdown> fails it.

The default is C<< $self->future_class->new >>. Override it when the queued
caller's Future has to be of a class of the transport's own. Every C<< ->then >>
off a pending Future is made with that Future's own C<new> -- in L<Future> as in
L<DBIO::Test::Future> -- so the waiter's class is the class of everything the
caller builds on the wait: the Future L</acquire> returns, the query chained
off it, the Future a blocking call finally C<< ->get >>s. A plain L<Future>
knows no event loop, and C<get> on it while pending croaks I<is not yet
complete and does not provide -E<gt>await>; a waiter whose class drives the
transport's loop in C<await> lets a blocking call wait for its turn instead.
Only the waiter needs that class: a Future the pool hands out ready never
waits.

What the seam must and must not do:

=over 4

=item * Return a new, pending Future answering C<is_ready>, C<then>, C<done>
and C<fail>. It may carry marks of the transport's own -- a back-reference to
the pool, held B<weakly>, since the pool holds the waiter.

=item * Not queue, register or settle it. The pool queues it after the seam
returns, and wires the cancel hook (L</_withdraw_waiter>) whatever the override
does, so an override never has to call the default.

=item * A seam that dies, or returns anything but a pending Future, fails the
L</acquire> -- with its error, or naming the class and C<_new_waiter> -- and
nothing is queued. L</acquire> never throws. A pool shut down from inside the
seam queues nothing either: the L</acquire> fails with the shutdown.

=back

=head2 _withdraw_waiter

  my $was_queued = $pool->_withdraw_waiter($waiter);
  $waiter->fail("gave up waiting\n") if $was_queued;

Take a queued caller's waiter -- a Future made by L</_new_waiter>, the one
L</acquire> chains the caller's Future off -- out of the queue, so no later
L</release> or L</_retire_in_use_connection> hands it a connection (ADR 0047
addendum 2026-09-28). Returns true if C<$waiter> was queued,
false if it was not: already handed a connection, already withdrawn, dropped by
L</shutdown> or as inherited after a fork, or never the pool's.

It does B<not> settle C<$waiter>: whoever withdraws it does, typically failing
it with the reason it stopped waiting, which reaches the caller through the
chain. A withdrawn waiter left pending waits for good. No connection is lost:
a waiter is handed a connection only as it leaves the queue, so one still in
the queue holds none.

A waiter whose class can be cancelled (L<Future> and its subclasses answer
C<on_cancel>) is withdrawn by the pool itself when it is cancelled -- also
when the caller cancels its own Future, since L<Future> carries a cancel down
the C<< ->then >> chain to the waiter. A waiter settled by somebody else without
being withdrawn is not lost either: L</release> passes over a waiter that is
no longer pending, but it stays queued until then.

=head2 _collect_queued

  my ($future, @waiters) = $pool->_collect_queued(sub { $storage->some_async(...) });

Runs the coderef and returns what it returned followed by the waiters L</acquire>
queued while it ran -- the callers the call itself left waiting for a
connection. Used by L<DBIO::Storage::Async> around the Futures it builds for
the calls on the storage itself, which is how the pool knows which Futures wait
on its own queue (L</_note_queued_for>).

=head2 _note_queued_for

  $pool->_note_queued_for($future, @waiters);

Records that C<$future> waits on the queued C<@waiters> of this pool: a Future
derived from them, as the Futures are that the C<*_async> methods of the
storage return. The pool holds the Future weakly and forgets it once it is
decided. See L</_refuse_queued_for>.

=head2 _queued_waiters_for

  my @waiters = $pool->_queued_waiters_for($future);

The waiters of this pool, still queued, that C<$future> waits on: those noted for
it (L</_note_queued_for>), and for an aggregate such as C<< Future->needs_all >>
those of the Futures it is made of, found through C<pending_futures> where the
Future class has it. Empty for a Future that waits on none of this pool's queue.

=head2 _refuse_queued_for

  my $n = $pool->_refuse_queued_for($future, $message);

Takes every waiter C<$future> waits on (L</_queued_waiters_for>) out of the
queue and fails it with C<$message>, so the statement behind it never runs.
Returns how many it took out. Asked by L<DBIO::Storage::Async> for the Future a
transaction's or a pipeline's coderef returns: a Future that waits on this
pool's own queue cannot settle before the transaction or pipeline that holds its
connection ends (L<DBIO::Storage::Async/_txn_inner_future>).

=head2 _idle_connection_alive

  sub _idle_connection_alive {
    my ($self, $conn) = @_;
    ...   # local state, or a non-blocking read of what the server already sent
    return $alive;
  }

Borrow-time liveness seam (ADR 0047 addendum 2026-09-27).
L</acquire> asks it about an idle connection before handing that connection
out. One it does not vouch for -- false, or a throw, which is also passed to
the pool's C<on_error> (an C<on_error> that dies in turn is warned, never
thrown out of L</acquire>) -- is retired through L</_retire_connection>, and the
next idle connection is tried, then a fresh one spawned (or the caller queued,
at L</max_size>). So a connection whose server session ended while it sat idle
-- a server restart, an idle timeout, an administrator's kill -- does not cost
a caller a failed query first. Without the seam the only report of such a
death is L</_mark_connection_dead> from that failed query, and after a server
restart every idle connection is dead: each is handed out, and fails, once.

The default answers true without looking: no check and no cost, the behaviour
from before the seam. Override it only if the transport can answer B<without a
round trip> -- from local state, or from a non-blocking read of what the server
has already sent (the close or the error a server sends when it ends an idle
session). It runs on every borrow of an idle connection, so it must never block
and never send anything to the server.

It narrows the window; it does not close it. A connection can still die
between the check and its first statement, or without the server saying so (a
network partition); that statement fails, and the transport reports the
connection through L</_mark_connection_dead> as before. It is asked about idle
connections only: a freshly spawned one has just come up, and one handed
straight to a queued caller was in use a moment ago.

=head2 _connection_ready_future

  sub _connection_ready_future { my ($self, $conn) = @_; ... }

Readiness seam, chained by L</acquire> around every connection it hands out
— freshly spawned, reused-idle, or handed to a queued waiter. Returns a
Future that resolves to C<$conn> once the connection is actually ready to
run queries.

For a synchronous pool the default is a safe no-op: with no readiness Future
registered for the connection it answers
C<< $self->future_class->done($conn) >> (the whole default is shown below).

A DBI / synchronous connection is usable the instant its constructor
returns, so an immediately-C<done> Future is correct and L</acquire> stays
ready-at-once. Behaviour for every existing synchronous pool is therefore
unchanged.

B<Async transports MUST gate readiness here> -- by building their connections
through L</_create_ready_connection>, which registers the readiness Future the
default honours, or by overriding this seam when readiness is not
callback-shaped. A backend whose connection is not
usable when its constructor returns — every event-loop transport: EV::Pg,
EV::MariaDB, C<future_io>, ... — is still connecting in the background when
the handle first exists. If such a driver registers no readiness Future and
leaves this seam at its default,
L</acquire> hands out a live-looking but unconnected handle and the very
first bound query on a cold pool dies C<not connected>. This is not a
theoretical edge: C<dbio-mysql-ev> shipped exactly this bug — its
C<_create_connection> wired C<on_connect =E<gt> sub {}>, a pure no-op, with
no readiness tracking, and the symptom was papered over with test-harness
pre-warming rather than fixed in the driver.
The correct gate is a per-connection Future that resolves from the
transport's C<on_connect> callback and fails from its C<on_error> -- what
L</_create_ready_connection> wires.

The default deliberately does NOT auto-detect the async case — it cannot
know whether a given transport's constructor connects synchronously — so
forgetting the gate stays possible by design. What the base does
provide is that the responsibility now lives at ONE documented seam, and
the bookkeeping for the common "resolve a per-connection Future from a
connect callback" pattern is supplied by L</_register_connection_ready>,
L</_connection_ready_lookup> and L</_clear_connection_ready>.

=head3 The default honours a registered readiness Future (ADR 0030 §4)

The default is not an B<unconditional>
immediately-C<done>: it consults the readiness side table first, so a
transport that registers a per-connection Future — which
L</_create_ready_connection> does for you — is gated correctly B<without>
overriding this seam at all. The default is exactly:

  return $self->future_class->done($conn)
    if blessed($conn) && $conn->can('is_connected') && $conn->is_connected;
  return $self->_connection_ready_lookup($conn)
      || $self->future_class->done($conn);

which is the override C<dbio-postgresql-ev> and C<dbio-mysql-ev> each wrote
by hand (identically), lifted here so they can inherit it instead.

Nothing that worked before changes. A synchronous pool registers no
readiness Future, so the lookup misses and the result is the same
immediately-C<done> as before; the C<is_connected> probe is only ever a
B<fast path to that same answer>, never away from it, and it is guarded by
C<can()> because core cannot require an arbitrary transport handle to
implement it. A driver that keeps its own override is unaffected — the
default is not consulted at all.

=head3 What the pool does with a pending readiness Future

A Future the seam returns B<ready> is consumed at once. Onto one it returns
B<pending> the pool chains itself exactly once per L</acquire> -- one
C<< ->then >> -- and it makes the caller's Future with C<new> called on that
instance, so a pending readiness Future has to answer both. The pool holds the
chain; the caller holds only its own Future. For an override that returns a
Future of the transport's own, one never registered through
L</_register_connection_ready>, that means:

=over 4

=item * B<The caller's cancel does not reach it.> The caller's Future is not
chained off the readiness Future, so cancelling an L</acquire> no longer
cancels the connect behind it: the connect runs on, and the connection goes to
the next queued caller or to the idle list. A transport that wants a connect
stopped has to stop it itself.

=item * B<L</shutdown> cancels the chain.> With L<Future>, cancelling a
C<< ->then >> cancels the Future it was chained off, so the readiness Future
itself is cancelled: its C<on_cancel> callbacks run, and a C<done> or C<fail>
that arrives later is ignored. A Future class that cannot be cancelled is only
let go of, and settling it later changes nothing in the shut down pool. In
global destruction nothing is cancelled, as nothing is settled there. A
registered readiness Future of a connection the pool holds is failed by
L</shutdown> instead, before any of this.

=item * B<It has to settle.> Resolve or fail it for every connection it was
returned pending for. Until then the caller waits, and the pool holds the chain
and through it the connection -- until L</shutdown>, or until the connection is
retired, at the latest. After a retirement the pool still keeps the chain
itself, and the Future with it, until the Future settles or the pool is gone.

=back

=head2 _create_ready_connection

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

Builds one connection through L</_new_connection> with its readiness Future
already wired and registered — the whole of the "async pool" boilerplate an
event-loop transport would otherwise hand-roll (ADR 0030 §4).
Takes the named arguments the transport's constructor expects and returns
the connection; L</_connection_ready_future> then finds the Future by
connection, so a driver that builds its connections this way needs B<no>
readiness code of its own.

The wiring owns C<on_connect> and C<on_error>: they are appended after the
caller's arguments, so passing your own is not a way to extend them.
C<on_connect> resolves the Future with the connection; an error B<before>
connect fails it — so a dependent L</acquire> fails instead of hanging —
and after connect the Future is already ready, so errors fall through to the
pool's own C<on_error>, which is called in either case.

The transport keeps both callbacks as long as the connection lives, so they
hold the connection and its readiness Future only B<weakly>; the pool's
connection list and readiness table are what keep them alive. Once the pool
lets go of a connection -- retired, shut down, dropped as inherited after a
fork -- it is freed as soon as no caller holds it. A callback
that fires once its Future is gone settles nothing; C<on_error> still reaches
the pool's C<on_error>.

That holds for a connection retired through L</_retire_connection> while an
L</acquire> still waits for it to come up as well: the pool lets go of that
acquire's hand-over with the connection. What it keeps is the
readiness Future and its own chain on it, until that Future settles or the
pool is gone -- the Future may be settled after all, by a callback of a
connection its transport still holds.

A callback somebody hung on the readiness Future that dies as C<on_connect> or
C<on_error> settles it is reported through the pool's C<on_error> and does not
reach the transport; the error the transport reported is passed on all the
same.

This is the mechanism, not a policy: a pool whose connections are usable the
moment the constructor returns has no reason to call it, and
L</_create_connection> stays a required hook precisely so that choice is
made explicitly per driver rather than guessed by the base.

=head2 _new_connection

  sub _new_connection {
    my ($self, %args) = @_;
    require EV::Pg;
    return EV::Pg->new(%args);
  }

Raw-handle seam used by L</_create_ready_connection>: construct the
transport's connection object from named arguments (the caller's, plus the
C<on_connect> / C<on_error> the readiness wiring supplies) and return it.
Nothing else — do not register or track the connection here.

It exists as a B<named method> rather than a coderef so a test can subclass
the pool and return a fake connection, exercising the readiness wiring with
no event loop and no database. Both EV pools had already isolated exactly
this seam by hand (C<_new_ev_pg>, C<_new_ev_mariadb>) for that reason.

Croaks unless overridden; only L</_create_ready_connection> calls it, so a
pool that builds its connections in its own L</_create_connection> never
needs it.

=head2 _register_connection_ready

  $self->_register_connection_ready($conn, $ready_future);

Bookkeeping primitive for the L</_connection_ready_future> pattern. Stores a
per-connection readiness Future keyed by C<Scalar::Util::refaddr($conn)>, so
an async L</_create_connection> can hand the Future's C<done> / C<fail> to
the transport's C<on_connect> / C<on_error> callbacks and have
L</_connection_ready_future> find it again by connection. Returns the Future.

=head2 _connection_ready_lookup

  my $ready = $self->_connection_ready_lookup($conn);

Return the readiness Future registered for C<$conn> via
L</_register_connection_ready>, or undef if none (e.g. a synchronous pool
that never registered one). An async L</_connection_ready_future> override
typically returns
C<< $self->_connection_ready_lookup($conn) || $self->future_class->done($conn) >>.

=head2 _clear_connection_ready

  $self->_clear_connection_ready($conn);

Drop C<$conn>'s readiness Future from the side table. Called for you by
L</shutdown> for every pooled connection, so an async L</_shutdown_connection>
override never has to clean the table up itself; also exposed for drivers
that retire a single connection outside shutdown. A no-op when no readiness
table exists.

=head2 acquire_txn

Acquire a connection pinned for exclusive transaction use.
Same as L</acquire> but the connection will not be released
back to the idle pool until explicitly released. Being L</acquire>, it
carries the same fork guard.

=head2 release

  $pool->release($conn);
  $pool->release($conn, $lease);

Return a connection to the idle pool. C<$lease> is optional, from L</_lease>;
see below. If waiters are queued, hands the
connection straight to the oldest waiter instead. After L</shutdown>, release
is a no-op: a late callback cannot repopulate the idle list or settle a waiter.

B<The session is reset at the end of every borrow> (ADR 0079).
Release stays the synchronous return of ownership; what follows is the pool's.
With an owning C<storage> that has C<_reset_pool_connection>
(L<DBIO::Storage::Async/_reset_pool_connection>), the connection goes into the
state I<resetting>: the lease ends at once, a second release of it is a no-op,
its slot stays taken and neither the idle list nor a queued waiter gets it. The
pool holds the Future the seam returned. When it is done, the connection goes
to the oldest waiter still waiting, or to the idle list. A seam that fails,
dies, returns no Future, or does not answer within C<reset_timeout> retires the
connection (L</_retire_in_use_connection>): the next borrower gets a fresh one.
L</shutdown>, L</_verify_pid> and a retirement void a reset that is running; its
Future is cancelled (a forked child's inherited one is left alone) and a late
answer changes nothing. L</shutdown> sends no disconnect action beside a reset.
A connection that was never handed out -- one that came up for a caller who gave
up meanwhile -- is not reset. A pool without an owning storage is not a session
pool: it hands the connection on as it is.

A waiter that is no longer waiting -- its Future cancelled, or settled by
somebody else -- is passed over and dropped from the queue: the connection
goes to the oldest waiter still waiting, or back to the idle list when there
is none. Handed to a cancelled Future, the connection would be lost -- neither
borrowed nor idle, in a pool of one for good -- and a settled one refuses it.

The waiter's callbacks run inside C<release>, as its Future is settled, and
they are another caller's. One that dies does not reach whoever released: it
is reported through the pool's C<on_error> -- and warned, if C<on_error> dies
in turn -- as where a connection is handed over as it comes up (L</acquire>).
The connection is the waiter's all the same, and not idle as well. This is
about a callback a Future runs bare, L<Future>'s C<on_done>, C<on_fail> and
C<on_ready>. The death of one made with C<< ->then >> is the failure of the
Future C<< ->then >> returned, in L<Future> as in L<DBIO::Test::Future>, and
the pool is told nothing.

A connection the pool does not hold is not taken back. In a forked child that
is a connection inherited from the parent (L</_verify_pid>): taking it in
would hand the parent's session out in the child after all.

A connection reported dead through L</_mark_connection_dead> is not taken back
either: release retires it (L</_retire_in_use_connection>), and a queued waiter
gets a fresh connection in its place.

A connection that is already idle is not taken a second time: releasing it
again changes nothing, where it would otherwise sit on the idle list twice and
be handed to two callers.

A release that arrives after the connection went on -- to a queued caller, or
to the next L</acquire> -- is told from its current holder's by the lease. The
holder takes it with L</_lease> right after its acquire and passes it as the
second argument; a release whose lease is not the connection's current one is
a silent no-op. A release without a lease cannot be told and is taken as its
current holder's: the callers that can lose the race pass it, and the others
release once.

=head2 _lease

  my $lease = $pool->_lease($conn);
  ...
  $pool->release($conn, $lease);

The lease of the borrow C<$conn> is in right now. Ask for it
right after L</acquire> resolved, and hand it back as the second argument of
L</release>. A connection has one lease for as long as it is borrowed: asking
twice gives the same one, and the release that ends the borrow -- or the
connection's retirement -- ends the lease, so whoever gets the connection next
is given another.

A release that carries a lease is taken only when it is the connection's
current one. One that is not belongs to an earlier borrow -- the connection was
handed to a queued caller, or borrowed again from the idle list, since -- and is
a silent no-op: it changes nothing, throws nothing, warns nothing and does not
reach C<on_error>, as every release the pool does not take. A release without a
lease is taken as the release of the current holder, as it always was.

Returns nothing for a connection the pool does not hold, and after
L</shutdown>. The lease is opaque: compare it for nothing, hand it back only.

=head2 size

Total connections (active + idle). A connection still being spawned is not
one yet, though its slot is taken (L</acquire>).

=head2 available

Number of idle connections.

=head2 max_size

Configured maximum pool size.

=head2 is_shutdown

  if ($pool->is_shutdown) { ... }

True once L</shutdown> has been called on the pool, false before. A pool that
is shut down refuses L</acquire>; a caller that holds a pool across several
steps (L<DBIO::Storage::Async/deploy_async>) asks it between the steps.

=head2 shutdown

Permanently shut down this pool instance. The transition is idempotent and
terminal: queued and readiness-pending acquires fail deterministically with
C<Connection pool has been shut down>, later C<acquire> / C<acquire_txn>
requests return the same failed-Future diagnostic, and late L</release> calls
have no effect.

Connections that reached readiness run the owning storage's disconnect actions
before L</_shutdown_connection>. Cold connections whose readiness is still
pending run no disconnect actions; they are retired and closed exactly once.
Restart belongs to the owning storage lifecycle, which builds a new backend and
pool rather than reviving this instance.

A callback that dies as C<shutdown> fails its Future -- that of a queued
caller, of a caller waiting for its connection to come up, the readiness Future
of such a connection -- or as the wait for a connection is cancelled, is
reported through the pool's C<on_error> (and warned, if C<on_error> dies in
turn) and does not end the shutdown: everyone else is failed and every
connection closed all the same. Thrown out of C<shutdown>, it
left the callers behind it unsettled and the connections open, in a pool that
takes no second shutdown.

In a forked child that inherited the pool, C<shutdown> -- also the one
C<DESTROY> runs when the child exits -- first drops the inherited state through
L</_verify_pid>, like every other entry point: the parent's queued waiters are
neither failed nor resolved, so none of the parent's callbacks runs in the
child, and none of the parent's connections is closed. The
pool is shut down for the child all the same.

In global destruction -- the C<shutdown> C<DESTROY> runs when a process exits
with the pool still alive -- it settles no Future: queued waiters and pending
readiness Futures are dropped, not failed. Perl frees objects in no particular
order there, so a waiter may already be gone, or the Future its caller holds
may be; and no event loop runs any more, so nobody is left to be told. The
connections are closed as always, as far as they are still
there: one that is already gone is skipped. What tells a cold connection from
one that came up -- its readiness Future, the hand-over of the acquire waiting
for it -- may be gone ahead of the pool as well, so there the disconnect
actions can run against a connection still coming up.

=head2 _verify_pid

  $pool->_verify_pid;

Fork safety on the way in, the counterpart of L</shutdown>'s on the way out.
The pool's connections belong to the process that opened them, recorded as the
pool's owner. L</acquire> (and with it L</acquire_txn>), L</release>,
L</shutdown> and L</_retire_connection> call this first. In any other process
-- a forked child that inherited the pool -- it drops everything the pool
inherited and makes the current process the owner, so the child's first
L</acquire> spawns a connection of its own instead of handing out one of the
parent's, whose socket the parent is still reading.

The inherited state is dropped, not torn down, the way
C<DBIO::Storage::DBI::_verify_pid> drops an inherited C<$dbh>: no
L</_shutdown_connection> and no C<on_disconnect_*> actions, because the
connections are the parent's and it is still using them. Queued waiters are
dropped unsettled: they are the parent's callers, and settling one in the child
would run the parent's callback there. The readiness bookkeeping goes with
them, and so do the hand-overs the pool held for acquires still waiting for a
connection to come up (L</acquire>): dropped unsettled, their
callers being the parent's. So does the slot of a spawn that was in flight when
the process forked -- a provider that forks while it answers: the spawn is the
parent's, and holds nothing in the child's pool.

A hand-over's chain cannot be taken off the readiness Future it was made off,
and that Future may still be settled in the child -- one the transport made
itself in L</_connection_ready_future>, say. So the chain is neither cancelled,
which would run the parent's C<on_cancel> callbacks here, nor just forgotten:
the pool leaves it with nothing to act for and keeps it until its readiness
Future settles. Settling that Future in the child then
resolves none of the parent's callers, gives the child's pool no connection,
and L<Future> has no sequence Future to warn of. The child's pool holds
neither the parent's caller nor the inherited connection for it, and a
L</shutdown> in the child neither cancels such a chain nor fails anybody. The
chains go with the child's pool; a readiness Future settled only after that
makes L<Future> warn I<lost a sequence Future>.

Dropping a handle must not end the parent's session from the handle's
destructor either, and that half belongs to the transport: it opens its
connections fork-safe (DBD::Pg, DBD::mysql: C<< AutoInactiveDestroy => 1 >>),
as L<DBIO::Storage::Async/_listen_open> requires for the listen connection.

A pool with no recorded owner is left alone, as the sync storage leaves a
handle with no recorded pid.

=head2 set_conninfo_provider

  $pool->set_conninfo_provider($provider);

Makes every connection this pool opens from now on come from C<$provider>
(a coderef answering the conninfo, see L</new>) and drops the static
C<conninfo> the pool was built with. Connections that are open and leases in
flight are not touched; a spawn already running keeps the conninfo it took.
Called by L<DBIO::Storage::Async/set_access_broker> when a broker is attached
after the pool was built.

=head2 _retire_connection

  $pool->_retire_connection($conn);

Drop C<$conn> from the pool for good: unregister it from the connection list so
it stops counting against L</max_size>, close it through
L</_shutdown_connection> (best-effort, like L</shutdown>), and clear its
readiness bookkeeping. For a connection that must never be handed out -- a
fresh connection whose connect actions were refused, and
available to a driver that has to retire a connection it found dead.

The idle list is also cleared of C<$conn>, so a retired connection cannot be
reissued by a concurrent caller. The waiter queue is deliberately untouched:
a connection this is called for was never handed to a waiter, and waking or
replacing waiters belongs to a separate concern -- for a checked-out
connection, L</_retire_in_use_connection>. The C<on_disconnect_*> actions
are not run either -- the connect actions are what failed, so there is no
session state to tear down and the teardown would only fail in turn.

A connection an L</acquire> still waits on -- retired while it is coming up --
takes that acquire's hand-over with it. The acquire fails with
C<Connection was retired while it was coming up>, unless its caller gave up
already; it waited for a connection that was gone, until L</shutdown>. The pool
holds neither the caller's Future nor the connection any more, which is freed
as soon as no caller holds it. A readiness Future that settles afterwards
hands nobody the connection the pool closed; if it fails, the slot the
connection had is offered to the oldest caller still waiting, as after any
connect that failed. The queue is left alone here as well:
hand the slot on at once with L</_retire_in_use_connection>. During
L</shutdown> none of this applies -- it fails every caller itself.

=head2 _retire_in_use_connection

  $pool->_retire_in_use_connection($conn);

The L</release> counterpart for a checked-out connection that must never be
handed out again, because the caller left it in a state the next borrower
cannot use -- a pipeline whose exit failed, say. The
connection is retired through L</_retire_connection>, and the slot it held goes
where L</release> would have sent the connection: to the oldest queued waiter,
which gets a freshly spawned replacement, or fails with the spawn's error
rather than waiting for a release that may never come. A spawn that failed took
no slot, so the next waiter gets the next attempt, until one is served or none
is left. With no waiter queued
nothing is spawned; the next L</acquire> spawns on demand. After L</shutdown> it
is a no-op, like a late L</release>. A waiter no longer waiting is passed over
as L</release> passes it over, and nothing is spawned for it.

The replacement is spawned for a waiter already taken off the queue, and the
spawn calls code that is not the pool's (L</acquire>). A pool
shut down from inside it fails that waiter with C<Connection pool has been shut
down>, like everyone still queued, and leaves no connection open. A waiter that
gave up while its replacement was spawned -- cancelled, or settled by somebody
else -- is passed over then: the replacement goes where L</release> sends a
connection, to the oldest caller still waiting or to the idle list.

A callback of a waiter that dies as the waiter is settled here -- with the
replacement, with the spawn's error, with the shutdown -- goes to the pool's
C<on_error>, as in L</release>, not to whoever retired the connection. After a
spawn's error the slot goes on to the next waiter all the same.

L</_retire_connection> on its own leaves the waiter queue alone, which is right
for the connections it was written for: none of them was ever handed out. A
checked-out connection's slot is what a waiter is queued for, so retiring it
without handing the slot on would leave that waiter pending until some
unrelated release came along -- in a pool of one, for good. The same holds for
a connection still coming up, which L</acquire> therefore retires through this
method when it does not become ready.

=head2 _mark_connection_dead

  $pool->_mark_connection_dead($conn);

Report that C<$conn> is dead -- its server session is gone, its socket closed,
the protocol out of step -- so the pool never hands it out again. The pool
cannot see this by itself: its only per-connection health signal is the
readiness Future of L</_connection_ready_future>, which resolves once, when
the connection first comes up, and stays resolved after the session behind it
has died. Without a report, L</release> puts a dead connection back on the
idle list and the next L</acquire> hands it to a caller whose query then fails
the same way.

Call it from wherever the death is seen: typically the transport's query path
on a connection-level error (I<server has gone away>, I<connection lost> -- not
a query error the session survives), or a connection error callback such as
EV::Pg's C<on_error> after connect. It may be called any number of times,
before or after the connection is released. What happens depends on where the
connection is:

=over 4

=item * B<checked out> -- nothing yet: whoever holds it still does, and will
hand it back. When it comes back through L</release>, it is retired through
L</_retire_in_use_connection> instead of idled, and a caller queued for its
slot gets a freshly spawned connection. The report does not replace the hand
back: the caller releases as always.

=item * B<idle> -- retired at once through L</_retire_connection>. No one
holds it, and no waiter can be queued while a connection is idle.

=item * B<not held by the pool> -- already retired, never the pool's, or
inherited across a fork -- and B<after L</shutdown>>: nothing happens.

=back

The mark is a weak reference to the connection. It neither keeps a connection
the pool has dropped alive -- one a forked child dropped as inherited, say --
nor outlives it, so it cannot land on a later connection that happens to reuse
the address. Retiring the connection also clears it.

=head2 _create_connection

  sub _create_connection { my ($self, $conninfo) = @_; ... }

Required driver hook: build and return one connection from the
(already transformed) connect info. The pool tracks the connection;
do not push it anywhere yourself.

=head2 _shutdown_connection

  sub _shutdown_connection { my ($self, $conn) = @_; $conn->finish }

Optional driver hook: close one connection during L</shutdown>.
Defaults to a no-op; exceptions are swallowed by the caller.

=head2 _transform_conninfo

  sub _transform_conninfo { my ($self, $conninfo) = @_; ... }

Optional driver hook: adapt stored connect info into the shape the
driver's connection constructor expects (e.g. a libpq conninfo
string). Defaults to returning it unchanged.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
