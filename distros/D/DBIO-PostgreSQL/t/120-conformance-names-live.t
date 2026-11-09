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

# LIVE test for core ADR 0077 (karr dbio k391): the shared Names list, answered
# by this driver against a real PostgreSQL server. A schema name is set (and
# read back as given) or refused with a DBIO::Exception; an extension name the
# server cannot install is refused by the driver before a statement meets it.
DBIO::PostgreSQL::Test::Conformance->run('Names');

done_testing;
