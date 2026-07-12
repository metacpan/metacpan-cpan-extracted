use strict;
use warnings;
use Test::More;

# WP4d (karr #6) -- 'immediate' async mode smoke. The graph *_async methods have
# a sync equivalent (cypher/create_graph/drop_graph), so -- exactly like the core
# CRUD *_async (select_async etc.) -- they degrade under { async => 'immediate' }:
# no event loop, no async backend, the sync method runs in-process and its result
# is wrapped in an immediately-resolved Future. This proves cypher_async resolves
# in-process without a loop. Fully offline (no real database).

use DBIO::Test;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;

# ===========================================================================
# Part A -- FAITHFUL connect { async => 'immediate' }: the storage is in
# immediate mode, builds NO async backend (no event loop), and its future_class
# is the in-process DBIO::Future::Immediate. connect() is lazy; no DB is opened.
# ===========================================================================
{
  package T::AgeImmSchema;
  use base qw( DBIO::PostgreSQL::Age DBIO::Schema );
  use mro 'c3';
}
{
  my $schema = T::AgeImmSchema->connect(
    'dbi:Pg:dbname=dbio_offline_immediate', '', '', { async => 'immediate' },
  );
  my $storage = $schema->storage;

  is $storage->_async_mode, 'immediate', 'the instance is in immediate async mode';
  ok !defined $storage->_async_storage,
    'immediate builds NO embedded async backend (no event loop, no pool)';
  is $storage->future_class, 'DBIO::Future::Immediate',
    'future_class is the in-process immediate Future (no event loop)';
  can_ok $storage, qw( cypher_async create_graph_async drop_graph_async );
  ok !$storage->connected, 'no database was opened for the immediate-mode connect';
}

# ===========================================================================
# Part B -- IN-PROCESS RESOLUTION. Compose the Age layer over a base whose dbh_do
# hands cypher() a canned result, force immediate mode, and prove cypher_async
# returns an ALREADY-ready immediate Future resolving to exactly what sync
# cypher() returns -- with no event loop ever run.
# ===========================================================================
{
  package T::CannedDBH;
  sub new { bless {}, shift }
  sub selectall_arrayref { return [ { node => '"alice"' } ] }
  sub do { return '0E0' }
}
{
  package T::ImmSyncBase;
  use base 'DBIO::PostgreSQL::Storage';
  sub dbh_do { my ($self, $cb) = @_; return $cb->($self, T::CannedDBH->new) }
}

{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  my $composed = DBIO::Storage::Composed->compose('T::ImmSyncBase', ['DBIO::PostgreSQL::Age::Storage']);
  my $storage = $composed->new($schema);

  # Force immediate: mode set, backend explicitly absent (no event loop).
  $storage->_async_mode('immediate');
  $storage->{_async_storage_obj} = undef;

  my @args = ('social', 'MATCH (n) RETURN n', ['node']);

  my $sync_rows = $storage->cypher(@args);
  my $future    = $storage->cypher_async(@args);

  isa_ok $future, 'DBIO::Future::Immediate',
    'cypher_async returns an in-process immediate Future (not an event-loop Future)';
  ok $future->is_ready,
    'the Future is ALREADY ready -- resolved in-process, no event loop needed';

  my $async_rows = $future->get;
  is_deeply $async_rows, $sync_rows,
    'immediate cypher_async resolves to exactly what sync cypher() returns';
  is $async_rows->[0]{node}, '"alice"', '... the canned row came through';

  # create_graph_async / drop_graph_async degrade the same way.
  my $cg = $storage->create_graph_async('social');
  isa_ok $cg, 'DBIO::Future::Immediate', 'create_graph_async also degrades in-process';
  ok $cg->is_ready, '... and is immediately ready (no loop)';

  my $dg = $storage->drop_graph_async('social', 1);
  isa_ok $dg, 'DBIO::Future::Immediate', 'drop_graph_async also degrades in-process';
  ok $dg->is_ready, '... and is immediately ready (no loop)';
}

# ===========================================================================
# Part C -- a PLAIN sync connection (no async mode at all) croaks loudly on
# cypher_async: immediate is opt-in, never a silent auto-degrade.
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  my $composed = DBIO::Storage::Composed->compose('T::ImmSyncBase', ['DBIO::PostgreSQL::Age::Storage']);
  my $storage = $composed->new($schema);
  # no _async_mode set -> a pure sync connection

  my $lived = eval { $storage->cypher_async('g', 'RETURN 1', ['x']); 1 };
  ok !$lived, 'cypher_async on a plain sync connection croaks (no silent degrade)';
  like $@, qr/not an async connection/,
    'the croak explains an async mode must be chosen at connect time';
}

done_testing;
