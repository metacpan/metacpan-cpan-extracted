use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0030/0031 gave every ResultSet *_async a real backend-routed async
# equivalent EXCEPT find(): there is no find_async. Downstream code that needs
# find()'s unique-constraint-narrowed, relationship-key-aware lookup async has
# nothing to reach for but single_async, which -- like sync single() -- takes
# its condition raw, with NO relationship-key processing at all. A
# relationship-valued condition key that find() safely resolves to a concrete
# scalar (or safely misses on, per ADR 0034) reaches single_async's WHERE
# unprocessed: the related Row's blessed reference ends up as a literal bind
# value, which a real DBI driver rejects ("Cannot bind a reference").
# find_async closes the gap by sharing find()'s own condition-processing/
# valueset internals and dispatching through _rs_run_async exactly like its
# four RS async siblings (all_async/first_async/single_async/count_async).
#
# All of this runs on the mock storage -- no real DB, no event loop.

# --- A mock async backend that delegates to the sync storage ------------------
# Same shape as t/resultset/async_backend.t's My::Mock::RowBackend: *_async
# resolve via the underlying sync DBIO::Test::Storage, so any sync/async
# difference in output is a bug in find_async's routing/inflation, not the rows.
{
  package My::Mock::FindAsyncBackend;
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
}

DBIO::Storage::DBI->register_async_mode( findasyncmock => 'My::Mock::FindAsyncBackend' );

# Set the chosen mode on a mock storage exactly as connect would, clearing the
# resolved-backend cache. Mirrors the helper in t/resultset/async_backend.t.
sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# pull just the bound values (captured bind entries are [ $attrs, $value ])
# out of the SELECT(s) issued since the last reset_captured
sub select_bind_values {
  my ($storage) = @_;
  my ($q) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  return $q ? [ map { $_->[1] } @{ $q->{bind} || [] } ] : [];
}

# -----------------------------------------------------------------------
# find_async by primary key (positional-values form) on a backend
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'findasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $f = $schema->resultset('Artist')->find_async(1);
  isa_ok $f, 'DBIO::Future::Immediate', 'find_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my $row = $f->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'find_async resolves with an inflated Row';
  is $row->name, 'Miles Davis', 'find_async(1) found the PK row (positional-value form)';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'find_async routed through the backend select_single_async, not the sync degrade' );
}

# -----------------------------------------------------------------------
# find_async parity with sync find(): named unique constraint via key =>
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'findasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $sync  = $schema->resultset('Artist')->find({ artistid => 1 }, { key => 'artist_artistid' });
  my $async = $schema->resultset('Artist')->find_async({ artistid => 1 }, { key => 'artist_artistid' })->get;

  isa_ok $async, 'DBIO::Test::Schema::Artist', 'find_async(key => ...) resolves with a Row';
  is $async->artistid, $sync->artistid,
    'find_async matches sync find() on a named unique constraint';
}

# -----------------------------------------------------------------------
# find_async parity with sync find(): heuristics mode (no key given)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'findasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $sync  = $schema->resultset('Artist')->find({ artistid => 1, name => 'Miles Davis' });
  my $async = $schema->resultset('Artist')->find_async({ artistid => 1, name => 'Miles Davis' })->get;

  isa_ok $async, 'DBIO::Test::Schema::Artist', 'find_async (heuristics mode) resolves with a Row';
  is $async->artistid, $sync->artistid,
    'find_async matches sync find() in heuristics mode';
}

# -----------------------------------------------------------------------
# find_async parity with sync find(): prefetch/collapse (find()'s
# "Query returned more than one row" branch -- find_async must route through
# the collapse-aware fetch-all path, like all_async/first_async, not
# select_single_async)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'findasyncmock');

  # two joined rows for the same artist -- must collapse to one Artist with
  # two prefetched cds, for both sync find() and find_async
  $storage->mock_persistent(qr/FROM "artist"/i, [
    [ 1, 'Miles Davis', 13, undef, 10, 1, 'Kind of Blue', 1959, undef, undef ],
    [ 1, 'Miles Davis', 13, undef, 11, 1, 'Bitches Brew', 1970, undef, undef ],
  ]);

  my $sync  = $schema->resultset('Artist')->find(1, { prefetch => 'cds' });
  my $async = $schema->resultset('Artist')->find_async(1, { prefetch => 'cds' })->get;

  isa_ok $async, 'DBIO::Test::Schema::Artist',
    'find_async (prefetch/collapse) resolves with a single collapsed Row';
  is $async->artistid, $sync->artistid,
    'find_async matches sync find() under prefetch/collapse';

  my $cdids = sub { [ sort { $a <=> $b } map { $_->cdid } $_[0]->cds->all ] };
  is_deeply $cdids->($async), $cdids->($sync),
    'find_async prefetch parity: same collapsed nested cds as sync find() (no extra query)';
}

# -----------------------------------------------------------------------
# THE BUG: a relationship-valued condition key. find() resolves it down to a
# concrete scalar condition (ADR 0034); find_async must match -- not bind the
# raw related Row reference the way single_async does.
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'findasyncmock');

  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);
  my $artist = $schema->resultset('Artist')->find(1);   # a real, in_storage related Row
  isa_ok $artist, 'DBIO::Test::Schema::Artist', 'fixture: an in_storage Artist row';

  $storage->clear_mocks;
  # CD's table name is a scalar-ref (literal SQL, unquoted) -- see CD.pm
  $storage->mock_persistent(qr/FROM cd\b/i, [ [ 10, 1, 'Bitches Brew', 1970, undef, undef ] ]);

  # sync find(), for reference: resolves { artist => $artist } to a scalar FK
  # before the query is ever built.
  $storage->reset_captured;
  my $sync_cd = $schema->resultset('CD')->find({ artist => $artist, title => 'Bitches Brew' });
  isa_ok $sync_cd, 'DBIO::Test::Schema::CD', 'sync find() resolves the relationship-keyed condition';
  ok( !( grep { ref($_) && $_->isa('DBIO::Row') } @{ select_bind_values($storage) } ),
    'sync find() bound a plain scalar FK, not the related Row object' );

  # Pin single_async's existing (unchanged, documented-raw) behaviour: given
  # the identical condition, it does NOT resolve the relationship key -- the
  # blessed related Row goes into the bind list as-is. On a real DBI driver
  # this is exactly the "Cannot bind a reference" failure; the mock's
  # bind_param is a no-op stub so it does not itself raise here, but the raw
  # reference in the captured bind is the unprocessed pass-through that causes it.
  $storage->reset_captured;
  $schema->resultset('CD')->single_async({ artist => $artist, title => 'Bitches Brew' })->get;
  ok( ( grep { ref($_) && $_->isa('DBIO::Row') } @{ select_bind_values($storage) } ),
    'single_async (unchanged) binds the raw related Row reference -- the pinned pre-existing gap' );

  # find_async: shares find()'s own condition-processing, so it matches sync
  # find() -- a plain resolved scalar bind, not the reference.
  $storage->reset_captured;
  my $async_cd = $schema->resultset('CD')->find_async({ artist => $artist, title => 'Bitches Brew' })->get;
  isa_ok $async_cd, 'DBIO::Test::Schema::CD', 'find_async resolves the relationship-keyed condition';
  is $async_cd->cdid, $sync_cd->cdid, 'find_async matches sync find() on the resolved row';
  ok( !( grep { ref($_) && $_->isa('DBIO::Row') } @{ select_bind_values($storage) } ),
    'find_async, unlike single_async, resolved the relationship key to a plain scalar bind' );
}

# -----------------------------------------------------------------------
# THE GAP, non-concrete case: a relationship value that does NOT resolve to a
# concrete FK (ADR 0034) is a safe MISS for find() -- no query is even run.
# find_async must match: resolve with undef, no SELECT issued.
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'findasyncmock');

  my $sync_miss = $schema->resultset('CD')->find({ liner_notes => { notes => 'hello' } });
  ok !defined($sync_miss), 'sync find(): non-concrete relation condition is a safe miss';

  $storage->reset_captured;
  my $async_miss = $schema->resultset('CD')->find_async({ liner_notes => { notes => 'hello' } })->get;
  ok !defined($async_miss), 'find_async: matches -- also a safe miss';
  ok( !( grep { $_->{op} eq 'select' } $storage->captured_queries ),
    'find_async issued no SELECT for the non-concrete condition, just like sync find()' );
}

# -----------------------------------------------------------------------
# sync instance: find_async croaks (no silent degrade), matching every other
# RS *_async
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, undef);   # undef mode == sync

  throws_ok { $schema->resultset('Artist')->find_async(1) }
    qr/not an async connection/,
    'find_async on a sync instance croaks';
}

# -----------------------------------------------------------------------
# immediate mode: degrades to the sync find(), still resolves via a Future
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;   # mock default: 'immediate'
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';

  $schema->storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $f = $schema->resultset('Artist')->find_async(1);
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate find_async returns a Future';
  ok $f->is_ready, 'immediate find_async is ready';
  my $row = $f->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'immediate find_async still resolves/inflates';
}

done_testing;
