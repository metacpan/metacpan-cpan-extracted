use strict;
use warnings;
use Test::More;

use DBIO::DB2::Test::Conformance;

plan skip_all => 'Set DBIO_TEST_DB2_DSN and DBIO_TEST_DB2_USER (and _PASS) to run this test'
  unless DBIO::DB2::Test::Conformance->conformance_live_available;

# LIVE test for karr k57 (core ADR 0060): the shared DDL case table, answered by
# this driver against a real Db2. Each case works in a schema of its own, see
# DBIO::DB2::Test::Conformance.
DBIO::DB2::Test::Conformance->run('DDL');

done_testing;
