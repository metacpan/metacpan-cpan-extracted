use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_INFORMIX_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_INFORMIX_DSN};

use DBIO::Informix::Test::Conformance;

# LIVE test for karr k24 (core ADR 0060): the shared Bind case table, answered
# by this driver against a real Informix server. The database is the case's
# namespace: it must be empty and is emptied again after each case.
# WARNING: drops the tables and views its cases create in the database it runs in.
DBIO::Informix::Test::Conformance->run('Bind');

done_testing;
