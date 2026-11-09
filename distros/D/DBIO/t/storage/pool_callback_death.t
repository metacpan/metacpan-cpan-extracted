use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k279. The pool settles Futures that are not its own: release hands the
# connection to the oldest queued caller, _retire_in_use_connection hands on a
# fresh spawn or its error, shutdown fails everyone still waiting -- queued
# callers, callers whose connection is still coming up, the readiness Futures
# of those connections -- and lets go of the chains it held for them. A Future
# runs its callbacks as it is settled, so the code of the caller it belongs to
# runs inside that pool method. When such a callback died, the death was
# thrown at whoever had called the method: at the caller that released, for
# the callback of another; and out of the middle of shutdown, which then left
# the callers behind it unsettled and its connections open.
#
# Where a connection is handed over as it comes up, such a death has gone to
# the pool's on_error since k258. The claims this file pins say the same for
# every other place:
#
#   1. _retire_in_use_connection, the replacement spawn dies: a callback of
#      the caller it failed that dies in turn goes to on_error, and the caller
#      queued behind still gets the next attempt;
#   2. _retire_in_use_connection, the pool is shut down from inside the
#      replacement spawn: a callback of the caller it fails goes to on_error;
#   3. shutdown: a dying callback of a queued caller, of a caller whose
#      connection is still coming up, on the readiness Future of such a
#      connection, or as the wait for one is cancelled, goes to on_error --
#      and shutdown goes on: everyone else is failed with the shutdown, every
#      connection is closed, once, and the pool holds nothing;
#   4. an on_error that dies in turn is warned with the report it was given;
#   5. a callback made with ->then is none of this, in either Future class:
#      its death is the failure of the Future ->then returned, nothing is
#      thrown and nothing reported -- with DBIO::Test::Future that is the only
#      kind of callback there is.
#
# release itself, and the caller a retirement serves, are pinned in section 6
# of t/storage/pool_reentrant_callbacks.t. Mock only, no event loop and no
# database; a callback can die bare only under Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K279::Conn;
  sub new { my ($class, %args) = @_; bless {%args}, $class }
}

{
  # Connections usable the moment they exist. {refuse_spawn}{$id} makes the
  # spawn of connection $id die; {in_spawn}{$id} is run inside it.
  package K279::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $id = ++$self->{n};
    if (my $code = delete $self->{in_spawn}{$id}) { $code->() }
    die "spawn $id refused\n" if $self->{refuse_spawn}{$id};
    my $conn = K279::Conn->new(id => $id);
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Connections still coming up, their readiness Future registered with the
  # pool (_create_ready_connection).
  package K279::ReadyPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = K279::Conn->new(%args, id => ++$self->{n});
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Connections still coming up behind a readiness Future the transport's own
  # seam makes: the pool's readiness table does not know it.
  package K279::OwnReadyPool;
  use base 'K279::Pool';

  sub _connection_ready_future {
    my ($self, $conn) = @_;
    return $conn->{ready} ||= $self->future_class->new;
  }
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

sub closed { [ sort { $a <=> $b } @{ $_[0]{closed} || [] } ] }

sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  $code->($label);
  is_deeply [@warnings], [], "$label: nothing warned";
  return;
}

my $SHUT = qr/Connection pool has been shut down/;

my $have_future = eval { require Future; 1 };

SKIP: {
  skip 'Future not installed: no callback can die bare', 1 unless $have_future;
  my $fc = 'Future';

  # -------------------------------------------------------------------------
  # 1. The replacement spawn dies, and so does a callback of the caller it
  #    failed.
  # -------------------------------------------------------------------------
  scenario "replacement spawn dies, the failed caller's callback dies" => sub {
    my $l = shift;
    my $pool = new_pool('K279::Pool', $fc);
    my $conn = $pool->acquire->get;
    $pool->{refuse_spawn}{2} = 1;

    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    $first->on_fail(sub { die "caller callback died\n" });

    ok eval { $pool->_retire_in_use_connection($conn); 1 },
      "$l: the retirement does not die of it" or diag $@;

    like failure_of($first), qr/spawn 2 refused/, "$l: the caller has its spawn's error";
    is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
    like $pool->{errors}[0], qr/a spawn's failure was handed to a queued caller: caller callback died/,
      "$l: of the callback's own error, and of what it died under";
    is resolved_id($second), 3, "$l: the caller queued behind gets the next attempt";
    is $pool->size, 1, "$l: one connection in the pool of one";
    is queued($pool), 0, "$l: nobody is left queued";
  };

  # -------------------------------------------------------------------------
  # 2. The pool is shut down from inside the replacement spawn.
  # -------------------------------------------------------------------------
  scenario "replacement spawn shut down from inside, the failed caller's callback dies" => sub {
    my $l = shift;
    my $pool = new_pool('K279::Pool', $fc);
    my $conn = $pool->acquire->get;
    $pool->{in_spawn}{2} = sub { $pool->shutdown };

    my $waiter = $pool->acquire;
    $waiter->on_fail(sub { die "caller callback died\n" });

    ok eval { $pool->_retire_in_use_connection($conn); 1 },
      "$l: the retirement does not die of it" or diag $@;

    like failure_of($waiter), $SHUT, "$l: the caller fails with the shutdown";
    is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
    like $pool->{errors}[0], qr/the shutdown failed a queued caller: caller callback died/,
      "$l: of the callback's own error, and of what it died under";
    is_deeply closed($pool), [ 1, 2 ], "$l: every connection the pool made is closed, once";
    is $pool->size, 0, "$l: the shut down pool counts no connection";
  };

  # -------------------------------------------------------------------------
  # 3. shutdown.
  # -------------------------------------------------------------------------
  scenario "shutdown, a queued caller's callback dies" => sub {
    my $l = shift;
    my $pool = new_pool('K279::Pool', $fc);
    my $conn = $pool->acquire->get;

    my ($first, $second, $third) = map { $pool->acquire } 1 .. 3;
    $first->on_fail(sub { die "caller callback died\n" });

    my $returned = eval { $pool->shutdown };
    is $returned, 1, "$l: shutdown does not die of it" or diag $@;

    like failure_of($first), $SHUT, "$l: the caller whose callback died fails with the shutdown";
    like failure_of($second), $SHUT, "$l: so does the caller queued behind it";
    like failure_of($third), $SHUT, "$l: and the one behind that";
    is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
    like $pool->{errors}[0], qr/the shutdown failed a queued caller: caller callback died/,
      "$l: of the callback's own error, and of what it died under";
    is_deeply closed($pool), [1], "$l: the connection is closed, once";
    is $pool->size + $pool->available, 0, "$l: the pool holds nothing";
    is queued($pool), 0, "$l: nobody is left queued";

    like failure_of($pool->acquire), $SHUT, "$l: a later acquire fails with the shutdown";
    is $pool->shutdown, 1, "$l: a second shutdown is the no-op it always is";
    is_deeply closed($pool), [1], "$l: and closes nothing again";
  };

  scenario "shutdown, a callback on a registered readiness Future dies" => sub {
    my $l = shift;
    my $pool = new_pool('K279::ReadyPool', $fc, size => 2);

    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    ok !$first->is_ready && !$second->is_ready, "$l: two callers wait for their connections to come up";
    $pool->_connection_ready_lookup($pool->{built}[0])
      ->on_fail(sub { die "readiness callback died\n" });

    my $returned = eval { $pool->shutdown };
    is $returned, 1, "$l: shutdown does not die of it" or diag $@;

    like failure_of($first), $SHUT, "$l: the caller of that connection fails with the shutdown";
    like failure_of($second), $SHUT, "$l: so does the caller of the next";
    is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
    like $pool->{errors}[0],
      qr/the shutdown failed the readiness of a connection still coming up: readiness callback died/,
      "$l: of the callback's own error, and of what it died under";
    is_deeply closed($pool), [ 1, 2 ], "$l: both connections are closed, once each";
    is $pool->size, 0, "$l: the pool holds nothing";
    is scalar keys %{ $pool->{_ready_handovers} }, 0, "$l: no hand-over is left behind";
  };

  # The hand-overs are a hash: which caller shutdown fails first is not
  # fixed, so the callback of each dies -- whichever came first, the other
  # was left unsettled.
  scenario "shutdown, the callbacks of callers whose connections are still coming up die" => sub {
    my $l = shift;
    my $pool = new_pool('K279::OwnReadyPool', $fc, size => 2);

    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    ok !$first->is_ready && !$second->is_ready, "$l: two callers wait for their connections to come up";
    $_->on_fail(sub { die "caller callback died\n" }) for $first, $second;

    my $returned = eval { $pool->shutdown };
    is $returned, 1, "$l: shutdown does not die of it" or diag $@;

    like failure_of($first), $SHUT, "$l: the first caller fails with the shutdown";
    like failure_of($second), $SHUT, "$l: and so does the second";
    is scalar @{ $pool->{errors} }, 2, "$l: on_error is told of each callback, once";
    is scalar( grep {
      /the shutdown failed a caller waiting for its connection to come up: caller callback died/
    } @{ $pool->{errors} } ), 2, "$l: of its own error, and of what it died under";
    is_deeply closed($pool), [ 1, 2 ], "$l: both connections are closed, once each";
    is $pool->size, 0, "$l: the pool holds nothing";
    is scalar keys %{ $pool->{_ready_handovers} }, 0, "$l: no hand-over is left behind";
  };

  scenario "shutdown, a callback dies as the wait for a connection is cancelled" => sub {
    my $l = shift;
    my $pool = new_pool('K279::OwnReadyPool', $fc, size => 2);

    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    my @ready = map { $_->{ready} } @{ $pool->{built} };
    $_->on_cancel(sub { die "transport on_cancel died\n" }) for @ready;

    my $returned = eval { $pool->shutdown };
    is $returned, 1, "$l: shutdown does not die of it" or diag $@;

    like failure_of($first), $SHUT, "$l: the first caller fails with the shutdown";
    like failure_of($second), $SHUT, "$l: and so does the second";
    is scalar( grep { $_->is_cancelled } @ready ), 2,
      "$l: both readiness Futures are cancelled";
    is scalar @{ $pool->{errors} }, 2, "$l: on_error is told of each callback, once";
    is scalar( grep {
      /the shutdown cancelled the wait for a connection to come up: transport on_cancel died/
    } @{ $pool->{errors} } ), 2, "$l: of its own error, and of what it died under";
    is_deeply closed($pool), [ 1, 2 ], "$l: both connections are closed, once each";
    is $pool->size, 0, "$l: the pool holds nothing";
  };

  # -------------------------------------------------------------------------
  # 4. An on_error that dies in turn.
  # -------------------------------------------------------------------------
  for my $way (qw(release shutdown)) {
    my $pool = new_pool('K279::Pool', $fc, on_error => sub { die "on_error died\n" });
    my $conn = $pool->acquire->get;
    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    my $settled = $way eq 'release' ? 'on_done' : 'on_fail';
    $first->$settled(sub { die "caller callback died\n" });

    @warnings = ();
    ok eval { $pool->$way($way eq 'release' ? $conn : ()); 1 },
      "$way, on_error dies as well: $way does not die of either" or diag $@;
    is scalar @warnings, 1, "$way, on_error dies as well: warned, once";
    like $warnings[0], qr/on_error died \(on_error died\).*caller callback died/s,
      "$way, on_error dies as well: with on_error's death and the report it was given";
    if ($way eq 'release') {
      is resolved_id($first), 1, "$way, on_error dies as well: the caller has its connection all the same";
    }
    else {
      like failure_of($second), $SHUT, "$way, on_error dies as well: the caller queued behind is failed all the same";
      is_deeply closed($pool), [1], "$way, on_error dies as well: and the connection closed";
    }
    @warnings = ();
  }
}

# ---------------------------------------------------------------------------
# 5. A callback made with ->then. Its death never left the Future ->then
#    returned, before k279 as after: the pool is told nothing, because the
#    caller that made the callback holds the Future that failed of it.
# ---------------------------------------------------------------------------
for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {
  for my $way (qw(release _retire_in_use_connection shutdown)) {
    scenario "$fc, $way, a ->then callback dies" => sub {
      my $l = shift;
      my $pool = new_pool('K279::Pool', $fc);
      my $conn = $pool->acquire->get;

      my ($first, $second) = map { $pool->acquire } 1 .. 2;
      my $die     = sub { die "then callback died\n" };
      my $derived = $first->then($die, $die);

      ok eval { $pool->$way($way eq 'shutdown' ? () : $conn); 1 },
        "$l: $way does not die of it" or diag $@;

      like failure_of($derived), qr/then callback died/,
        "$l: the death is the failure of the Future ->then returned";
      is_deeply $pool->{errors}, [], "$l: on_error is told nothing";
      if ($way eq 'shutdown') {
        like failure_of($second), $SHUT, "$l: the caller queued behind is failed with the shutdown";
        is_deeply closed($pool), [1], "$l: and the connection closed";
      }
      else {
        is resolved_id($first), $way eq 'release' ? 1 : 2, "$l: the caller has its connection";
        ok !$second->is_ready, "$l: the caller queued behind keeps waiting";
      }
    };
  }
}

is_deeply \@warnings, [], 'nothing warned outside a scenario either';

done_testing;
