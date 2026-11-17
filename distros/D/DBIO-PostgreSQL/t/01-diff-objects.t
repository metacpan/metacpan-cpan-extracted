use strict;
use warnings;
use Test::More;
use DBIO::PostgreSQL::Diff::Schema;
use DBIO::PostgreSQL::Diff::Extension;
use DBIO::PostgreSQL::Diff::Type;
use DBIO::PostgreSQL::Diff::Policy;
use DBIO::PostgreSQL::Diff::Table;
use DBIO::PostgreSQL::Diff::Function;
use DBIO::PostgreSQL::Diff::Trigger;
use DBIO::PostgreSQL::Diff;

subtest 'diff-schema' => sub {
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
};

subtest 'diff-extension' => sub {
  my @ops = DBIO::PostgreSQL::Diff::Extension->diff(
    {},
    { pgcrypto => { extension_name => 'pgcrypto', version => '1.3' } },
  );

  is(scalar @ops, 1, 'one extension to create');
  is($ops[0]->action, 'create', 'action is create');
  like($ops[0]->as_sql, qr/CREATE EXTENSION.*pgcrypto/, 'DDL is correct');

  @ops = DBIO::PostgreSQL::Diff::Extension->diff(
    { pgcrypto => { extension_name => 'pgcrypto', version => '1.3' } },
    { pgcrypto => { extension_name => 'pgcrypto', version => '1.4' } },
  );

  is(scalar @ops, 1, 'one extension to update');
  is($ops[0]->action, 'update', 'action is update');
  like($ops[0]->as_sql, qr/ALTER EXTENSION pgcrypto UPDATE TO '1.4'/, 'DDL is correct');

  @ops = DBIO::PostgreSQL::Diff::Extension->diff(
    { pgcrypto => { extension_name => 'pgcrypto', version => '1.3' } },
    {},
  );

  is(scalar @ops, 1, 'one extension to drop');
  is($ops[0]->action, 'drop', 'action is drop');
};

subtest 'diff-type' => sub {
  # Create new enum
  my @ops = DBIO::PostgreSQL::Diff::Type->diff(
    {},
    {
      'public.status' => {
        schema_name => 'public',
        type_name   => 'status',
        type_kind   => 'enum',
        values      => [qw( active inactive )],
      },
    },
  );

  is(scalar @ops, 1, 'one type to create');
  is($ops[0]->action, 'create', 'action is create');
  like($ops[0]->as_sql, qr/CREATE TYPE public\.status AS ENUM/, 'enum DDL');
  like($ops[0]->as_sql, qr/'active', 'inactive'/, 'enum values');

  # Add enum value
  @ops = DBIO::PostgreSQL::Diff::Type->diff(
    {
      'public.status' => {
        schema_name => 'public',
        type_name   => 'status',
        type_kind   => 'enum',
        values      => [qw( active inactive )],
      },
    },
    {
      'public.status' => {
        schema_name => 'public',
        type_name   => 'status',
        type_kind   => 'enum',
        values      => [qw( active inactive suspended )],
      },
    },
  );

  is(scalar @ops, 1, 'one type change');
  is($ops[0]->action, 'add_value', 'action is add_value');
  like($ops[0]->as_sql, qr/ALTER TYPE public\.status ADD VALUE 'suspended'/, 'add value DDL');

  # Create composite type
  @ops = DBIO::PostgreSQL::Diff::Type->diff(
    {},
    {
      'public.address' => {
        schema_name => 'public',
        type_name   => 'address',
        type_kind   => 'composite',
        attributes  => [
          { name => 'street', type => 'text', ordinal => 1 },
          { name => 'city', type => 'text', ordinal => 2 },
        ],
      },
    },
  );

  is(scalar @ops, 1, 'one type to create');
  like($ops[0]->as_sql, qr/CREATE TYPE public\.address AS/, 'composite DDL');
};

subtest 'diff-policy' => sub {
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
};

subtest 'diff-table' => sub {
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
  like($ops[0]->as_sql, qr/^DROP TABLE auth\.sessions;$/, 'drop table DDL, written without CASCADE (nothing outside the model goes with it)');
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
};

subtest 'diff-function' => sub {
  my $fn_def = <<'SQL';
CREATE OR REPLACE FUNCTION auth.update_modified_at() RETURNS trigger AS $$
BEGIN
  NEW.modified_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SQL

  # Create function
  my @ops = DBIO::PostgreSQL::Diff::Function->diff(
    {},
    {
      'auth.update_modified_at()' => {
        definition  => $fn_def,
        language    => 'plpgsql',
        return_type => 'trigger',
      },
    },
  );

  is(scalar @ops, 1, 'one function to create');
  is($ops[0]->action, 'create', 'action is create');
  is($ops[0]->function_key, 'auth.update_modified_at()', 'function_key set');
  like($ops[0]->as_sql, qr/CREATE OR REPLACE FUNCTION auth\.update_modified_at/, 'create function DDL');
  like($ops[0]->as_sql, qr/;$/, 'ends with semicolon');
  like($ops[0]->summary, qr/\+function: auth\.update_modified_at\(\)/, 'create summary');

  # Drop function
  @ops = DBIO::PostgreSQL::Diff::Function->diff(
    { 'public.old_fn()' => { definition => 'CREATE FUNCTION public.old_fn()...' } },
    {},
  );
  is(scalar @ops, 1, 'one function to drop');
  is($ops[0]->action, 'drop', 'action is drop');
  like($ops[0]->as_sql, qr/^DROP FUNCTION public\.old_fn\(\);$/, 'drop function DDL');
  like($ops[0]->summary, qr/-function: public\.old_fn\(\)/, 'drop summary');

  # Replace when definition changed
  @ops = DBIO::PostgreSQL::Diff::Function->diff(
    { 'auth.fn()' => { definition => 'OLD BODY' } },
    { 'auth.fn()' => { definition => 'NEW BODY' } },
  );
  is(scalar @ops, 1, 'one replace op');
  is($ops[0]->action, 'replace', 'action is replace');
  like($ops[0]->as_sql, qr/NEW BODY/, 'replace uses new definition');
  like($ops[0]->summary, qr/~function: auth\.fn\(\)/, 'replace summary uses ~');

  # No op when definition unchanged
  @ops = DBIO::PostgreSQL::Diff::Function->diff(
    { 'auth.fn()' => { definition => 'SAME' } },
    { 'auth.fn()' => { definition => 'SAME' } },
  );
  is(scalar @ops, 0, 'no ops when definition identical');

  # Semicolon normalization — existing trailing semi preserved, whitespace stripped
  @ops = DBIO::PostgreSQL::Diff::Function->diff(
    {},
    { 'public.f()' => { definition => "CREATE FUNCTION public.f() ...;  \n" } },
  );
  is(scalar @ops, 1, 'one create');
  like($ops[0]->as_sql, qr/;$/, 'trailing semicolon normalized');
  unlike($ops[0]->as_sql, qr/;;/, 'no double semicolons');

  # Missing definition: there is no statement, so there is no operation. It
  # used to be a comment in the place of the statement, which Deploy skipped
  # together with the statement behind it (karr k120, t/100-diff-no-statement.t).
  @ops = eval { DBIO::PostgreSQL::Diff::Function->diff(
    {},
    { 'public.f()' => {} },
  ) };
  like($@, qr/\Arefusing to diff: function public\.f\(\) /, 'missing definition is refused, naming the function');
  is(scalar @ops, 0, '... and no operation is built for it');

  # Multiple functions — sorted
  @ops = DBIO::PostgreSQL::Diff::Function->diff(
    { 'z.del()' => { definition => 'X' } },
    {
      'a.add()' => { definition => 'A' },
      'm.mod()' => { definition => 'M' },
    },
  );
  is(scalar @ops, 3, 'three ops');
  is($ops[0]->function_key, 'a.add()', 'sorted: a.add first');
  is($ops[0]->action, 'create');
  is($ops[1]->function_key, 'm.mod()', 'sorted: m.mod second');
  is($ops[1]->action, 'create');
  is($ops[2]->function_key, 'z.del()', 'drop z.del last');
  is($ops[2]->action, 'drop');
};

subtest 'diff-trigger' => sub {
  my $trg_def = 'CREATE TRIGGER users_modified_at BEFORE UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION auth.update_modified_at()';

  # Create trigger
  my @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
    {},
    {
      'auth.users' => {
        users_modified_at => {
          definition => $trg_def,
          timing     => 'BEFORE',
          event      => 'UPDATE',
        },
      },
    },
  );

  is(scalar @ops, 1, 'one trigger to create');
  is($ops[0]->action, 'create', 'action is create');
  is($ops[0]->table_key, 'auth.users', 'table_key set');
  is($ops[0]->trigger_name, 'users_modified_at', 'trigger_name set');
  is($ops[0]->as_sql, $trg_def . ';', 'create uses full definition with trailing semi');
  like($ops[0]->summary, qr/\+trigger: users_modified_at on auth\.users/, 'create summary');

  # Drop trigger
  @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
    {
      'public.t' => {
        old_trg => { definition => 'CREATE TRIGGER old_trg ...' },
      },
    },
    {},
  );
  is(scalar @ops, 1, 'one trigger to drop');
  is($ops[0]->action, 'drop', 'action is drop');
  is($ops[0]->as_sql, 'DROP TRIGGER old_trg ON public.t;', 'drop trigger DDL');
  like($ops[0]->summary, qr/-trigger: old_trg on public\.t/, 'drop summary');

  # Definition change: drop + create pair
  @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
    { 'public.t' => { trg => { definition => 'OLD DEF' } } },
    { 'public.t' => { trg => { definition => 'NEW DEF' } } },
  );
  is(scalar @ops, 2, 'definition change produces 2 ops');
  is($ops[0]->action, 'drop', 'first is drop (old)');
  like($ops[0]->as_sql, qr/DROP TRIGGER trg ON public\.t/, 'drops old');
  is($ops[1]->action, 'create', 'second is create (new)');
  is($ops[1]->as_sql, 'NEW DEF;', 'creates with new definition');

  # Unchanged definition → no op
  @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
    { 'public.t' => { trg => { definition => 'SAME' } } },
    { 'public.t' => { trg => { definition => 'SAME' } } },
  );
  is(scalar @ops, 0, 'no ops when definition unchanged');

  # Triggers on different tables, multiple at once
  @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
    {
      'public.gone' => { trg_x => { definition => 'X' } },
    },
    {
      'auth.users' => {
        a_trg => { definition => 'A' },
        b_trg => { definition => 'B' },
      },
    },
  );
  is(scalar @ops, 3, 'two creates + one drop');
  # Creates sorted by (table, name)
  is($ops[0]->trigger_name, 'a_trg', 'a_trg first');
  is($ops[0]->action, 'create');
  is($ops[1]->trigger_name, 'b_trg', 'b_trg second');
  is($ops[1]->action, 'create');
  is($ops[2]->trigger_name, 'trg_x', 'trg_x dropped last');
  is($ops[2]->action, 'drop');

  # Missing definition in create: there is no statement, so there is no
  # operation. It used to be a comment in the place of the statement, which
  # Deploy skipped together with the statement behind it (karr k120,
  # t/100-diff-no-statement.t).
  @ops = eval { DBIO::PostgreSQL::Diff::Trigger->diff(
    {},
    { 'public.t' => { t1 => {} } },
  ) };
  like($@, qr/\Arefusing to diff: trigger t1 on public\.t /, 'missing definition is refused, naming trigger and table');
  is(scalar @ops, 0, '... and no operation is built for it');
};

# Regression: the full diff dispatch must hand DBIO::PostgreSQL::Diff::Table
# the *column* sections (not the *table* sections) as its trailing args, so
# a newly created table renders with its columns. Previously every
# table-aware diff received the tables section, so Diff::Table->columns
# became a table_info hashref and as_sql() died with
# "Not an ARRAY reference" the moment a deploy/upgrade had to CREATE a table.
subtest 'diff-dispatch' => sub {
  my $source = { tables => {}, columns => {} };
  my $target = {
    tables  => {
      'public.users' => { schema_name => 'public', table_name => 'users' },
    },
    columns => {
      'public.users' => [
        { column_name => 'id',   data_type => 'integer', not_null => 1, identity => 'a' },
        { column_name => 'name', data_type => 'text' },
      ],
    },
  };

  my $diff = DBIO::PostgreSQL::Diff->new( source => $source, target => $target );

  ok $diff->has_changes, 'diff detects the new table';

  my $sql = eval { $diff->as_sql };
  ok !$@, 'as_sql does not die on a table-create op' or diag $@;

  like $sql, qr/CREATE TABLE public\.users \(/, 'new table rendered as CREATE TABLE';
  like $sql, qr/\bid integer NOT NULL\b/,        'first column comes from the columns section';
  like $sql, qr/\bname text\b/,                  'second column rendered';
  unlike $sql, qr/CREATE TABLE public\.users \(\)/, 'table is not an empty shell';
};

done_testing;
