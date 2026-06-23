use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Table;

# Create table
my @ops = DBIO::PostgreSQL::Diff::Table->diff(
  {},
  {
    'public.users' => {
      schema_name => 'public',
      table_name  => 'users',
      kind        => 'r',
    },
  },
);

is(scalar @ops, 1, 'one table to create');
is($ops[0]->action, 'create', 'action is create');
is($ops[0]->schema_name, 'public', 'schema_name set');
is($ops[0]->table_name, 'users', 'table_name set');
is($ops[0]->qualified_name, 'public.users', 'qualified_name');
like($ops[0]->as_sql, qr/^CREATE TABLE public\.users \(\);$/, 'create table DDL (empty shell)');
like($ops[0]->summary, qr/\+table: public\.users/, 'create summary');

# Drop table
@ops = DBIO::PostgreSQL::Diff::Table->diff(
  {
    'auth.sessions' => {
      schema_name => 'auth',
      table_name  => 'sessions',
      kind        => 'r',
    },
  },
  {},
);

is(scalar @ops, 1, 'one table to drop');
is($ops[0]->action, 'drop', 'action is drop');
like($ops[0]->as_sql, qr/^DROP TABLE auth\.sessions CASCADE;$/, 'drop table DDL with CASCADE');
like($ops[0]->summary, qr/-table: auth\.sessions/, 'drop summary');

# No changes when same
@ops = DBIO::PostgreSQL::Diff::Table->diff(
  { 'public.users' => { schema_name => 'public', table_name => 'users' } },
  { 'public.users' => { schema_name => 'public', table_name => 'users' } },
);
is(scalar @ops, 0, 'no ops when tables identical');

# Mixed: create + drop
@ops = DBIO::PostgreSQL::Diff::Table->diff(
  { 'public.old' => { schema_name => 'public', table_name => 'old' } },
  { 'public.new' => { schema_name => 'public', table_name => 'new' } },
);
is(scalar @ops, 2, 'two ops: create + drop');
is($ops[0]->action, 'create', 'first op is create (target)');
is($ops[0]->table_name, 'new', 'create new');
is($ops[1]->action, 'drop', 'second op is drop (source)');
is($ops[1]->table_name, 'old', 'drop old');

# Multiple tables across schemas — stable sort order
@ops = DBIO::PostgreSQL::Diff::Table->diff(
  {},
  {
    'public.users' => { schema_name => 'public', table_name => 'users' },
    'auth.roles'   => { schema_name => 'auth',   table_name => 'roles' },
    'api.tokens'   => { schema_name => 'api',    table_name => 'tokens' },
  },
);
is(scalar @ops, 3, 'three creates across schemas');
# sorted by key (schema.table)
is($ops[0]->qualified_name, 'api.tokens', 'first sorted: api.tokens');
is($ops[1]->qualified_name, 'auth.roles', 'second sorted: auth.roles');
is($ops[2]->qualified_name, 'public.users', 'third sorted: public.users');

# table_info passed through
@ops = DBIO::PostgreSQL::Diff::Table->diff(
  {},
  { 'public.t' => { schema_name => 'public', table_name => 't', rls_enabled => 1 } },
);
is($ops[0]->table_info->{rls_enabled}, 1, 'table_info preserved');

done_testing;
