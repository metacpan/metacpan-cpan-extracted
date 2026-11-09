use strict;
use warnings;

use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Informix::Storage;

# ADR 0037 (karr k23) -- the boolean-valued EXISTS query behind
# DBIO::ResultSet's results_exist, results_exist_async and
# results_exist_as_query. Two things have to be true on Informix and neither
# is inherited:
#
#   * the supports_exists_query capability has to be *declared*. Core defaults
#     it to 0 and refuses all three methods outright, so a driver without the
#     declaration has no results_exist at all.
#   * the statement needs a FROM clause that every Informix release takes.
#     Informix 15.0.1 does accept a FROM-less SELECT (measured, karr k23), but
#     the hook is a static class fact that cannot ask which release it talks
#     to, and the FROM-less form is not something the older releases this
#     driver mostly meets are known to take. So the statement gets the
#     catalog's own one-row selection, systables WHERE tabid = 1 (tabid 1 is
#     systables itself, present in every database of every release), instead
#     of sysmaster:sysdual, which would make every existence check depend on
#     a cross-database reference into sysmaster.
#
# The first half is offline: both are class facts, nothing opens a connection.
# The SKIP block at the end executes the rendering against a server.

sub informix_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::Informix::Storage');
  return $schema->connect(@_);
}

my $schema  = informix_schema('dbi:Informix:ixdb@ixserver');
my $storage = $schema->storage;

is (
  $storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END'
. ' FROM systables WHERE tabid = 1',
  'the hook appends the one-row selection of the catalog and leaves the CASE '
. 'spelling to core -- only the FROM clause is this driver\'s business',
);

is (
  ref $storage,
  'DBIO::Informix::Storage',
  '... answered by the storage the schema declared, still that class after '
. 'driver determination: the string above is this driver\'s answer and not '
. 'the base rendering arrived at by accident',
);

isnt (
  DBIO::Informix::Storage->can('_exists_value_sql'),
  DBIO::Storage::DBI->can('_exists_value_sql'),
  '... and it is a real override, by coderef identity',
);

ok (
  $storage->_use_supports_exists_query,
  'supports_exists_query is declared. Core defaults it to 0 and throws on '
. 'all three results_exist* methods without it',
);

{
  my $rs = $schema->resultset('Artist')->search({ name => 'foo' });

  my ($sql, @bind) = @{ ${ $rs->results_exist_as_query } };

  like (
    $sql,
    qr/\A\( SELECT CASE WHEN EXISTS \(.*"name" = \?.*\) THEN 1 ELSE 0 END FROM systables WHERE tabid = 1 \)\z/s,
    'results_exist_as_query is the driver\'s complete statement in the one '
  . 'pair of parentheses core adds',
  );

  is_deeply (
    [ map { $_->[1] } @bind ],
    [ 'foo' ],
    '... and the inner condition\'s bind values travel out with it',
  );
}

ok (
  ! $storage->connected,
  'none of the above opened a connection: rendering and capability are '
. 'class facts',
);

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run the live half', 4
    unless $dsn;

  skip 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix'), 4
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

  {
    package T::ExistsRow;
    use base 'DBIO::Core';
    __PACKAGE__->table('naehte_exists');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer' },
      name => { data_type => 'varchar', size => 20 },
    );
    __PACKAGE__->set_primary_key('id');

    package T::ExistsSchema;
    use base 'DBIO::Schema';
    __PACKAGE__->storage_type('+DBIO::Informix::Storage');
    __PACKAGE__->register_class(Row => 'T::ExistsRow');
  }

  my $live = T::ExistsSchema->connect($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  eval { $dbh->do('DROP TABLE naehte_exists') };
  $dbh->do('CREATE TABLE naehte_exists (id INTEGER PRIMARY KEY, name VARCHAR(20))');
  END { local $@; eval { $dbh->do('DROP TABLE naehte_exists') } if $dbh }

  $dbh->do(q{INSERT INTO naehte_exists VALUES (1, 'foo')});

  # The pins above prove what this driver renders, not that Informix accepts
  # it: a subselect inside a CASE WHEN condition with a FROM that is not the
  # subselect's own is the half the SQL reference does not state outright.
  is ($live->resultset('Row')->search({ name => 'foo' })->results_exist, 1,
    'Informix runs the statement results_exist builds and answers 1 when the '
  . 'subquery has rows, with the search condition bound');

  is ($live->resultset('Row')->search({ name => 'nope' })->results_exist, 0,
    '... and 0 when it has none');

  my ($true) = $dbh->selectrow_array(
    $live->storage->_exists_value_sql('(SELECT 1 FROM naehte_exists)'));
  is ($true, 1, 'the bare rendering answers an integer 1');

  my ($false) = $dbh->selectrow_array(
    $live->storage->_exists_value_sql('(SELECT 1 FROM naehte_exists WHERE 1 = 0)'));
  is ($false, 0, '... and an integer 0 -- not an engine-typed boolean');
}

done_testing;
