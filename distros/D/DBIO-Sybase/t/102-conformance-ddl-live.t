use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless DBIO::Sybase::Test::Conformance->conformance_live_available;

# LIVE (karr k97, core ADR 0060): the shared DDL case table, answered by this
# driver against a real ASE. Each case works in a database of its own, the diff
# postcondition runs through a throwaway one -- see
# DBIO::Sybase::Test::Conformance. Needs a login allowed to CREATE DATABASE and
# the room for it (README, "Live tests").
DBIO::Sybase::Test::Conformance->run('DDL');

done_testing;
