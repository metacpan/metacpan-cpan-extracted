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

# karr k100 -- a policy is created as the target has it.
#
# WHY: CREATE POLICY wrote the command and the two expressions and left out
# whom the policy is for and what kind it is. A policy the target has as
# RESTRICTIVE ... TO app_reader came out without both: permissive, and for
# PUBLIC. A restrictive policy narrows what the permissive ones let through;
# written as permissive it widens it, for every role.
{
  my $policy = sub {
    my (%info) = @_;
    my ($op) = DBIO::PostgreSQL::Diff::Policy->diff(
      {},
      { 'public.users' => { p => {
        schema_name => 'public', table_name => 'users', policy_name => 'p',
        command => 'ALL', permissive => 1, roles => undef, %info,
      } } },
      $tables_with_rls, $tables_with_rls,
    );
    return $op->as_sql;
  };

  is($policy->(permissive => 0, command => 'SELECT', roles => ['app_reader'], using_expr => '(owner = CURRENT_USER)'),
    'CREATE POLICY p ON public.users AS RESTRICTIVE FOR SELECT TO app_reader USING ((owner = CURRENT_USER));',
    'a restrictive policy for one role keeps both: AS RESTRICTIVE, TO the role');

  is($policy->(command => 'INSERT', roles => [ 'AppWriter', 'app_reader' ], check_expr => '(id > 0)'),
    'CREATE POLICY p ON public.users FOR INSERT TO "AppWriter", app_reader WITH CHECK ((id > 0));',
    'every role is written, each an identifier by the rule of the server');

  is($policy->(roles => undef, using_expr => 'true'),
    'CREATE POLICY p ON public.users USING (true);',
    'a policy for everybody -- the catalog has no role names for it -- has no TO, which is PUBLIC');

  is($policy->(roles => ['PUBLIC'], using_expr => 'true'),
    'CREATE POLICY p ON public.users TO PUBLIC USING (true);',
    'PUBLIC in a model built by hand is the key word, not a role of that name');

  is($policy->(using_expr => 'true', permissive => undef),
    'CREATE POLICY p ON public.users USING (true);',
    'a model that says nothing about the kind gets the permissive policy PostgreSQL makes by default');
}

# Row level security of a table that is created in this diff is switched on
# in this diff. It was compared only for tables on both sides, so a new table
# stood there with its policies and without the row level security that makes
# them apply -- every row readable -- until the next diff.
{
  my %new = ( 'public.fresh' => { schema_name => 'public', table_name => 'fresh', rls_enabled => 1 } );
  my @rls = DBIO::PostgreSQL::Diff::Policy->diff(
    {},
    { 'public.fresh' => { p => {
      schema_name => 'public', table_name => 'fresh', policy_name => 'p', using_expr => 'true',
    } } },
    {}, { %new, 'public.open' => { schema_name => 'public', table_name => 'open', rls_enabled => 0 } },
  );
  is_deeply([ map { $_->as_sql } @rls ], [
    'ALTER TABLE public.fresh ENABLE ROW LEVEL SECURITY;',
    'CREATE POLICY p ON public.fresh USING (true);',
  ], 'a new table with row level security gets it enabled along with its policies; one without is left alone');
}

done_testing;
