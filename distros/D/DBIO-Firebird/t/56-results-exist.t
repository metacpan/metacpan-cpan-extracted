use strict;
use warnings;
use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;

# ADR 0037 -- the boolean-valued EXISTS query behind DBIO::ResultSet's
# results_exist, results_exist_async and results_exist_as_query. Two separate
# things have to be true on Firebird, and neither of them is inherited:
#
#   * the statement needs a FROM clause. Core's base rendering of
#     _exists_value_sql is a FROM-less SELECT, and Firebird has no FROM-less
#     SELECT at all, so this driver overrides the hook and appends the one-row
#     system table RDB$DATABASE -- the same one this storage already selects
#     from for GEN_ID and for the engine version.
#   * the supports_exists_query capability has to be *declared*. Core defaults
#     it to 0 and refuses all three methods outright rather than degrading
#     silently to has_rows -- so a driver that ships the override but forgets
#     the declaration has built a feature nobody can reach. The
#     results_exist_as_query pin below is the tripwire: without the
#     declaration it throws a typed DBIO::Exception naming the capability and
#     this file goes red.
#
# Both live on DBIO::Firebird::Storage::Common, so DBD::Firebird and
# DBD::InterBase get the same answer; the InterBase leg below is what keeps
# that true.
#
# All of it is offline. The driver is declared, and both the hook and the
# capability are static class facts, so nothing here opens a connection; that
# is the point of the seam, not an accident of the test.
#
# A schema always has a driver (core ADR 0067). DBIO::Test::Schema is shared
# by the driver suites and keeps none in its class, so every connect below
# declares the storage of the DBD it names on a clone.

my $schema  = DBIO::Test::Schema->clone(storage_type => '+DBIO::Firebird::Storage')
  ->connect('dbi:Firebird:db=/nonexistent.fdb');
my $storage = $schema->storage;

# Driver resolution is lazy, and core only ever asks the hook after the
# capability check has resolved it (results_exist* ask supports_exists_query
# first). Asked first on an unresolved storage, the hook runs twice: core's
# resolving wrapper sits behind next::method and re-dispatches from the top of
# the class, so the suffix is appended twice. That is core's wrapper, not this
# rendering; resolving first asks the hook in the state core asks it in. Reads
# the DSN only, no connection.
$storage->_determine_driver;

# ------------------------------------------------------------ the rendering

is (
  $storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END'
. ' FROM RDB$DATABASE',
  'the hook appends Firebird\'s one-row system table and leaves the CASE '
. 'spelling to core -- only the dummy table is this driver\'s business',
);

like (
  $storage->_exists_value_sql('(SELECT 42)'),
  qr/ FROM RDB\$DATABASE$/,
  '... spelled with the dollar, which is a real character of the identifier '
. 'and not a Perl variable that interpolated away to "FROM RDB"',
);

is (
  ref $storage,
  'DBIO::Firebird::Storage',
  '... answered by the declared storage, which stands as declared: the hook '
. 'is resolved on that class, so the string above is this driver\'s answer '
. 'and not the base rendering arrived at by accident',
);

isnt (
  DBIO::Firebird::Storage->can('_exists_value_sql'),
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
  . ' WHERE ( "name" = ? )) THEN 1 ELSE 0 END FROM RDB$DATABASE )',
    'results_exist_as_query is the driver\'s complete statement in the one '
  . 'pair of parentheses core is allowed to add -- no SELECT * FROM (...) AS '
  . '_existence_subq wrapper, and no FROM-less SELECT for Firebird to reject',
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
. 'are class facts, and the driver is the declared one',
);

# ------------------------------------------- the same answer via DBD::InterBase

{
  my $ib = DBIO::Test::Schema
    ->clone(storage_type => '+DBIO::Firebird::Storage::InterBase')
    ->connect('dbi:InterBase:db=/nonexistent.fdb')
    ->storage;
  $ib->_determine_driver;   # as above

  is (
    $ib->_exists_value_sql('(SELECT 42)'),
    'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM RDB$DATABASE',
    'the InterBase driver renders the same statement -- both hook and '
  . 'capability sit on the shared Storage::Common, so neither DBD can be '
  . 'left behind by an edit to the other',
  );

  ok ($ib->_use_supports_exists_query, '... and declares the capability too');
  ok (! $ib->connected, '... without connecting either');
}

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass)
    = @ENV{map { "DBIO_TEST_FIREBIRD_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_FIREBIRD_DSN}, _USER and _PASS to run the live half', 2
    unless $dsn && $user && $pass;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('rdbms_firebird'), 2
    unless DBIO::Optional::Dependencies->req_ok_for('rdbms_firebird');

  # The pins above prove what this driver renders, not that Firebird accepts
  # it, and a subquery inside a CASE WHEN condition is the half of this
  # spelling the Language Reference does not state outright. Executed with no
  # fixture at all: the statement carries its own one-row table.
  my $live = DBIO::Test::Schema->clone(storage_type => '+DBIO::Firebird::Storage')
    ->connect($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  my ($true) = $dbh->selectrow_array(
    $storage->_exists_value_sql('(SELECT 1 FROM RDB$DATABASE)')
  );
  is ($true, 1, 'Firebird runs the rendered statement and answers 1 when the '
               . 'subquery has rows');

  my ($false) = $dbh->selectrow_array(
    $storage->_exists_value_sql('(SELECT 1 FROM RDB$DATABASE WHERE 1 = 0)')
  );
  is ($false, 0, '... and 0 when it has none -- an integer either way, not an '
                . 'engine-typed boolean');
}

done_testing;
