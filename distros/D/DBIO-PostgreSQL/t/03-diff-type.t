use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Type;

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

done_testing;
