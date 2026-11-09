use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k258, found by the k256 worker. acquire spawns a connection when the
# pool has room and gates it on _connection_ready_future. While that readiness
# Future was pending, acquire returned $ready->then(...) to its caller, and
# Future.pm carries a cancel down a ->then chain to the Future it was chained
# off. A caller that gave up -- a cancel, the loser of a wait_any -- therefore
# cancelled the pool's readiness Future:
#
#   * the connection came up to a cancelled Future that settled nothing. It
#     kept its slot against max_size, was never idle and never handed out; in
#     a pool of one, every later acquire waited for good;
#   * a connect that failed found the same cancelled Future, so the connection
#     was never retired either;
#   * the same when _retire_in_use_connection handed a fresh spawn to a queued
#     waiter and that waiter's caller gave up.
#
# acquire now hands a connection still coming up to its caller through a
# Future of the caller's own, and the pool holds the chain off the readiness
# Future. The claims this file pins, for a pool of one:
#
#   * a caller that gave up loses nothing: the connection that comes up goes
#     to the next caller still waiting, or to idle; one that fails to come up
#     is retired, and the next acquire spawns anew;
#   * a caller that waits is served as before: its connection, or the error;
#   * shutdown fails a caller still waiting, closes the connection once, and a
#     readiness that settles afterwards changes nothing -- whether the pool
#     registered the readiness Future (_create_ready_connection) or the
#     transport made it in a _connection_ready_future of its own;
#   * a forked child that drops what it inherited settles nothing of it;
#   * a callback on the caller's Future that dies in the hand-over is reported,
#     not swallowed by the chain it runs under;
#   * none of it warns -- in particular Future.pm never "lost a sequence
#     Future", which is what a chain nobody holds ends in.
#
# Mock only: fake handles whose connect is fired by hand, no event loop, no
# database. What needs no cancel runs against DBIO::Test::Future and Future.pm;
# giving up is a cancel, which only Future.pm has -- and only a cancel reaches
# the Future the pool can see, since it travels down the caller's own chain.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  # A transport handle as EV::Pg / EV::MariaDB are one: it keeps the callbacks
  # it was constructed with, and the test fires them.
  package K258::Conn;
  sub new          { my ($class, %args) = @_; bless {%args}, $class }
  sub fire_connect { $_[0]{on_connect}->() }
  sub fire_error   { $_[0]{on_error}->($_[1]) }
}

{
  # Readiness registered with the pool: what the EV drivers do.
  package K258::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = K258::Conn->new(%args, id => ++$self->{n});
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Readiness the transport makes and keeps itself, in a seam override of its
  # own: the pool never registers it (the shape of dbio-async's poll-driven
  # readiness).
  package K258::OwnReadyPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $conn = K258::Conn->new(id => ++$self->{n});
    $conn->{ready} = $self->future_class->new;
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _connection_ready_future { $_[1]{ready} }
  sub _shutdown_connection     { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # An owning storage that records the disconnect actions it is asked for.
  package K258::Storage;
  sub new { bless { torn_down => [] }, $_[0] }
  sub _teardown_pool_connection { push @{ $_[0]{torn_down} }, $_[1]{id} }
}

sub new_pool {
  my ($class, $fc, %args) = @_;
  my $errors = [];
  my $pool = $class->new(
    conninfo     => 'x',
    size         => 1,
    future_class => $fc,
    on_error     => sub { push @$errors, $_[0] },
    %args,
  );
  $pool->{errors} = $errors;
  return $pool;
}

# acquire on a pool with room: the acquire, and the connection spawned for it.
sub cold_acquire {
  my ($pool) = @_;
  my $f = $pool->acquire;
  return ($f, $pool->{built}[-1]);
}

# A pool of one whose connection is up and checked out.
sub warm_pool {
  my ($fc) = @_;
  my $pool = new_pool('K258::Pool', $fc);
  my ($f, $conn) = cold_acquire($pool);
  $conn->fire_connect;
  return ($pool, $f->get);
}

# Did $f resolve with a value -- not pending, not failed, not cancelled?
sub resolved {
  my ($f) = @_;
  return 0 unless $f->is_ready && !$f->is_failed;
  return 0 if $f->can('is_cancelled') && $f->is_cancelled;
  return 1;
}

# The id of the connection $f resolved with, or undef.
sub resolved_id { resolved($_[0]) ? $_[0]->get->{id} : undef }

# What $f failed with, or undef.
sub failure_of {
  my ($f) = @_;
  return undef unless $f->is_ready && $f->is_failed;
  eval { $f->get };
  return "$@";
}

# How many hand-overs the pool still holds.
sub handovers { scalar keys %{ $_[0]{_ready_handovers} || {} } }

# Run one scenario, and require that nothing warned -- while it ran, or as its
# pool and Futures went out of scope.
sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  $code->($label);
  is_deeply [@warnings], [], "$label: nothing warned";
  return;
}

my $have_future = eval { require Future; 1 };
my @future_classes = ('DBIO::Test::Future', $have_future ? 'Future' : ());

# ---------------------------------------------------------------------------
# A caller that does not give up. Nothing here needs a cancel, so it runs
# against both Future classes: the hand-over must not cost what worked.
# ---------------------------------------------------------------------------
for my $fc (@future_classes) {

  scenario "$fc, the caller waits to the end" => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);

    ok !$f->is_ready, "$l: the acquire is pending while its connection comes up";
    isa_ok $f, $fc, "$l: the Future the caller waits on";

    $conn->fire_connect;
    is resolved_id($f), 1, "$l: it resolves with the connection that came up";
    is $pool->size, 1, "$l: the pool holds that one connection";
    is $pool->available, 0, "$l: borrowed by the caller, not idle";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
  };

  scenario "$fc, the connect fails while the caller waits" => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);

    $conn->fire_error("could not connect\n");
    like failure_of($f), qr/could not connect/,
      "$l: the connect's own error reaches the caller";
    is $pool->size, 0, "$l: the connection is retired -- it keeps no slot";
    is_deeply $pool->{closed}, [1], "$l: and is closed exactly once";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
    is_deeply $pool->{errors}, ["could not connect\n"],
      "$l: on_error got the connect error, and nothing else";

    my ($next, $fresh) = cold_acquire($pool);
    is $fresh->{id}, 2, "$l: the next acquire spawns a new connection";
    $fresh->fire_connect;
    is resolved_id($next), 2, "$l: and is served by it";
  };

  scenario "$fc, a fresh spawn handed to a queued caller that waits" => sub {
    my $l = shift;
    my ($pool, $conn) = warm_pool($fc);
    my $queued = $pool->acquire;
    ok !$queued->is_ready, "$l: a second caller is queued for the pool of one";

    $pool->_retire_in_use_connection($conn);
    my $fresh = $pool->{built}[-1];
    is $fresh->{id}, 2, "$l: the queued caller's slot got a fresh connection";
    ok !$queued->is_ready, "$l: which it waits for, still coming up";

    $fresh->fire_connect;
    is resolved_id($queued), 2, "$l: and gets once it is up";
    is $pool->available, 0, "$l: borrowed, not idle";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
  };

  # shutdown, with the readiness Future registered by the pool. Its connection
  # loop fails that Future, which fails the caller through the hand-over.
  for my $late (qw(connect error)) {
    scenario "$fc, shutdown while the caller waits (registered readiness, late $late)" => sub {
      my $l = shift;
      my $storage = K258::Storage->new;
      my $pool = new_pool('K258::Pool', $fc, storage => $storage);
      my ($f, $conn) = cold_acquire($pool);

      $pool->shutdown;
      like failure_of($f), qr/Connection pool has been shut down/,
        "$l: the caller fails with the shutdown, it does not wait for good";
      is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
      is_deeply $storage->{torn_down}, [],
        "$l: it never came up, so no disconnect action runs against it";
      is handovers($pool), 0, "$l: no hand-over is left behind";

      ok eval {
        $late eq 'connect' ? $conn->fire_connect : $conn->fire_error("late\n");
        1;
      }, "$l: the transport settling afterwards does not die" or diag $@;
      is_deeply $pool->{closed}, [1], "$l: nor close the connection again";
      is $pool->size + $pool->available, 0, "$l: nor put it back into the pool";
      like failure_of($f), qr/Connection pool has been shut down/,
        "$l: nor change what the caller was told";
    };
  }

  # shutdown, with a readiness Future the pool never registered. The connection
  # loop cannot fail it, so nothing but the hand-over can reach the caller.
  for my $late (qw(done fail)) {
    scenario "$fc, shutdown while the caller waits (the transport's own readiness, late $late)" => sub {
      my $l = shift;
      my $pool = new_pool('K258::OwnReadyPool', $fc);
      my ($f, $conn) = cold_acquire($pool);
      my $ready = $conn->{ready};
      ok !$f->is_ready, "$l: the acquire is pending on the transport's Future";

      $pool->shutdown;
      like failure_of($f), qr/Connection pool has been shut down/,
        "$l: the caller fails with the shutdown, it does not wait for good";
      is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
      is handovers($pool), 0, "$l: no hand-over is left behind";

      # What the seam's POD tells a transport: with Future.pm the pool's cancel
      # of its chain is a cancel of the readiness Future it was chained off.
      if ($ready->can('is_cancelled')) {
        ok $ready->is_cancelled,
          "$l: the cancel of the pool's chain reached the transport's readiness Future";
      }
      else {
        ok !$ready->is_ready,
          "$l: a readiness Future that cannot be cancelled is left as it was";
      }

      ok eval {
        $late eq 'done' ? $ready->done($conn) : $ready->fail("late\n");
        1;
      }, "$l: the transport settling it afterwards does not die" or diag $@;
      is_deeply $pool->{closed}, [1], "$l: nor close the connection again";
      is $pool->size + $pool->available, 0, "$l: nor put it back into the pool";
      like failure_of($f), qr/Connection pool has been shut down/,
        "$l: nor change what the caller was told";
    };
  }

  # A forked child drops what it inherited (k233) and settles nothing of it
  # (k234): the caller waiting here is the parent's, and resolving it in the
  # child would run the parent's callback there, on the parent's connection.
  scenario "$fc, a forked child drops an inherited hand-over" => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);

    $pool->{_owner_pid} = -1;    # this process is not the one that opened it
    $pool->_verify_pid;
    is handovers($pool), 0, "$l: the hand-over is dropped with the connection";
    is $pool->size, 0, "$l: which the child's pool no longer counts";

    $conn->fire_connect;
    ok !$f->is_ready, "$l: the connect arriving in the child settles nothing";
    is $pool->size + $pool->available, 0, "$l: and gives the pool no connection";
    is $pool->{closed}, undef, "$l: nothing of the parent's is closed";
  };
}

# ---------------------------------------------------------------------------
# A caller that gives up. That is a cancel, so Future.pm only.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future not installed: no caller can cancel, the k258 case is not checked', 1
    unless $have_future;
  my $fc = 'Future';

  # The case of the card.
  scenario 'cancelled while the connection comes up' => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);

    $f->cancel;
    is $pool->size, 1, "$l: the connection still coming up keeps its slot";
    is $pool->available, 0, "$l: and is not idle before it is up";

    $conn->fire_connect;
    is $pool->available, 1, "$l: once up it is idle -- not lost with its caller";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";

    my $next = $pool->acquire;
    ok resolved($next),
      "$l: the next acquire resolves at once -- in a pool of one it waited for good";
    is resolved_id($next), 1, "$l: on that very connection";
    is scalar @{ $pool->{built} }, 1, "$l: nothing else was spawned";
    is $pool->size, 1, "$l: the pool of one holds one connection";
  };

  scenario 'cancelled while a second caller is queued' => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($first, $conn) = cold_acquire($pool);
    my $second = $pool->acquire;
    ok !$second->is_ready, "$l: the second caller is queued, the pool of one is full";

    $first->cancel;
    ok !$second->is_ready, "$l: and keeps waiting, the connection is not up yet";

    $conn->fire_connect;
    is resolved_id($second), 1,
      "$l: the connection that comes up goes to the caller still waiting";
    is $pool->available, 0, "$l: handed on, not parked idle beside a waiting caller";
    is scalar @{ $pool->{built} }, 1, "$l: nothing else was spawned";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
  };

  scenario 'cancelled, and then the connect fails' => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);

    $f->cancel;
    $conn->fire_error("could not connect\n");
    is $pool->size, 0,
      "$l: the connection is retired -- its slot is free although nobody waited";
    is_deeply $pool->{closed}, [1], "$l: and it is closed exactly once";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
    ok $f->is_cancelled, "$l: the caller's Future stays as the caller left it";

    my ($next, $fresh) = cold_acquire($pool);
    is $fresh->{id}, 2, "$l: the next acquire spawns a new connection";
    $fresh->fire_connect;
    is resolved_id($next), 2, "$l: and is served by it";
  };

  # The same loss, by the other way into the readiness seam: the waiter's
  # ->then adopted the Future acquire's callback returned, and cancelled it.
  scenario 'a fresh spawn handed to a queued caller that cancels' => sub {
    my $l = shift;
    my ($pool, $conn) = warm_pool($fc);
    my $queued = $pool->acquire;

    $pool->_retire_in_use_connection($conn);
    my $fresh = $pool->{built}[-1];
    is $fresh->{id}, 2, "$l: the queued caller's slot got a fresh connection";

    $queued->cancel;
    $fresh->fire_connect;
    is $pool->size, 1, "$l: the fresh connection keeps its slot";
    is $pool->available, 1, "$l: and is idle once up -- not lost with its caller";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";

    my $next = $pool->acquire;
    is resolved_id($next), 2, "$l: the next acquire gets it at once";
    is_deeply $pool->{closed}, [1], "$l: only the retired connection was closed";
  };

  # shutdown after the caller gave up: nobody is left to be told, but the
  # connection is the pool's to close, once, as one that never came up.
  for my $late (qw(connect error)) {
    scenario "cancelled, then shutdown (registered readiness, late $late)" => sub {
      my $l = shift;
      my $storage = K258::Storage->new;
      my $pool = new_pool('K258::Pool', $fc, storage => $storage);
      my ($f, $conn) = cold_acquire($pool);

      $f->cancel;
      $pool->shutdown;
      is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
      is_deeply $storage->{torn_down}, [],
        "$l: it never came up, so no disconnect action runs against it";
      is handovers($pool), 0, "$l: no hand-over is left behind";

      ok eval {
        $late eq 'connect' ? $conn->fire_connect : $conn->fire_error("late\n");
        1;
      }, "$l: the transport settling afterwards does not die" or diag $@;
      is_deeply $pool->{closed}, [1], "$l: nor close the connection again";
      is $pool->size + $pool->available, 0, "$l: nor put it back into the pool";
      ok $f->is_cancelled, "$l: the caller's Future stays as the caller left it";
    };
  }

  for my $late (qw(done fail)) {
    scenario "cancelled, then shutdown (the transport's own readiness, late $late)" => sub {
      my $l = shift;
      my $pool = new_pool('K258::OwnReadyPool', $fc);
      my ($f, $conn) = cold_acquire($pool);
      my $ready = $conn->{ready};

      $f->cancel;
      ok !$ready->is_ready,
        "$l: the caller's cancel does not reach the transport's readiness Future";

      $pool->shutdown;
      is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
      is handovers($pool), 0, "$l: no hand-over is left behind";
      ok $ready->is_cancelled, "$l: shutdown's cancel of the pool's chain does";

      ok eval {
        $late eq 'done' ? $ready->done($conn) : $ready->fail("late\n");
        1;
      }, "$l: the transport settling it afterwards does not die" or diag $@;
      is_deeply $pool->{closed}, [1], "$l: nor close the connection again";
      is $pool->size + $pool->available, 0, "$l: nor put it back into the pool";
    };
  }

  # The hand-over runs under the ->then off the readiness Future, which turns a
  # death into the failure of a Future nobody reads. A callback of the caller's
  # that dies there must still be heard of.
  scenario "the caller's callback dies as its connection is handed over" => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);
    $f->on_done(sub { die "caller callback died\n" });

    ok eval { $conn->fire_connect; 1 },
      "$l: the death is not thrown into the transport's on_connect" or diag $@;
    is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
    like $pool->{errors}[0], qr/caller callback died/, "$l: with the callback's own error";
    is resolved_id($f), 1, "$l: the caller has its connection all the same";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
  };

  scenario "the caller's callback dies as the connect's failure is handed over" => sub {
    my $l = shift;
    my $pool = new_pool('K258::Pool', $fc);
    my ($f, $conn) = cold_acquire($pool);
    $f->on_fail(sub { die "caller callback died\n" });

    ok eval { $conn->fire_error("could not connect\n"); 1 },
      "$l: the death is not thrown into the transport's on_error" or diag $@;
    is scalar( grep { /caller callback died/ } @{ $pool->{errors} } ), 1,
      "$l: on_error is told of the callback's death, once";
    is scalar( grep { $_ eq "could not connect\n" } @{ $pool->{errors} } ), 1,
      "$l: beside the connect error it gets anyway";
    like failure_of($f), qr/could not connect/, "$l: the caller has the connect error";
    is $pool->size, 0, "$l: the connection is retired";
    is_deeply $pool->{closed}, [1], "$l: and closed exactly once";
  };

  # An on_error that dies in turn may not take the report with it (as for the
  # idle liveness check, k252): the one warning this file expects.
  {
    @warnings = ();
    my $l = 'the callback dies, and on_error dies reporting it';
    my $pool = new_pool('K258::Pool', $fc, on_error => sub { die "on_error died\n" });
    my ($f, $conn) = cold_acquire($pool);
    $f->on_done(sub { die "caller callback died\n" });

    ok eval { $conn->fire_connect; 1 }, "$l: the transport's on_connect does not die"
      or diag $@;
    is scalar @warnings, 1, "$l: exactly one warning";
    like $warnings[0], qr/on_error died.*caller callback died/s,
      "$l: naming both deaths";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
    @warnings = ();
  }
}

is_deeply \@warnings, [], 'nothing warned outside a scenario either';

done_testing;
