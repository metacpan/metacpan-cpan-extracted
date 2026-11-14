use strict;
use warnings;
use Test::More;
use Scalar::Util ();

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k261: what the hand-over register of k258 left open. acquire hands a
# connection still coming up to its caller through a Future of the caller's
# own, and the pool holds the chain off the readiness Future in
# {_ready_handovers} until that Future settles. A connection that left the pool
# some other way -- retired while it was coming up, dropped as inherited in a
# forked child -- left its hand-over standing: it held the connection, the
# caller and the chain, and a chain that fired later acted for a pool the
# connection was no longer part of. The claims this file pins:
#
#   1. A connection retired through _retire_connection WHILE it is coming up:
#      the caller waiting for it fails then and there, with the retirement. The
#      pool lets go of the hand-over, of the caller's Future and of the
#      connection, which is freed as soon as no caller holds it (k235). A
#      readiness Future that settles afterwards hands nobody the connection the
#      pool closed, and nothing warns -- whoever made that Future, the pool or
#      the transport. _retire_connection leaves the queue alone, as it always
#      did; a connect that fails after the retirement still offers the free slot
#      to the oldest queued caller (k260), and _retire_in_use_connection hands
#      it on at once.
#   2. A forked child drops the hand-overs it inherited (_verify_pid) for good:
#      a readiness Future settled in the child resolves none of the parent's
#      callers and warns of nothing, the child's pool holds neither the parent's
#      caller nor the inherited connection, and nothing of the parent's is
#      cancelled -- not by _verify_pid and not by a shutdown in the child.
#   3. shutdown lets go of the connection of a hand-over also where it cannot
#      cancel the chain it held (DBIO::Test::Future).
#   4. A callback that dies as the transport's connect or error callback settles
#      the registered readiness Future does not reach the transport; it goes to
#      on_error, and the transport's error is still reported (left open by
#      k279).
#
# And one thing that stays as it is, by decision (ADR 0047, addendum
# 2026-10-08 (III)):
#
#   5. A caller that lets go of its Future without cancelling it. The pool
#      cannot tell: the connection comes up, is handed to a Future nobody
#      reads, and is lost -- counted, never idle, never handed out. Holding the
#      caller's Future weakly would tell with Future.pm, and would free the
#      Future of a DBIO::Test::Future caller at once, whose chain is held from
#      its head only. Cancel the Future, as with release: once.
#
# (k261's last point, shutdown running disconnect actions against a connection
# still coming up, is karr k262: t/storage/pool_shutdown_coming_up.t.)
#
# Mock only: fake handles whose connect is fired by hand, no event loop, no
# database, a fork stood in for by the owner pid. DBIO::Test::Future and
# Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K261::Conn;
  our %Destroyed;
  our $Next = 0;

  sub new {
    my ($class, %args) = @_;
    return bless { id => ++$Next, args => \%args }, $class;
  }
  sub fire_connect { $_[0]{args}{on_connect}->() }
  sub fire_error   { $_[0]{args}{on_error}->($_[1]) }
  sub DESTROY      { $Destroyed{ $_[0]{id} }++ }
}

{
  # Readiness registered with the pool, as the EV drivers build theirs. The
  # test's own handle on a connection is weak.
  package K261::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my $self = shift;
    my $conn = K261::Conn->new(@_);
    push @{ $self->{ids} }, $conn->{id};
    Scalar::Util::weaken( $self->{built}{ $conn->{id} } = $conn );
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Readiness the transport makes and keeps itself (the shape of dbio-async's
  # poll): the pool never registers it. The test holds it, as a transport does.
  package K261::OwnReadyPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $conn = K261::Conn->new;
    push @{ $self->{ids} }, $conn->{id};
    $self->{ready}{ $conn->{id} } = $self->future_class->new;
    Scalar::Util::weaken( $self->{built}{ $conn->{id} } = $conn );
    return $conn;
  }

  sub _connection_ready_future { $_[0]{ready}{ $_[1]{id} } }
  sub _shutdown_connection     { push @{ $_[0]{closed} }, $_[1]{id} }
}

sub new_pool {
  my ($class, $fc, %args) = @_;
  my $errors = [];
  my $pool = $class->new(
    conninfo     => 'fake',
    size         => 1,
    future_class => $fc,
    on_error     => sub { push @$errors, $_[0] },
    %args,
  );
  $pool->{errors} = $errors;
  return $pool;
}

sub destroyed { $K261::Conn::Destroyed{ $_[0] } // 0 }
sub handovers { scalar keys %{ $_[0]{_ready_handovers} || {} } }
sub queued    { scalar @{ $_[0]{_waiters} } }

# What the pool still holds of a hand-over it let go of: the chain off the
# readiness Future, until that Future settles.
sub parked { scalar keys %{ $_[0]{_parked_handovers} || {} } }

# The Future the pool made for the caller of its one pending hand-over, held
# weakly: the pool's holds on it are what the test is about.
sub weak_caller {
  my ($pool) = @_;
  my ($handover) = values %{ $pool->{_ready_handovers} };
  Scalar::Util::weaken(my $caller = $handover->[0]);
  return \$caller;
}

sub resolved {
  my ($f) = @_;
  return 0 unless $f->is_ready && !$f->is_failed;
  return 0 if $f->can('is_cancelled') && $f->is_cancelled;
  return 1;
}

sub failure_of {
  my ($f) = @_;
  return '' unless $f->is_ready && $f->is_failed;
  eval { $f->get };
  return "$@";
}

my $SHUT    = qr/Connection pool has been shut down/;
my $RETIRED = qr/Connection was retired while it was coming up/;

my $have_future = eval { require Future; 1 };

for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {

  # -------------------------------------------------------------------------
  # 1. Retired while it is coming up.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, retired while coming up";
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];
    ok !$f->is_ready, "$l: the acquire waits for its connection to come up";
    is handovers($pool), 1, "$l: the pool holds its hand-over";
    my $caller = weak_caller($pool);

    $pool->_retire_connection($pool->{built}{$id});
    is $pool->size, 0, "$l: the retired connection keeps no slot";
    is_deeply $pool->{closed}, [$id], "$l: and is closed";

    like failure_of($f), $RETIRED,
      "$l: the caller fails with the retirement -- it does not wait for a connection that is gone";
    is handovers($pool), 0, "$l: the pool lets go of the hand-over";
    is destroyed($id), 1, "$l: and the connection is freed, no caller holding it";
    undef $f;
    ok !defined $$caller, "$l: nor does the pool keep the caller's Future";

    $pool->shutdown;
    is_deeply $pool->{closed}, [$id], "$l: closed once, not again by the shutdown";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # The slot is free, so the pool goes on.
  {
    my $l = "$fc, retired while coming up, the next acquire";
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];

    $pool->_retire_connection($pool->{built}{$id});
    my $next = $pool->acquire;
    is $pool->{ids}[-1], $id + 1, "$l: spawns a new connection";
    $pool->{built}{ $id + 1 }->fire_connect;
    is resolved($next) && $next->get->{id}, $id + 1, "$l: and is served by it";
    like failure_of($f), $RETIRED, "$l: the first caller has failed with the retirement, and stays so";

    $pool->shutdown;
    like failure_of($f), $RETIRED, "$l: a shutdown changes nothing about it";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # The readiness Future settles after the retirement: the pool's own, settled
  # by the handle's callbacks, and one the transport made and keeps itself.
  for my $class (qw(K261::Pool K261::OwnReadyPool)) {
    for my $late (qw(connect error)) {
      my $l = "$fc, $class, retired while coming up, then a late $late";
      @warnings = ();
      my $pool = new_pool($class, $fc);
      my $f    = $pool->acquire;
      my $id   = $pool->{ids}[-1];
      my $conn = $pool->{built}{$id};    # held by the test, as the transport holds it

      $pool->_retire_connection($conn);
      is parked($pool), 1, "$l: the pool keeps the wait for the readiness Future";

      ok eval {
        if ($class eq 'K261::Pool') {
          $late eq 'connect' ? $conn->fire_connect : $conn->fire_error("could not connect\n");
        }
        else {
          my $ready = $pool->{ready}{$id};
          $late eq 'connect' ? $ready->done($conn) : $ready->fail("could not connect\n");
        }
        1;
      }, "$l: it does not die" or diag $@;

      like failure_of($f), $RETIRED,
        "$l: the caller has failed with the retirement -- it is not handed the connection the pool closed";
      is $pool->size + $pool->available, 0, "$l: the pool does not take the connection back";
      is_deeply $pool->{closed}, [$id], "$l: nor close it again";
      is $pool->{ids}[-1], $id, "$l: and spawns nothing, nobody being queued";
      is handovers($pool) + parked($pool), 0, "$l: the pool holds nothing of the hand-over any more";
      is_deeply $pool->{errors},
        [ $class eq 'K261::Pool' && $late eq 'error' ? "could not connect\n" : () ],
        "$l: on_error is told what the transport told it, and nothing else";
      is_deeply [@warnings], [], "$l: nothing warned";
      $pool->shutdown;
      is_deeply [@warnings], [], "$l: nor at shutdown";
    }
  }

  # The connect fails after the retirement, with a second caller queued. A
  # readiness failure hands the slot on (k260), and the failure still arrives.
  {
    my $l = "$fc, retired while coming up, then the connect fails, a caller queued";
    @warnings = ();
    my $pool   = new_pool('K261::Pool', $fc);
    my $first  = $pool->acquire;
    my $id     = $pool->{ids}[-1];
    my $conn   = $pool->{built}{$id};
    my $second = $pool->acquire;
    is queued($pool), 1, "$l: the second caller is queued for the pool of one";

    $pool->_retire_connection($conn);
    is queued($pool), 1,
      "$l: _retire_connection leaves the queue alone, as documented -- the slot is free and a caller waits";
    like failure_of($first), $RETIRED, "$l: the first caller fails with the retirement";

    ok eval { $conn->fire_error("could not connect\n"); 1 }, "$l: the late error does not die"
      or diag $@;
    is_deeply $pool->{errors}, ["could not connect\n"], "$l: on_error gets the connect error";
    like failure_of($first), $RETIRED, "$l: which changes nothing for the first caller";

    is $pool->{ids}[-1], $id + 1, "$l: the queued caller's slot gets a fresh spawn (the hand-on)";
    my $fresh = $pool->{built}{ $id + 1 };
    $fresh->fire_connect if $fresh;
    is resolved($second) && $second->get->{id}, $id + 1, "$l: which serves it";
    is_deeply $pool->{closed}, [$id], "$l: the retired connection is closed once";
    $pool->shutdown;
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # Retired through _retire_in_use_connection: the slot is handed on at once.
  {
    my $l = "$fc, retired in use while coming up, a caller queued";
    @warnings = ();
    my $pool   = new_pool('K261::Pool', $fc);
    my $first  = $pool->acquire;
    my $id     = $pool->{ids}[-1];
    my $second = $pool->acquire;

    $pool->_retire_in_use_connection($pool->{built}{$id});
    like failure_of($first), $RETIRED, "$l: the caller waiting for it fails with the retirement";
    is $pool->{ids}[-1], $id + 1, "$l: the queued caller's slot gets a fresh spawn at once";
    $pool->{built}{ $id + 1 }->fire_connect;
    is resolved($second) && $second->get->{id}, $id + 1, "$l: which serves it";
    is destroyed($id), 1, "$l: the retired connection is freed";
    is_deeply $pool->{closed}, [$id], "$l: closed once";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
    $pool->shutdown;
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # -------------------------------------------------------------------------
  # 2. A forked child, and a readiness Future of the transport's own.
  # -------------------------------------------------------------------------
  for my $late (qw(done fail)) {
    for my $shuts_down (0, 1) {
      my $l = "$fc, a forked child drops a hand-over on the transport's own readiness, "
            . ($shuts_down ? 'shuts its pool down, ' : '') . "late $late";
      @warnings = ();
      my $pool  = new_pool('K261::OwnReadyPool', $fc);
      my $f     = $pool->acquire;
      my $id    = $pool->{ids}[-1];
      my $conn  = $pool->{built}{$id};
      my $ready = $pool->{ready}{$id};
      ok !$f->is_ready, "$l: the acquire waits on the transport's Future";

      my $cancelled = 0;
      $ready->on_cancel(sub { $cancelled++ }) if $ready->can('on_cancel');

      $pool->{_owner_pid} = -1;    # this process is not the one that opened it
      $pool->_verify_pid;
      is handovers($pool), 0, "$l: the child drops the hand-over";
      is $pool->size, 0, "$l: with the connection, which it no longer counts";

      $pool->shutdown if $shuts_down;
      ok !$f->is_ready, "$l: the parent's caller is not failed in the child";
      ok !$ready->is_ready, "$l: the transport's Future is left as it is";
      is $cancelled, 0, "$l: none of its on_cancel callbacks runs in the child";

      ok eval {
        $late eq 'done' ? $ready->done($conn) : $ready->fail("late\n");
        1;
      }, "$l: the transport settling it in the child does not die" or diag $@;

      ok !$f->is_ready, "$l: the parent's caller is not settled in the child";
      is_deeply [@warnings], [], "$l: nothing warned";
      is $pool->size + $pool->available, 0, "$l: it gives the child's pool no connection";
      is $pool->{closed}, undef, "$l: and nothing of the parent's is closed";
      is_deeply $pool->{errors}, [], "$l: nor reported";
      is parked($pool), 0, "$l: the child's pool holds nothing of the hand-over any more";
    }
  }

  # What the child's pool keeps of an inherited hand-over until its readiness
  # Future settles: the wait, and nothing the wait was for.
  {
    my $l = "$fc, a forked child, the hand-over it dropped";
    @warnings = ();
    my $pool   = new_pool('K261::OwnReadyPool', $fc);
    my $f      = $pool->acquire;
    my $id     = $pool->{ids}[-1];
    my $ready  = $pool->{ready}{$id};
    my $caller = weak_caller($pool);

    $pool->{_owner_pid} = -1;
    $pool->_verify_pid;
    undef $f;

    ok !defined $$caller, "$l: the child's pool does not hold the parent's caller";
    is destroyed($id), 1, "$l: nor the inherited connection";
    is parked($pool), 1, "$l: it keeps the wait for the transport's Future";
    ok eval { $ready->done; 1 }, "$l: which the transport settles" or diag $@;
    is parked($pool), 0, "$l: and that is gone then";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # The pool's own readiness Future: the inherited handle's callback fires in
  # the child.
  {
    my $l = "$fc, a forked child, the inherited handle connects";
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];
    my $conn = $pool->{built}{$id};    # held by the test, as the transport holds it

    $pool->{_owner_pid} = -1;
    $pool->_verify_pid;
    ok eval { $conn->fire_connect; 1 }, "$l: its connect callback does not die" or diag $@;

    ok !$f->is_ready, "$l: the parent's caller is not settled in the child";
    is $pool->size + $pool->available, 0, "$l: it gives the child's pool no connection";
    is handovers($pool) + parked($pool), 0, "$l: the child's pool holds nothing of the hand-over";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # -------------------------------------------------------------------------
  # 3. shutdown, and a chain it cannot cancel.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, shutdown while a connection comes up behind the transport's own readiness";
    @warnings = ();
    my $pool  = new_pool('K261::OwnReadyPool', $fc);
    my $f     = $pool->acquire;
    my $id    = $pool->{ids}[-1];
    my $ready = $pool->{ready}{$id};

    $pool->shutdown;
    like failure_of($f), $SHUT, "$l: the caller fails with the shutdown";
    undef $f;
    is destroyed($id), 1, "$l: the connection is freed, no caller holding it";
    ok eval { $ready->done; 1 }, "$l: the transport settling its Future afterwards does not die"
      or diag $@;
    is_deeply $pool->{closed}, [$id], "$l: the connection was closed once";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # -------------------------------------------------------------------------
  # 5. The caller lets go of its Future without cancelling it: as it is.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, the caller drops its Future while the connection comes up";
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];

    undef $f;
    $pool->{built}{$id}->fire_connect;
    my ($size, $idle) = ($pool->size, $pool->available);
    my $next = $pool->acquire;

    is $size, 1, "$l: the connection that came up keeps its slot";
    is handovers($pool), 0, "$l: its hand-over is settled";
    is_deeply [@warnings], [], "$l: nothing warned -- no sequence Future is lost";
    is_deeply $pool->{errors}, [], "$l: and nothing is reported";

    is $idle, 0, "$l: it is not idle -- handed to a Future nobody reads";
    ok !$next->is_ready, "$l: and the next acquire on the pool of one waits";
    $pool->shutdown;
    like failure_of($next), $SHUT, "$l: until shutdown fails it";
    is_deeply $pool->{closed}, [$id], "$l: and closes the connection";
    is_deeply [@warnings], [], "$l: nothing warned at shutdown either";
  }
}

# ---------------------------------------------------------------------------
# A callback run bare can die only under Future.pm.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future not installed: no callback can die bare, and nothing can be cancelled', 1
    unless $have_future;
  my $fc = 'Future';

  # 1., continued. The caller's own callback dies as the retirement fails it.
  {
    my $l = 'retired while coming up, the callback of the caller it fails dies';
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];
    $f->on_fail(sub { die "caller callback died\n" });

    ok eval { $pool->_retire_connection($pool->{built}{$id}); 1 },
      "$l: the retirement does not die of it" or diag $@;
    like failure_of($f), $RETIRED, "$l: the caller fails with the retirement";
    is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
    like $pool->{errors}[0],
      qr/a caller was told that its connection was retired while it was coming up: caller callback died/,
      "$l: of the callback's own error, and of what it died under";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # A caller that gave up already is told nothing.
  {
    my $l = 'retired while coming up, the caller had cancelled';
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];
    $f->cancel;
    is handovers($pool), 1, "$l: the pool still holds the hand-over of the connection coming up";

    ok eval { $pool->_retire_connection($pool->{built}{$id}); 1 },
      "$l: the retirement does not die" or diag $@;
    ok $f->is_cancelled, "$l: the caller's Future is as it was";
    is handovers($pool), 0, "$l: the pool lets go of the hand-over";
    is destroyed($id), 1, "$l: and the connection is freed";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
    is_deeply [@warnings], [], "$l: nothing warned";
  }

  # ---------------------------------------------------------------------------
  # 4. A callback on the registered readiness Future dies as the transport's
  #    own callback settles it.
  # ---------------------------------------------------------------------------
  for my $event (qw(connect error)) {
    my $l = "the transport reports its $event, a callback on the readiness Future dies";
    @warnings = ();
    my $pool = new_pool('K261::Pool', $fc);
    my $f    = $pool->acquire;
    my $id   = $pool->{ids}[-1];
    my $conn = $pool->{built}{$id};
    $pool->_connection_ready_lookup($conn)->on_ready(sub { die "readiness callback died\n" });

    ok eval {
      $event eq 'connect' ? $conn->fire_connect : $conn->fire_error("could not connect\n");
      1;
    }, "$l: the transport's callback does not die of it" or diag $@;

    if ($event eq 'connect') {
      is resolved($f) && $f->get->{id}, $id, "$l: the caller has its connection";
      is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
      like $pool->{errors}[0],
        qr/the readiness of a connection that came up was settled: readiness callback died/,
        "$l: of the callback's own error, and of what it died under";
    }
    else {
      like failure_of($f), qr/could not connect/, "$l: the caller has the connect's error";
      is scalar @{ $pool->{errors} }, 2, "$l: on_error is told of the callback and of the connect error";
      like $pool->{errors}[0],
        qr/the readiness of a connection that failed to come up was settled: readiness callback died/,
        "$l: of the callback's own error, and of what it died under";
      is $pool->{errors}[1], "could not connect\n", "$l: and of the transport's error, as always";
    }
    is_deeply [@warnings], [], "$l: nothing warned";
  }
}

done_testing;
