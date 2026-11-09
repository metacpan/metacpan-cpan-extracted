use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test ':DiffSQL';
use DBIO::SQLite::JSON qw(json);

my $schema = DBIO::SQLite::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::SQLite::Storage',
);

my $rs = $schema->resultset('Artist');

# Shorthand: the SELECT columns Artist always yields
my $sel = q{"me"."artistid", "me"."name", "me"."rank", "me"."charfield"};

# ---------------------------------------------------------------------------
# The three base extraction forms (as_order gives the bare selector SQL).
# The JSON path is ALWAYS a bind, never interpolated.
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( {}, { order_by => json('me.data')->extract('$.status')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY json_extract(me.data, ?) )},
  [ [ {} => '$.status' ] ],
  'extract() emits json_extract(col, ?) with the path bound',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => json('me.data')->get('$.status')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY me.data -> ? )},
  [ [ {} => '$.status' ] ],
  'get() emits col -> ? (JSON value) with the path bound',
);

is_same_sql_bind(
  $rs->search( {}, { order_by => json('me.data')->get_text('$.status')->as_order } )->as_query,
  qq{( SELECT $sel FROM "artist" "me" ORDER BY me.data ->> ? )},
  [ [ {} => '$.status' ] ],
  'get_text() emits col ->> ? (text value) with the path bound',
);

# ---------------------------------------------------------------------------
# Comparisons — path bind first, then the compared value.
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( json('me.data')->extract('$.status')->eq('active') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (json_extract(me.data, ?)) = ? )},
  [ [ {} => '$.status' ], [ {} => 'active' ] ],
  'extract()->eq()',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get('$.status')->eq('active') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data -> ?) = ? )},
  [ [ {} => '$.status' ], [ {} => 'active' ] ],
  'get()->eq()',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get_text('$.status')->eq('active') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data ->> ?) = ? )},
  [ [ {} => '$.status' ], [ {} => 'active' ] ],
  'get_text()->eq()',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get_text('$.status')->ne('deleted') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data ->> ?) != ? )},
  [ [ {} => '$.status' ], [ {} => 'deleted' ] ],
  'get_text()->ne()',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get_text('$.score')->gt(100) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data ->> ?) > ? )},
  [ [ {} => '$.score' ], [ {} => 100 ] ],
  'get_text()->gt()',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get_text('$.score')->le(50) )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data ->> ?) <= ? )},
  [ [ {} => '$.score' ], [ {} => 50 ] ],
  'get_text()->le()',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get_text('$.name')->like('John%') )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data ->> ?) LIKE ? )},
  [ [ {} => '$.name' ], [ {} => 'John%' ] ],
  'get_text()->like()',
);

# ---------------------------------------------------------------------------
# NULL checks — only the path is bound.
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search( json('me.data')->get_text('$.avatar')->is_null )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data ->> ?) IS NULL )},
  [ [ {} => '$.avatar' ] ],
  'get_text()->is_null',
);

is_same_sql_bind(
  $rs->search( json('me.data')->get('$.meta')->is_not_null )->as_query,
  qq{( SELECT $sel FROM "artist" "me" WHERE (me.data -> ?) IS NOT NULL )},
  [ [ {} => '$.meta' ] ],
  'get()->is_not_null',
);

# ---------------------------------------------------------------------------
# as_select — the extracted value under an alias.
# ---------------------------------------------------------------------------

is_same_sql_bind(
  $rs->search(
    {},
    { select => [ json('me.data')->extract('$.status')->as_select('status') ] },
  )->as_query,
  q{( SELECT json_extract(me.data, ?) AS status FROM "artist" "me" )},
  [ [ {} => '$.status' ] ],
  'extract()->as_select()',
);

# ---------------------------------------------------------------------------
# A consumption method without a selector is a loud error.
# ---------------------------------------------------------------------------

eval { json('me.data')->eq('x') };
like(
  $@,
  qr/no JSON path selected/,
  'consumption without a selector croaks',
);

# ---------------------------------------------------------------------------
# Executed against SQLite.
#
# Everything above compares strings, against a column (me.data) the artist
# table does not even have. That shows what is emitted, not that SQLite takes
# a JSON path as a *bind*, nor what the three forms hand back. So: real rows
# holding JSON text, queried through $rs->search with the fragments json()
# builds -- the generated SQL and binds are what runs.
#
# Values are read raw off the cursor, so nothing between SQLite and the
# assertion can reshape them.
# ---------------------------------------------------------------------------

{
  my $live = DBIO::SQLite::Test->init_schema( no_populate => 1 );
  my $docs = $live->resultset('Serialized');

  $docs->create({ id => 1, serialized => '{"status":"active","score":150,"meta":{"a":1}}' });
  $docs->create({ id => 2, serialized => '{"status":"deleted","score":20}' });
  $docs->create({ id => 3, serialized => '{"score":7}' });

  my $doc = json('me.serialized');

  # What SQLite returns for the extraction on one row.
  my $value_of = sub {
    my ($id, $op) = @_;
    my ($value) = $docs->search(
      { 'me.id' => $id },
      { select => [ $op->as_select('v') ], as => ['v'] },
    )->cursor->next;
    return $value;
  };

  # The ids a condition selects.
  my $ids_where = sub {
    my ($cond, $attrs) = @_;
    return [
      map { $_->[0] } $docs->search(
        $cond, { columns => ['id'], order_by => 'me.id', %{ $attrs || {} } },
      )->cursor->all
    ];
  };

  # -- extract(): json_extract(col, ?), JSON1 -- no version gate ------------

  is(
    $value_of->( 1, $doc->extract('$.status') ),
    'active',
    'executed: extract() takes the path as a bind and returns a string as its SQL text',
  );

  is(
    $value_of->( 1, $doc->extract('$.meta') ),
    '{"a":1}',
    'executed: extract() returns a sub-document as JSON text',
  );

  is_deeply(
    $ids_where->( $doc->extract('$.status')->eq('active') ),
    [1],
    'executed: extract()->eq() filters rows in WHERE',
  );

  is_deeply(
    $ids_where->( $doc->extract('$.status')->is_null ),
    [3],
    'executed: extract()->is_null finds the row whose document lacks the path',
  );

  is_deeply(
    $ids_where->( {}, { order_by => { -desc => $doc->extract('$.score')->as_order } } ),
    [ 1, 2, 3 ],
    'executed: extract()->as_order sorts by the number (150, 20, 7), not by its text',
  );

  # -- get() / get_text(): the -> and ->> operators, libsqlite 3.38+ --------

  my $server_info = $live->storage->_server_info;

  SKIP: {
    skip "libsqlite $server_info->{dbms_version} has no -> / ->> operators (needs 3.38)", 9
      unless $server_info->{normalized_dbms_version} >= '3.038';

    # The distinction README and POD draw: -> yields the JSON representation,
    # ->> the text / SQL value.
    is(
      $value_of->( 1, $doc->get('$.status') ),
      '"active"',
      'executed: get() returns the JSON representation -- a string keeps its quotes',
    );

    is(
      $value_of->( 1, $doc->get_text('$.status') ),
      'active',
      'executed: get_text() returns the SQL text value -- no quotes',
    );

    is(
      $value_of->( 1, $doc->get('$.meta') ),
      '{"a":1}',
      'executed: get() returns a sub-document as JSON',
    );

    # ... and what that distinction means in a WHERE.
    is_deeply(
      $ids_where->( $doc->get_text('$.status')->eq('active') ),
      [1],
      'executed: get_text()->eq() compares the SQL value',
    );

    is_deeply(
      $ids_where->( $doc->get('$.status')->eq('active') ),
      [],
      'executed: get()->eq() against the bare string matches nothing ...',
    );

    is_deeply(
      $ids_where->( $doc->get('$.status')->eq('"active"') ),
      [1],
      '... because -> compares the JSON representation',
    );

    is_deeply(
      $ids_where->( $doc->get_text('$.score')->gt(100) ),
      [1],
      'executed: get_text()->gt() compares a JSON number as a number',
    );

    is_deeply(
      $ids_where->( $doc->get_text('$.status')->is_null ),
      [3],
      'executed: get_text()->is_null finds the row whose document lacks the path',
    );

    is_deeply(
      $ids_where->( $doc->get('$.meta')->is_not_null ),
      [1],
      'executed: get()->is_not_null finds the row whose document has the path',
    );
  }
}

done_testing;
