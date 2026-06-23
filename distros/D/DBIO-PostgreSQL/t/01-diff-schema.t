use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Schema;

my @ops = DBIO::PostgreSQL::Diff::Schema->diff(
  { public => { oid => 1 } },
  { public => { oid => 1 }, auth => { oid => 2 } },
);

is(scalar @ops, 1, 'one schema to create');
is($ops[0]->action, 'create', 'action is create');
is($ops[0]->schema_name, 'auth', 'schema name is auth');
like($ops[0]->as_sql, qr/CREATE SCHEMA auth/, 'DDL is correct');

@ops = DBIO::PostgreSQL::Diff::Schema->diff(
  { public => { oid => 1 }, old_schema => { oid => 3 } },
  { public => { oid => 1 } },
);

is(scalar @ops, 1, 'one schema to drop');
is($ops[0]->action, 'drop', 'action is drop');
is($ops[0]->schema_name, 'old_schema', 'schema name is old_schema');
like($ops[0]->as_sql, qr/DROP SCHEMA old_schema/, 'DDL is correct');

@ops = DBIO::PostgreSQL::Diff::Schema->diff(
  { public => { oid => 1 } },
  { public => { oid => 1 } },
);

is(scalar @ops, 0, 'no changes');

done_testing;
