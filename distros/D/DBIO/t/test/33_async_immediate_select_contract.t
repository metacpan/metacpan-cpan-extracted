use strict;
use warnings;
use Test::More;

use Scalar::Util ();
use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# karr k201 / ADR 0053: the STORAGE-LEVEL *_async result form is backend-
# independent. The `immediate` mode is a faithful stand-in of a real
# DBIO::Storage::Async backend at the storage level -- it must resolve the two
# read methods with the SAME transport form a real backend does (the raw form
# the ORM inflation consumes), NOT pass the synchronous cursor / flat row list
# through unchanged.
#
#   select_async        -> a LIST of raw row arrayrefs (the cursor ->all shape)
#   select_single_async -> a SINGLE arrayref, or undef when there is no row
#
# A fake-real backend that delegates each read to the underlying sync storage --
# identical in shape to the reference backend in t/resultset/async_backend.t --
# provides the canonical form. immediate is compared against it on identical
# mock rows. This is offline: no event loop, no real database.

# --- The canonical-form reference: a real async backend delegating to sync -----
{
  package My::Mock::SelectBackend;
  use base 'DBIO::Storage::Async';

  sub new { my ($c, $s) = @_; bless { schema => $s }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { 1 }

  # the underlying synchronous DBIO::Test::Storage
  sub _sync { $_[0]{schema}->storage }

  sub select_async {
    my ($self, @args) = @_;
    # ->all yields raw arrayrefs through _select_args, exactly like a real cursor
    my @rows = $self->_sync->select(@args)->all;
    return DBIO::Future::Immediate->done(@rows);
  }

  sub select_single_async {
    my ($self, @args) = @_;
    my @row = $self->_sync->select_single(@args);
    return DBIO::Future::Immediate->done( @row ? [ @row ] : undef );
  }
}

DBIO::Storage::DBI->register_async_mode( selectmock => 'My::Mock::SelectBackend' );

# Set the chosen mode on a mock storage exactly as connect would, clearing the
# resolved-backend cache. Mirrors the helper in t/test/14_async_backend.t.
sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# Fresh storage-level select args for the Artist source, built off a resultset
# so the SQL is exactly what the ORM would emit (and matches the mock pattern).
sub artist_select_args {
  my ($schema) = @_;
  my $a = $schema->resultset('Artist')
                 ->search(undef, { order_by => 'me.artistid' })
                 ->_resolved_attrs;
  return ($a->{from}, $a->{select}, $a->{where}, $a);
}

sub artist_single_args {
  my ($schema, $id) = @_;
  my $a = $schema->resultset('Artist')->search({ artistid => $id })->_resolved_attrs;
  return ($a->{from}, $a->{select}, $a->{where}, $a);
}

my @ARTIST_ROWS = (
  [ 1, 'Miles Davis',   13, undef ],
  [ 2, 'John Coltrane', 13, undef ],
);

# -----------------------------------------------------------------------
# select_async: immediate resolves with the SAME raw-row-arrayref form a real
# backend does -- not the sync cursor object it used to pass through.
# -----------------------------------------------------------------------
{
  my $schema_real  = DBIO::Test->init_schema;
  my $storage_real = set_mode($schema_real->storage, 'selectmock');
  $storage_real->mock_persistent(qr/FROM "artist"/i, [ @ARTIST_ROWS ]);
  isa_ok $storage_real->_async_storage, 'My::Mock::SelectBackend',
    'selectmock builds the delegating fake-real backend';

  my $schema_imm  = DBIO::Test->init_schema;   # mock default: 'immediate'
  my $storage_imm = $schema_imm->storage;
  is $storage_imm->_async_mode, 'immediate', 'the other instance is in immediate mode';
  $storage_imm->mock_persistent(qr/FROM "artist"/i, [ @ARTIST_ROWS ]);

  my @real = $storage_real->select_async(artist_select_args($schema_real))->get;
  my @imm  = $storage_imm->select_async(artist_select_args($schema_imm))->get;

  # The property: identical transport form across the two backends.
  is_deeply \@imm, \@real,
    'immediate select_async resolves with the same form as a real backend';

  # And spell out that form concretely, so a regression to a cursor / flat list
  # cannot pass by merely matching a same-shaped real backend.
  is scalar @imm, 2, 'select_async resolves with the two raw rows, as a list';
  is ref $imm[0], 'ARRAY',
    'each resolved row is a raw arrayref, not a cursor object';
  ok !Scalar::Util::blessed($imm[0]),
    'the resolved element is an unblessed arrayref (not a FakeCursor)';
  is_deeply $imm[0], [ 1, 'Miles Davis', 13, undef ],
    'first raw row carries the column values in select order';
  is_deeply $imm[1], [ 2, 'John Coltrane', 13, undef ],
    'second raw row too';
}

# -----------------------------------------------------------------------
# select_single_async: immediate resolves with a SINGLE arrayref, matching a
# real backend -- not the flat (col, col, ...) list it used to pass through.
# -----------------------------------------------------------------------
{
  my $schema_real  = DBIO::Test->init_schema;
  my $storage_real = set_mode($schema_real->storage, 'selectmock');
  $storage_real->mock_persistent(qr/FROM "artist"/i, [ [ 7, 'Sun Ra', 13, undef ] ]);

  my $schema_imm  = DBIO::Test->init_schema;
  my $storage_imm = $schema_imm->storage;
  $storage_imm->mock_persistent(qr/FROM "artist"/i, [ [ 7, 'Sun Ra', 13, undef ] ]);

  my $real = $storage_real->select_single_async(artist_single_args($schema_real, 7))->get;
  my $imm  = $storage_imm->select_single_async(artist_single_args($schema_imm, 7))->get;

  is_deeply $imm, $real,
    'immediate select_single_async resolves with the same form as a real backend';
  is ref $imm, 'ARRAY',
    'select_single_async resolves with a single arrayref, not a flat list';
  ok !Scalar::Util::blessed($imm), 'and it is an unblessed arrayref';
  is_deeply $imm, [ 7, 'Sun Ra', 13, undef ],
    'the single arrayref carries the row column values';
}

# -----------------------------------------------------------------------
# select_single_async with no matching row resolves with undef in BOTH modes.
# -----------------------------------------------------------------------
{
  my $schema_real  = DBIO::Test->init_schema;
  my $storage_real = set_mode($schema_real->storage, 'selectmock');
  $storage_real->mock_persistent(qr/FROM "artist"/i, []);

  my $schema_imm  = DBIO::Test->init_schema;
  my $storage_imm = $schema_imm->storage;
  $storage_imm->mock_persistent(qr/FROM "artist"/i, []);

  my $real = $storage_real->select_single_async(artist_single_args($schema_real, 99))->get;
  my $imm  = $storage_imm->select_single_async(artist_single_args($schema_imm, 99))->get;

  is $real, undef, 'a real backend resolves select_single_async with undef when empty';
  is $imm,  undef, 'immediate resolves select_single_async with undef when empty too';
}

done_testing;
