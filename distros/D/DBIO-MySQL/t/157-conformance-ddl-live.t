use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_MYSQL_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_MYSQL_DSN} && $ENV{DBIO_TEST_MYSQL_USER};

use DBIO::MySQL::Test::Conformance;

# LIVE test for karr k120 (core ADR 0060): the shared DDL case table, answered
# by this driver against a real MySQL or MariaDB server (run it once against
# each). Each case works in a database of its own and the diff postcondition
# runs through a temporary one -- see DBIO::MySQL::Test::Conformance.
DBIO::MySQL::Test::Conformance->run('DDL');

done_testing;
