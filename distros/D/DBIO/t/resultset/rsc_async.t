use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0030/0031 gave DBIO::ResultSet's reads real backend-routed async twins
# (all_async/first_async/single_async/count_async) plus find_async. DBIO::ResultSetColumn
# -- the get_column() helper -- was left out: sync single()/all()/min()/max()/sum()/func()
# had no async counterpart at all. This closes that gap for the search-side (PR-B of the
# async-parity series): single_async/all_async mirror RS's own all_async/single_async
# shape one tier down (RSC bypasses the cursor exactly like sync single() does), and
# min_async/max_async/sum_async/func_async route the aggregate through func_rs() + the
# select_single_async shape (RSC's own func() pulls one row via a cursor in scalar
# context; the async twins go straight through select_single_async instead, matching
# single_async's already-established bypass-the-cursor style).
#
# next_async/first_async/reset_async are NOT built here -- they need async cursor
# iteration, which does not exist yet (extends ADR 0031's stated first_async deferral;
# see the POD).
#
# NOTE on mock row shape: RSC's own queries select exactly ONE column (the requested
# column, or a single aggregate expression) -- unlike a plain ResultSet query, which
# selects the full column list. Every mocked row below is therefore a single-element
# arrayref, and every parity assertion is paired with a sanity check that pins the
# sync side to the concrete mocked value, so a mismatched mock shape fails loudly
# instead of silently comparing two empty/undef results as if they matched.
#
# All of this runs on the mock storage -- no real DB, no event loop.

# --- A mock async backend that delegates to the sync storage ------------------
# Same shape as t/resultset/async_backend.t's My::Mock::RowBackend and
# t/resultset/find_async.t's My::Mock::FindAsyncBackend: *_async resolve via the
# underlying sync DBIO::Test::Storage, so any sync/async difference in output is a
# bug in the RSC routing/inflation, not the rows.
{
  package My::Mock::RSCAsyncBackend;
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

DBIO::Storage::DBI->register_async_mode( rscasyncmock => 'My::Mock::RSCAsyncBackend' );

# Set the chosen mode on a mock storage exactly as connect would, clearing the
# resolved-backend cache. Mirrors the helper in t/resultset/async_backend.t.
sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# -----------------------------------------------------------------------
# all_async on a live backend: routing + parity with sync all()
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rscasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM cd\b/i, [ [ '1959' ], [ '1970' ] ]);

  my $rs    = $schema->resultset('CD')->search({ artist => 1 }, { order_by => 'me.cdid' });
  my $rscol = $rs->get_column('year');

  my @sync_all = $rscol->all;
  is_deeply \@sync_all, [ '1959', '1970' ], 'sanity: sync all() returns the mocked years';

  my $af = $rscol->all_async;
  isa_ok $af, 'DBIO::Future::Immediate', 'all_async returns a Future';
  ok $af->is_ready, 'resolves (immediately, under the mock backend)';
  my @async_all = $af->get;
  is_deeply \@async_all, \@sync_all, 'all_async matches sync all() (plain column values)';
  is_deeply $backend->{calls}, ['select'], 'all_async routed through backend select_async';
}

# -----------------------------------------------------------------------
# single_async on a live backend: routing + parity with sync single()
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rscasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM cd\b/i, [ [ '1959' ] ]);

  my $rs    = $schema->resultset('CD')->search({ cdid => 10 });
  my $rscol = $rs->get_column('year');

  my $sync_single = $rscol->single;
  is $sync_single, '1959', 'sanity: sync single() returns the mocked year';

  my $sf = $rscol->single_async;
  isa_ok $sf, 'DBIO::Future::Immediate', 'single_async returns a Future';
  is $sf->get, $sync_single, 'single_async matches sync single()';
  is_deeply $backend->{calls}, ['select_single'], 'single_async routed through backend select_single_async';
}

# -----------------------------------------------------------------------
# min_async/max_async/sum_async on a live backend: routing (select_single_async,
# not select_async) + parity with sync min/max/sum. The mock storage returns
# canned rows verbatim regardless of the aggregate function in the SQL, so each
# case registers its own single-column value rather than relying on the mock to
# actually compute MIN/MAX/SUM.
# -----------------------------------------------------------------------
for my $case (
  [ min => 'min_async', '1959' ],
  [ max => 'max_async', '1970' ],
  [ sum => 'sum_async', '3929' ],
) {
  my ($sync_method, $async_method, $mocked_value) = @$case;

  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rscasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM cd\b/i, [ [ $mocked_value ] ]);

  my $rs    = $schema->resultset('CD')->search({ artist => 1 });
  my $rscol = $rs->get_column('year');

  my $sync_val = $rscol->$sync_method;
  is $sync_val, $mocked_value, "sanity: sync $sync_method() returns the mocked aggregate";

  my $f = $rscol->$async_method;
  isa_ok $f, 'DBIO::Future::Immediate', "$async_method returns a Future";
  is $f->get, $sync_val, "$async_method matches sync $sync_method()";
  is_deeply $backend->{calls}, ['select_single'],
    "$async_method routes through backend select_single_async, not select_async";
}

# -----------------------------------------------------------------------
# func_async: general case, parity with sync func() in scalar context
# (RSC's own SYNOPSIS/func POD example: LENGTH(title))
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rscasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM cd\b/i, [ [ 12 ] ]);   # canned LENGTH(title) value

  my $rs    = $schema->resultset('CD')->search({ cdid => 10 });
  my $rscol = $rs->get_column('title');

  my $sync_len = $rscol->func('LENGTH');
  is $sync_len, 12, 'sanity: sync func(LENGTH) returns the mocked aggregate';

  my $f = $rscol->func_async('LENGTH');
  isa_ok $f, 'DBIO::Future::Immediate', 'func_async returns a Future';
  is $f->get, $sync_len, 'func_async(LENGTH) matches sync func(LENGTH) (scalar case)';
  is_deeply $backend->{calls}, ['select_single'],
    'func_async routes through backend select_single_async, like min_async/max_async/sum_async';
}

# -----------------------------------------------------------------------
# func() no longer has a list-context (multi-row) shape: ADR 0042 removed all
# wantarray-dependent return types, and func() was one of them. It always
# returns the single scalar and refuses list context outright. Per-row values
# come from func_rs($fn)->all / ->all_async instead -- that path inflates a Row
# per row, so there is deliberately no list-context func_async to build.
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rscasyncmock');

  $storage->mock_persistent(qr/FROM cd\b/i, [ [ 9 ], [ 12 ] ]);   # canned per-row LENGTH(title) values

  my $rs    = $schema->resultset('CD')->search({ artist => 1 }, { order_by => 'me.cdid' });
  my $rscol = $rs->get_column('title');

  is $rscol->func('LENGTH'), 9,
    'func(LENGTH) returns the first row value (scalar only, ADR 0042)';

  throws_ok { my @x = $rscol->func('LENGTH') } 'DBIO::Exception',
    'func() in list context throws instead of returning one value per row (ADR 0042)';
  throws_ok { my @x = $rscol->func('LENGTH') } qr/list context/,
    'the exception names list context';

  my @inflated = $rscol->func_rs('LENGTH')->all_async->get;
  isa_ok $inflated[0], 'DBIO::Test::Schema::CD',
    'per-row values come from func_rs($fn)->all_async, which inflates Row objects';
}

# -----------------------------------------------------------------------
# sync instance: every new *_async croaks (no silent degrade), matching every
# other DBIO *_async
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, undef);   # undef mode == sync

  my $rscol = $schema->resultset('CD')->get_column('year');

  throws_ok { $rscol->single_async } qr/not an async connection/, 'single_async on a sync instance croaks';
  throws_ok { $rscol->all_async }    qr/not an async connection/, 'all_async on a sync instance croaks';
  throws_ok { $rscol->min_async }    qr/not an async connection/, 'min_async on a sync instance croaks';
  throws_ok { $rscol->max_async }    qr/not an async connection/, 'max_async on a sync instance croaks';
  throws_ok { $rscol->sum_async }    qr/not an async connection/, 'sum_async on a sync instance croaks';
  throws_ok { $rscol->func_async('LENGTH') } qr/not an async connection/, 'func_async on a sync instance croaks';
}

# -----------------------------------------------------------------------
# immediate mode: degrades to the sync method, still resolves via a Future
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;   # mock default: 'immediate'
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';

  $schema->storage->mock_persistent(qr/FROM cd\b/i, [ [ '1959' ] ]);

  my $rs    = $schema->resultset('CD')->search({ artist => 1 });
  my $rscol = $rs->get_column('year');

  is_deeply [ $rscol->all ], [ '1959' ], 'sanity: sync all() returns the mocked year';

  my $f = $rscol->all_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate all_async returns a Future';
  ok $f->is_ready, 'immediate all_async is ready';
  is_deeply [ $f->get ], [ $rscol->all ], 'immediate all_async matches sync all()';

  is $rscol->min, '1959', 'sanity: sync min() returns the mocked year';

  my $mf = $rscol->min_async;
  ok $mf->is_ready, 'immediate min_async is ready';
  is $mf->get, $rscol->min, 'immediate min_async matches sync min()';
}

done_testing;
