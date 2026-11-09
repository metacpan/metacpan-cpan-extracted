use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';
use DBIO::PostgreSQL::Vector qw(vector);

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);

my $rs = $schema->resultset('Artist');

# Shorthand: just the SELECT columns we always get for Artist
my $sel = q{"me"."artistid", "me"."name", "me"."rank", "me"."charfield"};

# Query vector reused by the threshold tests
my $v = [ 0.1, 0.2 ];

# ---------------------------------------------------------------------------
# KNN: as_order — all six distance operators
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->l2_distance([ 0.1, 0.2 ])->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <-> ?::vector) )},
  [ [ {} => '[0.1,0.2]' ] ],
  'l2_distance — <-> KNN order',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->max_inner_product([ 0.1, 0.2 ])->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <#> ?::vector) )},
  [ [ {} => '[0.1,0.2]' ] ],
  'max_inner_product — <#> KNN order',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->cosine_distance([ 0.1, 0.2 ])->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <=> ?::vector) )},
  [ [ {} => '[0.1,0.2]' ] ],
  'cosine_distance — <=> KNN order',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->cosine_distance([ 0.1, 0.2 ])->as_order, rows => 5 } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <=> ?::vector) LIMIT ? )},
  [ [ {} => '[0.1,0.2]' ], [ { sqlt_datatype => 'integer' } => 5 ] ],
  'cosine_distance KNN with rows — nearest-neighbors shape',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->l1_distance([ 0.1, 0.2 ])->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <+> ?::vector) )},
  [ [ {} => '[0.1,0.2]' ] ],
  'l1_distance — <+> KNN order',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->hamming_distance('101010')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <~> ?::bit) )},
  [ [ {} => '101010' ] ],
  'hamming_distance — <~> KNN order, bit cast forced',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->jaccard_distance('101010')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <%> ?::bit) )},
  [ [ {} => '101010' ] ],
  'jaccard_distance — <%> KNN order, bit cast forced',
);

# ---------------------------------------------------------------------------
# KNN: as_order under -desc
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { order_by => { -desc => vector('me.embedding')->l2_distance([ 0.1, 0.2 ])->as_order } } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <-> ?::vector) DESC )},
  [ [ {} => '[0.1,0.2]' ] ],
  'as_order under -desc',
);

# ---------------------------------------------------------------------------
# Query-vector serialization
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->l2_distance('[0.1, 0.2]')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <-> ?::vector) )},
  [ [ {} => '[0.1, 0.2]' ] ],
  'plain string query vector — passed through verbatim',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding')->l2_distance({ dims => 3, values => { 0 => 0.1, 2 => 0.2 } })->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <-> ?::sparsevec) )},
  [ [ {} => '{0:0.1,2:0.2}/3' ] ],
  'sparsevec hashref — {i:v,...}/dims serialization with sparsevec cast',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding', cast => 'halfvec')->cosine_distance([ 0.1, 0.2 ])->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <=> ?::halfvec) )},
  [ [ {} => '[0.1,0.2]' ] ],
  'explicit cast option — halfvec override',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => vector('me.embedding', cast => 'halfvec')->hamming_distance('101010')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.embedding <~> ?::bit) )},
  [ [ {} => '101010' ] ],
  'hamming forces bit over an explicit cast — the operator only exists for bit columns',
);

# ---------------------------------------------------------------------------
# Threshold: distance-range filter in WHERE (lt / le / gt / ge)
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( vector('me.embedding')->l2_distance($v)->lt(5) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE ( (me.embedding <-> ?::vector) < ? ) )},
  [ [ {} => '[0.1,0.2]' ], [ {} => 5 ] ],
  'l2_distance()->lt() — distance range filter',
);

is_same_sql_bind(
  $rs->search( vector('me.embedding')->l2_distance($v)->le(5) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE ( (me.embedding <-> ?::vector) <= ? ) )},
  [ [ {} => '[0.1,0.2]' ], [ {} => 5 ] ],
  'l2_distance()->le()',
);

is_same_sql_bind(
  $rs->search( vector('me.embedding')->cosine_distance($v)->gt(0.8) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE ( (me.embedding <=> ?::vector) > ? ) )},
  [ [ {} => '[0.1,0.2]' ], [ {} => 0.8 ] ],
  'cosine_distance()->gt()',
);

is_same_sql_bind(
  $rs->search( vector('me.embedding')->cosine_distance($v)->ge(0.8) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE ( (me.embedding <=> ?::vector) >= ? ) )},
  [ [ {} => '[0.1,0.2]' ], [ {} => 0.8 ] ],
  'cosine_distance()->ge()',
);

# ---------------------------------------------------------------------------
# Threshold combined with a regular condition
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search({
    -and => [
      vector('me.embedding')->l2_distance($v)->le(3),
      { 'me.rank' => 13 },
    ],
  })->as_query,
  qq{( SELECT $sel FROM "artist" "me"
       WHERE ( (me.embedding <-> ?::vector) <= ? AND "me"."rank" = ? ) )},
  [ [ {} => '[0.1,0.2]' ], [ {} => 3 ], [ { sqlt_datatype => 'integer', dbic_colname => 'me.rank' } => 13 ] ],
  'distance filter combined with a regular condition',
);

# ---------------------------------------------------------------------------
# SELECT: as_select
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { select => [ vector('me.embedding')->l2_distance($v)->as_select('distance') ] } )->as_query,
  qq{( SELECT (me.embedding <-> ?::vector) AS distance FROM "artist" "me" )},
  [ [ {} => '[0.1,0.2]' ] ],
  'as_select — selecting the distance under an alias',
);

# ---------------------------------------------------------------------------
# Column and alias are code: letters, digits, underscores and dots (karr k155)
# ---------------------------------------------------------------------------

for my $bad ('me.embedding; DROP TABLE t; --', 'me embedding', '"me"."e"', '', undef) {
  my $ok = eval { vector($bad); 1 };
  my $err = "$@";
  ok !$ok, 'vector(): a column other than a plain identifier throws: ' . (defined $bad ? "'$bad'" : 'undef');
  unlike $err, qr/DROP TABLE/, '... and the message does not repeat it' if defined $bad;
}

for my $bad ('d; DROP TABLE t', 'a b', '"d"', '') {
  my $ok = eval { vector('me.embedding')->l2_distance($v)->as_select($bad); 1 };
  my $err = "$@";
  ok !$ok, "as_select: an alias other than a plain identifier throws: '$bad'";
  unlike $err, qr/DROP TABLE/, '... and the message does not repeat it';
}

done_testing;
