use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_FIREBIRD_DSN};

use DBIO::Firebird::Test::Conformance;

# LIVE test for karr k55 (core ADR 0060): the shared DDL case table, answered
# by this driver against a real Firebird server. Firebird has no schemas
# before 6, so the database is the case's namespace: it must be empty and is
# emptied again after each case -- see DBIO::Firebird::Test::Conformance.
# WARNING: drops every table and view of the database it runs in.
DBIO::Firebird::Test::Conformance->run('DDL');

done_testing;
