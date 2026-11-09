use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k270. The pool settles a caller's Future from inside its own methods:
# release hands the connection to the oldest queued caller with ->done,
# _retire_in_use_connection hands on a fresh spawn or its error, shutdown fails
# everyone still queued, and a connection that comes up is handed over from the
# transport's connect callback. A Future runs its callbacks as it is settled,
# so the caller's code runs INSIDE that pool method -- and may call release,
# acquire or shutdown on the same pool before the method has returned. Only a
# retirement re-entered from _shutdown_connection was pinned
# (t/storage/pool_readiness.t). A pool of one depends on the slot accounting
# holding under exactly this: one slot, and every hand-over nested in the last.
#
# The claims this file pins:
#
#   1. a caller that releases from inside its callback, and acquires again,
#      before or after: every caller is served exactly once, in the order it
#      asked, the pool never counts more connections than its size, and nothing
#      is left queued;
#   2. a caller that shuts the pool down from inside its callback: everyone
#      still queued fails with the shutdown, the connection is closed once, and
#      the pool method it was called from returns;
#   3. a caller failed by shutdown that calls back into the pool gets the
#      shutdown from acquire, and release and shutdown do nothing;
#   4. the same under _retire_in_use_connection, for the caller it serves and
#      for the caller whose spawn died;
#   5. the same as a connection that was still coming up is handed over;
#   6. a callback that dies as release, or _retire_in_use_connection, hands it
#      the connection does not reach whoever called that -- another caller: it
#      goes to on_error, as where a connection is handed over as it comes up
#      (k258), and the connection is handed over all the same (karr k279;
#      t/storage/pool_callback_death.t has the other places the pool settles
#      somebody else's Future);
#   7. an on_error that shuts the pool down while acquire is in it -- told of
#      a liveness check that threw: the acquire fails with the shutdown and
#      spawns nothing into the shut down pool (karr k277).
#
# Mock only, no event loop and no database, against DBIO::Test::Future and
# Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K270R::Conn;
  sub new          { my ($class, %args) = @_; bless {%args}, $class }
  sub fire_connect { $_[0]{on_connect}->() }
}

{
  # Connections usable the moment they exist. {refuse_spawn}{$id} makes the
  # spawn of connection $id die; {probe_dies} makes the liveness check throw.
  package K270R::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $id = ++$self->{n};
    die "spawn $id refused\n" if $self->{refuse_spawn}{$id};
    return K270R::Conn->new(id => $id);
  }

  sub _idle_connection_alive {
    my ($self) = @_;
    die "liveness probe broke\n" if $self->{probe_dies};
    return 1;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Connections still coming up: readiness registered with the pool, the
  # connect fired by the test.
  package K270R::ReadyPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = K270R::Conn->new(%args, id => ++$self->{n});
    push @{ $self->{built} }, $conn;
    return $conn;
  }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
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

# Run $code inside the settling of $f: with the connection when it resolves,
# with (undef, $error) when it fails. The Future derived for it is kept, so no
# chain is lost on the way.
my @keep;
sub on_settled {
  my ($f, $code) = @_;
  my $fc = ref $f;
  push @keep, $f->then(
    sub { $code->($_[0]);        $fc->done },
    sub { $code->(undef, $_[0]); $fc->done },
  );
  return;
}

sub resolved_id {
  my ($f) = @_;
  return $f && $f->is_ready && !$f->is_failed ? $f->get->{id} : undef;
}

sub failure_of {
  my ($f) = @_;
  return undef unless $f && $f->is_ready && $f->is_failed;
  eval { $f->get };
  return "$@";
}

sub queued { scalar @{ $_[0]{_waiters} } }

sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  @keep     = ();
  $code->($label);
  @keep = ();
  is_deeply [@warnings], [], "$label: nothing warned";
  return;
}

my $SHUT = qr/Connection pool has been shut down/;

my $have_future = eval { require Future; 1 };

for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {

  # -------------------------------------------------------------------------
  # 1. Release from inside the callback, and acquire again.
  # -------------------------------------------------------------------------
  scenario "$fc, each caller releases at once and acquires again" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;
    my (@served, @sizes);

    for my $name (qw(A B C)) {
      on_settled($pool->acquire, sub {
        my ($c) = @_;
        push @served, "$name:$c->{id}";
        push @sizes, $pool->size;
        $pool->release($c);
        on_settled($pool->acquire, sub {
          push @served, "$name again:$_[0]{id}";
          push @sizes, $pool->size;
          $pool->release($_[0]);
        });
      });
    }
    is queued($pool), 3, "$l: three callers are queued for the pool of one";

    ok eval { $pool->release($conn); 1 }, "$l: the release they all run under returns"
      or diag $@;

    # Each release finds the next queued caller before the one releasing has
    # asked again, so the first round is served oldest first; a caller asking
    # again finds the connection idle once nobody is queued.
    is_deeply \@served,
      [ 'A:1', 'B:1', 'C:1', 'C again:1', 'B again:1', 'A again:1' ],
      "$l: every caller is served exactly once per acquire, on the one connection";
    is_deeply [ grep { $_ != 1 } @sizes ], [],
      "$l: the pool counts one connection at every hand-over";
    is queued($pool), 0, "$l: nobody is left queued";
    is $pool->size, 1, "$l: the pool of one holds one connection";
    is $pool->available, 1, "$l: idle, once";
    is_deeply $pool->{closed}, undef, "$l: nothing was closed";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
  };

  # Asking again BEFORE releasing queues the caller behind everyone already
  # waiting: the release then serves the queue strictly oldest first.
  scenario "$fc, each caller acquires again and then releases" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;
    my (@served, @queued_at);

    for my $name (qw(A B C)) {
      on_settled($pool->acquire, sub {
        my ($c) = @_;
        push @served, "$name:$c->{id}";
        on_settled($pool->acquire, sub {
          push @served, "$name again:$_[0]{id}";
          $pool->release($_[0]);
        });
        push @queued_at, queued($pool);
        $pool->release($c);
      });
    }

    ok eval { $pool->release($conn); 1 }, "$l: the release they all run under returns"
      or diag $@;

    is_deeply \@served,
      [ 'A:1', 'B:1', 'C:1', 'A again:1', 'B again:1', 'C again:1' ],
      "$l: the queue is served oldest first, a caller asking again goes to its end";
    is_deeply \@queued_at, [ 3, 3, 3 ],
      "$l: (each second acquire was queued, the pool of one being full)";
    is queued($pool), 0, "$l: nobody is left queued";
    is $pool->size, 1, "$l: the pool of one holds one connection";
    is $pool->available, 1, "$l: idle, once";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
  };

  # -------------------------------------------------------------------------
  # 2. shutdown from inside the callback release serves.
  # -------------------------------------------------------------------------
  scenario "$fc, a served caller shuts the pool down" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;

    my ($a, $b, $c) = map { $pool->acquire } 1 .. 3;
    on_settled($a, sub { $pool->shutdown });

    ok eval { $pool->release($conn); 1 }, "$l: the release it runs under returns"
      or diag $@;

    is resolved_id($a), 1, "$l: the caller that shut down had been handed the connection";
    like failure_of($b), $SHUT, "$l: the caller queued behind it fails with the shutdown";
    like failure_of($c), $SHUT, "$l: and so does the one behind that";
    is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
    is $pool->size + $pool->available, 0, "$l: the pool holds nothing";
    is queued($pool), 0, "$l: nobody is left queued";

    like failure_of($pool->acquire), $SHUT, "$l: a later acquire fails with the shutdown";
    ok eval { $pool->release($conn); 1 }, "$l: a later release does not die" or diag $@;
    is $pool->available, 0, "$l: nor take the closed connection back";
    is_deeply $pool->{closed}, [1], "$l: nor close it again";
  };

  # -------------------------------------------------------------------------
  # 3. A caller failed by shutdown calls back into the pool.
  # -------------------------------------------------------------------------
  scenario "$fc, a caller failed by shutdown calls back into the pool" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;

    my ($a, $b) = map { $pool->acquire } 1 .. 2;
    my ($retry, $released, $again);
    on_settled($a, sub {
      $retry    = $pool->acquire;
      $released = eval { $pool->release($conn); 1 };
      $again    = $pool->shutdown;
    });

    ok eval { $pool->shutdown; 1 }, "$l: the shutdown it runs under returns" or diag $@;

    like failure_of($a), $SHUT, "$l: the first queued caller fails with the shutdown";
    like failure_of($retry), $SHUT, "$l: its acquire from the callback fails with it too";
    ok $released, "$l: its release from the callback does not die";
    is $again, 1, "$l: its shutdown from the callback is the no-op of a second shutdown";
    like failure_of($b), $SHUT, "$l: the caller queued behind it still fails with the shutdown";
    is queued($pool), 0, "$l: nothing was queued by the acquire from the callback";
    is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
    is $pool->size + $pool->available, 0, "$l: the pool holds nothing";
    is $pool->{n}, 1, "$l: and spawned nothing";
  };

  # -------------------------------------------------------------------------
  # 4. Under _retire_in_use_connection.
  # -------------------------------------------------------------------------
  scenario "$fc, a caller served by a retirement releases at once" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;
    my (@served, @sizes);

    for my $name (qw(A B)) {
      on_settled($pool->acquire, sub {
        push @served, "$name:$_[0]{id}";
        push @sizes, $pool->size;
        $pool->release($_[0]);
      });
    }

    ok eval { $pool->_retire_in_use_connection($conn); 1 },
      "$l: the retirement they run under returns" or diag $@;

    is_deeply \@served, [ 'A:2', 'B:2' ],
      "$l: the fresh connection goes to the first caller, and from it to the second";
    is_deeply [ grep { $_ != 1 } @sizes ], [], "$l: the pool counts one connection throughout";
    is $pool->{n}, 2, "$l: one replacement was spawned, not one per caller";
    is_deeply $pool->{closed}, [1], "$l: only the retired connection was closed";
    is $pool->available, 1, "$l: the replacement ends idle";
    is queued($pool), 0, "$l: nobody is left queued";
  };

  scenario "$fc, a caller served by a retirement shuts the pool down" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;

    my ($a, $b) = map { $pool->acquire } 1 .. 2;
    on_settled($a, sub { $pool->shutdown });

    ok eval { $pool->_retire_in_use_connection($conn); 1 },
      "$l: the retirement it runs under returns" or diag $@;

    is resolved_id($a), 2, "$l: the caller that shut down had been handed the replacement";
    like failure_of($b), $SHUT, "$l: the caller queued behind it fails with the shutdown";
    is_deeply $pool->{closed}, [ 1, 2 ],
      "$l: the retired connection and the replacement are closed, once each";
    is $pool->{n}, 2, "$l: nothing was spawned for the caller that failed";
    is $pool->size + $pool->available, 0, "$l: the pool holds nothing";
  };

  # The caller whose spawn died asks again from inside its failure: its second
  # acquire takes the free slot, and the caller queued behind it is not lost.
  scenario "$fc, a caller whose replacement spawn died acquires again" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::Pool', $fc);
    my $conn = $pool->acquire->get;
    $pool->{refuse_spawn}{2} = 1;

    my ($a, $b) = map { $pool->acquire } 1 .. 2;
    my ($retry, $size_in_callback);
    on_settled($a, sub {
      $retry = $pool->acquire;
      $size_in_callback = $pool->size;
    });

    ok eval { $pool->_retire_in_use_connection($conn); 1 },
      "$l: the retirement it runs under returns" or diag $@;

    like failure_of($a), qr/spawn 2 refused/, "$l: the caller fails with its spawn's error";
    is resolved_id($retry), 3, "$l: its acquire from the callback spawns into the free slot";
    is $size_in_callback, 1, "$l: (one connection in the pool of one)";
    is $pool->size, 1, "$l: the retirement spawns no second one beside it";
    is $pool->{n}, 3, "$l: -- two spawns in all, the refused one and this";
    ok !$b->is_ready, "$l: the caller queued behind waits for that connection";
    is queued($pool), 1, "$l: still in the queue";

    $pool->release($retry->get);
    is resolved_id($b), 3, "$l: and gets it once it is released -- it is not lost";
    is queued($pool), 0, "$l: nobody is left queued";
    is_deeply $pool->{closed}, [1], "$l: only the retired connection was closed";
  };

  # -------------------------------------------------------------------------
  # 5. As a connection that was still coming up is handed over.
  # -------------------------------------------------------------------------
  scenario "$fc, a caller handed a connection as it comes up releases at once" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::ReadyPool', $fc);
    my @served;

    my $first  = $pool->acquire;
    my $second = $pool->acquire;
    my $conn   = $pool->{built}[0];
    ok !$first->is_ready, "$l: the first caller waits for its connection to come up";
    is queued($pool), 1, "$l: the second is queued behind it";

    on_settled($first, sub { push @served, "first:$_[0]{id}"; $pool->release($_[0]) });
    on_settled($second, sub { push @served, "second:$_[0]{id}" });

    ok eval { $conn->fire_connect; 1 }, "$l: the connect callback it runs under returns"
      or diag $@;

    is_deeply \@served, [ 'first:1', 'second:1' ],
      "$l: the connection goes to its caller, and from its release to the queued one";
    is $pool->size, 1, "$l: the pool of one holds one connection";
    is $pool->available, 0, "$l: borrowed by the second caller";
    is queued($pool), 0, "$l: nobody is left queued";
    is scalar keys %{ $pool->{_ready_handovers} }, 0, "$l: no hand-over is left behind";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
  };

  scenario "$fc, a caller handed a connection as it comes up shuts the pool down" => sub {
    my $l = shift;
    my $pool = new_pool('K270R::ReadyPool', $fc);

    my $first  = $pool->acquire;
    my $second = $pool->acquire;
    my $conn   = $pool->{built}[0];
    on_settled($first, sub { $pool->shutdown });

    ok eval { $conn->fire_connect; 1 }, "$l: the connect callback it runs under returns"
      or diag $@;

    is resolved_id($first), 1, "$l: the caller that shut down had been handed the connection";
    like failure_of($second), $SHUT, "$l: the caller queued behind it fails with the shutdown";
    is_deeply $pool->{closed}, [1], "$l: the connection is closed exactly once";
    is $pool->size + $pool->available, 0, "$l: the pool holds nothing";
    is scalar keys %{ $pool->{_ready_handovers} }, 0, "$l: no hand-over is left behind";
    is_deeply $pool->{errors}, [], "$l: nothing was reported";
  };

  # -------------------------------------------------------------------------
  # 7. An on_error that shuts the pool down while acquire is in it (karr
  #    k277): the report of a liveness check that threw goes to on_error from
  #    inside acquire, which had looked for the shutdown on its way in.
  # -------------------------------------------------------------------------
  scenario "$fc, on_error shuts the pool down while acquire is in it" => sub {
    my $l = shift;
    my $pool;
    $pool = new_pool('K270R::Pool', $fc, on_error => sub { $pool->shutdown });
    $pool->release($pool->acquire->get);
    $pool->{probe_dies} = 1;

    my $f = $pool->acquire;

    like failure_of($f), $SHUT, "$l: the acquire fails with the shutdown";
    is_deeply $pool->{closed}, [1], "$l: the shutdown closes the idle connection";
    is $pool->{n}, 1, "$l: nothing is spawned into the shut down pool";
    is $pool->size, 0, "$l: which holds nothing";
    is queued($pool), 0, "$l: and queues nobody";
    undef $pool;
  };
}

# ---------------------------------------------------------------------------
# 6. A callback that dies as release hands it the connection (karr k279).
#    Future.pm only: on_done runs the callback bare, where ->then turns a death
#    into the failure of the derived Future (as DBIO::Test::Future always does).
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future not installed: no callback can die under release', 1 unless $have_future;
  my $fc = 'Future';
  my %handed = (
    release                   => qr/a released connection was handed to a queued caller/,
    _retire_in_use_connection => qr/a new connection was handed to a queued caller/,
  );

  for my $way (qw(release _retire_in_use_connection)) {
    scenario "$way, the served caller's callback dies" => sub {
      my $l = shift;
      my $pool = new_pool('K270R::Pool', $fc);
      my $conn = $pool->acquire->get;

      my ($a, $b) = map { $pool->acquire } 1 .. 2;
      $a->on_done(sub { die "caller callback died\n" });

      my $lived = eval { $pool->$way($conn); 1 };
      my $death = $@;
      my $id    = $way eq 'release' ? 1 : 2;

      ok $lived, "$l: $way does not die of another caller's callback" or diag $death;
      is scalar @{ $pool->{errors} }, 1, "$l: on_error is told, once";
      like $pool->{errors}[0], qr/$handed{$way}: caller callback died/,
        "$l: of the callback's own error, and of what it died under";

      is resolved_id($a), $id, "$l: the caller has its connection all the same";
      is $pool->size, 1, "$l: the pool of one holds one connection";
      is $pool->available, 0, "$l: borrowed, not idle";
      ok !$b->is_ready, "$l: the caller queued behind it keeps waiting";
      $pool->release($a->get);
      is resolved_id($b), $id, "$l: and is served by the next release";
    };
  }
}

is_deeply \@warnings, [], 'nothing warned outside a scenario either';

done_testing;
