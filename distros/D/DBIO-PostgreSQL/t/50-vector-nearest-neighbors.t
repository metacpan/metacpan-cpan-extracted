use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';
use DBIO::PostgreSQL::ResultSet;

# karr k38 -- one-call KNN on top of the vector() DSL (karr k37).
#
# WHY this test exists: the sugar has to be reachable without the user naming a
# ResultSet class, and it has to build the SAME query a hand-written vector()
# call would -- ordered by the distance the caller named, with that distance
# also selected so the row can report it. Two things are therefore load-bearing
# here and neither is cosmetic:
#
#   1. Declaring a pgvector column is the whole opt-in. If the resultset_class
#      promotion in DBIO::PostgreSQL::Result stops firing, nearest_neighbors
#      is simply not there -- and the promotion must NOT fire on a type that
#      merely looks like one (tsvector) or trample a user's own resultset.
#   2. The distance keyword decides the operator, and the operator decides
#      whether an hnsw/ivfflat index can serve the query at all (karr k39): a
#      wrong operator is not an error, it is a silent sequential scan. So the
#      keyword -> operator mapping is a contract, not an implementation detail.

# ---------------------------------------------------------------------------
# resultset_class promotion (DBIO::PostgreSQL::Result::register_column)
# ---------------------------------------------------------------------------

{
  package NN::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('items');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    name      => { data_type => 'text' },
    embedding => { data_type => 'vector(3)' },
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  NN::Result::Item->result_source_instance->resultset_class,
  'DBIO::PostgreSQL::ResultSet',
  'vector(3) column promotes resultset_class -- declaring the column is the whole opt-in',
);

{
  package NN::Result::Bare;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('bare');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    half      => { data_type => 'halfvec(3)' },
    sparse    => { data_type => 'sparsevec(3)' },
    embedding => { data_type => 'vector' },       # no dimension
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  NN::Result::Bare->result_source_instance->resultset_class,
  'DBIO::PostgreSQL::ResultSet',
  'halfvec/sparsevec/dimensionless vector promote too',
);

{
  package NN::Result::NoVector;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('no_vector');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer' },
    body    => { data_type => 'text' },
    indexed => { data_type => 'tsvector' },   # NOT a pgvector type
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  NN::Result::NoVector->result_source_instance->resultset_class,
  'DBIO::ResultSet',
  'tsvector is a full-text type, not a pgvector one -- no promotion',
);

{
  package NN::ResultSet::Custom;
  use base 'DBIO::PostgreSQL::ResultSet';
  sub my_own_method {1}
}

{
  package NN::Result::CustomRS;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('custom_rs');
  __PACKAGE__->resultset_class('NN::ResultSet::Custom');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    embedding => { data_type => 'vector(3)' },
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  NN::Result::CustomRS->result_source_instance->resultset_class,
  'NN::ResultSet::Custom',
  'a resultset subclassing DBIO::PostgreSQL::ResultSet survives the promotion',
);

# ---------------------------------------------------------------------------
# Generated SQL
# ---------------------------------------------------------------------------

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);

# Artist has no embedding column offline -- the distance expression is a
# literal, exactly as in t/26-vector.t, so this stays an offline test.
$schema->source('Artist')->resultset_class('DBIO::PostgreSQL::ResultSet');

my $rs = $schema->resultset('Artist');
my $sel = q{"me"."artistid", "me"."name", "me"."rank", "me"."charfield"};
my $v   = [ 0.1, 0.2 ];

isa_ok( $rs, 'DBIO::PostgreSQL::ResultSet', 'promoted source hands out' );

is_same_sql_bind(
  $rs->nearest_neighbors( embedding => $v, distance => 'cosine', rows => 5 )->as_query,
  qq{(
    SELECT $sel, (me.embedding <=> ?::vector) AS neighbor_distance
      FROM "artist" "me"
     ORDER BY (me.embedding <=> ?::vector)
     LIMIT ?
  )},
  [
    [ {} => '[0.1,0.2]' ],
    [ {} => '[0.1,0.2]' ],
    [ { sqlt_datatype => 'integer' } => 5 ],
  ],
  'nearest_neighbors -- distance selected, KNN order, rows as LIMIT',
);

# Keyword -> operator. The whole point of the keyword set: it is the Rails
# neighbor gem's, so ported queries keep their strings. The cast column is
# the placeholder cast each operator forces: hamming/jaccard only exist for
# bit columns, so they cast to bit even without an explicit cast option.
my @keywords = (
  [ euclidean     => '<->' => 'vector' ],
  [ l2            => '<->' => 'vector' ],
  [ cosine        => '<=>' => 'vector' ],
  [ inner_product => '<#>' => 'vector' ],
  [ taxicab       => '<+>' => 'vector' ],
  [ l1            => '<+>' => 'vector' ],
  [ hamming       => '<~>' => 'bit' ],
  [ jaccard       => '<%>' => 'bit' ],
);

for my $pair (@keywords) {
  my ( $keyword, $op, $cast ) = @$pair;
  is_same_sql_bind(
    $rs->nearest_neighbors( embedding => $v, distance => $keyword )->as_query,
    qq{(
      SELECT $sel, (me.embedding $op ?::$cast) AS neighbor_distance
        FROM "artist" "me"
       ORDER BY (me.embedding $op ?::$cast)
    )},
    [ [ {} => '[0.1,0.2]' ], [ {} => '[0.1,0.2]' ] ],
    "distance => '$keyword' renders $op with ?::$cast",
  );
}

is_same_sql_bind(
  $rs->nearest_neighbors( embedding => $v, distance => 'COSINE' )->as_query,
  qq{(
    SELECT $sel, (me.embedding <=> ?::vector) AS neighbor_distance
      FROM "artist" "me"
     ORDER BY (me.embedding <=> ?::vector)
  )},
  [ [ {} => '[0.1,0.2]' ], [ {} => '[0.1,0.2]' ] ],
  'distance keywords are case-insensitive',
);

is_deeply(
  [ grep { $_ eq 'neighbor_distance' } @{ $rs->nearest_neighbors( embedding => $v, distance => 'l2' )->_resolved_attrs->{as} } ],
  ['neighbor_distance'],
  'the distance is registered as neighbor_distance, so get_column reaches it',
);

# ---------------------------------------------------------------------------
# Column qualification
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { alias => 'artist' } )->nearest_neighbors( embedding => $v, distance => 'l2' )->as_query,
  qq{(
    SELECT "artist"."artistid", "artist"."name", "artist"."rank", "artist"."charfield",
           (artist.embedding <-> ?::vector) AS neighbor_distance
      FROM "artist" "artist"
     ORDER BY (artist.embedding <-> ?::vector)
  )},
  [ [ {} => '[0.1,0.2]' ], [ {} => '[0.1,0.2]' ] ],
  'an unqualified column resolves against the current source alias',
);

is_same_sql_bind(
  $rs->nearest_neighbors( 'other.embedding', $v, distance => 'l2' )->as_query,
  qq{(
    SELECT $sel, (other.embedding <-> ?::vector) AS neighbor_distance
      FROM "artist" "me"
     ORDER BY (other.embedding <-> ?::vector)
  )},
  [ [ {} => '[0.1,0.2]' ], [ {} => '[0.1,0.2]' ] ],
  'an already-qualified column is passed through untouched',
);

# ---------------------------------------------------------------------------
# cast passthrough -- hamming/jaccard are bit-column operators
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->nearest_neighbors( embedding => '101010', distance => 'hamming', cast => 'bit' )->as_query,
  qq{(
    SELECT $sel, (me.embedding <~> ?::bit) AS neighbor_distance
      FROM "artist" "me"
     ORDER BY (me.embedding <~> ?::bit)
  )},
  [ [ {} => '101010' ], [ {} => '101010' ] ],
  'cast reaches vector() -- bit column with Hamming distance',
);

is_same_sql_bind(
  $rs->nearest_neighbors( embedding => { dims => 3, values => { 0 => 0.1, 2 => 0.2 } }, distance => 'l2' )->as_query,
  qq{(
    SELECT $sel, (me.embedding <-> ?::sparsevec) AS neighbor_distance
      FROM "artist" "me"
     ORDER BY (me.embedding <-> ?::sparsevec)
  )},
  [ [ {} => '{0:0.1,2:0.2}/3' ], [ {} => '{0:0.1,2:0.2}/3' ] ],
  'a sparsevec query vector casts itself, as in the vector() DSL',
);

# ---------------------------------------------------------------------------
# Chaining -- the sugar returns an ordinary resultset
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->nearest_neighbors( embedding => $v, distance => 'cosine' )->search( { 'me.rank' => 13 } )->as_query,
  qq{(
    SELECT $sel, (me.embedding <=> ?::vector) AS neighbor_distance
      FROM "artist" "me"
     WHERE "me"."rank" = ?
     ORDER BY (me.embedding <=> ?::vector)
  )},
  [
    [ {} => '[0.1,0.2]' ],
    [ { sqlt_datatype => 'integer', dbic_colname => 'me.rank' } => 13 ],
    [ {} => '[0.1,0.2]' ],
  ],
  'the returned resultset chains with a plain search',
);

# ---------------------------------------------------------------------------
# Errors -- a mis-named metric must never quietly become another one
# ---------------------------------------------------------------------------

throws_ok {
  $rs->nearest_neighbors( embedding => $v, distance => 'manhattan' );
}
qr/unknown distance 'manhattan'/, 'an unknown distance keyword throws';

isa_ok( $@, 'DBIO::Exception', 'the thrown error' );

throws_ok {
  $rs->nearest_neighbors( embedding => $v );
}
qr/distance is required/, 'a missing distance throws instead of guessing a metric';

throws_ok {
  $rs->nearest_neighbors( embedding => $v, distance => 'l2', row => 5 );
}
qr/unknown option 'row'/, 'a mistyped option throws instead of being ignored';

# karr k57 -- the cast option is interpolated unquoted into the SQL string, so
# an attacker-supplied cast is SQL injection unless the value is whitelisted.
throws_ok {
  $rs->nearest_neighbors( embedding => $v, distance => 'l2', cast => 'vector); DROP TABLE x; --' );
}
qr/unknown cast/, 'a malicious cast string throws instead of reaching the SQL';

isa_ok( $@, 'DBIO::Exception', 'the thrown error' );

# karr k155 -- the column is code, written into the SQL: a plain identifier
# (letters, digits, underscores, dots) or an exception that does not repeat it.
throws_ok {
  $rs->nearest_neighbors( 'embedding; DROP TABLE x; --' => $v, distance => 'l2' );
}
qr/plain identifier/, 'a column that is no plain identifier throws';
unlike( $@, qr/DROP TABLE/, '... and the message does not repeat it' );

lives_ok {
  $rs->nearest_neighbors( embedding => $v, distance => 'l2' );
} 'a plain column does not';

done_testing;
