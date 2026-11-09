use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Test::Conformance;

plan skip_all => 'Set DBIO_TEST_MSSQL_ODBC_DSN (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless DBIO::MSSQL::Test::Conformance->conformance_live_available;

# LIVE test for karr k71 (core ADR 0060): the shared DDL case table, answered
# by this driver against a real SQL Server. Each case works in a database of
# its own; the diff postcondition runs through a throwaway database -- see
# DBIO::MSSQL::Test::Conformance.
DBIO::MSSQL::Test::Conformance->run('DDL');

done_testing;
