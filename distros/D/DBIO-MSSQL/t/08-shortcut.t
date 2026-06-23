use strict;
use warnings;
use Test::More;

# OFFLINE only: this exercises the `use DBIO -ms` shortcut wiring
# (DBIO::Shortcut::ms -> DBIO->apply_driver(..., 'MSSQL')). No connection
# is ever made, so no real database (and no DBIO::Test::Storage either) is
# required -- we only inspect storage_type / loaded components.

# --- Schema: -ms pins the MSSQL storage driver ---
{
  package TestMSSQL::Schema;
  use DBIO 'Schema', -ms;
}

is(
  TestMSSQL::Schema->storage_type,
  '+DBIO::MSSQL::Storage',
  "-ms on a Schema sets storage_type to +DBIO::MSSQL::Storage",
);

# --- Result: -ms loads the DBIO::MSSQL::Result component ---
{
  package TestMSSQL::Schema::Result::Thing;
  use DBIO 'Core', -ms;
}

ok(
  TestMSSQL::Schema::Result::Thing->isa('DBIO::MSSQL::Result'),
  "-ms on a Result class makes it isa DBIO::MSSQL::Result",
);

ok(
  TestMSSQL::Schema::Result::Thing->can('mssql_index'),
  "-ms Result class gains mssql_index from DBIO::MSSQL::Result",
);

ok(
  TestMSSQL::Schema::Result::Thing->can('mssql_indexes'),
  "-ms Result class gains mssql_indexes from DBIO::MSSQL::Result",
);

done_testing;
