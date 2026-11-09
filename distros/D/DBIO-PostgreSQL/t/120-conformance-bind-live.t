use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_PG_DSN};

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::Test::Conformance;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k150 (core ADR 0060): the shared Bind case table, answered
# by this driver against a real PostgreSQL server. Each case works in a schema
# of its own -- see DBIO::PostgreSQL::Test::Conformance.
DBIO::PostgreSQL::Test::Conformance->run('Bind');

done_testing;
