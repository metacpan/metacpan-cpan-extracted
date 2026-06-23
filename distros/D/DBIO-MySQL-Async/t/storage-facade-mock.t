use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::Async::Storage;
use DBIO::MySQL::Async::QueryExecutor;

# OFFLINE facade test. This is the path that was NEVER exercised before:
# driving the public storage methods (select_async/insert_async/... and
# their sync wrappers) end-to-end through a pool whose acquire() returns a
# DONE Future — exactly as DBIO::Storage::PoolBase::acquire does.
#
# Before the fix, the storage did `my $mdb = $self->pool->acquire;` and
# handed that Future straight to the executor. The executor would then call
# `$future->query(...)` — a Future has no query() method — so against a real
# connection every CRUD op blew up. These mocks reproduce that contract: a
# real EV::MariaDB-shaped connection has ->query; a Future does not.

# A fake connection that records the queries it is asked to run. Crucially
# it ONLY has ->query — if the storage hands a Future here instead of a
# connection, the call dies (a Future has no ->query), catching BUG 1.
{
  package FakeConn;
  sub new { bless { id => $_[1], log => [] }, $_[0] }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{log} }, $sql;
    # Synchronous callback with canned rows, mimicking EV::MariaDB.
    return unless $cb;
    if ($sql =~ /LAST_INSERT_ID/) {
      $cb->([[ 42 ]], undef);
    } elsif ($sql =~ /^SELECT/) {
      $cb->([[ 1, 'row' ]], undef);
    } else {
      # INSERT/UPDATE/DELETE: affected-rows shape
      $cb->([], undef);
    }
  }
}

# A pool that returns a DONE Future from acquire (the PoolBase contract)
# and records acquire/release so we can assert no connection leaks and that
# the waiter-queue path (pending Future) is honored.
{
  package FakePool;
  use Future ();
  sub new {
    bless {
      conns      => [],
      next_id    => 0,
      acquired   => 0,
      released   => 0,
      queue_mode => 0,     # when true, acquire returns a PENDING future
      pending    => undef,
    }, $_[0];
  }
  sub acquire {
    my $self = shift;
    $self->{acquired}++;
    if ($self->{queue_mode}) {
      # Simulate a full pool: hand back a pending future and stash it so
      # the test can resolve it later, proving the storage chains off the
      # Future rather than discarding it.
      my $f = Future->new;
      $self->{pending} = $f;
      return $f;
    }
    my $conn = FakeConn->new(++$self->{next_id});
    push @{ $self->{conns} }, $conn;
    return Future->done($conn);
  }
  sub acquire_txn { $_[0]->acquire }
  sub release {
    my ($self, $conn) = @_;
    $self->{released}++;
    push @{ $self->{released_conns} //= [] }, $conn;
  }
  sub shutdown { }
  sub available { 1 }
}

# Build a storage wired to the fake pool + the REAL QueryExecutor, so the
# executor genuinely calls ->query on whatever the storage hands it.
sub build_storage {
  my $storage = DBIO::MySQL::Async::Storage->new(undef);
  my $pool = FakePool->new;
  $storage->{pool}     = $pool;
  $storage->{executor} = DBIO::MySQL::Async::QueryExecutor->new(pool => $pool);
  return ($storage, $pool);
}

# --- select_async: conn is unpacked from the Future, executor gets the conn

{
  my ($storage, $pool) = build_storage;
  my $f = $storage->select_async('artist', '*', { id => 1 });
  isa_ok $f, 'Future', 'select_async returns a Future';
  ok $f->is_ready, 'select_async resolves (conn was unpacked from acquire Future)';
  my @rows = $f->get;
  is_deeply \@rows, [[ 1, 'row' ]], 'select_async returns the rows from the real conn';
  is $pool->{acquired}, 1, 'select_async acquired exactly one connection';
  is $pool->{released}, 1, 'select_async released the connection after completion';
  is $pool->{conns}[0]{log}[0], 'SELECT * FROM `artist` WHERE ( `id` = ? )',
    'executor ran the query on the real conn (not the Future)'
    or diag explain $pool->{conns}[0]{log};
}

# --- select_single_async: first-row post-processing on the facade path

{
  my ($storage, $pool) = build_storage;
  my $row = $storage->select_single_async('artist', '*', { id => 1 })->get;
  is_deeply $row, [ 1, 'row' ], 'select_single_async returns the first row';
  is $pool->{released}, 1, 'select_single_async released its connection';
}

# --- insert_async: INSERT + LAST_INSERT_ID() on the SAME conn, then release

{
  my ($storage, $pool) = build_storage;
  my $f = $storage->insert_async('artist', { name => 'Tom' });
  ok $f->is_ready, 'insert_async resolves through the acquire Future';
  $f->get;
  is $storage->last_insert_id, 42, 'last_insert_id captured from LAST_INSERT_ID()';
  is $pool->{acquired}, 1, 'insert_async acquired exactly one connection';
  is $pool->{released}, 1, 'insert_async released the connection once, after LII';
  my $conn = $pool->{conns}[0];
  is scalar(@{ $conn->{log} }), 2, 'INSERT and LAST_INSERT_ID() ran on one conn';
  like $conn->{log}[0], qr/^INSERT INTO `artist`/, 'first query is the INSERT';
  is $conn->{log}[1], 'SELECT LAST_INSERT_ID()',
    'LAST_INSERT_ID ran on the SAME conn as the INSERT';
}

# --- update_async / delete_async: facade path, conn unpacked + released

for my $case (
  [ update_async => sub { $_[0]->update_async('artist', { name => 'X' }, { id => 1 }) }, qr/^UPDATE `artist`/ ],
  [ delete_async => sub { $_[0]->delete_async('artist', { id => 1 }) },                  qr/^DELETE FROM `artist`/ ],
) {
  my ($name, $call, $re) = @$case;
  my ($storage, $pool) = build_storage;
  my $f = $call->($storage);
  ok $f->is_ready, "$name resolves through the acquire Future";
  $f->get;
  is $pool->{acquired}, 1, "$name acquired one connection";
  is $pool->{released}, 1, "$name released the connection after completion";
  like $pool->{conns}[0]{log}[0], $re, "$name ran its SQL on the real conn";
}

# --- sync wrappers block via ->get and still work through the facade

{
  my ($storage, $pool) = build_storage;
  my @rows = $storage->select('artist', '*', { id => 1 });
  is_deeply \@rows, [[ 1, 'row' ]], 'sync select() works through the facade';
  is $pool->{released}, 1, 'sync select() released its connection';
}

# --- failure path: a query error must still release the connection (no leak)

{
  package FailConn;
  sub new { bless {}, $_[0] }
  sub query { my ($self, $sql, $cb) = @_; $cb->(undef, 'boom') if $cb }
}
{
  my ($storage, $pool) = build_storage;
  # Swap acquire to hand back a failing connection.
  no warnings 'redefine';
  local *FakePool::acquire = sub {
    my $self = shift;
    $self->{acquired}++;
    return Future->done(FailConn->new);
  };
  my $f = $storage->select_async('artist', '*', { id => 1 });
  ok $f->is_ready, 'select_async settles even on query error';
  ok $f->is_failed, 'select_async fails when the conn reports an error';
  is $pool->{released}, 1, 'connection released on the failure path (no leak)';
}

# --- waiter-queue: acquire returns a PENDING future; storage must chain off
#     it, not discard it. Before the fix, the pending Future was thrown away
#     and the query silently never ran.

{
  my ($storage, $pool) = build_storage;
  $pool->{queue_mode} = 1;
  my $f = $storage->select_async('artist', '*', { id => 1 });
  isa_ok $f, 'Future', 'select_async returns a Future while pool is full';
  ok !$f->is_ready, 'result Future is pending until the pool hands over a conn';

  # Now a connection frees up: resolve the pending acquire Future with a
  # real conn, exactly as PoolBase::release would for a queued waiter.
  $pool->{queue_mode} = 0;
  my $conn = FakeConn->new(99);
  push @{ $pool->{conns} }, $conn;
  $pool->{pending}->done($conn);

  ok $f->is_ready, 'result Future resolves once the waiter gets a connection';
  my @rows = $f->get;
  is_deeply \@rows, [[ 1, 'row' ]], 'queued query ran on the handed-over conn';
  is $conn->{log}[0], 'SELECT * FROM `artist` WHERE ( `id` = ? )',
    'the previously-queued query actually executed (waiter not discarded)';
  is $pool->{released}, 1, 'queued connection released after the query';
}

done_testing;
