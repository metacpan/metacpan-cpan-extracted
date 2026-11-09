use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Scalar::Util ();

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k277. acquire decides from the pool's books -- an idle connection, room
# for a new one, or the queue -- and acts on what it decided. In between it
# calls code that is not the pool's: the conninfo provider (an AccessBroker's
# answer), _transform_conninfo, _create_connection and the owning storage's
# connect actions in a spawn; _idle_connection_alive and on_error before an idle
# connection is handed out; _new_waiter before a caller is queued;
# _connection_ready_future before a connection is handed over. Any of it can
# come back into the pool -- a client that runs the event loop while it
# fetches, a transport that reports an error from its constructor -- and the
# books acquire read are then no longer the books it writes into. Before k277
# an acquire made from inside a spawn took the slot of that spawn (two
# connections in a pool of one), and a pool shut down from inside got the
# connection all the same, never to be closed. t/storage/pool_reentrant_callbacks.t
# has the other half: a caller's callback running inside release.
#
# The claims this file pins, each for every seam it can be made at:
#
#   1. a pool shut down from inside a spawn: the acquire fails with the
#      shutdown, a connection made by then is closed, once, and not counted, and
#      none is made after it; a spawn that died as well keeps its own error;
#   2. an acquire made from inside a spawn is queued behind it -- the spawn
#      holds its slot from before the first seam -- and gets the connection once
#      it is released;
#   3. a spawn that dies after such an acquire was queued behind it hands its
#      slot on: that caller gets a spawn of its own and does not wait for a
#      release nobody is left to make;
#   4. a spawn that dies holds no slot (k260): seams that die more often than
#      the pool has slots leave it able to open connections up to its size;
#   5. the same for the replacement _retire_in_use_connection spawns for a
#      queued caller -- and that caller, giving up while its replacement is
#      spawned, does not lose the connection: it goes where release sends one;
#   6. a pool shut down from inside the liveness check of an idle connection,
#      from inside _new_waiter or from inside _connection_ready_future: the
#      acquire fails with the shutdown, hands out no connection the shutdown
#      closed and queues nobody in the shut down pool;
#   7. a spawn in flight when the process forks holds no slot in the child.
#
# Mock only, no event loop and no database, against DBIO::Test::Future and
# Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K277::Conn;
  sub new { my ($class, %args) = @_; bless {%args}, $class }
}

{
  # The owning storage as far as the pool knows it: the connect actions of a
  # fresh connection, the disconnect actions of one that is closed.
  package K277::Storage;
  sub new { bless {}, shift }
  sub _setup_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{set_up} }, $conn->{id};
    $self->{pool}->_seam(actions => $conn);
  }
  sub _teardown_pool_connection { push @{ $_[0]{torn_down} }, $_[1]{id} }
}

{
  # Every seam runs what the test put there: {seam}{$name} once,
  # {seam_always}{$name} each time.
  package K277::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _seam {
    my ($self, $name, @args) = @_;
    my $code = delete $self->{seam}{$name} || $self->{seam_always}{$name}
      or return;
    return $code->(@args);
  }

  sub _transform_conninfo { $_[0]->_seam('transform'); $_[1] }

  # {built} counts a connection once it exists, before the seam: a seam that
  # shuts the pool down there has a connection in hand the pool never counted.
  sub _create_connection {
    my ($self) = @_;
    my $conn = K277::Conn->new(id => ++$self->{n});
    push @{ $self->{built} }, $conn->{id};
    $self->_seam(create => $conn);
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
  sub _new_waiter          { $_[0]->_seam('waiter'); $_[0]->SUPER::_new_waiter }

  # The seam's answer is the liveness check's; with no seam it vouches.
  sub _idle_connection_alive {
    my ($self, $conn) = @_;
    return 1 unless $self->{seam}{alive};
    return $self->_seam(alive => $conn);
  }

  # {ready_for}: every connection the readiness seam was asked about
  sub _connection_ready_future {
    my ($self, $conn) = @_;
    push @{ $self->{ready_for} }, $conn->{id};
    $self->_seam(ready => $conn);
    return $self->SUPER::_connection_ready_future($conn);
  }
}

# A pool of one, unless told otherwise, with a provider and an owning storage.
# {asked} counts how often the provider was asked.
sub new_pool {
  my ($fc, %args) = @_;
  my $storage = K277::Storage->new;
  my $weak;
  my $pool = K277::Pool->new(
    size              => 1,
    future_class      => $fc,
    storage           => $storage,
    conninfo_provider => sub { $weak->{asked}++; $weak->_seam('provider'); 'fake' },
    on_error          => sub { push @{ $weak->{errors} }, $_[0] },
    %args,
  );
  Scalar::Util::weaken($weak = $pool);
  Scalar::Util::weaken($storage->{pool} = $pool);
  $pool->{t_storage} = $storage;   # the pool holds its storage weakly
  $pool->{errors}    = [];
  $pool->{$_}        = [] for qw(built closed);
  return $pool;
}

sub resolved_id {
  my ($f) = @_;
  return $f && $f->is_ready && !$f->is_failed ? $f->get->{id} : undef;
}

sub failure_of {
  my ($f) = @_;
  return '' unless $f && $f->is_ready && $f->is_failed;
  eval { $f->get };
  return "$@";
}

sub queued { scalar @{ $_[0]{_waiters} } }

sub closed { [ sort { $a <=> $b } @{ $_[0]{closed} } ] }

sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  $code->($label);
  is_deeply [@warnings], [], "$label: nothing warned";
  return;
}

my $SHUT = qr/Connection pool has been shut down/;

# The seams of a spawn, in the order it calls them. A connection exists from
# 'create' on, and the pool counts it from 'actions' on.
my @SPAWN_SEAMS = qw(provider transform create actions);
my %MADE        = (create => 1, actions => 1);

my $have_future = eval { require Future; 1 };

for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {

  for my $seam (@SPAWN_SEAMS) {

    # -----------------------------------------------------------------------
    # 1. The pool is shut down from inside the spawn.
    # -----------------------------------------------------------------------
    scenario "$fc, shutdown from inside $seam" => sub {
      my $l = shift;
      my $pool = new_pool($fc, size => 2);
      my $held = $pool->acquire->get;
      $pool->{seam}{$seam} = sub { $pool->shutdown };

      my $f = $pool->acquire;

      like failure_of($f), $SHUT, "$l: the acquire fails with the shutdown";
      is $pool->size, 0, "$l: the shut down pool counts no connection";
      is_deeply $pool->{built}, [ 1, $MADE{$seam} ? 2 : () ],
        $MADE{$seam} ? "$l: (the connection was being made when the pool was shut down)"
                     : "$l: no connection is made after the shutdown";
      is_deeply closed($pool), $pool->{built},
        "$l: every connection the pool made is closed, once";
      is_deeply $pool->{t_storage}{set_up}, [ 1, $seam eq 'actions' ? 2 : () ],
        "$l: no connect action runs against a connection of the shut down pool";
      is_deeply $pool->{ready_for}, [1],
        "$l: and the readiness seam is asked about none";
      is queued($pool), 0, "$l: nobody is queued";
    };

    # A spawn that died keeps its own error, shut down or not: nothing of it
    # is left to close but what the pool counted.
    scenario "$fc, shutdown from inside $seam, which then dies" => sub {
      my $l = shift;
      my $pool = new_pool($fc, size => 2);
      my $held = $pool->acquire->get;
      $pool->{seam}{$seam} = sub { $pool->shutdown; die "$seam died\n" };

      my $f = $pool->acquire;

      like failure_of($f), qr/\Q$seam\E died/, "$l: the acquire fails with its spawn's error";
      is $pool->size, 0, "$l: the shut down pool counts no connection";
      is_deeply closed($pool), [ 1, $seam eq 'actions' ? 2 : () ],
        "$l: every connection the pool counted is closed, once";
      is_deeply $pool->{ready_for}, [1],
        "$l: the readiness seam is asked about no connection of the shut down pool";
      is_deeply $pool->{errors}, [], "$l: nothing was reported";
    };

    # -----------------------------------------------------------------------
    # 2. An acquire made from inside the spawn.
    # -----------------------------------------------------------------------
    scenario "$fc, acquire from inside $seam" => sub {
      my $l = shift;
      my $pool = new_pool($fc);
      my $inner;
      $pool->{seam}{$seam} = sub { $inner = $pool->acquire };

      my $outer = $pool->acquire;

      is resolved_id($outer), 1, "$l: the acquire that spawns gets its connection";
      ok $inner && !$inner->is_ready, "$l: the acquire made from inside is queued behind the spawn";
      is $pool->{n}, 1, "$l: one connection is made for the pool of one";
      is $pool->size, 1, "$l: which counts one";

      $pool->release($outer->get);
      is resolved_id($inner), 1, "$l: the queued caller gets that connection once it is released";
      is queued($pool), 0, "$l: nobody is left queued";
      is_deeply $pool->{errors}, [], "$l: nothing was reported";
    };

    # -----------------------------------------------------------------------
    # 3. ... and the spawn dies after it.
    # -----------------------------------------------------------------------
    scenario "$fc, acquire from inside $seam, which then dies" => sub {
      my $l = shift;
      my $pool = new_pool($fc);
      my $inner;
      $pool->{seam}{$seam} = sub { $inner = $pool->acquire; die "$seam died\n" };

      my $outer = $pool->acquire;

      like failure_of($outer), qr/\Q$seam\E died/, "$l: the acquire fails with its spawn's error";
      is resolved_id($inner), $pool->{n},
        "$l: the caller queued behind that spawn gets the slot, on a spawn of its own";
      is $pool->size, 1, "$l: one connection in the pool of one";
      is queued($pool), 0, "$l: nobody is left queued";
      is_deeply $pool->{errors}, [], "$l: nothing was reported";
    };

    # -----------------------------------------------------------------------
    # 4. A spawn that dies holds no slot.
    # -----------------------------------------------------------------------
    scenario "$fc, $seam dies more often than the pool has slots" => sub {
      my $l = shift;
      my $pool = new_pool($fc, size => 2);
      $pool->{seam_always}{$seam} = sub { die "$seam died\n" };

      my @failed = map { $pool->acquire } 1 .. 3;
      is scalar( grep { failure_of($_) =~ /\Q$seam\E died/ } @failed ), 3,
        "$l: three acquires fail, each with its spawn's error";
      is $pool->size, 0, "$l: the pool counts no connection";

      delete $pool->{seam_always}{$seam};
      my @served = map { $pool->acquire } 1 .. 2;
      is scalar( grep { defined resolved_id($_) } @served ), 2,
        "$l: once the seam answers, the pool opens connections up to its size";
      ok !$pool->acquire->is_ready, "$l: and queues the caller after that";
      is $pool->size, 2, "$l: counting two";
    };

    # -----------------------------------------------------------------------
    # 5. The replacement _retire_in_use_connection spawns for a queued caller.
    # -----------------------------------------------------------------------
    scenario "$fc, replacement spawn, acquire from inside $seam" => sub {
      my $l = shift;
      my $pool = new_pool($fc);
      my $conn   = $pool->acquire->get;
      my $waiter = $pool->acquire;
      my $inner;
      $pool->{seam}{$seam} = sub { $inner = $pool->acquire };

      ok eval { $pool->_retire_in_use_connection($conn); 1 }, "$l: the retirement returns"
        or diag $@;

      is resolved_id($waiter), 2, "$l: the queued caller gets the replacement";
      ok $inner && !$inner->is_ready, "$l: the acquire made from inside is queued behind it";
      is $pool->{n}, 2, "$l: one replacement is made, no connection beside it";
      is $pool->size, 1, "$l: one connection in the pool of one";

      $pool->release($waiter->get);
      is resolved_id($inner), 2, "$l: the queued caller gets it once it is released";
    };

    scenario "$fc, replacement spawn, shutdown from inside $seam" => sub {
      my $l = shift;
      my $pool = new_pool($fc);
      my $conn = $pool->acquire->get;
      my ($first, $second) = map { $pool->acquire } 1 .. 2;
      $pool->{seam}{$seam} = sub { $pool->shutdown };

      ok eval { $pool->_retire_in_use_connection($conn); 1 }, "$l: the retirement returns"
        or diag $@;

      like failure_of($first), $SHUT, "$l: the caller the replacement was for fails with the shutdown";
      like failure_of($second), $SHUT, "$l: and so does the one queued behind it";
      is $pool->size, 0, "$l: the shut down pool counts no connection";
      is_deeply $pool->{built}, [ 1, $MADE{$seam} ? 2 : () ],
        $MADE{$seam} ? "$l: (the replacement was being made when the pool was shut down)"
                     : "$l: no replacement is made after the shutdown";
      is_deeply closed($pool), $pool->{built},
        "$l: every connection the pool made is closed, once";
      is_deeply $pool->{ready_for}, [1],
        "$l: the readiness seam is asked about no connection of the shut down pool";
    };
  }

  # A queued caller whose waiter is settled by somebody else while its
  # replacement is spawned: the pool took the waiter off the queue for that
  # spawn, so nothing else passes it over.
  for my $behind (0, 1) {
    my $with = $behind ? 'another caller queued behind it' : 'nobody queued behind it';

    scenario "$fc, a queued caller gives up while its replacement is spawned, $with" => sub {
      my $l = shift;
      my $pool = new_pool($fc);
      my $conn    = $pool->acquire->get;
      my $gave_up = $pool->acquire;
      my $raw     = $pool->{_waiters}[0];
      my $next    = $behind ? $pool->acquire : undef;
      $pool->{seam}{create} = sub { $raw->fail("gave up waiting\n") };

      ok eval { $pool->_retire_in_use_connection($conn); 1 }, "$l: the retirement returns"
        or diag $@;

      like failure_of($gave_up), qr/gave up waiting/, "$l: the caller has the failure it was given";
      is $pool->size, 1, "$l: the pool counts the replacement";
      if ($behind) {
        is resolved_id($next), 2, "$l: which goes to the caller queued behind";
      }
      else {
        is $pool->available, 1, "$l: which is idle";
        is resolved_id($pool->acquire), 2, "$l: and handed out by the next acquire";
      }
      is $pool->{n}, 2, "$l: one replacement was made";
      is_deeply closed($pool), [1], "$l: only the retired connection was closed";
    };
  }

  scenario "$fc, a queued caller gives up while its replacement is spawned, and the spawn dies" => sub {
    my $l = shift;
    my $pool = new_pool($fc);
    my $conn    = $pool->acquire->get;
    my $gave_up = $pool->acquire;
    my $raw     = $pool->{_waiters}[0];
    my $next    = $pool->acquire;
    $pool->{seam}{create} = sub { $raw->fail("gave up waiting\n"); die "create died\n" };

    ok eval { $pool->_retire_in_use_connection($conn); 1 }, "$l: the retirement returns"
      or diag $@;

    like failure_of($gave_up), qr/gave up waiting/, "$l: the caller keeps the failure it was given";
    is resolved_id($next), 3, "$l: the caller queued behind gets the next spawn";
    is $pool->size, 1, "$l: one connection in the pool of one";
    is queued($pool), 0, "$l: nobody is left queued";
  };

  # -------------------------------------------------------------------------
  # 6. The pool is shut down from inside the other seams of acquire.
  # -------------------------------------------------------------------------
  for my $vouches (1, 0) {
    my $answer = $vouches ? 'vouches for it' : 'does not vouch for it';

    scenario "$fc, the liveness check of an idle connection shuts the pool down and $answer" => sub {
      my $l = shift;
      my $pool = new_pool($fc);
      $pool->release($pool->acquire->get);
      $pool->{seam}{alive} = sub { $pool->shutdown; $vouches };

      my $f = $pool->acquire;

      like failure_of($f), $SHUT,
        "$l: the acquire fails with the shutdown -- it does not hand out the connection it closed";
      is_deeply closed($pool), [1], "$l: (the idle connection, closed by the shutdown, once)";
      is $pool->{n}, 1, "$l: nothing is spawned into the shut down pool";
      is $pool->size, 0, "$l: which counts no connection";
      is $pool->{asked}, 1, "$l: the provider is asked for nothing more";
      is_deeply $pool->{ready_for}, [1],
        "$l: and the readiness seam is not asked about the closed connection";
    };
  }

  scenario "$fc, shutdown from inside _new_waiter" => sub {
    my $l = shift;
    my $pool = new_pool($fc);
    my $conn = $pool->acquire->get;
    $pool->{seam}{waiter} = sub { $pool->shutdown };

    my $f = $pool->acquire;

    like failure_of($f), $SHUT, "$l: the acquire fails with the shutdown";
    is queued($pool), 0, "$l: and is not queued in the shut down pool";
    is_deeply closed($pool), [1], "$l: (whose connection is closed, once)";
  };

  scenario "$fc, shutdown from inside _connection_ready_future, fresh connection" => sub {
    my $l = shift;
    my $pool = new_pool($fc);
    $pool->{seam}{ready} = sub { $pool->shutdown };

    my $f = $pool->acquire;

    like failure_of($f), $SHUT,
      "$l: the acquire fails with the shutdown -- it does not hand out the connection it closed";
    is_deeply closed($pool), [1], "$l: (closed by the shutdown, once)";
    is scalar keys %{ $pool->{_ready_handovers} || {} }, 0, "$l: no hand-over is left behind";
  };

  scenario "$fc, shutdown from inside _connection_ready_future, connection handed on by release" => sub {
    my $l = shift;
    my $pool = new_pool($fc);
    my $conn   = $pool->acquire->get;
    my $waiter = $pool->acquire;
    $pool->{seam}{ready} = sub { $pool->shutdown };

    ok eval { $pool->release($conn); 1 }, "$l: the release returns" or diag $@;

    like failure_of($waiter), $SHUT,
      "$l: the queued caller fails with the shutdown -- it is not handed the connection it closed";
    is_deeply closed($pool), [1], "$l: (closed by the shutdown, once)";
  };
}

# A queued caller that cancels (Future.pm; DBIO::Test::Future has no cancel)
# while its replacement is spawned: ->done on a cancelled Future does nothing,
# and the connection was neither borrowed nor idle.
SKIP: {
  skip 'Future not installed: nothing can be cancelled', 1 unless $have_future;

  # Future.pm only as well: on_done runs a callback bare. One that dies as the
  # slot of a failed spawn is handed on may not throw out of acquire.
  scenario "Future, the callback of the caller a failed spawn's slot goes to dies" => sub {
    my $l = shift;
    my $pool = new_pool('Future');
    my $inner;
    $pool->{seam}{provider} = sub {
      $inner = $pool->acquire;
      $inner->on_done(sub { die "caller callback died\n" });
      die "provider died\n";
    };

    my $outer = eval { $pool->acquire };

    is $@, '', "$l: acquire does not throw";
    like failure_of($outer), qr/provider died/, "$l: it fails with its spawn's error";
    is resolved_id($inner), 1, "$l: the caller queued behind it has its connection all the same";
    is scalar( grep { /caller callback died/ } @{ $pool->{errors} } ), 1,
      "$l: and on_error is told of its callback, once";
  };

  for my $behind (0, 1) {
    my $with = $behind ? 'another caller queued behind it' : 'nobody queued behind it';

    scenario "Future, a queued caller cancels while its replacement is spawned, $with" => sub {
      my $l = shift;
      my $pool = new_pool('Future');
      my $conn    = $pool->acquire->get;
      my $gave_up = $pool->acquire;
      my $next    = $behind ? $pool->acquire : undef;
      $pool->{seam}{create} = sub { $gave_up->cancel };

      ok eval { $pool->_retire_in_use_connection($conn); 1 }, "$l: the retirement returns"
        or diag $@;

      is $pool->size, 1, "$l: the pool counts the replacement";
      if ($behind) {
        is resolved_id($next), 2, "$l: which goes to the caller queued behind";
      }
      else {
        is $pool->available, 1, "$l: which is idle, not lost";
        is resolved_id($pool->acquire), 2, "$l: and handed out by the next acquire";
      }
      is queued($pool), 0, "$l: nobody is left queued";
    };
  }
}

# ---------------------------------------------------------------------------
# 7. A fork while a spawn is in flight -- a broker that forks while it
#    answers. The child inherits the pool with the parent's spawn standing in
#    it; that spawn is the parent's, and holds no slot of the child's pool.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'fork not available on this platform', 7 unless $Config{d_fork};

  my $pool = new_pool('DBIO::Test::Future');
  my %seen;

  # The child never touches the TAP stream. It reports over a pipe, one
  # key=value per line, and leaves through POSIX::_exit: no END block, no
  # destructor of the parent's objects runs there.
  $pool->{seam}{provider} = sub {
    pipe my $r, my $w or die "pipe: $!";
    my $pid = fork;
    defined $pid or die "fork failed: $!";
    unless ($pid) {
      close $r;
      my %child;
      $child{error} = "$@" unless eval {
        my $f = $pool->acquire;
        $child{id}     = resolved_id($f) // '';
        $child{size}   = $pool->size;
        $child{queued} = queued($pool);
        1;
      };
      for my $key (sort keys %child) {
        (my $value = $child{$key} // '') =~ s/\n/ /g;
        print {$w} "$key=$value\n";
      }
      close $w;
      POSIX::_exit(0);
    }
    close $w;
    %seen = map { chomp; split /=/, $_, 2 } <$r>;
    close $r;
    waitpid $pid, 0;
    $seen{exit} = $?;
  };

  my $outer = $pool->acquire;

  is $seen{exit}, 0, 'child: exits cleanly';
  is $seen{error}, undef, 'child: nothing died';
  is $seen{id}, 1, "child: its acquire gets a connection of its own -- the parent's spawn holds no slot there";
  is $seen{size}, 1, 'child: its pool of one counts that connection';
  is $seen{queued}, 0, 'child: and queues nobody';

  is resolved_id($outer), 1, 'parent: its spawn goes on to its connection';
  is $pool->size, 1, 'parent: its pool of one counts that connection';
}

is_deeply \@warnings, [], 'nothing warned outside a scenario either';

done_testing;
