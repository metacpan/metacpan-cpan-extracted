use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless DBIO::Sybase::Test::Conformance->conformance_live_available;

# LIVE (karr k97, core ADR 0060): the shared Diff case table, answered by this
# driver against a real ASE. Each case works in a database of its own; the
# upgrade connects a second schema to the same database. Needs a login allowed
# to CREATE DATABASE and the room for it (README, "Live tests").
#
# The three view cases (added, dropped, definition changed) run through
# DBIO::Sybase::Diff::View (karr k98). The three deploy cases (table version 4,
# diff-deploy-*) run through conformance_deploy.
DBIO::Sybase::Test::Conformance->run('Diff');

done_testing;
