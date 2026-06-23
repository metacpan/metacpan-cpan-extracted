use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff;

# Regression: the full diff dispatch must hand DBIO::PostgreSQL::Diff::Table
# the *column* sections (not the *table* sections) as its trailing args, so
# a newly created table renders with its columns. Previously every
# table-aware diff received the tables section, so Diff::Table->columns
# became a table_info hashref and as_sql() died with
# "Not an ARRAY reference" the moment a deploy/upgrade had to CREATE a table.

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

done_testing;
