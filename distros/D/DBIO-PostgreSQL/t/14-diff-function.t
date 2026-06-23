use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Function;

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

# Missing definition falls back to comment
@ops = DBIO::PostgreSQL::Diff::Function->diff(
  {},
  { 'public.f()' => {} },
);
like($ops[0]->as_sql, qr/^-- CREATE OR REPLACE FUNCTION public\.f\(\)/, 'missing definition yields comment');

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

done_testing;
