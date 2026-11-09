use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# $rs->upsert_async, the async twin of $rs->upsert (ADR 0036).
#
# Core's job is the dispatch, not re-testing SQL generation: option
# validation, conflict-target rules and the capability gate all route through
# the same private _upsert_prepare() the synchronous upsert() uses (verified
# below by checking the async and sync paths refuse identically), so the
# structural coverage already in t/resultset/upsert.t is not duplicated here.
# What IS specific to upsert_async is exercised: real non-blocking dispatch
# for the single-statement row_or_undef/row_or_die/void shapes, and the
# documented sync-degrade for the shapes/paths that cannot be a single
# insert_async (count, cascade, fallback).

# Same driver-SQLMaker stand-in as t/resultset/upsert.t: consumes
# $options->{on_conflict} and marks the statement, so the on_conflict
# structure is known to have crossed the seam.
{
  package DBIO::Test::UpsertAsyncSQLMaker;
  use base 'DBIO::SQLMaker';

  sub insert {
    my ($self, $table, $data, $options) = @_;

    my $on_conflict = $options ? delete $options->{on_conflict} : undef;
    return $self->next::method($table, $data, $options) unless $on_conflict;

    my ($sql, @bind) = $self->next::method($table, $data, $options);
    return ("$sql /*CONFLICT*/", @bind);
  }
}

# A mock async backend whose insert_async delegates to the REAL (mock) sync
# DBIO::Test::Storage -- same object as $schema->storage -- so it shares every
# mock/capture set up on it. Modelled on t/resultset/async_backend.t's
# My::Mock::RowBackend; any difference between sync upsert() and async
# upsert_async() output on this backend is a bug in the RS async dispatch,
# not in how the row was produced.
{
  package My::Mock::UpsertBackend;
  use base 'DBIO::Storage::Async';

  sub new { my ($c, $s) = @_; bless { schema => $s, calls => [] }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { 1 }

  sub _sync { $_[0]{schema}->storage }

  sub insert_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'insert';
    my $cols = $self->_sync->insert(@args);
    return DBIO::Future::Immediate->done($cols);
  }
}

DBIO::Storage::DBI->register_async_mode( upsertmock => 'My::Mock::UpsertBackend' );

sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

sub upsert_async_schema {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'upsertmock');
  $storage->sql_maker_class('DBIO::Test::UpsertAsyncSQLMaker');
  $storage->_use_supports_upsert(1);
  $storage->reset_captured;
  return $schema;
}

# ---------------------------------------------------------------------------
# row_or_undef (default): real async dispatch through the backend's
# insert_async, inflated in the Future's ->then.
# ---------------------------------------------------------------------------
{
  my $s       = upsert_async_schema();
  my $backend = $s->storage->_async_storage;
  $s->storage->_use_insert_returning(1);
  $s->storage->mock(qr/INSERT INTO "artist"/, [ [ 42 ] ]);

  my $f = $s->resultset('Artist')->upsert_async(
    { name => 'Named', rank => 1 }, { conflict_target => 'name' },
  );
  isa_ok $f, 'DBIO::Future::Immediate', 'upsert_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my $row = $f->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'row_or_undef resolves with a Result';
  is $row->artistid, 42, 'the identity the engine returned is folded in';
  ok $row->in_storage, 'the returned Result is marked stored';
  ok !$row->is_changed, 'and clean';

  is_deeply $backend->{calls}, ['insert'],
    'routed through the backend insert_async, not a sync degrade';

  my @q = $s->storage->captured_queries;
  is scalar @q, 1, 'an upsert is exactly one statement';
  like $q[0]{sql}, qr/RETURNING "artistid"/, 'the RETURNING tail was requested';
  like $q[0]{sql}, qr{/\*CONFLICT\*/}, 'the on_conflict structure reached the SQLMaker';
}

# ---------------------------------------------------------------------------
# void: Future resolves with nothing, one round-trip through insert_async.
# ---------------------------------------------------------------------------
{
  my $s       = upsert_async_schema();
  my $backend = $s->storage->_async_storage;
  $s->storage->_use_insert_returning(1);

  my @ret = $s->resultset('Artist')->upsert_async(
    { name => 'Named', rank => 1 }, { conflict_target => 'name', result => 'void' },
  )->get;

  is scalar @ret, 0, 'result => void resolves with nothing';
  is_deeply $backend->{calls}, ['insert'], 'still routed through insert_async';

  my @q = $s->storage->captured_queries;
  is scalar @q, 1, 'still exactly one statement';
  unlike $q[0]{sql}, qr/RETURNING/i, 'result => void emits no RETURNING tail';
}

# ---------------------------------------------------------------------------
# row_or_die: no nameable row -- the Future FAILS, it does not resolve undef.
# ---------------------------------------------------------------------------
{
  my $s = upsert_async_schema();

  my $f = $s->resultset('NoPrimaryKey')->upsert_async(
    { foo => 1, bar => 2, baz => 3 },
    { conflict_target => [qw/foo bar/], result => 'row_or_die' },
  );
  ok $f->is_failed, 'row_or_die over async fails the Future rather than throwing bare';
  throws_ok { $f->get } qr/row_or_die.*did not name it/s,
    'the failure carries the same message the sync path throws';
}

# ---------------------------------------------------------------------------
# result => count: no async transport contract carries an affected-row count
# for INSERT SQL -- documented sync-degrade, still resolves correctly, and
# does NOT touch the backend at all (it never reaches insert_async).
# ---------------------------------------------------------------------------
{
  my $s       = upsert_async_schema();
  my $backend = $s->storage->_async_storage;
  $s->storage->_use_insert_returning(1);

  my $count = $s->resultset('Artist')->upsert_async(
    { name => 'Named', rank => 1 }, { conflict_target => 'name', result => 'count' },
  )->get;

  is $count, 1, 'result => count resolves with the affected-row count';
  is_deeply $backend->{calls}, [], 'count degrades to sync -- insert_async was never called';

  my @q = $s->storage->captured_queries;
  is scalar @q, 1, 'the sync-degrade path is still exactly one statement';
}

# ---------------------------------------------------------------------------
# nested relationship data (cascade): degrades to the synchronous
# _upsert_cascade, exactly like create_async's related-object multi-create.
# ---------------------------------------------------------------------------
{
  my $s       = upsert_async_schema();
  my $backend = $s->storage->_async_storage;
  $s->storage->_use_insert_returning(1);
  $s->storage->mock(qr/INSERT INTO "artist"/, [ [ 42 ] ]);
  $s->storage->mock(qr/INSERT INTO "cd"/,     [ [ 99 ] ]);

  my $f = $s->resultset('Artist')->upsert_async(
    { name => 'Cascaded', rank => 1, cds => [ { title => 'T', year => 2020 } ] },
    { conflict_target => 'name', relations => { cds => { conflict_target => [qw/artist title/] } } },
  );
  ok $f->is_ready, 'a cascade upsert_async still resolves (synchronously, under the hood)';
  my $row = $f->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'the cascade resolves with the top-level Result';
  is_deeply $backend->{calls}, [], 'the cascade never touches the async backend directly';
}

# ---------------------------------------------------------------------------
# fallback => 'update_or_create': a client-side two-step, degrades to sync.
# ---------------------------------------------------------------------------
{
  my $s       = DBIO::Test->init_schema;
  my $storage = set_mode($s->storage, 'upsertmock');
  my $backend = $storage->_async_storage;
  # No _use_supports_upsert(1) -- this is exactly the unsupported-engine case.

  my $row = $s->resultset('Artist')->upsert_async(
    { artistid => 5, name => 'Fallback' }, { fallback => 'update_or_create' },
  )->get;

  isa_ok $row, 'DBIO::Test::Schema::Artist', 'fallback resolves with a Result';
  is $row->name, 'Fallback', 'fallback wrote via update_or_create';
  is_deeply $backend->{calls}, [], 'the fallback never touches the async backend directly';
}

# ---------------------------------------------------------------------------
# Validation shares _upsert_prepare with sync upsert() -- an invalid call
# throws synchronously and identically, not as a failed Future.
# ---------------------------------------------------------------------------
{
  my $s = upsert_async_schema();

  throws_ok { $s->resultset('Artist')->upsert_async({ name => 'x' }, { bogus => 1 }) }
    qr/unknown option\(s\) 'bogus'/,
    'upsert_async validates options synchronously, same message as sync upsert()';

  throws_ok { $s->resultset('Artist')->upsert_async({}, {}) }
    qr/non-empty hashref/,
    'upsert_async refuses empty data synchronously, same as sync upsert()';
}

# No capability, no fallback -- both refuse identically (and synchronously).
{
  my $s       = DBIO::Test->init_schema;
  my $storage = set_mode($s->storage, 'upsertmock');

  throws_ok { $s->resultset('Artist')->upsert_async({ artistid => 1, name => 'x' }) }
    qr/does not declare the supports_upsert capability/,
    'upsert_async refuses on an unsupported engine exactly like sync upsert()';
}

# ---------------------------------------------------------------------------
# sync instance: *_async croaks (no silent degrade) -- same contract as every
# other ResultSet/Row *_async method (ADR 0030/0031).
# ---------------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, undef);   # undef mode == sync
  $storage->_use_supports_upsert(1);

  throws_ok { $schema->resultset('Artist')->upsert_async({ artistid => 1, name => 'x' }) }
    qr/not an async connection/,
    'upsert_async on a sync instance croaks';
}

# ---------------------------------------------------------------------------
# immediate mode: degrades to the synchronous upsert() wrapped in an
# immediately-resolved Future, still fully parity-correct.
# ---------------------------------------------------------------------------
{
  my $schema = DBIO::Test->init_schema;   # mock default: 'immediate'
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';
  $schema->storage->sql_maker_class('DBIO::Test::UpsertAsyncSQLMaker');
  $schema->storage->_use_supports_upsert(1);
  $schema->storage->_use_insert_returning(1);
  $schema->storage->mock(qr/INSERT INTO "artist"/, [ [ 42 ] ]);

  my $f = $schema->resultset('Artist')->upsert_async(
    { name => 'Named', rank => 1 }, { conflict_target => 'name' },
  );
  ok $f->is_ready, 'immediate mode resolves immediately';
  my $row = $f->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'immediate mode still resolves a Result';
  is $row->artistid, 42, 'immediate mode still folds in the identity';
}

done_testing;
