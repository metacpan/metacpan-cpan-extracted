use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';
use DBIO::PostgreSQL::InflateColumn::Vector;

# karr k40 -- pgvector columns inflate/deflate by default.
#
# WHY this test exists: the acceptance criterion is that
#   $row->update({ embedding => [0.1, 0.2, 0.3] })
# stores the serialized pgvector text and reads back an arrayref WITHOUT user
# glue. That makes inflation the default for vector/halfvec/sparsevec columns
# (a deliberate deviation from the jsonb opt-in precedent -- see the ticket
# note), so two things are load-bearing here:
#
#   1. Declaring a pgvector column is the whole opt-in. DBIO::PostgreSQL::Result
#      loads InflateColumn::Vector, whose register_column hook wires inflate/
#      deflate for every vector/halfvec/sparsevec column. A plain string must
#      pass through verbatim (idempotence -- never double-serialize), and a
#      non-pgvector column must be untouched.
#   2. The deflate path is the insert/update bind path. In search(), SQL::Abstract
#      expands an arrayref to an IN list and a hashref to a condition hash
#      BEFORE any deflate could see them -- that is DBIC semantics and stays
#      that way; vector search goes through the vector() DSL (karr k37) or a
#      string literal.

# ---------------------------------------------------------------------------
# Result classes
# ---------------------------------------------------------------------------

{
  package VI::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('items');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    embedding => { data_type => 'vector(3)' },
    half      => { data_type => 'halfvec(3)' },
    sparse    => { data_type => 'sparsevec(3)' },
    plain     => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package VI::Result::NoDims;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('no_dims');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    embedding => { data_type => 'vector' },       # no dimension
    sparse    => { data_type => 'sparsevec' },     # no dimension
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package VI::Result::OptOut;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('opt_out');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    embedding => { data_type => 'vector(3)', inflate_pgvector => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);
$schema->register_class( 'Item',   'VI::Result::Item' );
$schema->register_class( 'NoDims', 'VI::Result::NoDims' );
$schema->register_class( 'OptOut', 'VI::Result::OptOut' );
my $storage = $schema->storage;

# ---------------------------------------------------------------------------
# Registration -- declaring the column is the whole opt-in
# ---------------------------------------------------------------------------

my $item_info = VI::Result::Item->column_info('embedding');
ok( $item_info->{_inflate_info}, 'vector column carries _inflate_info' );

my $half_info = VI::Result::Item->column_info('half');
ok( $half_info->{_inflate_info}, 'halfvec column carries _inflate_info' );

my $sparse_info = VI::Result::Item->column_info('sparse');
ok( $sparse_info->{_inflate_info}, 'sparsevec column carries _inflate_info' );

my $plain_info = VI::Result::Item->column_info('plain');
ok( !$plain_info->{_inflate_info}, 'plain text column is untouched (zero change)' );

my $optout_info = VI::Result::OptOut->column_info('embedding');
ok( !$optout_info->{_inflate_info}, 'inflate_pgvector => 0 opts out of inflation' );

# ---------------------------------------------------------------------------
# Deflate -- insert binds
# ---------------------------------------------------------------------------

sub _insert_bind {
  my ( $rs, $vals ) = @_;
  $storage->reset_captured;
  $rs->create($vals);
  my @inserts = grep { $_->{sql} =~ /\AINSERT/ } $storage->captured_queries;
  return $inserts[0]{bind}[0][1];
}

is(
  _insert_bind( $schema->resultset('Item'), { embedding => [ 0.1, 0.2, 0.3 ] } ),
  '[0.1,0.2,0.3]',
  'insert bind: vector arrayref deflates to pgvector text',
);

is(
  _insert_bind( $schema->resultset('Item'), { half => [ 0.1, 0.2 ] } ),
  '[0.1,0.2]',
  'insert bind: halfvec arrayref deflates',
);

is(
  _insert_bind( $schema->resultset('Item'), { sparse => { 0 => 0.1, 2 => 0.2 } } ),
  '{0:0.1,2:0.2}/3',
  'insert bind: sparsevec hashref deflates with dims from the column size',
);

is(
  _insert_bind(
    $schema->resultset('Item'),
    { sparse => { dims => 3, values => { 0 => 0.1, 2 => 0.2 } } },
  ),
  '{0:0.1,2:0.2}/3',
  'insert bind: sparsevec { dims, values } wrapper deflates',
);

is(
  _insert_bind( $schema->resultset('Item'), { embedding => '[0.1, 0.2]' } ),
  '[0.1, 0.2]',
  'insert bind: a plain string passes through verbatim (idempotent)',
);

is(
  _insert_bind( $schema->resultset('Item'), { plain => 'hello' } ),
  'hello',
  'insert bind: plain text column untouched',
);

# ---------------------------------------------------------------------------
# Deflate -- update binds (the acceptance path)
# ---------------------------------------------------------------------------

$storage->clear_mocks;
$storage->mock(
  qr/SELECT.*FROM "items"/i,
  [ [ 1, '[0.1,0.2,0.3]', '[0.1,0.2]', '{0:0.1,2:0.2}/3', 'hello' ] ],
  [ 'id', 'embedding', 'half', 'sparse', 'plain' ],
);

my $row = $schema->resultset('Item')->find(1);
isa_ok( $row, 'DBIO::Row', 'mock fetch hands out a row' );

$storage->reset_captured;
$row->update({ embedding => [ 0.9, 0.8, 0.7 ] });
my @updates = grep { $_->{sql} =~ /\AUPDATE/ } $storage->captured_queries;
is( $updates[0]{bind}[0][1], '[0.9,0.8,0.7]',
  'update bind: arrayref deflates -- the acceptance path' );

$storage->reset_captured;
$row->update({ sparse => { 1 => 0.5 } });
@updates = grep { $_->{sql} =~ /\AUPDATE/ } $storage->captured_queries;
is( $updates[0]{bind}[0][1], '{1:0.5}/3',
  'update bind: sparsevec hashref deflates with column dims' );

# ---------------------------------------------------------------------------
# Inflate -- fetch
# ---------------------------------------------------------------------------

$storage->clear_mocks;
$storage->mock(
  qr/SELECT.*FROM "items"/i,
  [ [ 1, '[0.1,0.2,0.3]', '[0.1,0.2]', '{0:0.1,2:0.2}/3', 'hello' ] ],
  [ 'id', 'embedding', 'half', 'sparse', 'plain' ],
);

my $fetched = $schema->resultset('Item')->find(1);

is_deeply( $fetched->embedding, [ 0.1, 0.2, 0.3 ],
  'inflate: vector text becomes an arrayref of numbers' );
is_deeply( $fetched->half, [ 0.1, 0.2 ],
  'inflate: halfvec text becomes an arrayref of numbers' );
is_deeply(
  $fetched->sparse,
  { dims => 3, values => { 0 => 0.1, 2 => 0.2 } },
  'inflate: sparsevec text becomes { dims, values }',
);
is( $fetched->plain, 'hello', 'inflate: plain text untouched' );

# A fetched value that does not look like a pgvector literal is returned as-is
$storage->clear_mocks;
$storage->mock(
  qr/SELECT.*FROM "items"/i,
  [ [ 1, 'not-a-vector', '[0.1,0.2]', '{0:0.1,2:0.2}/3', 'hello' ] ],
  [ 'id', 'embedding', 'half', 'sparse', 'plain' ],
);
my $odd = $schema->resultset('Item')->find(1);
is( $odd->embedding, 'not-a-vector',
  'inflate: a non-literal value is returned as-is, not mangled' );

# ---------------------------------------------------------------------------
# Errors -- a sparsevec hashref without dimensions must never guess
# ---------------------------------------------------------------------------

throws_ok {
  _insert_bind( $schema->resultset('NoDims'), { sparse => { 0 => 0.1 } } );
}
qr/cannot deflate a sparsevec hashref without dimensions/,
  'sparsevec hashref on a dimension-less column throws instead of guessing';

# ---------------------------------------------------------------------------
# search() -- DBIC semantics stay intact
# ---------------------------------------------------------------------------

# An arrayref in search() is an IN list, not a vector literal -- SQL::Abstract
# expands it before any deflate could see it. This is DBIC semantics and is
# deliberately left alone; vector search goes through the vector() DSL.
is_same_sql_bind(
  $schema->resultset('Item')->search({ embedding => [ 0.1, 0.2 ] })->as_query,
  qq{( SELECT "me"."id", "me"."embedding", "me"."half", "me"."sparse", "me"."plain"
         FROM "items" "me"
        WHERE ( "embedding" = ? OR "embedding" = ? ) )},
  [
    [ { sqlt_datatype => 'vector(3)', dbic_colname => 'embedding' } => 0.1 ],
    [ { sqlt_datatype => 'vector(3)', dbic_colname => 'embedding' } => 0.2 ],
  ],
  'search with an arrayref stays an IN list -- DBIC semantics preserved',
);

# A string literal in search() passes through verbatim (idempotent)
is_same_sql_bind(
  $schema->resultset('Item')->search({ embedding => '[0.1, 0.2]' })->as_query,
  qq{( SELECT "me"."id", "me"."embedding", "me"."half", "me"."sparse", "me"."plain"
         FROM "items" "me"
        WHERE ( "embedding" = ? ) )},
  [ [ { sqlt_datatype => 'vector(3)', dbic_colname => 'embedding' } => '[0.1, 0.2]' ] ],
  'search with a string literal passes through verbatim',
);

done_testing;
