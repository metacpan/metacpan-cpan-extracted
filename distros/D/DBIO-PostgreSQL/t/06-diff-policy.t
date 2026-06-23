use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Policy;

my $tables_no_rls = {
  'public.users' => { rls_enabled => 0, rls_forced => 0 },
};
my $tables_with_rls = {
  'public.users' => { rls_enabled => 1, rls_forced => 0 },
};

# Enable RLS
my @ops = DBIO::PostgreSQL::Diff::Policy->diff(
  {}, {},
  $tables_no_rls, $tables_with_rls,
);

is(scalar @ops, 1, 'one operation');
is($ops[0]->action, 'enable_rls', 'action is enable_rls');
like($ops[0]->as_sql, qr/ENABLE ROW LEVEL SECURITY/, 'RLS DDL');

# Create policy
@ops = DBIO::PostgreSQL::Diff::Policy->diff(
  {},
  {
    'public.users' => {
      own_data => {
        policy_name => 'own_data',
        command     => 'ALL',
        using_expr  => 'id = current_user_id()',
      },
    },
  },
  $tables_with_rls, $tables_with_rls,
);

is(scalar @ops, 1, 'one policy to create');
is($ops[0]->action, 'create', 'action is create');
like($ops[0]->as_sql, qr/CREATE POLICY own_data/, 'policy DDL');

done_testing;
