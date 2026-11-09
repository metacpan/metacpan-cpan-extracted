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
# The operators are written as operators, with the ? of each as '\?' (a bare
# ? is a DBI placeholder, '\?' its literal question mark), so a GIN index
# over the column answers them (karr k121). The text is held to the
# character: a comparison that normalises SQL is no witness for a backslash.
# ---------------------------------------------------------------------------

for my $case (
  [ '? key-existence',  { '?'  => 'email' },
    q{"me"."data" \\? ?},                [ 'email' ] ],
  [ '?| any-key',       { '?|' => [qw(email phone)] },
    q{"me"."data" \\?| ARRAY[?, ?]},     [ 'email', 'phone' ] ],
  [ '?& all-keys',      { '?&' => [qw(name email)] },
    q{"me"."data" \\?& ARRAY[?, ?]},     [ 'name', 'email' ] ],
  # single string for ?| and ?& (convenience)
  [ '?| single string — one-element ARRAY[]', { '?|' => 'email' },
    q{"me"."data" \\?| ARRAY[?]},        [ 'email' ] ],
  [ '?& single string — one-element ARRAY[]', { '?&' => 'email' },
    q{"me"."data" \\?& ARRAY[?]},        [ 'email' ] ],
) {
  my ($name, $cond, $where, $binds) = @$case;
  my ($sql, @bind) = @${ $rs->search({ 'me.data' => $cond })->as_query };
  is $sql, qq{(SELECT $sel FROM "artist" "me" WHERE ( $where ))},
    "$name: as_query shows the operator, not jsonb_exists*()";
  is_deeply [ map { $_->[1] } @bind ], $binds, '... with one bind per key';
}

# ---------------------------------------------------------------------------
# JSONPath: @? @@  (PostgreSQL 12+)
# ---------------------------------------------------------------------------

# The operator is written '@\?': a bare '?' is a placeholder to DBD::Pg, and
# '\?' is its literal question mark, so the statement has one placeholder for
# its one bind and runs at the dbh; the future_io transport drops the
# backslash when it numbers (DBIO::PostgreSQL::Util::number_placeholders).
# as_query shows what the maker wrote (karr k120). The text is held to the
# character: a comparison that normalises SQL is no witness for a backslash.
{
  my $query = $rs->search({ 'me.data' => { '@?' => '$.status == "active"' } })->as_query;
  my ($sql, @bind) = @$$query;

  is $sql,
    qq{(SELECT $sel FROM "artist" "me" WHERE ( "me"."data" \@\\? ?::jsonpath ))},
    '@? JSONPath predicate: as_query shows the operator as @\?';
  is_deeply [ map { $_->[1] } @bind ], [ '$.status == "active"' ],
    '... with the jsonpath as its one bind';

  my $bare = () = $sql =~ /(?<!\\)\?/g;
  is $bare, scalar(@bind),
    '... and one ? that is no \? for each bind: what DBD::Pg counts at the dbh';
}

# The same beside another condition, and inside a subquery: the operator keeps
# its backslash wherever the statement is put together.
{
  my $inner = $rs->search({ 'me.data' => { '@?' => '$.a' }, 'me.rank' => 3 });
  my ($sql, @bind) = @${ $inner->as_query };
  like $sql, qr/"me"\."data" \@\\\? \?::jsonpath/, '@? beside a bound column is @\?';
  my $bare = () = $sql =~ /(?<!\\)\?/g;
  is $bare, scalar(@bind), '... one bare ? per bind';

  my $outer = $rs->search({ 'me.artistid' => { -in => $inner->get_column('artistid')->as_query } });
  ($sql, @bind) = @${ $outer->as_query };
  like $sql, qr/\@\\\? \?::jsonpath/, '@? in a subquery is @\?';
  $bare = () = $sql =~ /(?<!\\)\?/g;
  is $bare, scalar(@bind), '... one bare ? per bind';
}

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
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>?) = ? )},
  [ [ {} => 'status' ], [ {} => 'active' ] ],
  'jsonb()->eq() single-key path',
);

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'status')->ne('deleted') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>?) != ? )},
  [ [ {} => 'status' ], [ {} => 'deleted' ] ],
  'jsonb()->ne()',
);

# ---------------------------------------------------------------------------
# Nested path
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.config', 'theme', 'color')->eq('dark') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.config#>>?::text[]) = ? )},
  [ [ {} => '{"theme","color"}' ], [ {} => 'dark' ] ],
  'jsonb()->eq() nested path — #>>',
);

# ---------------------------------------------------------------------------
# Numeric comparisons: lt / le / gt / ge
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->gt(100) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>?) > ? )},
  [ [ {} => 'score' ], [ {} => 100 ] ],
  'jsonb()->gt()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->ge(100) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>?) >= ? )},
  [ [ {} => 'score' ], [ {} => 100 ] ],
  'jsonb()->ge()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->lt(50) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>?) < ? )},
  [ [ {} => 'score' ], [ {} => 50 ] ],
  'jsonb()->lt()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.stats', 'score')->le(50) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.stats->>?) <= ? )},
  [ [ {} => 'score' ], [ {} => 50 ] ],
  'jsonb()->le()',
);

# ---------------------------------------------------------------------------
# Pattern matching: like / ilike
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'name')->like('John%') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>?) LIKE ? )},
  [ [ {} => 'name' ], [ {} => 'John%' ] ],
  'jsonb()->like()',
);

is_same_sql_bind(
  $rs->search( jsonb('me.attrs', 'name')->ilike('%smith%') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.attrs->>?) ILIKE ? )},
  [ [ {} => 'name' ], [ {} => '%smith%' ] ],
  'jsonb()->ilike()',
);

# ---------------------------------------------------------------------------
# NULL checks: is_null / is_not_null
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'avatar')->is_null )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>?) IS NULL )},
  [ [ {} => 'avatar' ] ],
  'jsonb()->is_null',
);

is_same_sql_bind(
  $rs->search( jsonb('me.data', 'email')->is_not_null )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>?) IS NOT NULL )},
  [ [ {} => 'email' ] ],
  'jsonb()->is_not_null',
);

# ---------------------------------------------------------------------------
# ORDER BY: as_order
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { order_by => jsonb('me.score', 'total')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.score->>?) )},
  [ [ {} => 'total' ] ],
  'jsonb()->as_order() ascending',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => { -desc => jsonb('me.score', 'total')->as_order } } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY (me.score->>?) DESC )},
  [ [ {} => 'total' ] ],
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
       WHERE ( (me.data->>?) = ?
          OR   "me"."data" @> ?::jsonb ) )},
  [ [ {} => 'status' ], [ {} => 'published' ], [ {} => '{"featured":true}' ] ],
  'path DSL and @> containment combined with OR',
);

# ---------------------------------------------------------------------------
# Path elements are binds, the column is code (karr k155)
# ---------------------------------------------------------------------------

{
  my $evil = q{x' || (select 1) || '};
  is_same_sql_bind(
    $rs->search( jsonb('me.data', $evil)->eq('a') )->as_query,
    qq{( SELECT $sel FROM "artist" "me" WHERE (me.data->>?) = ? )},
    [ [ {} => $evil ], [ {} => 'a' ] ],
    'a path element with a quote is a bind, not part of the statement',
  );

  is_same_sql_bind(
    $rs->search( jsonb('me.data', 'a"b', 'c\\d', 'e,f')->is_null )->as_query,
    qq{( SELECT $sel FROM "artist" "me" WHERE (me.data#>>?::text[]) IS NULL )},
    [ [ {} => '{"a\\"b","c\\\\d","e,f"}' ] ],
    'a nested path is one text[] literal, its elements quoted and escaped',
  );

  for my $bad ('me.data; DROP TABLE t; --', 'me data', '"me"."data"', '', undef) {
    my $ok = eval { jsonb($bad, 'k'); 1 };
    my $err = "$@";
    ok !$ok, 'a column other than letters, digits, underscores and dots throws: '
      . (defined $bad ? "'$bad'" : 'undef');
    unlike $err, qr/DROP TABLE/, '... and the message does not repeat it' if defined $bad;
  }
}

done_testing;
