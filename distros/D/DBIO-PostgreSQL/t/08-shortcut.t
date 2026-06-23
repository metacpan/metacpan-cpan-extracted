use strict;
use warnings;
use Test::More;

# Offline test for the DBIO::Shortcut::pg stub (`use DBIO -pg`).
# No DBI, no DSN, no real database — pure class-setup assertions.

# The stub must work cold: loading it on its own should be enough for the
# two-tier resolver in core to delegate to DBIO->apply_driver(..., 'PostgreSQL').
require_ok 'DBIO::Shortcut::pg';
can_ok 'DBIO::Shortcut::pg', 'apply';

# Schema class using the shortcut alongside the base role.
{
  package MyTest::Shortcut::Schema;
  use DBIO 'Schema', -pg;
}

ok 'MyTest::Shortcut::Schema'->isa('DBIO::Schema'),
  q{use DBIO 'Schema', -pg sets up DBIO::Schema inheritance};

is 'MyTest::Shortcut::Schema'->storage_type, '+DBIO::PostgreSQL::Storage',
  q{-pg pins storage_type to +DBIO::PostgreSQL::Storage on a Schema class};

# Result class using the shortcut — gains the PostgreSQL::Result component.
{
  package MyTest::Shortcut::Result::User;
  use DBIO 'Core', -pg;
}

ok 'MyTest::Shortcut::Result::User'->isa('DBIO::Core'),
  q{use DBIO 'Core', -pg sets up DBIO::Core inheritance};

ok 'MyTest::Shortcut::Result::User'->isa('DBIO::PostgreSQL::Result'),
  q{-pg loads the DBIO::PostgreSQL::Result component on a Result class};

# Assert a behaviour the component actually provides (see
# lib/DBIO/PostgreSQL/Result.pm): pg_schema / pg_index accessors.
can_ok 'MyTest::Shortcut::Result::User', qw(pg_schema pg_index pg_qualified_table);

MyTest::Shortcut::Result::User->pg_schema('auth');
MyTest::Shortcut::Result::User->table('users');
is 'MyTest::Shortcut::Result::User'->pg_qualified_table, 'auth.users',
  'PostgreSQL::Result behaviour reachable via -pg shortcut';

done_testing;
