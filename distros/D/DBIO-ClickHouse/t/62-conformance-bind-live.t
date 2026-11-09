use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test::Conformance;

# LIVE test for karr k43 (core ADR 0060): the shared Bind case table, answered
# by this driver against a real ClickHouse server. Values go through a column
# by every operation of the ResultSet API and must come back as written.
DBIO::ClickHouse::Test::Conformance->run('Bind');

done_testing;
