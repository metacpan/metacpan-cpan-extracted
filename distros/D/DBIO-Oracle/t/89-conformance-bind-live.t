use strict;
use warnings;
use Test::More;

# No NLS_LANG is set: the character set of the connection is the driver's own
# default (ora_charset / ora_ncharset AL32UTF8), whatever this process has. bind-non-ascii
# round-trips through the storage's upgrade of text binds.
BEGIN { delete $ENV{NLS_LANG} }

use DBI;
use DBIO::Oracle::Test::Conformance;

# LIVE (karr k63, core ADR 0060). The cases of the shared Bind table run
# against a real Oracle: each declaration is installed with $schema->deploy
# into the connected user's schema, a value is sent through the ResultSet API
# (bind path, never literal SQL) and read back from the server. The Bind list
# asks no fact and no diff.
#
# A case is correct or declared (conformance_refusals); there is no third answer.
#
# Without DBIO_TEST_ORA_DSN (and DBD::Oracle) only the declarations are
# checked and the number of cases not run is said. One run per database: two
# runs against the same user drop each other's objects.

my $class = 'DBIO::Oracle::Test::Conformance';

my $objects = sub {
  my $dbh = DBI->connect(@ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
    { RaiseError => 1, PrintError => 0 });
  my $rows = $dbh->selectall_arrayref(
    q{SELECT object_type || ' ' || object_name FROM user_objects
      WHERE object_name NOT LIKE 'BIN$%' ORDER BY 1});
  $dbh->disconnect;
  return [ map { $_->[0] } @$rows ];
};

my $live = $class->conformance_live_available;
my $before = $live ? $objects->() : undef;

my @problem = $class->check_declarations('Bind');
ok !@problem, 'the conformance declarations are whole'
  or diag join "\n", @problem;

if ($live) {
  my @results = $class->results('Bind');
  for my $r (@results) {
    ok $r->{status} ne 'fail', "$r->{case}: $r->{status}"
      or diag "$r->{case}: $r->{message}";
  }
  my $line = $class->summary_line(\@results);
  diag $line if defined $line;

  # the cleanup drops what the cases created and nothing else
  is_deeply $objects->(), $before,
    'the user owns exactly the objects it owned before the run';
}
else {
  diag scalar(@{ $class->cases('Bind') }) . ' cases not run: no server to run against';
}

done_testing;
