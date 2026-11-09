use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k262, from dbio-async k36. shutdown runs the owning storage's
# on_disconnect_do / on_disconnect_call against every connection that reached
# readiness, and none against a cold one: "Cold connections whose readiness is
# still pending run no disconnect actions; they are retired and closed exactly
# once." It told the two apart by the readiness table alone
# (_connection_ready_lookup), which knows only a readiness Future registered
# through _create_ready_connection.
#
#   * A readiness Future the transport makes itself, in a
#     _connection_ready_future of its own -- dbio-async's poll -- is not in
#     that table. A connection still coming up behind one looked ready to
#     shutdown, which ran the disconnect actions against it: a blocking
#     statement on a connection that is not connected yet.
#
# The pool does know such a connection: an acquire is waiting for it, and the
# hand-over it holds for that acquire now names the connection. The claims this
# file pins:
#
#   1. a connection an acquire still waits on gets no disconnect actions at
#      shutdown and is closed exactly once, whoever made its readiness Future
#      -- also when its caller gave up, and for a fresh spawn handed to a
#      queued caller; the caller fails with the shutdown, and a readiness that
#      settles afterwards changes nothing;
#   2. a connection that came up gets its disconnect actions, as before --
#      idle or checked out, alone or beside one still coming up;
#   3. a connection the transport's seam says is not ready AGAIN when it is
#      borrowed from the idle list is cold in the same way.
#
# The hand-over names its connection without holding it. That it does not keep
# a retired connection alive is pinned where k261 pins what does:
# t/storage/pool_handover_open_cases.t.
#
# Mock only: fake handles, a readiness Future settled by hand, a stand-in for
# the owning storage that records what it is asked. DBIO::Test::Future and
# Future.pm; a caller giving up is a cancel, which only Future.pm has.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K262::Conn;
  sub new { my ($class, %args) = @_; bless {%args}, $class }
}

{
  # Readiness the transport makes and keeps itself: the pool never registers
  # it. {ready}{$id} is the Future the seam answers for connection $id.
  package K262::OwnReadyPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $conn = K262::Conn->new(id => ++$self->{n});
    $self->{ready}{ $conn->{id} } = $self->future_class->new;
    Scalar::Util::weaken( $self->{built}{ $conn->{id} } = $conn );
    return $conn;
  }

  sub _connection_ready_future { $_[0]{ready}{ $_[1]{id} } }
  sub _shutdown_connection     { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Readiness registered with the pool, as the EV drivers build theirs: the
  # case shutdown always got right, here as the control.
  package K262::RegisteredPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = K262::Conn->new(%args, id => ++$self->{n});
    Scalar::Util::weaken( $self->{built}{ $conn->{id} } = $conn );
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # The owning storage, as far as the pool asks it: it records the connections
  # it is to set up and to tear down.
  package K262::Storage;
  sub new { bless { set_up => [], torn_down => [] }, $_[0] }
  sub _setup_pool_connection    { push @{ $_[0]{set_up} },    $_[1]{id} }
  sub _teardown_pool_connection { push @{ $_[0]{torn_down} }, $_[1]{id} }
}

sub new_pool {
  my ($class, $fc, %args) = @_;
  my $storage = K262::Storage->new;
  my $errors  = [];
  my $pool = $class->new(
    conninfo     => 'fake',
    size         => 1,
    future_class => $fc,
    storage      => $storage,
    on_error     => sub { push @$errors, $_[0] },
    %args,
  );
  $pool->{errors} = $errors;
  return ($pool, $storage);
}

# The transport's connect completes for connection $id.
sub come_up {
  my ($pool, $id) = @_;
  $pool->{ready}{$id}->done($pool->{built}{$id});
  return;
}

sub failure_of {
  my ($f) = @_;
  return undef unless $f->is_ready && $f->is_failed;
  eval { $f->get };
  return "$@";
}

sub handovers { scalar keys %{ $_[0]{_ready_handovers} || {} } }

sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  $code->($label);
  is_deeply [@warnings], [], "$label: nothing warned";
  return;
}

my $SHUT = qr/Connection pool has been shut down/;

my $have_future = eval { require Future; 1 };

for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {

  # -------------------------------------------------------------------------
  # 1. Still coming up at shutdown.
  # -------------------------------------------------------------------------
  for my $late (qw(done fail)) {
    scenario "$fc, shutdown while a connection comes up on the transport's own readiness, late $late" => sub {
      my $l = shift;
      my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
      my $f     = $pool->acquire;
      my $conn  = $pool->{built}{1};
      my $ready = $pool->{ready}{1};
      ok !$f->is_ready, "$l: the acquire waits for its connection to come up";
      is_deeply $storage->{set_up}, [1], "$l: (the storage was asked to set it up, once)";

      $pool->shutdown;

      is_deeply $storage->{torn_down}, [],
        "$l: it never came up, so no disconnect action runs against it";
      is_deeply $pool->{closed}, [1], "$l: it is closed exactly once";
      like failure_of($f), $SHUT, "$l: the caller fails with the shutdown";
      is handovers($pool), 0, "$l: no hand-over is left behind";
      is $pool->size + $pool->available, 0, "$l: the pool holds nothing";

      ok eval {
        $late eq 'done' ? $ready->done($conn) : $ready->fail("late\n");
        1;
      }, "$l: the transport settling it afterwards does not die" or diag $@;
      is_deeply $storage->{torn_down}, [], "$l: nor bring a disconnect action";
      is_deeply $pool->{closed}, [1], "$l: nor a second close";
      like failure_of($f), $SHUT, "$l: nor change what the caller was told";
      is_deeply $pool->{errors}, [], "$l: and nothing is reported";
    };
  }

  # The control: readiness registered with the pool, which shutdown fails and
  # so always knew to be cold.
  scenario "$fc, shutdown while a connection comes up on a registered readiness" => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::RegisteredPool', $fc);
    my $f = $pool->acquire;

    $pool->shutdown;

    is_deeply $storage->{torn_down}, [], "$l: no disconnect action runs against it";
    is_deeply $pool->{closed}, [1], "$l: it is closed exactly once";
    like failure_of($f), $SHUT, "$l: the caller fails with the shutdown";
  };

  # A fresh spawn handed to a queued caller is coming up like any other.
  scenario "$fc, shutdown while a replacement handed to a queued caller comes up" => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
    my $first = $pool->acquire;
    come_up($pool, 1);
    my $conn   = $first->get;
    my $queued = $pool->acquire;

    $pool->_retire_in_use_connection($conn);
    ok !$queued->is_ready, "$l: the queued caller waits for the replacement to come up";
    is_deeply $pool->{closed}, [1], "$l: (the retired connection was closed)";

    $pool->shutdown;

    is_deeply $storage->{torn_down}, [],
      "$l: no disconnect action runs -- not against the replacement, still cold";
    is_deeply $pool->{closed}, [ 1, 2 ], "$l: the replacement is closed exactly once";
    like failure_of($queued), $SHUT, "$l: the queued caller fails with the shutdown";
  };

  # -------------------------------------------------------------------------
  # 2. A connection that came up gets its disconnect actions.
  # -------------------------------------------------------------------------
  scenario "$fc, shutdown with a connection that came up, idle" => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
    my $f = $pool->acquire;
    come_up($pool, 1);
    $pool->release($f->get);

    $pool->shutdown;
    is_deeply $storage->{torn_down}, [1], "$l: its disconnect actions run, once";
    is_deeply $pool->{closed}, [1], "$l: and it is closed, once";
  };

  scenario "$fc, shutdown with a connection that came up, checked out" => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
    my $f = $pool->acquire;
    come_up($pool, 1);
    my $conn = $f->get;
    is handovers($pool), 0, "$l: its hand-over is settled";

    $pool->shutdown;
    is_deeply $storage->{torn_down}, [1], "$l: its disconnect actions run, once";
    is_deeply $pool->{closed}, [1], "$l: and it is closed, once";
  };

  scenario "$fc, shutdown with one connection up and one coming up" => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc, size => 2);
    my $up = $pool->acquire;
    come_up($pool, 1);
    my $cold = $pool->acquire;
    ok !$cold->is_ready, "$l: the second connection is still coming up";

    $pool->shutdown;
    is_deeply $storage->{torn_down}, [1],
      "$l: disconnect actions run against the one that came up, and only it";
    is_deeply [ sort @{ $pool->{closed} } ], [ 1, 2 ], "$l: both are closed, once each";
    like failure_of($cold), $SHUT, "$l: the caller of the cold one fails with the shutdown";
  };

  # -------------------------------------------------------------------------
  # 3. Not ready again when borrowed from the idle list.
  # -------------------------------------------------------------------------
  scenario "$fc, shutdown while an idle connection the seam holds back is borrowed" => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
    my $f = $pool->acquire;
    come_up($pool, 1);
    $pool->release($f->get);

    # The transport is not done with it: its seam answers a pending Future.
    $pool->{ready}{1} = $fc->new;
    my $again = $pool->acquire;
    ok !$again->is_ready, "$l: the acquire waits for the seam's word";

    $pool->shutdown;
    is_deeply $storage->{torn_down}, [],
      "$l: no disconnect action runs against a connection its transport calls not ready";
    is_deeply $pool->{closed}, [1], "$l: it is closed exactly once";
    like failure_of($again), $SHUT, "$l: the caller fails with the shutdown";
  };

}

# ---------------------------------------------------------------------------
# 1, the caller gave up. A cancel, so Future.pm only.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future not installed: no caller can cancel', 1 unless $have_future;
  my $fc = 'Future';

  scenario 'cancelled, then shutdown while the connection still comes up' => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
    my $f = $pool->acquire;

    $f->cancel;
    is handovers($pool), 1, "$l: the pool keeps the hand-over, the connect runs on";

    $pool->shutdown;
    is_deeply $storage->{torn_down}, [],
      "$l: no disconnect action runs against the connection, still cold";
    is_deeply $pool->{closed}, [1], "$l: it is closed exactly once";
    ok $pool->{ready}{1}->is_cancelled, "$l: the transport's readiness Future is cancelled";
  };

  # Once it came up it went idle -- ready, whatever became of its caller.
  scenario 'cancelled, the connection comes up, then shutdown' => sub {
    my $l = shift;
    my ($pool, $storage) = new_pool('K262::OwnReadyPool', $fc);
    my $f = $pool->acquire;

    $f->cancel;
    come_up($pool, 1);
    is $pool->available, 1, "$l: the connection that came up is idle";

    $pool->shutdown;
    is_deeply $storage->{torn_down}, [1], "$l: its disconnect actions run, once";
    is_deeply $pool->{closed}, [1], "$l: and it is closed, once";
  };
}

is_deeply \@warnings, [], 'nothing warned outside a scenario either';

done_testing;
