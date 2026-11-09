use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Oracle::Test::Conformance;

# LIVE (karr k63, core ADR 0060). The cases of the shared Diff table run
# against a real Oracle: the `from` declaration is installed with
# $schema->deploy into the connected user's schema, the rows are loaded, and
# DBIO::Oracle::Deploy upgrades it to the `to` declaration through
# DBIO::Oracle::Test::Conformance::conformance_upgrade. What the case must show
# is read back through DBIO::Oracle::Introspect and the ResultSet API, a diff
# against the target declaration must then be empty, and the cleanup drops the
# objects the user owns afterwards and did not before; nothing else.
#
# A case is correct or declared (conformance_refusals); there is no third
# answer. Without DBIO_TEST_ORA_DSN (and DBD::Oracle) only the declarations are
# checked and the number of cases not run is said. One run per database: two
# runs against the same user drop each other's objects.

my $objects = sub {
  my $dbh = DBI->connect(@ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
    { RaiseError => 1, PrintError => 0 });
  my $rows = $dbh->selectall_arrayref(
    q{SELECT object_type || ' ' || object_name FROM user_objects
      WHERE object_name NOT LIKE 'BIN$%' ORDER BY 1});
  $dbh->disconnect;
  return [ map { $_->[0] } @$rows ];
};

my $live = DBIO::Oracle::Test::Conformance->conformance_live_available;
my $before = $live ? $objects->() : undef;

DBIO::Oracle::Test::Conformance->run('Diff');

# the cleanup drops what the cases created and nothing else
is_deeply $objects->(), $before,
  'the user owns exactly the objects it owned before the run'
  if $live;

done_testing;
