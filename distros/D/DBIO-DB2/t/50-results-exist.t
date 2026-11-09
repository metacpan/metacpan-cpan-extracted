use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO ();
use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::DB2::Storage;

# ADR 0037 -- the boolean-valued EXISTS query behind DBIO::ResultSet's
# results_exist, results_exist_async and results_exist_as_query. Two separate
# things have to be true on DB2, and neither of them is inherited:
#
#   * the statement needs a FROM clause. Core's base rendering of
#     _exists_value_sql is a FROM-less SELECT and DB2's subselect has no
#     FROM-less form, so this driver overrides the hook and appends
#     SYSIBM.SYSDUMMY1 -- the one-row catalog view IBM ships for exactly this,
#     "for SQL statements in which a table reference is required, but the
#     contents of the table are not important" (SQL Reference,
#     SYSIBM.SYSDUMMY1, LUW 11.5 and z/OS 12).
#   * the supports_exists_query capability has to be *declared*. Core defaults
#     it to 0 and refuses all three methods outright rather than degrading
#     silently to has_rows -- so a driver that ships the override but forgets
#     the declaration has built a feature nobody can reach. The
#     results_exist_as_query pin below is the tripwire: without the
#     declaration it throws a typed DBIO::Exception naming the capability and
#     this file goes red.
#
# The CASE half needed nothing from this driver: a searched CASE's WHEN takes
# a search-condition and EXISTS is a predicate, so core's base spelling is
# already DB2's. Only the missing FROM was ever the gap.
#
# All of it is offline. The schema declares its driver, and both the hook and
# the capability are static class facts, so nothing here opens a connection;
# that is the point of the seam, not an accident of the test.
#
# DBIO::Test::Schema is shared by every driver's suite and keeps no driver in
# its class (core ADR 0067): each use declares one, and this file declares DB2
# on a clone, so the shared class stays driverless.

sub db2_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::DB2::Storage');
  return $schema->connection(@_);
}

my $schema  = db2_schema('dbi:DB2:DATABASE=nonexistent');
my $storage = $schema->storage;

# ------------------------------------------------------------ the rendering

# The first call on a fresh storage has its own assertion. _exists_value_sql
# is on the driver-determination list of DBIO::Storage::DBI: the override
# calls next::method while the driver is not yet determined, and the wrapper
# once re-dispatched to this override a second time, so the dummy table was
# appended twice. Core fixed the wrapper; this pins that the first call
# renders the dummy table once.
is (
  $storage->_exists_value_sql('(SELECT 42)'),
  'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM SYSIBM.SYSDUMMY1',
  'the first call on a storage whose driver is not yet determined renders '
. 'the dummy table once, like every later one',
);

is (
  $storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END'
. ' FROM SYSIBM.SYSDUMMY1',
  'the hook appends DB2\'s one-row catalog view and leaves the CASE spelling '
. 'to core -- only the dummy table is this driver\'s business',
);

is (
  ref $storage,
  'DBIO::DB2::Storage',
  '... answered by the DB2 storage the schema declared (core ADR 0067), so the '
. 'string above is this driver\'s answer and not the base rendering arrived '
. 'at by accident',
);

is (
  DBIO::Test::Schema->storage_type,
  '::DBI',
  '... and the declaration stays on the clone: the shared DBIO::Test::Schema '
. 'still names no driver, so no other suite inherits DB2 from this file',
);

SKIP: {
  # DBIO->driver_for came with the refusal, in core ADR 0067; a core without
  # it still determines a driver from the DSN, and there is nothing to refuse.
  skip 'core predates ADR 0067 (no DBIO->driver_for): it still determines '
     . 'the driver from the DSN', 1
    unless DBIO->can('driver_for');

  throws_ok
    { DBIO::Test::Schema->connect('dbi:DB2:DATABASE=nonexistent') }
    qr/declares no driver/,
    '... while the same DSN without a declaration is refused: dbi:DB2: names '
  . 'the DBD and nothing else, so DB2\'s hooks are reached by declaring the '
  . 'driver and never by the DSN alone';
}

isnt (
  DBIO::DB2::Storage->can('_exists_value_sql'),
  DBIO::Storage::DBI->can('_exists_value_sql'),
  '... and it is a real override, by coderef identity rather than by the '
. 'inherited string happening to look right',
);

# --------------------------------------------- one copy of the table name

is (
  $storage->_dummy_table,
  'SYSIBM.SYSDUMMY1',
  '_dummy_table is the single source of the catalog view\'s name: '
. '_dbh_last_insert_id needs it for IDENTITY_VAL_LOCAL() (ADR 0002) and '
. '_exists_value_sql needs it for the statement above, and a second literal '
. 'would be a second thing to get wrong',
);

is (
  $storage->_dummy_table('/'),
  'SYSIBM/SYSDUMMY1',
  '... and it still honours a server-reported qualifier separator, which is '
. 'what ADR 0002 kept sql_name_sep for -- only a caller already holding a '
. '$dbh may pass one, since resolving it probes the server',
);

like (
  $storage->_exists_value_sql('(SELECT 42)'),
  qr/ FROM SYSIBM\.SYSDUMMY1$/,
  '... while _exists_value_sql takes the default "." and never asks: it is a '
. 'static class fact, and a probe here would open a connection during query '
. 'build (ADR 0037 section 2, ADR 0039 section 7)',
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
  . ' WHERE ( "name" = ? )) THEN 1 ELSE 0 END FROM SYSIBM.SYSDUMMY1 )',
    'results_exist_as_query is the driver\'s complete statement in the one '
  . 'pair of parentheses core is allowed to add -- no SELECT * FROM (...) AS '
  . '_existence_subq wrapper, and no FROM-less SELECT for DB2 to reject',
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
. 'are class facts, and the driver is declared on the schema, not determined',
);

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass)
    = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run the live half', 2
    unless $dsn && $user;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_db2'), 2
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_db2');

  # The pins above prove what this driver renders, not that DB2 accepts it,
  # and a subquery inside a CASE WHEN condition is the half of this spelling
  # the SQL Reference does not state outright. Executed with no fixture at
  # all: the statement carries its own one-row table.
  my $live = db2_schema($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  my ($true) = $dbh->selectrow_array(
    $storage->_exists_value_sql('(SELECT 1 FROM SYSIBM.SYSDUMMY1)')
  );
  is ($true, 1, 'DB2 runs the rendered statement and answers 1 when the '
               . 'subquery has rows');

  my ($false) = $dbh->selectrow_array(
    $storage->_exists_value_sql('(SELECT 1 FROM SYSIBM.SYSDUMMY1 WHERE 1 = 0)')
  );
  is ($false, 0, '... and 0 when it has none -- an integer either way, not an '
                . 'engine-typed boolean');
}

done_testing;
