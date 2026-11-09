use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# OFFLINE TEST — exercises DBIO::PostgreSQL::SQLMaker row-locking rendering
# (FOR UPDATE / FOR SHARE + SKIP LOCKED / NOWAIT). No DBIO_TEST_PG_DSN needed.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);

my $rs = $schema->resultset('Artist')->search({ 'me.rank' => 13 });

is_same_sql_bind(
  $rs->search({}, { for => 'update' })->as_query,
  q{( SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"
        FROM "artist" "me" WHERE "me"."rank" = ? FOR UPDATE )},
  [ [ { sqlt_datatype => 'integer', dbic_colname => 'me.rank' } => 13 ] ],
  'plain for => update renders FOR UPDATE (no modifier)',
);

is_same_sql_bind(
  $rs->search({}, { for => 'update', skip_locked => 1 })->as_query,
  q{( SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"
        FROM "artist" "me" WHERE "me"."rank" = ? FOR UPDATE SKIP LOCKED )},
  [ [ { sqlt_datatype => 'integer', dbic_colname => 'me.rank' } => 13 ] ],
  'for => update, skip_locked => 1 renders FOR UPDATE SKIP LOCKED',
);

is_same_sql_bind(
  $rs->search({}, { for => 'update', nowait => 1 })->as_query,
  q{( SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"
        FROM "artist" "me" WHERE "me"."rank" = ? FOR UPDATE NOWAIT )},
  [ [ { sqlt_datatype => 'integer', dbic_colname => 'me.rank' } => 13 ] ],
  'for => update, nowait => 1 renders FOR UPDATE NOWAIT',
);

is_same_sql_bind(
  $rs->search({}, { for => 'shared', skip_locked => 1 })->as_query,
  q{( SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"
        FROM "artist" "me" WHERE "me"."rank" = ? FOR SHARE SKIP LOCKED )},
  [ [ { sqlt_datatype => 'integer', dbic_colname => 'me.rank' } => 13 ] ],
  'for => shared, skip_locked => 1 renders FOR SHARE SKIP LOCKED',
);

throws_ok {
  $rs->search({}, { for => 'update', skip_locked => 1, nowait => 1 })->as_query;
} qr/mutually exclusive/,
  'skip_locked + nowait together throws';

done_testing;
