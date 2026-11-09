use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0031's own Consequences section named Row-level update_async/delete_async
# as "not added (no caller); only Row::insert_async was needed (by
# create_async). Same pattern when wanted." DBIO-Valiant's validated async
# writes are that caller now. This file gives every Row/ResultSet operation
# ADR 0031 left out a real, backend-routed async counterpart: the row-level
# primitives (update_async/delete_async), the cheap wins that fall out of
# find_async (get_from_storage_async/discard_changes_async/
# update_or_insert_async/count_literal_async), the find_async-composed
# composites (find_or_new_async/find_or_create_async/update_or_create_async/
# update_or_new_async), and results_exist_async.
#
# All of this runs on the mock storage -- no real DB, no event loop.

# --- A mock async backend that delegates to the sync storage ------------------
# Same shape as t/resultset/async_backend.t's My::Mock::RowBackend, extended
# with update_async/delete_async (which that file's mock never needed).
{
  package My::Mock::ParityBackend;
  use base 'DBIO::Storage::Async';

  sub new { my ($c, $s) = @_; bless { schema => $s, calls => [] }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { 1 }

  sub _sync { $_[0]{schema}->storage }

  sub select_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'select';
    my @rows = $self->_sync->select(@args)->all;
    return DBIO::Future::Immediate->done(@rows);
  }

  sub select_single_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'select_single';
    my @row = $self->_sync->select_single(@args);
    return DBIO::Future::Immediate->done( @row ? [ @row ] : undef );
  }

  sub insert_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'insert';
    my $cols = $self->_sync->insert(@args);
    return DBIO::Future::Immediate->done($cols);
  }

  sub update_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'update';
    my $rows = $self->_sync->update(@args);
    return DBIO::Future::Immediate->done($rows);
  }

  sub delete_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'delete';
    my $rows = $self->_sync->delete(@args);
    return DBIO::Future::Immediate->done($rows);
  }

  # The transport seam for an already-rendered statement (ADR 0037 section 2:
  # results_exist executes the _exists_value_sql hook's complete statement,
  # which has no ident/select/where to hand to the CRUD entry points). Routed
  # through the sync fake storage so the statement lands in the same captured
  # query log the sync path uses -- that is what makes SQL parity assertable.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{$self->{calls}}, 'query';
    my (undef, $sth) = $self->_sync->_execute_rendered($sql, $bind);
    return DBIO::Future::Immediate->done(@{ $sth->fetchall_arrayref || [] });
  }
}

DBIO::Storage::DBI->register_async_mode( parityasyncmock => 'My::Mock::ParityBackend' );

# Set the chosen mode on a mock storage exactly as connect would, clearing the
# resolved-backend cache. Mirrors the helper in t/resultset/async_backend.t.
sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# --- A local schema carrying an OnColumnChange hook -------------------------
# Isolated from DBIO::Test::Schema (which registers no hooks) so registering
# before/after callbacks here can't leak into other tests. Mirrors the
# TestOCC::Schema fixture in t/helpers/row_helpers_storage.t.
{
  package TestUAOCC::Changes;
  our @LOG;
  sub reset { @LOG = () }
  sub all   { @LOG }
}

{
  package TestUAOCC::Schema;
  use base 'DBIO::Schema';
}

{
  package TestUAOCC::Schema::Result::Account;
  use base 'DBIO::Core';

  __PACKAGE__->table('account');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1,
    },
    amount => {
      data_type          => 'integer',
      keep_storage_value => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->before_column_change(
    amount => { method => 'record_before' },
  );
  __PACKAGE__->after_column_change(
    amount => { method => 'record_after' },
  );

  sub record_before {
    my ($self, $old, $new) = @_;
    push @TestUAOCC::Changes::LOG,
      { phase => 'before', column => 'amount', old => $old, new => $new };
  }

  sub record_after {
    my ($self, $old, $new) = @_;
    push @TestUAOCC::Changes::LOG,
      { phase => 'after', column => 'amount', old => $old, new => $new };
  }
}

TestUAOCC::Schema->register_class(
  Account => 'TestUAOCC::Schema::Result::Account'
);

sub connect_occ_schema {
  TestUAOCC::Schema->storage_type('+DBIO::Test::Storage');
  my $schema = TestUAOCC::Schema->connect(sub { });
  $schema->storage(DBIO::Test::Storage->new($schema));
  return $schema;
}

# =========================================================================
# update_async
# =========================================================================

subtest 'update_async: routes through the backend on a plain row (no hooks, no cascade_update)' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  isa_ok $backend, 'My::Mock::ParityBackend', 'parityasyncmock builds the delegating backend';

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);
  $row->{_dirty_columns} = {};
  $row->artist(2);

  my $f = $row->update_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'update_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my $result = $f->get;
  is $result, $row, 'update_async resolves with $self';
  is_deeply [ $row->get_dirty_columns ], [], 'dirty columns cleared after update_async';

  is_deeply $backend->{calls}, ['update'],
    'update_async routed through the backend update_async (no sync degrade)';
};

subtest 'update_async: sync/async parity on identical fixture data' => sub {
  my $schema  = DBIO::Test->init_schema;
  set_mode($schema->storage, 'parityasyncmock');

  my $sync_row  = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $sync_row->in_storage(1);
  $sync_row->{_dirty_columns} = {};
  $sync_row->artist(5);
  $sync_row->update;

  my $async_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $async_row->in_storage(1);
  $async_row->{_dirty_columns} = {};
  $async_row->artist(5);
  my $result = $async_row->update_async->get;

  is $result->artist, $sync_row->artist, 'update_async matches sync update on the same input';
  is $result->in_storage, $sync_row->in_storage, 'in_storage parity';
};

subtest 'update_async: OnColumnChange hooks fire identically on sync and async paths, via the punt' => sub {
  my $schema  = connect_occ_schema();
  set_mode($schema->storage, 'parityasyncmock');
  my $backend = $schema->storage->_async_storage;

  my $acc = $schema->resultset('Account')->new_result({ amount => 100 });
  $acc->insert;

  TestUAOCC::Changes::reset();
  $acc->amount(150);
  my $result = $acc->update_async->get;

  is $result->amount, 150, 'update_async applied the column change';
  is_deeply(
    [ TestUAOCC::Changes::all() ],
    [
      { phase => 'before', column => 'amount', old => 100, new => 150 },
      # after fires post-update, once the storage-value snapshot has already
      # been refreshed -- old legitimately equals new here (see OnColumnChange
      # POD and t/helpers/row_helpers_storage.t's identical assertion).
      { phase => 'after',  column => 'amount', old => 150, new => 150 },
    ],
    'before/after hooks fired, in the documented order, with correct old/new'
  );
  ok( !(grep { $_ eq 'update' } @{$backend->{calls}}),
    'update_async punted to sync (did not dispatch through backend update_async) because hooks are registered' );
};

subtest 'update_async: cascade_update relationship present but untouched dispatches truly async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  # CD has has_one/might_have relationships with cascade_update on by default
  # (mandatory_artwork, liner_notes). But DBIO::Relationship::CascadeActions'
  # own update() wrap only actually cascades to a 'single'-accessor
  # relationship if _relationship_data already has an entry for it -- i.e.
  # the accessor was explicitly assigned or already fetched-and-cached on
  # THIS instance (Relationship/CascadeActions.pm's own `next if ... !exists
  # $self->{_relationship_data}{$rel}` skip). A freshly-loaded CD that never
  # touched mandatory_artwork/liner_notes has nothing cascade_update would
  # act on, so update_async must dispatch truly async here -- a coarse,
  # schema-level "CD has ANY cascade_update relationship -> always punt"
  # gate would wrongly punt even a plain one-column update, failing the
  # promise that a simple flat write is 100% async.
  my $cd = $schema->resultset('CD')->new_result({ cdid => 1, artist => 1, title => 'Kind of Blue', year => 1959 });
  $cd->in_storage(1);
  $cd->{_dirty_columns} = {};
  $cd->title('Kind of Blue (Remaster)');

  my $result = $cd->update_async->get;
  is $result->title, 'Kind of Blue (Remaster)', 'update_async applied the column change';
  is_deeply $backend->{calls}, ['update'],
    'update_async dispatched through the backend -- no cascade_update related was ever touched on this instance';
};

subtest 'update_async: cascade_update related touched on this instance punts to sync, and the cascade actually fires' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  my $cd = $schema->resultset('CD')->new_result({ cdid => 1, artist => 1, title => 'Kind of Blue', year => 1959 });
  $cd->in_storage(1);

  # LinerNotes has a real, dirtyable non-PK column (unlike Artwork, which is
  # only its own PK) -- needed to actually observe the cascade doing
  # something, not just that the punt was taken. Assigning the might_have
  # accessor populates _relationship_data{liner_notes} -- exactly the slot
  # CascadeActions::update's skip condition checks -- via the real
  # relationship-accessor codegen (Relationship/Codegen.pm), not a
  # hand-poked hash.
  my $notes = $schema->resultset('LinerNotes')->new_result({ liner_id => 1, notes => 'original' });
  $notes->in_storage(1);
  $cd->liner_notes($notes);
  ok exists $cd->{_relationship_data}{liner_notes},
    'sanity check: assigning the might_have accessor populated _relationship_data, as CascadeActions itself checks';

  $notes->{_dirty_columns} = {};
  $notes->notes('revised');
  ok $notes->is_changed, 'sanity check: the related row has a dirty column before the cascade runs';

  $cd->{_dirty_columns} = {};
  $cd->title('Kind of Blue (Remaster)');

  $storage->reset_captured;
  my $result = $cd->update_async->get;
  is $result->title, 'Kind of Blue (Remaster)', 'update_async applied the column change via the punt';
  ok( !(grep { $_ eq 'update' } @{$backend->{calls}}),
    'update_async punted to sync because liner_notes was touched on this instance' );

  ok( (grep { $_->{sql} =~ /UPDATE "liner_notes"/ } $storage->captured_queries),
    'the cascade actually issued an UPDATE against the related liner_notes row' );
  ok !$notes->is_changed,
    'the related row is no longer dirty -- the cascade genuinely ran, not just the punt';
};

subtest 'update_async: a cascade_update relationship assigned via %upd itself (not a prior accessor call) also punts and cascades' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');

  # Note: %upd also carries a genuine column change (title) alongside the
  # relationship key. Without it, CD's own get_dirty_columns would be empty
  # after set_inflated_columns processes (and deletes) the relationship key
  # -- assigning liner_notes touches no column on CD's own side of a
  # might_have -- which would make the fast path's "nothing dirty" early
  # return mask whether the punt happened at all. The title change makes the
  # routing assertion below meaningful either way.

  # sync baseline: update({ title => ..., liner_notes => $obj }) on a CD that
  # never touched liner_notes before this call. set_inflated_columns (called
  # from inside update()) is what populates _relationship_data{liner_notes}
  # here -- it happens DURING the call, not before it.
  my $sync_cd = $schema->resultset('CD')->new_result({ cdid => 1, artist => 1, title => 'Kind of Blue', year => 1959 });
  $sync_cd->in_storage(1);
  my $sync_notes = $schema->resultset('LinerNotes')->new_result({ liner_id => 1, notes => 'stale' });
  $sync_notes->in_storage(1);
  $sync_notes->notes('fresh');
  ok !exists $sync_cd->{_relationship_data}{liner_notes},
    'sanity: liner_notes was never touched on the sync CD before this call';
  $sync_cd->update({ title => 'Kind of Blue (Remaster)', liner_notes => $sync_notes });
  ok !$sync_notes->is_changed,
    'sync update({ title => ..., liner_notes => $obj }) cascades and flushes the related row';

  # async: the identical shape, on a fresh fixture. The gate runs BEFORE
  # set_inflated_columns, so _relationship_data{liner_notes} does not exist
  # yet at gate-check time -- the gate must pre-scan %upd's own keys against
  # relationship metadata (no I/O) to catch this, not just the row's current
  # _relationship_data state, or this would silently dispatch truly async
  # and skip the cascade sync performs.
  my $backend = $storage->_async_storage;
  my $cd = $schema->resultset('CD')->new_result({ cdid => 2, artist => 1, title => 'Kind of Blue', year => 1959 });
  $cd->in_storage(1);
  my $notes = $schema->resultset('LinerNotes')->new_result({ liner_id => 2, notes => 'stale' });
  $notes->in_storage(1);
  $notes->notes('fresh');
  ok !exists $cd->{_relationship_data}{liner_notes},
    'sanity: liner_notes was never touched on the async CD before this call either';

  my $result = $cd->update_async({ title => 'Kind of Blue (Remaster)', liner_notes => $notes })->get;
  is $result->title, 'Kind of Blue (Remaster)', 'the column change from %upd was applied';
  ok( !(grep { $_ eq 'update' } @{$backend->{calls}}),
    'update_async punted to sync because %upd itself names a cascade_update relationship' );
  ok !$notes->is_changed,
    'update_async, via the punt, cascades and flushes the related row too -- parity with sync';
};

subtest 'update_async: immediate mode degrades to a synchronous update' => sub {
  my $schema = DBIO::Test->init_schema;   # mock default: 'immediate'
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);
  $row->{_dirty_columns} = {};
  $row->artist(9);

  my $f = $row->update_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate update_async returns a Future';
  ok $f->is_ready, 'immediate update_async is ready';
  is $f->get->artist, 9, 'immediate update_async runs the sync op and resolves';
};

subtest 'update_async: sync instance croaks (no silent degrade)' => sub {
  my $schema  = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);   # undef mode == sync

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  throws_ok { $row->update_async }
    qr/not an async connection/,
    'update_async on a sync instance croaks';
};

# =========================================================================
# delete_async
# =========================================================================

subtest 'delete_async: routes through the backend on a flat row (no cascade_delete relateds)' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  my $f = $row->delete_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'delete_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my $result = $f->get;
  is $result, $row, 'delete_async resolves with $self';
  ok !$row->in_storage, 'in_storage is false after delete_async';

  is_deeply $backend->{calls}, ['delete'],
    'delete_async routed through the backend delete_async (no sync degrade)';
};

subtest 'delete_async: sync/async parity on identical fixture data' => sub {
  my $schema  = DBIO::Test->init_schema;
  set_mode($schema->storage, 'parityasyncmock');

  my $sync_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $sync_row->in_storage(1);
  $sync_row->delete;

  my $async_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $async_row->in_storage(1);
  my $result = $async_row->delete_async->get;

  is $result->in_storage, $sync_row->in_storage, 'in_storage parity after delete';
};

subtest 'delete_async: cascade_delete relateds punt to sync (John\'s binding decision)' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  # Artist has has_many relationships (cds etc.) with cascade_delete on by
  # default; deleting one attempts to cascade-delete the related rows via
  # DBIO::Relationship::CascadeActions, wrapped at the component-composition
  # layer around delete(). delete_async can't reach into that wrap, so it
  # punts to the synchronous delete (still runs the cascade correctly)
  # exactly like insert_async's related-object multi-create punt.
  my $artist = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'Test Artist' });
  $artist->in_storage(1);

  my $result = $artist->delete_async->get;
  ok !$result->in_storage, 'delete_async applied the delete via the punt';
  ok( !(grep { $_ eq 'delete' } @{$backend->{calls}}),
    'delete_async punted to sync because Artist has cascade_delete relationships' );
};

subtest 'delete_async: immediate mode degrades to a synchronous delete' => sub {
  my $schema = DBIO::Test->init_schema;
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  my $f = $row->delete_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate delete_async returns a Future';
  ok $f->is_ready, 'immediate delete_async is ready';
  ok !$f->get->in_storage, 'immediate delete_async runs the sync op and resolves';
};

subtest 'delete_async: sync instance croaks (no silent degrade)' => sub {
  my $schema  = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  throws_ok { $row->delete_async }
    qr/not an async connection/,
    'delete_async on a sync instance croaks';
};

# =========================================================================
# get_from_storage_async
# =========================================================================

subtest 'get_from_storage_async: routes through the backend (via find_async)' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale name' });
  $row->in_storage(1);

  my $f = $row->get_from_storage_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'get_from_storage_async returns a Future';

  my $fresh = $f->get;
  isa_ok $fresh, 'DBIO::Test::Schema::Artist', 'resolves with an inflated Row object';
  is $fresh->name, 'Miles Davis', 'resolves with the storage-fresh data, not the stale in-memory value';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'get_from_storage_async routed through find_async -> backend select_single_async' );
};

subtest 'get_from_storage_async: sync/async parity on identical fixture data' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'John Coltrane', 13, undef ] ]);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale name' });
  $row->in_storage(1);

  my $sync_copy  = $row->get_from_storage;
  my $async_copy = $row->get_from_storage_async->get;

  is $async_copy->name, $sync_copy->name, 'get_from_storage_async matches sync get_from_storage';
};

subtest 'get_from_storage_async: immediate mode degrades to a synchronous fetch' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Albert Ayler', 13, undef ] ]);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale name' });
  $row->in_storage(1);

  my $f = $row->get_from_storage_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate get_from_storage_async returns a Future';
  ok $f->is_ready, 'immediate get_from_storage_async is ready';
  is $f->get->name, 'Albert Ayler', 'immediate get_from_storage_async runs the sync op and resolves';
};

subtest 'get_from_storage_async: sync instance croaks (no silent degrade)' => sub {
  my $schema = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'x' });
  $row->in_storage(1);

  throws_ok { $row->get_from_storage_async }
    qr/not an async connection/,
    'get_from_storage_async on a sync instance croaks';
};

# =========================================================================
# discard_changes_async
# =========================================================================

subtest 'discard_changes_async: not in storage resolves immediately with undef, no query' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'x' });
  # deliberately not marked in_storage

  my $f = $row->discard_changes_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'discard_changes_async returns a Future';
  is $f->get, undef, 'discard_changes_async resolves with undef when not in_storage, matching sync';
  is_deeply $backend->{calls}, [], 'no backend call was made -- no query issued, matching sync';
};

subtest 'discard_changes_async: refreshes in place when the row still exists' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Pharoah Sanders', 13, undef ] ]);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale name' });
  $row->in_storage(1);

  my $result = $row->discard_changes_async->get;
  is $result, $row, 'discard_changes_async resolves with $self, refreshed in place';
  is $row->name, 'Pharoah Sanders', 'in-memory object now carries the storage-fresh value';
  ok $row->in_storage, 'still marked in_storage';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'discard_changes_async routed through get_from_storage_async -> backend select_single_async' );
};

subtest 'discard_changes_async: row vanished from storage marks in_storage false' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/FROM "artist"/i, []);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 99, name => 'ghost' });
  $row->in_storage(1);

  my $result = $row->discard_changes_async->get;
  is $result, $row, 'discard_changes_async resolves with $self even when the row vanished';
  ok !$row->in_storage, 'in_storage is now false, matching sync semantics for a vanished row';
};

subtest 'discard_changes_async: sync/async parity on identical fixture data' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Sun Ra', 13, undef ] ]);

  my $sync_row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale' });
  $sync_row->in_storage(1);
  $sync_row->discard_changes;

  my $async_row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale' });
  $async_row->in_storage(1);
  $async_row->discard_changes_async->get;

  is $async_row->name, $sync_row->name, 'discard_changes_async matches sync discard_changes';
};

subtest 'discard_changes_async: immediate mode degrades to a synchronous refresh' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Ornette Coleman', 13, undef ] ]);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'stale' });
  $row->in_storage(1);

  my $f = $row->discard_changes_async;
  ok $f->is_ready, 'immediate discard_changes_async is ready';
  is $f->get->name, 'Ornette Coleman', 'immediate discard_changes_async runs the sync op and resolves';
};

subtest 'discard_changes_async: sync instance croaks (no silent degrade)' => sub {
  my $schema = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);

  my $row = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'x' });
  $row->in_storage(1);

  throws_ok { $row->discard_changes_async }
    qr/not an async connection/,
    'discard_changes_async on a sync instance croaks';
};

# =========================================================================
# update_or_insert_async / insert_or_update_async
# =========================================================================

subtest 'update_or_insert_async: in_storage delegates to update_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);
  $row->{_dirty_columns} = {};
  $row->artist(2);

  my $result = $row->update_or_insert_async->get;
  is $result, $row, 'update_or_insert_async resolves with $self';
  is_deeply $backend->{calls}, ['update'],
    'update_or_insert_async delegated to update_async for an in-storage row';
};

subtest 'update_or_insert_async: not in_storage delegates to insert_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->set_auto_increment('onekey', 7);

  my $row = $schema->resultset('OneKey')->new_result({ artist => 1, cd => 1 });

  my $result = $row->update_or_insert_async->get;
  ok $result->in_storage, 'row is marked in_storage after the insert branch';
  is $result->id, 7, 'autoinc id folded back from insert_async';
  is_deeply $backend->{calls}, ['insert'],
    'update_or_insert_async delegated to insert_async for a not-yet-stored row';
};

subtest 'insert_or_update_async: alias for update_or_insert_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);
  $row->{_dirty_columns} = {};
  $row->artist(3);

  $row->insert_or_update_async->get;
  is_deeply $backend->{calls}, ['update'], 'insert_or_update_async behaves exactly like update_or_insert_async';
};

subtest 'update_or_insert_async: sync/async parity, both branches' => sub {
  my $schema  = DBIO::Test->init_schema;
  set_mode($schema->storage, 'parityasyncmock');

  my $sync_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $sync_row->in_storage(1);
  $sync_row->{_dirty_columns} = {};
  $sync_row->artist(9);
  $sync_row->update_or_insert;

  my $async_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $async_row->in_storage(1);
  $async_row->{_dirty_columns} = {};
  $async_row->artist(9);
  $async_row->update_or_insert_async->get;

  is $async_row->artist, $sync_row->artist, 'found-branch parity with sync update_or_insert';

  $schema->storage->set_auto_increment('onekey', 40);
  my $sync_new = $schema->resultset('OneKey')->new_result({ artist => 1, cd => 1 })->update_or_insert;
  $schema->storage->set_auto_increment('onekey', 40);
  my $async_new = $schema->resultset('OneKey')->new_result({ artist => 1, cd => 1 })->update_or_insert_async->get;
  is $async_new->in_storage, $sync_new->in_storage, 'not-found-branch parity with sync update_or_insert';
};

subtest 'update_or_insert_async: immediate mode and sync-instance croak' => sub {
  my $schema = DBIO::Test->init_schema;
  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);
  $row->{_dirty_columns} = {};
  $row->artist(5);

  my $f = $row->update_or_insert_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate update_or_insert_async returns a Future';
  ok $f->is_ready, 'immediate update_or_insert_async is ready';
  is $f->get->artist, 5, 'immediate update_or_insert_async resolves correctly';

  set_mode($schema->storage, undef);
  throws_ok { $row->update_or_insert_async }
    qr/not an async connection/,
    'update_or_insert_async on a sync instance croaks (via the delegated update_async)';
};

# =========================================================================
# count_literal_async
# =========================================================================

subtest 'count_literal_async: routes through count_async and matches sync count_literal' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/SELECT\s+COUNT/i, [ [ 4 ] ]);

  my $rs = $schema->resultset('Artist');
  my $sync_count = $rs->count_literal('name IS NOT NULL');

  my $f = $rs->count_literal_async('name IS NOT NULL');
  isa_ok $f, 'DBIO::Future::Immediate', 'count_literal_async returns a Future';
  is $f->get, $sync_count, 'count_literal_async matches sync count_literal';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'count_literal_async routed through count_async -> backend select_single_async' );
};

subtest 'count_literal_async: immediate mode degrades to a synchronous count' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/SELECT\s+COUNT/i, [ [ 2 ] ]);

  my $f = $schema->resultset('Artist')->count_literal_async('1=1');
  ok $f->is_ready, 'immediate count_literal_async is ready';
  is $f->get, 2, 'immediate count_literal_async resolves with the count';
};

subtest 'count_literal_async: sync instance croaks (no silent degrade)' => sub {
  my $schema = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);

  throws_ok { $schema->resultset('Artist')->count_literal_async('1=1') }
    qr/not an async connection/,
    'count_literal_async on a sync instance croaks';
};

# =========================================================================
# find_or_new_async
# =========================================================================

subtest 'find_or_new_async: found branch resolves with the existing row via find_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $f = $schema->resultset('Artist')->find_or_new_async({ name => 'Miles Davis' });
  isa_ok $f, 'DBIO::Future::Immediate', 'find_or_new_async returns a Future';

  my $row = $f->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'resolves with an inflated Row object';
  ok $row->in_storage, 'the found row is in_storage';
  is $row->name, 'Miles Davis', 'resolves with the storage row';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'find_or_new_async routed the lookup through find_async -> backend select_single_async' );
};

subtest 'find_or_new_async: not-found branch resolves with a new, uninserted result' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/FROM "artist"/i, []);

  my $row = $schema->resultset('Artist')->find_or_new_async({ name => 'Nobody Yet' })->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'resolves with a Row object';
  ok !$row->in_storage, 'the new row is not in_storage';
  is $row->name, 'Nobody Yet', 'carries the supplied data';
};

subtest 'find_or_new_async: sync/async parity, both branches' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Wayne Shorter', 13, undef ] ]);
  my $sync_found  = $schema->resultset('Artist')->find_or_new({ name => 'Wayne Shorter' });
  my $async_found = $schema->resultset('Artist')->find_or_new_async({ name => 'Wayne Shorter' })->get;
  is $async_found->in_storage, $sync_found->in_storage, 'found-branch in_storage parity';
  is $async_found->name, $sync_found->name, 'found-branch data parity';

  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, []);
  my $sync_new  = $schema->resultset('Artist')->find_or_new({ name => 'Brand New' });
  my $async_new = $schema->resultset('Artist')->find_or_new_async({ name => 'Brand New' })->get;
  is $async_new->in_storage, $sync_new->in_storage, 'not-found-branch in_storage parity';
  is $async_new->name, $sync_new->name, 'not-found-branch data parity';
};

subtest 'find_or_new_async: immediate mode and sync-instance croak' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/FROM "artist"/i, []);
  my $f = $schema->resultset('Artist')->find_or_new_async({ name => 'Immediate Artist' });
  ok $f->is_ready, 'immediate find_or_new_async is ready';
  is $f->get->name, 'Immediate Artist', 'immediate find_or_new_async resolves correctly';

  set_mode($schema->storage, undef);
  throws_ok { $schema->resultset('Artist')->find_or_new_async({ name => 'x' }) }
    qr/not an async connection/,
    'find_or_new_async on a sync instance croaks';
};

# =========================================================================
# find_or_create_async
# =========================================================================

subtest 'find_or_create_async: found branch resolves with the existing row via find_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Herbie Hancock', 13, undef ] ]);

  my $row = $schema->resultset('Artist')->find_or_create_async({ name => 'Herbie Hancock' })->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'resolves with an inflated Row object';
  ok $row->in_storage, 'the found row is in_storage';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'find_or_create_async routed the lookup through find_async -> backend select_single_async' );
};

subtest 'find_or_create_async: not-found branch inserts via create_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, []);
  $storage->set_auto_increment('artist', 55);

  my $row = $schema->resultset('Artist')->find_or_create_async({ name => 'Freshly Signed' })->get;
  ok $row->in_storage, 'the created row is in_storage';
  is $row->artistid, 55, 'autoinc id folded back from create_async -> insert_async';
  is $row->name, 'Freshly Signed', 'carries the supplied data';

  ok( ( grep { $_ eq 'insert' } @{$backend->{calls}} ),
    'find_or_create_async routed the not-found branch through create_async -> backend insert_async' );
};

subtest 'find_or_create_async: sync/async parity, both branches' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Tony Williams', 13, undef ] ]);
  my $sync_found  = $schema->resultset('Artist')->find_or_create({ name => 'Tony Williams' });
  my $async_found = $schema->resultset('Artist')->find_or_create_async({ name => 'Tony Williams' })->get;
  is $async_found->in_storage, $sync_found->in_storage, 'found-branch in_storage parity';

  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, []);
  $storage->set_auto_increment('artist', 100);
  my $sync_new = $schema->resultset('Artist')->find_or_create({ name => 'Sync New' });
  $storage->set_auto_increment('artist', 100);
  my $async_new = $schema->resultset('Artist')->find_or_create_async({ name => 'Async New' })->get;
  is $async_new->in_storage, $sync_new->in_storage, 'not-found-branch in_storage parity';
};

subtest 'find_or_create_async: immediate mode and sync-instance croak' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/FROM "artist"/i, []);
  $schema->storage->set_auto_increment('artist', 200);
  my $f = $schema->resultset('Artist')->find_or_create_async({ name => 'Immediate New' });
  ok $f->is_ready, 'immediate find_or_create_async is ready';
  ok $f->get->in_storage, 'immediate find_or_create_async resolves with an inserted row';

  set_mode($schema->storage, undef);
  throws_ok { $schema->resultset('Artist')->find_or_create_async({ name => 'x' }) }
    qr/not an async connection/,
    'find_or_create_async on a sync instance croaks';
};

# =========================================================================
# update_or_create_async
# =========================================================================

subtest 'update_or_create_async: found branch updates the existing row via update_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Chick Corea', 13, undef ] ]);

  my $row = $schema->resultset('Artist')
                    ->update_or_create_async({ name => 'Chick Corea', rank => 99 })->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'resolves with an inflated Row object';
  ok $row->in_storage, 'the found row is in_storage';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ), 'lookup went through find_async' );
  ok( ( grep { $_ eq 'update' } @{$backend->{calls}} ),
    'update_or_create_async routed the found branch through update_async -> backend update_async' );
};

subtest 'update_or_create_async: not-found branch inserts via create_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, []);
  $storage->set_auto_increment('artist', 66);

  my $row = $schema->resultset('Artist')->update_or_create_async({ name => 'New Signing' })->get;
  ok $row->in_storage, 'the created row is in_storage';
  is $row->artistid, 66, 'autoinc id folded back from create_async';

  ok( ( grep { $_ eq 'insert' } @{$backend->{calls}} ),
    'update_or_create_async routed the not-found branch through create_async -> backend insert_async' );
};

subtest 'update_or_create_async: sync/async parity, both branches' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Ron Carter', 13, undef ] ]);
  my $sync_found  = $schema->resultset('Artist')->update_or_create({ name => 'Ron Carter', rank => 5 });
  my $async_found = $schema->resultset('Artist')->update_or_create_async({ name => 'Ron Carter', rank => 5 })->get;
  is $async_found->rank, $sync_found->rank, 'found-branch update parity';

  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, []);
  $storage->set_auto_increment('artist', 300);
  my $sync_new = $schema->resultset('Artist')->update_or_create({ name => 'Sync New UOC' });
  $storage->set_auto_increment('artist', 300);
  my $async_new = $schema->resultset('Artist')->update_or_create_async({ name => 'Async New UOC' })->get;
  is $async_new->in_storage, $sync_new->in_storage, 'not-found-branch in_storage parity';
};

subtest 'update_or_create_async: immediate mode and sync-instance croak' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/FROM "artist"/i, []);
  $schema->storage->set_auto_increment('artist', 400);
  my $f = $schema->resultset('Artist')->update_or_create_async({ name => 'Immediate UOC' });
  ok $f->is_ready, 'immediate update_or_create_async is ready';
  ok $f->get->in_storage, 'immediate update_or_create_async resolves with an inserted row';

  set_mode($schema->storage, undef);
  throws_ok { $schema->resultset('Artist')->update_or_create_async({ name => 'x' }) }
    qr/not an async connection/,
    'update_or_create_async on a sync instance croaks';
};

# =========================================================================
# update_or_new_async
# =========================================================================

subtest 'update_or_new_async: found branch updates the existing row via update_async' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Joe Zawinul', 13, undef ] ]);

  my $row = $schema->resultset('Artist')
                    ->update_or_new_async({ name => 'Joe Zawinul', rank => 42 })->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'resolves with an inflated Row object';
  ok $row->in_storage, 'the found row is in_storage';

  ok( ( grep { $_ eq 'update' } @{$backend->{calls}} ),
    'update_or_new_async routed the found branch through update_async -> backend update_async' );
};

subtest 'update_or_new_async: not-found branch resolves with a new, uninserted result' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/FROM "artist"/i, []);

  my $row = $schema->resultset('Artist')->update_or_new_async({ name => 'Not Yet Signed' })->get;
  ok !$row->in_storage, 'the new row is not in_storage';
  is $row->name, 'Not Yet Signed', 'carries the supplied data';
};

subtest 'update_or_new_async: sync/async parity, both branches' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Jack DeJohnette', 13, undef ] ]);
  my $sync_found  = $schema->resultset('Artist')->update_or_new({ name => 'Jack DeJohnette', rank => 7 });
  my $async_found = $schema->resultset('Artist')->update_or_new_async({ name => 'Jack DeJohnette', rank => 7 })->get;
  is $async_found->rank, $sync_found->rank, 'found-branch update parity';

  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, []);
  my $sync_new  = $schema->resultset('Artist')->update_or_new({ name => 'Sync New UON' });
  my $async_new = $schema->resultset('Artist')->update_or_new_async({ name => 'Async New UON' })->get;
  is $async_new->in_storage, $sync_new->in_storage, 'not-found-branch in_storage parity';
};

subtest 'update_or_new_async: immediate mode and sync-instance croak' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/FROM "artist"/i, []);
  my $f = $schema->resultset('Artist')->update_or_new_async({ name => 'Immediate UON' });
  ok $f->is_ready, 'immediate update_or_new_async is ready';
  ok !$f->get->in_storage, 'immediate update_or_new_async resolves with an uninserted row';

  set_mode($schema->storage, undef);
  throws_ok { $schema->resultset('Artist')->update_or_new_async({ name => 'x' }) }
    qr/not an async connection/,
    'update_or_new_async on a sync instance croaks';
};

# =========================================================================
# results_exist_async
# =========================================================================
#
# Since ADR 0037 both twins execute the SAME complete statement: the one the
# storage's _exists_value_sql hook renders (base form
# "SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END"). It carries no ident /
# select / where to hand to the CRUD entry points, so sync runs it through
# _execute_rendered and async through the transport's raw-SQL seam
# (_query_async) -- the same seam _execute_ddl_async already uses for
# statements core has rendered itself. What must not drift is the statement:
# the parity subtest below compares the captured SQL of both paths
# character-for-character, which is this ADR's named tripwire.

subtest 'results_exist_async: routes through the backend and matches sync results_exist' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->mock_persistent(qr/EXISTS/i, [ [ 1 ] ]);

  my $rs = $schema->resultset('Artist')->search({ name => 'Miles Davis' });
  my $sync_exists = $rs->results_exist;

  my $f = $rs->results_exist_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'results_exist_async returns a Future';
  is $f->get, $sync_exists, 'results_exist_async matches sync results_exist (true case)';
  is $f->get, 1, 'results_exist_async resolves with 1, not a raw truthy row';

  ok( ( grep { $_ eq 'query' } @{$backend->{calls}} ),
    'results_exist_async routed the rendered statement through the backend seam' );
};

subtest 'results_exist_async: resolves the identical SQL sync does' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);

  my $rs = $schema->resultset('Artist')->search({ name => 'Miles Davis' });

  $storage->reset_captured;
  $rs->results_exist;
  my @sync = $storage->captured_queries;

  $storage->reset_captured;
  $rs->results_exist_async->get;
  my @async = $storage->captured_queries;

  is scalar @sync,  1, 'sync results_exist issues exactly one statement';
  is scalar @async, 1, 'async results_exist_async issues exactly one statement';

  is $async[0]{sql}, $sync[0]{sql},
    'sync and async resolve the identical SQL (ADR 0037 tripwire)';
  # The sync statement binds [ \%attrs => $value ] pairs; a transport's runner
  # takes bare values (karr k342) -- the same values, in the same order.
  is_deeply $async[0]{bind},
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $sync[0]{bind} } ],
    'and the identical bind values';

  like $sync[0]{sql}, qr/^SELECT CASE WHEN EXISTS /,
    'both execute the hook\'s complete statement';
  unlike $sync[0]{sql}, qr/_existence_subq/,
    'neither wraps it in a derived table';
};

subtest 'results_exist_async: false case matches sync results_exist' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  $storage->mock_persistent(qr/EXISTS/i, [ [ 0 ] ]);

  my $rs = $schema->resultset('Artist')->search({ name => 'Nobody' });
  my $sync_exists = $rs->results_exist;

  is $rs->results_exist_async->get, $sync_exists, 'results_exist_async matches sync results_exist (false case)';
  is $rs->results_exist_async->get, 0, 'results_exist_async resolves with 0';
};

subtest 'results_exist_async: immediate mode degrades to a synchronous check' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/EXISTS/i, [ [ 1 ] ]);

  my $f = $schema->resultset('Artist')->search({ name => 'x' })->results_exist_async;
  ok $f->is_ready, 'immediate results_exist_async is ready';
  is $f->get, 1, 'immediate results_exist_async resolves correctly';
};

subtest 'results_exist_async: sync instance croaks (no silent degrade)' => sub {
  my $schema = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);

  throws_ok { $schema->resultset('Artist')->results_exist_async }
    qr/not an async connection/,
    'results_exist_async on a sync instance croaks';
};

# =========================================================================
# copy_async
# =========================================================================

subtest 'copy_async: routes through the backend on a flat row (no cascade_copy relateds)' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->set_auto_increment('onekey', 10);

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  my $f = $row->copy_async({ artist => 9 });
  isa_ok $f, 'DBIO::Future::Immediate', 'copy_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my $copy = $f->get;
  isa_ok $copy, 'DBIO::Test::Schema::OneKey', 'resolves with a Row object';
  isnt $copy, $row, 'the copy is a distinct object from the original';
  ok $copy->in_storage, 'the copy is in_storage';
  is $copy->id, 10, 'autoinc id assigned fresh by the copy insert, not carried over';
  is $copy->artist, 9, 'the supplied override was applied';
  is $copy->cd, 1, 'a non-overridden column was carried over from the original';
  ok $row->in_storage, 'the original row is untouched';

  is_deeply $backend->{calls}, ['insert'],
    'copy_async routed through the backend insert_async (no sync degrade)';
};

subtest 'copy_async: sync/async parity on identical fixture data' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');

  $storage->set_auto_increment('onekey', 20);
  my $sync_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $sync_row->in_storage(1);
  my $sync_copy = $sync_row->copy({ artist => 5 });

  $storage->set_auto_increment('onekey', 20);
  my $async_row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $async_row->in_storage(1);
  my $async_copy = $async_row->copy_async({ artist => 5 })->get;

  is $async_copy->artist, $sync_copy->artist, 'copy_async matches sync copy on the override';
  is $async_copy->cd, $sync_copy->cd, 'copy_async matches sync copy on the carried-over column';
  is $async_copy->in_storage, $sync_copy->in_storage, 'in_storage parity';
};

subtest 'copy_async: cascade_copy relateds punt to sync (mirrors insert_async/delete_async punt)' => sub {
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'parityasyncmock');
  my $backend = $storage->_async_storage;
  $storage->set_auto_increment('artist', 77);

  # Artist has has_many relationships (cds etc.) with cascade_copy on by
  # default; copy() follows them itself (not via a component wrap this time
  # -- it's inline in copy()'s own loop), recursively copying each related
  # row. copy_async can't express that as a single insert_async, so it
  # punts to the full synchronous copy, exactly like insert_async's
  # multi-create punt and delete_async's cascade_delete punt.
  my $artist = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'Original Artist' });
  $artist->in_storage(1);

  my $result = $artist->copy_async({ name => 'Copied Artist' })->get;
  isa_ok $result, 'DBIO::Test::Schema::Artist', 'resolves with a Row object';
  ok $result->in_storage, 'the copy is in_storage via the punt';
  is $result->name, 'Copied Artist', 'the override was applied via the punt';

  ok( !(grep { $_ eq 'insert' } @{$backend->{calls}}),
    'copy_async punted to sync because Artist has a cascade_copy relationship' );
};

subtest 'copy_async: immediate mode degrades to a synchronous copy' => sub {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->set_auto_increment('onekey', 30);

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  my $f = $row->copy_async({ artist => 2 });
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate copy_async returns a Future';
  ok $f->is_ready, 'immediate copy_async is ready';
  my $copy = $f->get;
  ok $copy->in_storage, 'immediate copy_async runs the sync op and resolves';
  is $copy->artist, 2, 'immediate copy_async applies the override';
};

subtest 'copy_async: sync instance croaks (no silent degrade)' => sub {
  my $schema = DBIO::Test->init_schema;
  set_mode($schema->storage, undef);

  my $row = $schema->resultset('OneKey')->new_result({ id => 1, artist => 1, cd => 1 });
  $row->in_storage(1);

  throws_ok { $row->copy_async({ artist => 2 }) }
    qr/not an async connection/,
    'copy_async on a sync instance croaks';
};

done_testing;
