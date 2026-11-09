use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test::Conformance;

# LIVE test for karr k43 (core ADR 0060): the shared DDL case table, answered
# by this driver against a real ClickHouse server. Each case works in a
# database of its own (dbio_cf_<pid>_<n>), which the run drops again.
DBIO::ClickHouse::Test::Conformance->run('DDL');

done_testing;
