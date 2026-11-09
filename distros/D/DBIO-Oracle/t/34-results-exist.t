use strict;
use warnings;
use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;

# ADR 0037 -- the boolean-valued EXISTS query behind DBIO::ResultSet's
# results_exist, results_exist_async and results_exist_as_query. Two separate
# things have to be true on Oracle, and neither of them is inherited:
#
#   * the statement needs a FROM clause. Core's base rendering of
#     _exists_value_sql is a FROM-less SELECT, which Oracle answers with
#     ORA-00923, so this driver overrides the hook and appends DUAL.
#   * the supports_exists_query capability has to be *declared*. Core defaults
#     it to 0 and refuses all three methods outright rather than degrading
#     silently to has_rows -- so a driver that ships the override but forgets
#     the declaration has built a feature nobody can reach.
#
# The second one is why this file exists. A missing declaration is invisible
# until someone calls the method: in dbio-sqlite it surfaced only as an
# otherwise unrelated test file aborting with exit 255, and a driver with no
# test of its own would never have surfaced it at all. The
# results_exist_as_query pin below is the tripwire -- without the declaration
# it throws a typed DBIO::Exception naming the capability, and this file goes
# red.
#
# All of it is offline. The schema declares this driver, and both the hook
# and the capability are static class facts, so nothing here opens a
# connection; that is the point of the seam, not an accident of the test.

# DBIO::Test::Schema is shared by the driver suites and declares no driver; a
# schema always has one (core ADR 0067). Each connect here declares Oracle's
# storage on a clone, so the shared class stays without one.
sub oracle_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::Oracle::Storage');
  return $schema->connect(@_);
}

my $schema  = oracle_schema('dbi:Oracle:orcl');
my $storage = $schema->storage;

# ------------------------------------------------------------ the rendering
#
# The first call is the one that runs driver determination; it renders FROM
# DUAL once, as every later one does (core no longer re-enters the override
# from its determination wrapper; found in karr k53).

is (
  $storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END'
. ' FROM DUAL',
  'the hook appends Oracle\'s one-row table and leaves the CASE spelling to '
. 'core -- only the dummy table is this driver\'s business, and once',
);

is (
  $storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END'
. ' FROM DUAL',
  '... and once the driver is determined, it appends it once',
);

is (
  ref $storage,
  'DBIO::Oracle::Storage',
  '... answered by the storage the schema declared, still that class after '
. 'the hook ran driver determination on the dbi:Oracle: DSN: the declared '
. 'driver stands, so the string above is this driver\'s answer and not the '
. 'base rendering arrived at by accident',
);

isnt (
  DBIO::Oracle::Storage->can('_exists_value_sql'),
  DBIO::Storage::DBI->can('_exists_value_sql'),
  '... and it is a real override, by coderef identity rather than by the '
. 'inherited string happening to look right',
);

# ------------------------------------------------------------ the capability

ok (
  $storage->_use_supports_exists_query,
  'supports_exists_query is declared. Core defaults it to 0 and throws on all '
. 'three results_exist* methods without it -- deliberately, since falling '
. 'back to has_rows would hand the caller a different query shape without '
. 'saying so',
);

# ---------------------------------------------------- what the caller gets

{
  my $rs = $schema->resultset('Artist')->search({ name => 'foo' });

  my ($sql, @bind) = @{ ${ $rs->results_exist_as_query } };

  is (
    $sql,
    '( SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me"'
  . ' WHERE ( "name" = ? )  ) THEN 1 ELSE 0 END FROM DUAL )',
    'results_exist_as_query is the driver\'s complete statement in the one '
  . 'pair of parentheses core is allowed to add -- no SELECT * FROM (...) AS '
  . '_existence_subq wrapper, which is where Oracle used to hit ORA-00933',
  );

  is_deeply (
    [ map { $_->[1] } @bind ],
    [ 'foo' ],
    '... and the inner condition\'s bind values travel out with it, so the '
  . 'fragment is usable in a correlated subquery',
  );
}

ok (
  ! $storage->connected,
  'none of the above opened a connection: the rendering and the capability '
. 'are class facts, and driver determination reads the DSN',
);

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run the live half', 2
    unless $dsn && $user && $pass;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('rdbms_oracle'), 2
    unless DBIO::Optional::Dependencies->req_ok_for('rdbms_oracle');

  # The pins above prove what this driver renders, not that Oracle accepts it,
  # and a subquery inside a CASE WHEN condition is the half of this spelling
  # the SQL reference does not state outright. Executed with no fixture at
  # all: the statement carries its own one-row table.
  my $live = oracle_schema($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  my ($true) = $dbh->selectrow_array(
    $storage->_exists_value_sql('(SELECT 1 FROM DUAL)')
  );
  is ($true, 1, 'Oracle runs the rendered statement and answers 1 when the '
               . 'subquery has rows');

  my ($false) = $dbh->selectrow_array(
    $storage->_exists_value_sql('(SELECT 1 FROM DUAL WHERE 1 = 0)')
  );
  is ($false, 0, '... and 0 when it has none -- an integer either way, not an '
                . 'engine-typed boolean');
}

done_testing;
