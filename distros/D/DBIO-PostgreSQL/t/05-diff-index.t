use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Index;

# Create index
my @ops = DBIO::PostgreSQL::Diff::Index->diff(
  {},
  {
    'public.users' => {
      idx_users_email => {
        index_name    => 'idx_users_email',
        access_method => 'btree',
        is_unique     => 1,
        definition    => 'CREATE UNIQUE INDEX idx_users_email ON public.users USING btree (email)',
        columns       => ['email'],
      },
    },
  },
);

is(scalar @ops, 1, 'one index to create');
is($ops[0]->action, 'create', 'action is create');
like($ops[0]->as_sql, qr/CREATE UNIQUE INDEX idx_users_email/, 'create index DDL');

# Drop index
@ops = DBIO::PostgreSQL::Diff::Index->diff(
  {
    'public.users' => {
      idx_old => {
        index_name    => 'idx_old',
        access_method => 'btree',
        columns       => ['old_col'],
      },
    },
  },
  {},
);

is(scalar @ops, 1, 'one index to drop');
is($ops[0]->action, 'drop', 'action is drop');
like($ops[0]->as_sql, qr/DROP INDEX idx_old/, 'drop index DDL');

# karr #32: when the owning table is itself being dropped in the same pass
# (present in source tables, absent from target tables), DROP TABLE ... CASCADE
# already removes the table's indexes, so no standalone DROP INDEX must be
# emitted for them.
@ops = DBIO::PostgreSQL::Diff::Index->diff(
  {
    'public.leftover' => {
      leftover_pkey => {
        index_name => 'leftover_pkey',
        access_method => 'btree',
        is_unique  => 1,
        is_primary => 1,
        columns    => ['id'],
      },
    },
  },
  {},
  # source tables: the leftover table exists live
  { 'public.leftover' => { schema_name => 'public', table_name => 'leftover' } },
  # target tables: it is gone -> table is being dropped
  {},
);
is(scalar @ops, 0, 'no standalone DROP INDEX when owning table is dropped (CASCADE covers it)');

# karr #32 guard: do NOT over-suppress. If the table stays but one of its
# indexes is removed, the standalone DROP INDEX is still required.
@ops = DBIO::PostgreSQL::Diff::Index->diff(
  {
    'public.users' => {
      idx_users_email => {
        index_name => 'idx_users_email',
        access_method => 'btree',
        columns    => ['email'],
      },
    },
  },
  {},
  # source tables: users exists
  { 'public.users' => { schema_name => 'public', table_name => 'users' } },
  # target tables: users still exists -> only the index is being dropped
  { 'public.users' => { schema_name => 'public', table_name => 'users' } },
);
is(scalar @ops, 1, 'index drop still emitted when the table itself survives');
is($ops[0]->action, 'drop', 'surviving-table index drop is a drop op');
like($ops[0]->as_sql, qr/DROP INDEX idx_users_email/, 'surviving-table index still dropped standalone');

done_testing;
