use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';
use DBIO::PostgreSQL::JSONB qw(jsonb);

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);

my $rs = $schema->resultset('Artist');

# Shorthand: just the SELECT columns we always get for Artist
my $sel = q{"me"."artistid", "me"."name", "me"."rank", "me"."charfield"};

# ---------------------------------------------------------------------------
# Containment: @>
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search({ 'me.data' => { '@>' => { status => 'active' } } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" @> ?::jsonb )},
  [ [ {} => '{"status":"active"}' ] ],
  '@> hashref — JSON-serialized',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '@>' => { role => 'admin', active => \1 } } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" @> ?::jsonb )},
  [ [ {} => '{"active":true,"role":"admin"}' ] ],
  '@> hashref — multiple keys, canonical JSON order',
);

is_same_sql_bind(
  $rs->search({ 'me.tags' => { '@>' => ['admin', 'user'] } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."tags" @> ?::jsonb )},
  [ [ {} => '["admin","user"]' ] ],
  '@> arrayref — JSON array',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '@>' => '{"role":"admin"}' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" @> ?::jsonb )},
  [ [ {} => '{"role":"admin"}' ] ],
  '@> plain string — passed through as-is',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '@>' => \'other_col' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" @> other_col )},
  [],
  '@> scalar ref — literal SQL, no binding',
);

# ---------------------------------------------------------------------------
# Contained-by: <@
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search({ 'me.tags' => { '<@' => ['a', 'b'] } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."tags" <@ ?::jsonb )},
  [ [ {} => '["a","b"]' ] ],
  '<@ arrayref — contained-by',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '<@' => { role => 'guest' } } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" <@ ?::jsonb )},
  [ [ {} => '{"role":"guest"}' ] ],
  '<@ hashref — contained-by',
);

# ---------------------------------------------------------------------------
# Key existence: ? ?| ?&
# (rewritten as jsonb_exists* to avoid DBI placeholder conflict)
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search({ 'me.data' => { '?' => 'email' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE jsonb_exists("me"."data", ?) )},
  [ [ {} => 'email' ] ],
  '? key-existence — jsonb_exists()',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '?|' => [qw(email phone)] } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE jsonb_exists_any("me"."data", ARRAY[?, ?]) )},
  [ [ {} => 'email' ], [ {} => 'phone' ] ],
  '?| any-key — jsonb_exists_any()',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '?&' => [qw(name email)] } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE jsonb_exists_all("me"."data", ARRAY[?, ?]) )},
  [ [ {} => 'name' ], [ {} => 'email' ] ],
  '?& all-keys — jsonb_exists_all()',
);

# single string for ?| and ?& (convenience)
is_same_sql_bind(
  $rs->search({ 'me.data' => { '?|' => 'email' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE jsonb_exists_any("me"."data", ARRAY[?]) )},
  [ [ {} => 'email' ] ],
  '?| single string — one-element ARRAY[]',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '?&' => 'email' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE jsonb_exists_all("me"."data", ARRAY[?]) )},
  [ [ {} => 'email' ] ],
  '?& single string — one-element ARRAY[]',
);

# ---------------------------------------------------------------------------
# JSONPath: @? @@  (PostgreSQL 12+)
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search({ 'me.data' => { '@?' => '$.status == "active"' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" @? ?::jsonpath )},
  [ [ {} => '$.status == "active"' ] ],
  '@? JSONPath predicate',
);

is_same_sql_bind(
  $rs->search({ 'me.data' => { '@@' => '$.score > 10' } })->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE "me"."data" @@ ?::jsonpath )},
  [ [ {} => '$.score > 10' ] ],
  '@@ JSONPath match',
);

# ---------------------------------------------------------------------------
# DBIO::PostgreSQL::JSONB — eq / ne
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'status')->eq('active') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>'status') = ? )},
  [ [ {} => 'active' ] ],
  'jsonb()->eq() single-key path',
);

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'status')->ne('deleted') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>'status') != ? )},
  [ [ {} => 'deleted' ] ],
  'jsonb()->ne()',
);

# ---------------------------------------------------------------------------
# Nested path
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.config', 'theme', 'color')->eq('dark') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.config#>>'{theme,color}') = ? )},
  [ [ {} => 'dark' ] ],
  'jsonb()->eq() nested path — #>>',
);

# ---------------------------------------------------------------------------
# Numeric comparisons: lt / le / gt / ge
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->gt(100) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>'score') > ? )},
  [ [ {} => 100 ] ],
  'jsonb()->gt()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->ge(100) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>'score') >= ? )},
  [ [ {} => 100 ] ],
  'jsonb()->ge()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->lt(50) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>'score') < ? )},
  [ [ {} => 50 ] ],
  'jsonb()->lt()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->le(50) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>'score') <= ? )},
  [ [ {} => 50 ] ],
  'jsonb()->le()',
);

# ---------------------------------------------------------------------------
# Pattern matching: like / ilike
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'name')->like('John%') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>'name') LIKE ? )},
  [ [ {} => 'John%' ] ],
  'jsonb()->like()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.attrs', 'name')->ilike('%smith%') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.attrs->>'name') ILIKE ? )},
  [ [ {} => '%smith%' ] ],
  'jsonb()->ilike()',
);

# ---------------------------------------------------------------------------
# NULL checks: is_null / is_not_null
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'avatar')->is_null )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>'avatar') IS NULL )},
  [],
  'jsonb()->is_null',
);

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'email')->is_not_null )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>'email') IS NOT NULL )},
  [],
  'jsonb()->is_not_null',
);

# ---------------------------------------------------------------------------
# ORDER BY: as_order
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { order_by => jsonb('me.score', 'total')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.score->>'total') )},
  [],
  'jsonb()->as_order() ascending',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => { -desc => jsonb('me.score', 'total')->as_order } } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.score->>'total') DESC )},
  [],
  'jsonb()->as_order() with -desc',
);

# ---------------------------------------------------------------------------
# Combined: path DSL + containment operator in one search
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search([
    jsonb('me.data', 'status')->eq('published'),
    { 'me.data' => { '@>' => { featured => \1 } } },
  ])->as_query,
  qq{( SELECT $sel FROM "artist" "me"
       WHERE ( (me.data->>'status') = ?
          OR   "me"."data" @> ?::jsonb ) )},
  [ [ {} => 'published' ], [ {} => '{"featured":true}' ] ],
  'path DSL and @> containment combined with OR',
);

done_testing;
