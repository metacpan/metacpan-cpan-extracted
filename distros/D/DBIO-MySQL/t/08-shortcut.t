use strict;
use warnings;
use Test::More;

# Offline test for the DBIO::Shortcut::mysql stub (`use DBIO -mysql`).
# No DBI, no DSN, no real database -- pure class-setup assertions.

# The stub must work cold: loading it on its own is enough for the two-tier
# resolver in core to delegate to DBIO->apply_driver(..., 'MySQL').
require_ok 'DBIO::Shortcut::mysql';
can_ok 'DBIO::Shortcut::mysql', 'apply';

# Schema class using the shortcut alongside the base role.
{
  package MyTest::Shortcut::Schema;
  use DBIO 'Schema', -mysql;
}

ok 'MyTest::Shortcut::Schema'->isa('DBIO::Schema'),
  q{use DBIO 'Schema', -mysql sets up DBIO::Schema inheritance};

is 'MyTest::Shortcut::Schema'->storage_type, '+DBIO::MySQL::Storage',
  q{-mysql pins storage_type to +DBIO::MySQL::Storage on a Schema class};

# Result class using the shortcut -- gains the MySQL::Result component.
{
  package MyTest::Shortcut::Result::User;
  use DBIO 'Core', -mysql;
}

ok 'MyTest::Shortcut::Result::User'->isa('DBIO::Core'),
  q{use DBIO 'Core', -mysql sets up DBIO::Core inheritance};

ok 'MyTest::Shortcut::Result::User'->isa('DBIO::MySQL::Result'),
  q{-mysql loads the DBIO::MySQL::Result component on a Result class};

# Assert behaviour the component actually provides (see
# lib/DBIO/MySQL/Result.pm): mysql_engine / mysql_charset / mysql_index.
can_ok 'MyTest::Shortcut::Result::User',
  qw(mysql_engine mysql_charset mysql_collate mysql_index mysql_indexes);

MyTest::Shortcut::Result::User->mysql_engine('InnoDB');
is 'MyTest::Shortcut::Result::User'->mysql_engine, 'InnoDB',
  'MySQL::Result behaviour reachable via -mysql shortcut';

MyTest::Shortcut::Result::User->mysql_index('idx_name' => { columns => ['name'] });
is_deeply 'MyTest::Shortcut::Result::User'->mysql_indexes,
  { idx_name => { columns => ['name'] } },
  'mysql_index registration reachable via -mysql shortcut';

done_testing;
