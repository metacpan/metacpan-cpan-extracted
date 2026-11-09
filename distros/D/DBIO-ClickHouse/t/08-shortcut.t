use strict;
use warnings;
use Test::More;

# Offline test for the DBIO::Shortcut::ch stub (`use DBIO -ch`).
# No DBI, no DSN, no real database — pure class-setup assertions.

# The stub must work cold: loading it on its own should be enough for the
# two-tier resolver in core to delegate to DBIO->apply_driver(..., 'ClickHouse').
require_ok 'DBIO::Shortcut::ch';
can_ok 'DBIO::Shortcut::ch', 'apply';

# Schema class using the shortcut alongside the base role.
{
  package MyTest::Shortcut::Schema;
  use DBIO 'Schema', -ch;
}

ok 'MyTest::Shortcut::Schema'->isa('DBIO::Schema'),
  q{use DBIO 'Schema', -ch sets up DBIO::Schema inheritance};

is 'MyTest::Shortcut::Schema'->storage_type, '+DBIO::ClickHouse::Storage',
  q{-ch pins storage_type to +DBIO::ClickHouse::Storage on a Schema class};

# ClickHouse now ships a DBIO::ClickHouse::Result component (the MergeTree
# table options the DDL layer needs), so apply_driver's Result path is live:
# a Result class using the shortcut gets the component loaded for it.
{
  package MyTest::Shortcut::Result;
  use DBIO 'Core', -ch;
}

ok 'MyTest::Shortcut::Result'->isa('DBIO::ClickHouse::Result'),
  q{use DBIO 'Core', -ch loads the ClickHouse::Result component};

can_ok 'MyTest::Shortcut::Result', 'clickhouse_table';

done_testing;
