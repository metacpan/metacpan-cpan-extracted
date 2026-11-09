use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless DBIO::Sybase::Test::Conformance->conformance_live_available;

# LIVE (karr k97, core ADR 0060): the shared Bind case table, answered by this
# driver against a real ASE. Each case works in a database of its own. Needs a
# login allowed to CREATE DATABASE and the room for it (README, "Live tests").
#
# Over FreeTDS four cases (the ones with a TEXT or IMAGE column) are server
# refusals: LOB content cannot be written, see DBIO::Sybase::Test::Conformance.
# bind-empty-string is a declared deviation (ASE keeps '' as one space).
DBIO::Sybase::Test::Conformance->run('Bind');

done_testing;
