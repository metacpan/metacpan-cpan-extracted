use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k270. Core's own callers release a connection exactly once, and that is
# pinned where they do it (t/test/19_async_deploy.t, t/test/43_async_txn_end.t).
# What the pool itself did with a second release of one connection was not:
# release took any connection the pool holds, without asking where it was.
#
#   * Released twice in a row, the connection went onto the idle list twice.
#     The pool then reported more idle connections than it holds, and handed
#     the one session to two callers, whose statements and transactions
#     interleave on it.
#
# The claims this file pins:
#
#   1. A connection that is already idle is not taken a second time. The second
#      release changes nothing -- not the idle list, not its order -- and says
#      nothing: like a release of a connection the pool does not hold, and like
#      a release after shutdown, it is a silent no-op.
#   2. A second release that arrives after the connection has gone on -- handed
#      to a queued caller by the first release, or borrowed again from the idle
#      list -- looks exactly like the release of its current holder, unless it
#      carries the lease of its borrow: $pool->_lease($conn) right after the
#      acquire, release($conn, $lease). One whose lease is no longer the
#      connection's is a silent no-op (karr k275). Without a lease, release is
#      what it always was.
#
# Mock only, against DBIO::Test::Future and Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K270::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K270::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection   { K270::Conn->new(++$_[0]{n}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

sub new_pool {
  my ($fc, $size) = @_;
  my $errors = [];
  my $pool = K270::Pool->new(
    conninfo     => 'fake',
    size         => $size,
    future_class => $fc,
    on_error     => sub { push @$errors, $_[0] },
  );
  $pool->{errors} = $errors;
  return $pool;
}

sub idle_ids { [ map { $_->{id} } @{ $_[0]{_idle} } ] }

# The id of the connection $f resolved with, or undef while it is pending.
sub resolved_id { $_[0]->is_ready && !$_[0]->is_failed ? $_[0]->get->{id} : undef }

my $have_future = eval { require Future; 1 };

for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {

  # -------------------------------------------------------------------------
  # 1. Released twice in a row, nothing in between.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, released twice";
    @warnings = ();
    my $pool = new_pool($fc, 2);
    my $conn = $pool->acquire->get;

    $pool->release($conn);
    my $lived = eval { $pool->release($conn); 1 };

    ok $lived, "$l: the second release does not die" or diag $@;
    is $pool->size, 1, "$l: the pool holds one connection";
    is $pool->available, 1, "$l: and reports one idle -- not more idle than it holds";
    is_deeply idle_ids($pool), [1], "$l: the connection is on the idle list once";
    is_deeply [@warnings], [], "$l: the second release does not warn";
    is_deeply $pool->{errors}, [], "$l: nor report anything to on_error";

    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    is resolved_id($first), 1, "$l: the next acquire gets the idle connection";
    is resolved_id($second), 2,
      "$l: the one after it a connection of its own -- not the same session again";
    is $pool->size, 2, "$l: (spawned, the pool had room)";

    $pool->release($_) for $first->get, $second->get;
    is $pool->available, 2, "$l: both come back, and available stays within size";
  }

  # A pool of one makes the same thing visible as a caller that must wait.
  {
    my $l = "$fc, released twice, pool of one";
    my $pool = new_pool($fc, 1);
    my $conn = $pool->acquire->get;
    $pool->release($conn) for 1 .. 3;

    my ($first, $second) = map { $pool->acquire } 1 .. 2;
    is resolved_id($first), 1, "$l: the first acquire gets the connection";
    ok !$second->is_ready,
      "$l: the second waits for it -- it is not handed the same session";

    $pool->release($first->get);
    is resolved_id($second), 1, "$l: and gets it once the first caller releases";
  }

  # The second release does not move the connection to the back of the idle
  # list either: acquire hands out the connection that has been idle longest.
  {
    my $l = "$fc, released twice, two idle";
    my $pool = new_pool($fc, 2);
    my ($one, $two) = map { $pool->acquire->get } 1 .. 2;

    $pool->release($one);
    $pool->release($two);
    $pool->release($one);

    is_deeply idle_ids($pool), [1, 2], "$l: the idle list keeps its order";
    is $pool->available, 2, "$l: and holds each connection once";
  }

  # -------------------------------------------------------------------------
  # 2. The second release arrives after the connection has gone on (karr k275).
  #
  # The pool counts one lease per borrow. A holder asks for it right after the
  # acquire resolves ($pool->_lease($conn)) and hands it back as the second
  # argument of release. A release whose lease is no longer the connection's --
  # the connection went to a queued caller, or was borrowed again from idle --
  # is not its current holder's and is a silent no-op, like the one of section
  # 1. A release without a lease behaves as it always did.
  # -------------------------------------------------------------------------

  # Handed to a queued caller by the first release; a second caller is queued.
  {
    my $l = "$fc, released again after it was handed to a queued caller";
    @warnings = ();
    my $pool = new_pool($fc, 1);
    my $conn = $pool->acquire->get;
    my $lease = $pool->_lease($conn);
    my ($first, $second) = map { $pool->acquire } 1 .. 2;

    $pool->release($conn, $lease);
    is resolved_id($first), 1, "$l: the first release hands it to the oldest queued caller";
    ok !$second->is_ready, "$l: the caller behind it keeps waiting";
    my $lease2 = $pool->_lease($first->get);
    isnt $lease2, $lease, "$l: the new holder's lease is not the first holder's";

    my $lived = eval { $pool->release($conn, $lease); 1 };
    ok $lived, "$l: the stale release does not die" or diag $@;
    ok !$second->is_ready, "$l: the caller behind it keeps waiting";
    is_deeply [@warnings], [], "$l: the stale release does not warn";
    is_deeply $pool->{errors}, [], "$l: nor report anything to on_error";

    $pool->release($conn, $lease2);
    is resolved_id($second), 1, "$l: the holder's own release hands it on";
    $pool->shutdown;
  }

  # Handed to a queued caller, and nobody else is queued.
  {
    my $l = "$fc, released again after it was handed on, nobody else queued";
    my $pool = new_pool($fc, 1);
    my $conn = $pool->acquire->get;
    my $lease = $pool->_lease($conn);
    my $holder = $pool->acquire;

    $pool->release($conn, $lease);
    is resolved_id($holder), 1, "$l: the first release hands it to the queued caller";
    my $lease2 = $pool->_lease($holder->get);

    $pool->release($conn, $lease);
    my $available = $pool->available;
    my $next = $pool->acquire;

    is $available, 0, "$l: the connection is not idle, its holder has it";
    ok !$next->is_ready, "$l: the next acquire waits for the holder's release";

    $pool->release($conn, $lease2);
    is resolved_id($next), 1, "$l: and gets it when the holder releases";
    $pool->shutdown;
  }

  # Idled by the first release and borrowed again before the second arrives.
  {
    my $l = "$fc, released again after it was borrowed again";
    my $pool = new_pool($fc, 1);
    my $conn = $pool->acquire->get;
    my $lease = $pool->_lease($conn);

    $pool->release($conn, $lease);
    my $holder = $pool->acquire;
    is resolved_id($holder), 1, "$l: the idle connection is borrowed again";
    my $lease2 = $pool->_lease($holder->get);

    $pool->release($conn, $lease);
    my $next = $pool->acquire;

    ok !$next->is_ready, "$l: the next acquire waits for the holder's release";
    is $pool->available, 0, "$l: the connection is not idle";

    $pool->release($conn, $lease2);
    is resolved_id($next), 1, "$l: and gets it when the holder releases";
    $pool->shutdown;
  }

  # A release without a lease behaves as it always did: it is taken for the
  # current holder's.
  {
    my $l = "$fc, released again without a lease";
    my $pool = new_pool($fc, 1);
    my $conn = $pool->acquire->get;
    my $holder = $pool->acquire;

    $pool->release($conn);
    is resolved_id($holder), 1, "$l: handed to the queued caller";
    $pool->release($conn);
    is $pool->available, 1, "$l: a second release without a lease is taken as before";
    $pool->shutdown;
  }

  # The lease of a release is the connection's own, taken from this pool.
  {
    my $l = "$fc, lease edge cases";
    @warnings = ();
    my $pool = new_pool($fc, 1);
    my $conn = $pool->acquire->get;

    ok defined $pool->_lease($conn), "$l: a held connection has a lease";
    is $pool->_lease($conn), $pool->_lease($conn), "$l: asking twice gives the same lease";
    is $pool->_lease(K270::Conn->new(99)), undef, "$l: a connection the pool does not hold has none";

    my $lease = $pool->_lease($conn);
    $pool->release($conn, $lease . 'x');
    is $pool->available, 0, "$l: a lease that was never the connection's releases nothing";
    $pool->release($conn, $lease);
    is $pool->available, 1, "$l: the right lease does";

    $pool->shutdown;
    ok eval { $pool->release($conn, $lease); 1 }, "$l: a leased release after shutdown is a no-op";
    is_deeply [@warnings], [], "$l: and nothing was warned";
  }
}

is_deeply \@warnings, [], 'nothing warned along the way';

done_testing;
