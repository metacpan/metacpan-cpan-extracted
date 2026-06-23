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

done_testing;
