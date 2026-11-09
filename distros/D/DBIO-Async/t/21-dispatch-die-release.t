use strict;
use warnings;
use Test::More;

use Future;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mocks' sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE regression test for karr k25 (core karr k229): a pooled query whose
# dispatch dies SYNCHRONOUSLY -- before there is a query Future to hang the
# release on -- must still hand its connection back to the pool.
#
# WHY IT MATTERS. _query_async releases the connection from an on_ready on the
# query Future. A transport whose prepare or query croaks at once ("another
# operation is in progress", "not connected") never produces that Future, so
# the on_ready is never attached: the caller sees a failed query, and the
# connection stays checked out for good. Nothing reports it. After N such calls
# a pool of N is wedged and every later query waits forever. Core fixed its
# documented _query_async pattern for this in karr k229; this dist's
# _query_async is the production copy of that pattern.
#
# WHAT IS REAL. The whole transport: _query_async, _release_on_ready,
# _await_query_result (in case 1), the Future::IO watcher seam on a real pipe,
# and the real DBIO::Async::Pool with its idle list, capacity and waiter queue
# -- sized 1, so a leaked connection turns the very next acquire into a waiter
# that nothing will ever wake. The pool only records its releases (the
# t/09 / t/14 wiring). The mocks own the DB-specific seams and nothing else,
# which section 0 pins.
#
# WHAT EACH CASE ASSERTS, the same four things:
#
#  * the query Future fails with the dispatch's OWN error -- the caller is told
#    what went wrong, not something the release path made up;
#  * the connection went back EXACTLY ONCE -- not zero (the leak), and not
#    twice (the same connection on the idle list twice is handed to two
#    concurrent callers);
#  * the next acquire resolves at once, with that same connection -- the pool
#    of one is not wedged;
#  * and a following query runs end to end on it.
#
# Case 1 dies in the driver's _submit_query, under the base _await_query_result.
# Case 2 dies in a driver's own _await_query_result -- the seam is overridable,
# and an override owes no Future->call wrapper, so the release guarantee cannot
# live one level below _query_async.

# --- RecPool21: the real pool, with every release recorded -----------------

{
  package RecPool21;
  use base 'DBIO::Async::Pool';

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# --- DieStorage21: the DB-specific seams over a pipe, dying on request -----

{
  package DieStorage21;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w };
  }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }

  # Same wiring as the skeleton's own pool(), only with the recording pool
  # class (the skeleton hardcodes DBIO::Async::Pool) -- as t/09 and t/14 do.
  sub pool {
    my $self = shift;
    return $self->{pool} ||= RecPool21->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { die "pool error: $_[0]" },
    );
  }

  # Dies synchronously while {submit_dies} counts down, the way a DBD's
  # query call refuses when the connection is busy. Otherwise puts the query
  # on the wire and makes the fd readable for the real Future::IO seam.
  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    if ($self->{submit_dies}) {
      $self->{submit_dies}--;
      die "another operation is in progress\n";
    }
    push @{ $self->{wire} }, { sql => $sql, conn => $conn->{id} };
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row-for', $self->{wire}[-1]{sql} ]);
  }
}

# --- OwnAwait21: a driver with its own _await_query_result -----------------
#
# Dies synchronously while {await_dies} counts down, BEFORE building any
# Future -- exactly what an override that does its own dispatch without a
# Future->call wrapper does when that dispatch refuses.

{
  package OwnAwait21;
  our @ISA = ('DieStorage21');

  sub _await_query_result {
    my $self = shift;
    if ($self->{await_dies}) {
      $self->{await_dies}--;
      die "not connected\n";
    }
    return $self->SUPER::_await_query_result(@_);
  }
}

sub new_storage {
  my ($class, %dies) = @_;
  my $storage = $class->new(undef);
  $storage->{_next_id} = 0;
  $storage->{wire}     = [];
  $storage->{$_}       = $dies{$_} for keys %dies;
  # pool_size 1: the failed query held the pool's ONLY connection, so the next
  # acquire can only be that connection coming back -- or a waiter forever.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# Drive the loop until the Future settles, without dying on a failure.
sub settle { my $f = shift; eval { $f->get }; return $f }

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion its meaning: the mocks
#    override the DB-specific seams and NOTHING of the release path. Compare
#    the resolved code refs -- the only probe that tells an inherited method
#    from an overridden one (the same probe t/12 uses).
# ---------------------------------------------------------------------------

for my $seam (qw(_query_async _release_on_ready _await_query_result)) {
  is refaddr(DieStorage21->can($seam)), refaddr(DBIO::Async::Storage->can($seam)),
    "DieStorage21 does NOT override $seam -- the transport itself runs";
}
for my $seam (qw(_query_async _release_on_ready)) {
  is refaddr(OwnAwait21->can($seam)), refaddr(DBIO::Async::Storage->can($seam)),
    "OwnAwait21 does NOT override $seam -- only the dispatch seam is its own";
}
isnt refaddr(OwnAwait21->can('_await_query_result')),
  refaddr(DBIO::Async::Storage->can('_await_query_result')),
  'OwnAwait21 DOES override _await_query_result -- the case 2 premise';

# ---------------------------------------------------------------------------
# The four assertions of the header, shared by both cases.
# ---------------------------------------------------------------------------

sub dispatch_die_releases {
  my ($label, $storage, $error_re) = @_;
  my $pool = $storage->pool;

  my $f = $storage->_query_async('SELECT 1', []);

  ok $f->is_ready && $f->is_failed,
    "$label: the query Future is failed at once -- the dispatch died";
  like scalar($f->failure // ''), $error_re,
    "$label: ... with the dispatch's own error";
  is scalar @{ $storage->{wire} }, 0,
    "$label: ... and nothing reached the wire";

  is_deeply $pool->{release_log} // [], [1],
    "$label: the connection went back to the pool exactly once";
  is $pool->available, 1,
    "$label: ... and sits on the idle list once";

  my $next = $pool->acquire;
  ok $next->is_ready && $next->is_done,
    "$label: the next acquire resolves at once -- the pool of one is not wedged";
  is $next->is_done ? $next->get->{id} : undef, 1,
    "$label: ... with the same connection (nothing was retired or respawned)";
  $pool->release($next->get) if $next->is_done;

  my $released = scalar @{ $pool->{release_log} // [] };
  my $g = settle($storage->_query_async('SELECT 2', []));
  ok $g->is_done, "$label: a following query runs on the pool of one";
  is_deeply $g->is_done ? $g->get : undef, [ 'row-for', 'SELECT 2' ],
    "$label: ... and resolves with what the connection answered";
  is scalar @{ $pool->{release_log} // [] }, $released + 1,
    "$label: ... releasing its connection once, as ever";
}

# ---------------------------------------------------------------------------
# 1. The driver's _submit_query dies, under the base _await_query_result.
# ---------------------------------------------------------------------------

dispatch_die_releases(
  '_submit_query dies',
  new_storage('DieStorage21', submit_dies => 1),
  qr/another operation is in progress/,
);

# ---------------------------------------------------------------------------
# 2. A driver's own _await_query_result dies before building a Future.
# ---------------------------------------------------------------------------

dispatch_die_releases(
  'own _await_query_result dies',
  new_storage('OwnAwait21', await_dies => 1),
  qr/not connected/,
);

done_testing;
