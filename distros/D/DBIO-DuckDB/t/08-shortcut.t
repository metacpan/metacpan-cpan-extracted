use strict;
use warnings;
use Test::More;

# Offline test for the DBIO::Shortcut::du stub (`use DBIO -du`).
# No DBI, no DSN, no real database — pure class-setup assertions.

# The stub must work cold: loading it on its own should be enough for the
# two-tier resolver in core to delegate to DBIO->apply_driver(..., 'DuckDB').
require_ok 'DBIO::Shortcut::du';
can_ok 'DBIO::Shortcut::du', 'apply';

# Schema class using the shortcut alongside the base role.
{
  package MyTest::Shortcut::Schema;
  use DBIO 'Schema', -du;
}

ok 'MyTest::Shortcut::Schema'->isa('DBIO::Schema'),
  q{use DBIO 'Schema', -du sets up DBIO::Schema inheritance};

is 'MyTest::Shortcut::Schema'->storage_type, '+DBIO::DuckDB::Storage',
  q{-du pins storage_type to +DBIO::DuckDB::Storage on a Schema class};

# DuckDB ships no DBIO::DuckDB::Result component, so the Result path is a
# no-op by design: apply_driver only calls load_components when the
# component exists. Assert the absence stays intentional.
ok !(-e 'lib/DBIO/DuckDB/Result.pm'),
  'no DBIO::DuckDB::Result component — Schema path only';

done_testing;
