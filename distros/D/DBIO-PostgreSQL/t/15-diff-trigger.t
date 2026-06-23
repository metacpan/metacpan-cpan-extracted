use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Trigger;

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

# Missing definition in create → comment fallback
@ops = DBIO::PostgreSQL::Diff::Trigger->diff(
  {},
  { 'public.t' => { t1 => {} } },
);
like($ops[0]->as_sql, qr/^-- CREATE TRIGGER t1 ON public\.t/, 'missing definition → comment');

done_testing;
