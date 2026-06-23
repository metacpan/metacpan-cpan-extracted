use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test ':DiffSQL';

my $schema = DBIO::SQLite::Test->init_schema;

# SQLite does not support FOR UPDATE — the SQLMaker strips it
is_same_sql_bind(
  $schema->resultset('Artist')->search ({}, {for => 'update'})->as_query,
  '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield" FROM "artist" "me")', [],
);

done_testing;
