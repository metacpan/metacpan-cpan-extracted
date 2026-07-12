use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0030/0031: ResultSet/Row *_async route through the chosen embedded async
# backend and inflate the raw result in the Future's ->then -- with full
# prefetch/collapse parity to the synchronous path -- instead of running the
# sync op and faking a Future. This test drives that on a mock backend that
# delegates row production to the underlying sync DBIO::Test::Storage, so the
# raw rows (and the SQL that would have produced them) are identical to the sync
# path; parity is therefore exercised by construction. No event loop, no real DB.

# --- A mock async backend that delegates to the sync storage ------------------
# Its *_async resolve via the very same sync cursor / select_single / insert the
# synchronous path uses, so any difference between sync and async output is a
# bug in the RS/Row inflation routing, not in the test rows.
{
  package My::Mock::RowBackend;
  use base 'DBIO::Storage::Async';

  sub new { my ($c, $s) = @_; bless { schema => $s, calls => [] }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { 1 }

  # the underlying synchronous DBIO::Test::Storage
  sub _sync { $_[0]{schema}->storage }

  sub select_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'select';
    # ->all yields raw arrayrefs, generated through _select_args exactly like a
    # real cursor would (karr #55 invariant preserved by the fake cursor).
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
    # sync insert returns the retrieved-columns hashref (autoinc PK etc.)
    my $cols = $self->_sync->insert(@args);
    return DBIO::Future::Immediate->done($cols);
  }
}

DBIO::Storage::DBI->register_async_mode( rowmock => 'My::Mock::RowBackend' );

# Set the chosen mode on a mock storage exactly as connect would, clearing the
# resolved-backend cache. Mirrors the helper in t/test/14_async_backend.t.
sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# -----------------------------------------------------------------------
# all_async on a real backend: inflated Row objects via Future, routed
# through select_async (not the sync degrade)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rowmock');
  my $backend = $storage->_async_storage;
  isa_ok $backend, 'My::Mock::RowBackend', 'rowmock builds the delegating backend';

  $storage->mock_persistent(qr/FROM "artist"/i, [
    [ 1, 'Miles Davis',   13, undef ],
    [ 2, 'John Coltrane', 13, undef ],
  ]);

  my $rs = $schema->resultset('Artist')->search(undef, { order_by => 'me.artistid' });

  my $f = $rs->all_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'all_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my @rows = $f->get;
  is scalar @rows, 2, 'all_async resolves with two results';
  isa_ok $rows[0], 'DBIO::Test::Schema::Artist',
    'result is an inflated Row object, not a raw arrayref/hash';
  is $rows[0]->name, 'Miles Davis', 'first row inflated correctly';
  is $rows[1]->artistid, 2, 'second row inflated correctly';

  is_deeply $backend->{calls}, ['select'],
    'all_async routed through the backend select_async (no sync degrade)';
}

# -----------------------------------------------------------------------
# all_async prefetch/collapse parity: nested has_many rows collapse exactly
# like the synchronous ->all
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rowmock');

  # JOIN rows for Artist (artistid,name,rank,charfield) prefetch cds
  # (cds.cdid,cds.artist,cds.title,cds.year,cds.genreid,cds.single_track):
  # artist 1 has two cds, artist 2 has one. Ordered by master PK for collapse.
  $storage->mock_persistent(qr/FROM "artist"/i, [
    [ 1, 'Miles Davis',   13, undef, 10, 1, 'Kind of Blue',   1959, undef, undef ],
    [ 1, 'Miles Davis',   13, undef, 11, 1, 'Bitches Brew',   1970, undef, undef ],
    [ 2, 'John Coltrane', 13, undef, 20, 2, 'A Love Supreme', 1965, undef, undef ],
  ]);

  my $prs = $schema->resultset('Artist')->search(undef, {
    prefetch => 'cds',
    order_by => 'me.artistid',
  });

  my @async = $prs->all_async->get;
  my @sync  = $prs->all;            # persistent mock -> same rows

  is scalar @async, 2, 'all_async collapsed the 3 join rows into 2 artists';
  isa_ok $async[0], 'DBIO::Test::Schema::Artist', 'collapsed master is a Row object';

  # prefetched cds are reachable WITHOUT a further query: only "FROM artist" is
  # mocked, so a separate "FROM cd" fetch would yield nothing and fail the count
  is_deeply [ sort { $a <=> $b } map { $_->cdid } $async[0]->cds->all ], [10, 11],
    'artist 1 has both prefetched cds (collapse + no extra query)';
  is scalar( $async[1]->cds->all ), 1, 'artist 2 has its single prefetched cd';

  my $shape = sub {
    [ map { [ $_->artistid, [ sort { $a <=> $b } map { $_->cdid } $_->cds->all ] ] } @_ ]
  };
  is_deeply $shape->(@async), $shape->(@sync),
    'all_async output matches all() exactly (prefetch/collapse parity)';
}

# -----------------------------------------------------------------------
# first_async / single_async on a backend
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rowmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM "artist"/i, [
    [ 7, 'Sun Ra', 13, undef ],
    [ 8, 'Pharoah Sanders', 13, undef ],
  ]);

  my $first = $schema->resultset('Artist')->search(undef, { order_by => 'me.artistid' })
                     ->first_async->get;
  isa_ok $first, 'DBIO::Test::Schema::Artist', 'first_async resolves with a Row';
  is $first->artistid, 7, 'first_async returns the first result';

  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 7, 'Sun Ra', 13, undef ] ]);
  my $single = $schema->resultset('Artist')->search({ artistid => 7 })->single_async->get;
  isa_ok $single, 'DBIO::Test::Schema::Artist', 'single_async resolves with a Row';
  is $single->name, 'Sun Ra', 'single_async inflated correctly';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'single_async routed through backend select_single_async' );
}

# -----------------------------------------------------------------------
# count_async on a backend resolves with the integer count
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rowmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/SELECT\s+COUNT/i, [ [ 5 ] ]);

  my $cf = $schema->resultset('Artist')->count_async;
  isa_ok $cf, 'DBIO::Future::Immediate', 'count_async returns a Future';
  is scalar $cf->get, 5, 'count_async resolves with the count value';

  ok( ( grep { $_ eq 'select_single' } @{$backend->{calls}} ),
    'count_async routed through backend select_single_async' );
}

# -----------------------------------------------------------------------
# create_async on a backend resolves with a stored Row object
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'rowmock');
  my $backend = $storage->_async_storage;

  $storage->set_auto_increment('artist', 42);

  my $crf = $schema->resultset('Artist')->create_async({ name => 'Cecil Taylor' });
  isa_ok $crf, 'DBIO::Future::Immediate', 'create_async returns a Future';

  my $row = $crf->get;
  isa_ok $row, 'DBIO::Test::Schema::Artist', 'create_async resolves with a Row object';
  is $row->name, 'Cecil Taylor', 'created row carries the supplied data';
  ok $row->in_storage, 'created row is marked in_storage';
  is $row->artistid, 42, 'autoinc id folded back from insert_async';

  is_deeply $backend->{calls}, ['insert'],
    'create_async routed through the backend insert_async';
}

# -----------------------------------------------------------------------
# sync instance: *_async croak (no silent degrade)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, undef);   # undef mode == sync

  throws_ok { $schema->resultset('Artist')->all_async }
    qr/not an async connection/,
    'all_async on a sync instance croaks';
  throws_ok { $schema->resultset('Artist')->count_async }
    qr/not an async connection/,
    'count_async on a sync instance croaks';
  throws_ok { $schema->resultset('Artist')->create_async({ name => 'x' }) }
    qr/not an async connection/,
    'create_async on a sync instance croaks';
}

# -----------------------------------------------------------------------
# immediate mode: degrade to an immediately-resolved Future (runs the sync op),
# still fully inflated
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;   # mock default: 'immediate'
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';

  $schema->storage->mock_persistent(qr/FROM "artist"/i, [
    [ 1, 'Albert Ayler', 13, undef ],
  ]);

  my $f = $schema->resultset('Artist')->all_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate all_async returns a Future';
  ok $f->is_ready, 'immediate all_async is ready';
  my @r = $f->get;
  is scalar @r, 1, 'immediate all_async runs the sync op and resolves';
  isa_ok $r[0], 'DBIO::Test::Schema::Artist', 'immediate all_async still inflates';

  $schema->storage->clear_mocks;
  $schema->storage->mock_persistent(qr/SELECT\s+COUNT/i, [ [ 3 ] ]);
  my $cf = $schema->resultset('Artist')->count_async;
  ok $cf->is_ready, 'immediate count_async is ready';
  is scalar $cf->get, 3, 'immediate count_async resolves with the count';
}

done_testing;
