use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k260, found by the k258 worker. A connection that fails to become ready
# is retired: it never lived a session, and must not keep a slot against
# max_size. The pool retired it through _retire_connection, which leaves the
# waiter queue alone -- "a connection this is called for was never handed to a
# waiter". But a caller can be queued for the slot of a connection that is
# still coming up: in a pool of one, the first acquire spawns and waits for the
# connect, the second is queued behind it. When the connect then failed, the
# first caller got the error, the pool was empty, and the second caller stayed
# in the queue of a pool with no connection left to be released -- for good.
#
# The claims this file pins (ADR 0047, addendum 2026-10-04):
#
#   * a connection that fails to become ready gives its slot to the oldest
#     caller still queued, as _retire_in_use_connection does for a checked-out
#     one: that caller gets a fresh spawn, or the spawn's error -- on both ways
#     a readiness failure arrives, the connection still coming up
#     (_hand_over_when_ready) and the seam that refuses a connection at once
#     (_retire_readiness_failure, a failed Future or a throw);
#   * the slot keeps going down the queue while it is free: a caller whose
#     replacement fails to come up, or whose spawn dies, fails with that error
#     and the next caller gets the next attempt;
#   * the caller whose connect failed still gets the connect's own error, also
#     when a callback of the caller the slot went to dies -- and that death is
#     reported through on_error;
#   * a caller that gave up is passed over, and with nobody queued nothing is
#     spawned.
#
# Mock only: fake handles whose connect is fired by hand, no event loop, no
# database. Everything but the cancel runs against DBIO::Test::Future and
# Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  # A transport handle that keeps the callbacks it was constructed with; the
  # test fires them.
  package K260::Conn;
  sub new          { my ($class, %args) = @_; bless {%args}, $class }
  sub fire_connect { $_[0]{on_connect}->() }
  sub fire_error   { $_[0]{on_error}->($_[1]) }
}

{
  # Readiness registered with the pool, the way the EV drivers build their
  # connections. {refuse_spawn}{$id} makes the spawn of connection $id die.
  package K260::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my ($self, %args) = @_;
    my $id = ++$self->{n};
    die "spawn $id refused\n" if $self->{refuse_spawn}{$id};
    my $conn = K260::Conn->new(%args, id => $id);
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Connections that are up the moment they exist, behind a readiness seam of
  # the transport's own that can refuse one at once: {refuse} on the connection
  # is 'fail' (a failed Future) or 'die' (a throw).
  package K260::SeamPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $conn = K260::Conn->new(id => ++$self->{n});
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _connection_ready_future {
    my ($self, $conn) = @_;
    my $refuse = $conn->{refuse}
      or return $self->future_class->done($conn);
    die "seam died for $conn->{id}\n" if $refuse eq 'die';
    return $self->future_class->fail("seam refused $conn->{id}\n");
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

sub new_pool {
  my ($class, $fc, %args) = @_;
  my $errors = [];
  my $pool = $class->new(
    conninfo     => 'x',
    size         => 1,
    future_class => $fc,
    on_error     => sub { push @$errors, $_[0] },
  );
  $pool->{errors} = $errors;
  $pool->{$_} = $args{$_} for keys %args;
  return $pool;
}

# Did $f resolve with a value -- not pending, not failed, not cancelled?
sub resolved {
  my ($f) = @_;
  return 0 unless $f->is_ready && !$f->is_failed;
  return 0 if $f->can('is_cancelled') && $f->is_cancelled;
  return 1;
}

sub resolved_id { resolved($_[0]) ? $_[0]->get->{id} : undef }

sub failure_of {
  my ($f) = @_;
  return undef unless $f->is_ready && $f->is_failed;
  eval { $f->get };
  return "$@";
}

sub queued    { scalar @{ $_[0]{_waiters} } }
sub built     { scalar @{ $_[0]{built} || [] } }
sub handovers { scalar keys %{ $_[0]{_ready_handovers} || {} } }

# Run one scenario, and require that it ran to its end and that nothing warned
# -- while it ran, or as its pool and Futures went out of scope.
sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  ok eval { $code->($label); 1 }, "$label: ran to its end" or diag $@;
  is_deeply [@warnings], [], "$label: nothing warned";
  return;
}

my $have_future = eval { require Future; 1 };
my @future_classes = ('DBIO::Test::Future', $have_future ? 'Future' : ());

for my $fc (@future_classes) {

  # -------------------------------------------------------------------------
  # The case of the card: a pool of one, A waits for its connection to come
  # up, B is queued behind it, the connect fails.
  # -------------------------------------------------------------------------
  scenario "$fc, the connect fails with a second caller queued" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my $first  = $pool->acquire;
    my $second = $pool->acquire;
    ok !$first->is_ready,  "$l: the first caller waits for its connection to come up";
    ok !$second->is_ready, "$l: the second is queued, the pool of one is full";
    is queued($pool), 1, "$l: (one caller in the queue)";

    $pool->{built}[0]->fire_error("could not connect\n");

    like failure_of($first), qr/could not connect/,
      "$l: the first caller gets the connect's own error";
    is_deeply $pool->{closed}, [1], "$l: the failed connection is closed exactly once";
    is queued($pool), 0, "$l: the second caller left the queue";
    is built($pool), 2, "$l: a fresh connection was spawned for it";
    is $pool->size, 1, "$l: and holds the pool's one slot";
    ok !$second->is_ready, "$l: it waits for that connection, still coming up";

    $pool->{built}[1]->fire_connect;
    is resolved_id($second), 2,
      "$l: and is served by it -- it waited for good before";
    is $pool->available, 0, "$l: borrowed, not idle";
    is handovers($pool), 0, "$l: the pool let go of both hand-overs";
    is_deeply $pool->{errors}, ["could not connect\n"],
      "$l: on_error got the connect error, and nothing else";
  };

  # A replacement that fails to come up as well fails the caller it was
  # spawned for -- with its error, not by leaving it in the queue.
  scenario "$fc, the replacement fails to connect as well" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my $first  = $pool->acquire;
    my $second = $pool->acquire;

    $pool->{built}[0]->fire_error("first connect failed\n");
    $pool->{built}[1]->fire_error("second connect failed\n");

    like failure_of($first), qr/first connect failed/,
      "$l: the first caller has the first connect's error";
    like failure_of($second), qr/second connect failed/,
      "$l: the second caller fails with the error of its own connection";
    is $pool->size, 0, "$l: neither connection keeps a slot";
    is_deeply $pool->{closed}, [1, 2], "$l: each is closed exactly once";
    is built($pool), 2, "$l: nothing is spawned once nobody waits";

    my $next = $pool->acquire;
    is built($pool), 3, "$l: the next acquire spawns a new connection";
    $pool->{built}[2]->fire_connect;
    is resolved_id($next), 3, "$l: and is served by it";
  };

  # Three callers: the slot goes down the queue one failed connect at a time.
  scenario "$fc, the slot goes down the queue" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my ($first, $second, $third) = map { $pool->acquire } 1 .. 3;
    is queued($pool), 2, "$l: two callers are queued behind the connecting one";

    $pool->{built}[0]->fire_error("first connect failed\n");
    is queued($pool), 1, "$l: the oldest of them took the slot";
    ok !$third->is_ready, "$l: the third keeps waiting -- the pool of one is full again";
    is $pool->size, 1, "$l: (it holds the replacement)";

    $pool->{built}[1]->fire_error("second connect failed\n");
    like failure_of($second), qr/second connect failed/,
      "$l: the second caller fails with its connection's error";
    is queued($pool), 0, "$l: and the third takes the slot in turn";

    $pool->{built}[2]->fire_connect;
    is resolved_id($third), 3, "$l: on a third connection, which comes up";
    is_deeply $pool->{closed}, [1, 2], "$l: the two failed ones were closed, once each";
    is $pool->size, 1, "$l: the pool holds the one that is up";
  };

  # The spawn of the replacement dies -- a refused connect action, a broker that
  # will not answer. That caller fails with the spawn's error; the slot is still
  # free, so the caller behind it gets the next attempt instead of waiting for a
  # release nobody is left to make.
  scenario "$fc, the replacement's spawn dies, and a third caller is queued" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc, refuse_spawn => { 2 => 1 });
    my ($first, $second, $third) = map { $pool->acquire } 1 .. 3;

    $pool->{built}[0]->fire_error("could not connect\n");

    like failure_of($first), qr/could not connect/,
      "$l: the first caller has the connect's error";
    like failure_of($second), qr/spawn 2 refused/,
      "$l: the second fails with the error of the spawn made for it";
    is queued($pool), 0, "$l: the third caller left the queue";
    is $pool->size, 1, "$l: a connection was spawned for it";
    ok !$third->is_ready, "$l: which it waits for";

    $pool->{built}[-1]->fire_connect;
    is resolved_id($third), 3, "$l: and gets once it is up";
  };

  scenario "$fc, every replacement spawn dies" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc, refuse_spawn => { 2 => 1, 3 => 1 });
    my ($first, $second, $third) = map { $pool->acquire } 1 .. 3;

    $pool->{built}[0]->fire_error("could not connect\n");

    like failure_of($second), qr/spawn 2 refused/,
      "$l: the second caller fails with the spawn made for it";
    like failure_of($third), qr/spawn 3 refused/,
      "$l: the third with the one made for it -- neither is left waiting";
    is queued($pool), 0, "$l: the queue is empty";
    is $pool->size, 0, "$l: and so is the pool";
  };

  # With nobody queued, the retirement spawns nothing: the next acquire does.
  scenario "$fc, the connect fails with nobody queued" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my $only = $pool->acquire;

    $pool->{built}[0]->fire_error("could not connect\n");
    like failure_of($only), qr/could not connect/, "$l: the caller has the error";
    is built($pool), 1, "$l: no replacement is spawned for nobody";
    is $pool->size, 0, "$l: the slot is free";
  };

  # -------------------------------------------------------------------------
  # The other way a readiness failure arrives: the seam refuses a connection
  # at once -- with a failed Future, or by dying. Here the connection is one a
  # release handed to a queued caller, with a second caller queued behind it.
  # -------------------------------------------------------------------------
  for my $how (qw(fail die)) {
    my $error = $how eq 'fail' ? qr/seam refused 1/ : qr/seam died for 1/;

    scenario "$fc, the seam refuses a handed-on connection ($how), a caller queued behind" => sub {
      my $l = shift;
      my $pool = new_pool('K260::SeamPool', $fc);
      my $conn = $pool->acquire->get;
      my ($second, $third) = map { $pool->acquire } 1 .. 2;
      is queued($pool), 2, "$l: two callers are queued for the pool's one connection";

      $conn->{refuse} = $how;
      $pool->release($conn);

      like failure_of($second), $error,
        "$l: the caller it was handed to fails with the seam's error";
      is_deeply $pool->{closed}, [1], "$l: the refused connection is closed exactly once";
      is resolved_id($third), 2,
        "$l: the caller behind it is served by a fresh one -- it waited for good before";
      is queued($pool), 0, "$l: nobody is left in the queue";
      is $pool->size, 1, "$l: the pool holds the fresh connection only";
    };

    scenario "$fc, the seam refuses a handed-on connection ($how), nobody behind" => sub {
      my $l = shift;
      my $pool = new_pool('K260::SeamPool', $fc);
      my $conn = $pool->acquire->get;
      my $second = $pool->acquire;

      $conn->{refuse} = $how;
      $pool->release($conn);

      like failure_of($second), $error, "$l: the caller fails with the seam's error";
      is built($pool), 1, "$l: no replacement is spawned for nobody";
      is $pool->size, 0, "$l: the slot is free";
    };
  }
}

# ---------------------------------------------------------------------------
# With a caller that gave up. That is a cancel, so Future.pm only.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future not installed: no caller can cancel', 1 unless $have_future;
  my $fc = 'Future';

  # k258 lets the connect of a caller that gave up run on. When it fails, the
  # slot still goes to whoever is queued behind it.
  scenario 'the connecting caller gave up, then the connect fails' => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my $first  = $pool->acquire;
    my $second = $pool->acquire;

    $first->cancel;
    $pool->{built}[0]->fire_error("could not connect\n");

    ok $first->is_cancelled, "$l: the caller's Future stays as the caller left it";
    is built($pool), 2, "$l: the queued caller got a fresh connection";
    $pool->{built}[1]->fire_connect;
    is resolved_id($second), 2, "$l: and is served by it";
    is_deeply $pool->{closed}, [1], "$l: the failed connection was closed once";
  };

  # A queued caller that gave up is passed over (k255): the slot goes to the
  # oldest caller STILL waiting, and nothing is spawned for one who is not.
  scenario 'the queued caller gave up, another is queued behind it' => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my ($first, $second, $third) = map { $pool->acquire } 1 .. 3;

    $second->cancel;
    $pool->{built}[0]->fire_error("could not connect\n");

    is built($pool), 2, "$l: one replacement is spawned";
    $pool->{built}[1]->fire_connect;
    is resolved_id($third), 2, "$l: for the caller still waiting";
    ok $second->is_cancelled, "$l: not for the one that gave up";
  };

  scenario 'the only queued caller gave up' => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc);
    my $first  = $pool->acquire;
    my $second = $pool->acquire;

    $second->cancel;
    $pool->{built}[0]->fire_error("could not connect\n");

    like failure_of($first), qr/could not connect/, "$l: the first caller has the error";
    is built($pool), 1, "$l: nothing is spawned for a caller that gave up";
    is $pool->size, 0, "$l: the slot is free";
  };

  # The slot is handed on under the ->then off the readiness Future, before the
  # caller whose connect failed is told. A callback of the caller the slot went
  # to that dies there must not cost the first caller its error, and must be
  # heard of.
  scenario "a callback of the queued caller dies as the slot is handed on" => sub {
    my $l = shift;
    my $pool = new_pool('K260::Pool', $fc, refuse_spawn => { 2 => 1 });
    my $first  = $pool->acquire;
    my $second = $pool->acquire;
    $second->on_fail(sub { die "queued caller's callback died\n" });

    ok eval { $pool->{built}[0]->fire_error("could not connect\n"); 1 },
      "$l: the death is not thrown into the transport's on_error" or diag $@;
    like failure_of($first), qr/could not connect/,
      "$l: the first caller still gets the connect's error";
    like failure_of($second), qr/spawn 2 refused/,
      "$l: the queued caller has the error of its spawn";
    is scalar( grep { /queued caller's callback died/ } @{ $pool->{errors} } ), 1,
      "$l: on_error is told of the callback's death, once";
    is scalar( grep { $_ eq "could not connect\n" } @{ $pool->{errors} } ), 1,
      "$l: beside the connect error it gets anyway";
    is handovers($pool), 0, "$l: the pool let go of the settled hand-over";
  };
}

is_deeply \@warnings, [], 'nothing warned outside a scenario either';

done_testing;
