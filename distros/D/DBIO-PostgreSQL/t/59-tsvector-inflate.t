use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';
use DBIO::PostgreSQL::InflateColumn::TSVector;

# karr k65 -- tsvector columns inflate/deflate by default.
#
# WHY this test exists: the acceptance criterion is that declaring a
# `data_type => 'tsvector'` column is the WHOLE opt-in (ADR 0006), so that
#   $row->update({ body_search => { cat => [3], fat => [2, 4] } })
# stores a raw tsvector literal and reads back a lexeme=>positions hashref
# WITHOUT user glue. Load-bearing properties:
#
#   1. Declaring a tsvector column wires inflate/deflate; a plain-text column
#      is untouched (zero change); inflate_tsvector => 0 opts out per column.
#   2. Whitespace tolerance in the type detector (karr k61): ' tsvector ' is
#      still recognised, exactly as the pgvector detector tolerates padding.
#   3. The deflate path is the insert/update BIND path -- it must emit a raw
#      tsvector literal (a bindable string), NOT a to_tsvector(...) SQL call.
#      A plain string passes through verbatim (idempotence -- never double-
#      serialize); a fetched value that is not a tsvector literal comes back
#      unchanged rather than mangled.
#   4. tsvector must NOT trigger the pgvector resultset promotion -- it is a
#      general-text type, not a pgvector one (see t/56). That is guaranteed by
#      this component owning its OWN detector; here we just assert the inflate
#      behaviour that is this ticket's job.

# ---------------------------------------------------------------------------
# Result classes
# ---------------------------------------------------------------------------

{
  package TSVI::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    search => { data_type => 'tsvector' },
    padded => { data_type => ' tsvector ' },   # karr k61 whitespace tolerance
    plain  => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TSVI::Result::OptOut;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('opt_out');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer' },
    search => { data_type => 'tsvector', inflate_tsvector => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);
$schema->register_class( 'Doc',    'TSVI::Result::Doc' );
$schema->register_class( 'OptOut', 'TSVI::Result::OptOut' );
my $storage = $schema->storage;

# ---------------------------------------------------------------------------
# Registration -- declaring the column is the whole opt-in
# ---------------------------------------------------------------------------

ok( TSVI::Result::Doc->column_info('search')->{_inflate_info},
  'tsvector column carries _inflate_info' );

ok( TSVI::Result::Doc->column_info('padded')->{_inflate_info},
  'a padded " tsvector " data_type is still recognised (karr k61)' );

ok( !TSVI::Result::Doc->column_info('plain')->{_inflate_info},
  'plain text column is untouched (zero change)' );

ok( !TSVI::Result::OptOut->column_info('search')->{_inflate_info},
  'inflate_tsvector => 0 opts out of inflation' );

# ---------------------------------------------------------------------------
# Deflate -- insert binds (the acceptance bind path)
# ---------------------------------------------------------------------------

sub _insert_bind {
  my ( $rs, $vals ) = @_;
  $storage->reset_captured;
  $rs->create($vals);
  my @inserts = grep { $_->{sql} =~ /\AINSERT/ } $storage->captured_queries;
  return $inserts[0]{bind}[0][1];
}

is(
  _insert_bind( $schema->resultset('Doc'),
    { search => { cat => [3], fat => [ 2, 4 ], rat => ['5A'] } } ),
  q{'cat':3 'fat':2,4 'rat':5A},
  'insert bind: hashref deflates to a raw tsvector literal, lexemes sorted',
);

is(
  _insert_bind( $schema->resultset('Doc'), { search => [qw( cat dog )] } ),
  q{'cat' 'dog'},
  'insert bind: arrayref deflates to positionless lexemes',
);

is(
  _insert_bind( $schema->resultset('Doc'), { search => { cat => [], dog => [] } } ),
  q{'cat' 'dog'},
  'insert bind: empty position arrays deflate to bare lexemes',
);

is(
  _insert_bind( $schema->resultset('Doc'), { search => q{'cat':3 'dog':1} } ),
  q{'cat':3 'dog':1},
  'insert bind: a plain string passes through verbatim (idempotent)',
);

is(
  _insert_bind( $schema->resultset('Doc'), { plain => 'hello' } ),
  'hello',
  'insert bind: plain text column untouched',
);

# A ref that is neither a hashref nor an arrayref cannot be deflated -- we
# refuse rather than guess. (A scalarref would be literal SQL in create() and
# never reach deflate, so exercise the deflate seam directly.)
throws_ok {
  DBIO::PostgreSQL::InflateColumn::TSVector->_deflate_tsvector_value( sub { } );
}
qr/tsvector column expects/,
  'a value that is neither hashref, arrayref, nor string throws instead of guessing';

# ---------------------------------------------------------------------------
# Deflate -- update binds
# ---------------------------------------------------------------------------

$storage->clear_mocks;
$storage->mock(
  qr/SELECT.*FROM "docs"/i,
  [ [ 1, q{'cat':3 'fat':2,4}, q{}, 'hello' ] ],
  [ 'id', 'search', 'padded', 'plain' ],
);

my $row = $schema->resultset('Doc')->find(1);
isa_ok( $row, 'DBIO::Row', 'mock fetch hands out a row' );

$storage->reset_captured;
$row->update({ search => { dog => [1], zebra => [] } });
my @updates = grep { $_->{sql} =~ /\AUPDATE/ } $storage->captured_queries;
is( $updates[0]{bind}[0][1], q{'dog':1 'zebra'},
  'update bind: hashref deflates on the update path' );

# ---------------------------------------------------------------------------
# Inflate -- fetch
# ---------------------------------------------------------------------------

$storage->clear_mocks;
$storage->mock(
  qr/SELECT.*FROM "docs"/i,
  [ [ 1, q{'cat':3 'fat':2,4 'rat':5A}, q{}, 'hello' ] ],
  [ 'id', 'search', 'padded', 'plain' ],
);

my $fetched = $schema->resultset('Doc')->find(1);

is_deeply(
  $fetched->search,
  { cat => ['3'], fat => [ '2', '4' ], rat => ['5A'] },
  'inflate: tsvector text becomes a lexeme => positions hashref (weight kept)',
);

is_deeply( $fetched->padded, {},
  q{inflate: the empty tsvector ('') becomes an empty hashref} );

is( $fetched->plain, 'hello', 'inflate: plain text untouched' );

# Round-trip: inflate then deflate reproduces the same literal
is(
  DBIO::PostgreSQL::InflateColumn::TSVector->_deflate_tsvector_value( $fetched->search ),
  q{'cat':3 'fat':2,4 'rat':5A},
  'round-trip: deflate of the inflated structure reproduces the literal',
);

# A fetched value that does not look like a tsvector literal is returned as-is
$storage->clear_mocks;
$storage->mock(
  qr/SELECT.*FROM "docs"/i,
  [ [ 1, 'not a tsvector', q{}, 'hello' ] ],
  [ 'id', 'search', 'padded', 'plain' ],
);
my $odd = $schema->resultset('Doc')->find(1);
is( $odd->search, 'not a tsvector',
  'inflate: a non-literal value is returned as-is, not mangled' );

done_testing;
