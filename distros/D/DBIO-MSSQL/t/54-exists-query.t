use strict;
use warnings;
use Test::More;
use Test::Exception;
use mro;
use DBIO::Test ':DiffSQL';

# Offline test of the supports_exists_query capability and the EXISTS
# rendering (ADR 0037). No database: the declaration is a static class fact
# and the rendering is a pure string transform, which is the whole point of
# the seam.

use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;

# --- the declaration is the DRIVER's, not the mock's ---------------------
#
# DBIO::Test::Storage sets _use_supports_exists_query(1) on itself, so asking
# the hybrid storage of an init_schema() would answer 1 whatever this driver
# says. Ask the real classes.
#
# And ask them WHERE the 1 comes from, not just what it is (karr k29). Both
# rebless targets put the TRANSPORT class ahead of the MSSQL ENGINE class in
# the c3 linearisation --
#
#   ODBC:   @ISA (DBIO::Storage::DBI::ODBC, DBIO::MSSQL::Storage)
#   Sybase: @ISA (DBIO::Sybase::Storage,    DBIO::MSSQL::Storage)
#
# -- and Class::Accessor::Grouped::get_inherited walks exactly that
# linearisation, returning the first DEFINED declaration along it. A value
# assertion cannot tell a 1 declared here from a 1 declared by a transport,
# and on this capability that is not hypothetical: dbio-sybase declares 1 as
# well, today on DBIO::Sybase::Storage::ASE, which is not in this chain. Were
# it to move up to DBIO::Sybase::Storage, every assertion below would stay
# green while the answer on a Microsoft SQL Server connection came from a
# Sybase ASE fact that happens to agree. Same helper, same argument as
# t/42-deploy-transactional-ddl.t: set_inherited stores the declaration in
# $Class::__cag_<field>, so the classes holding that variable are both the
# proof that this driver stated the value itself and the proof that nothing
# ahead of it shadows it.

sub declaring_classes {
  my ($class) = @_;
  no strict 'refs';
  return [ grep { defined ${ $_ . '::__cag__use_supports_exists_query' } }
             @{ mro::get_linear_isa($class) } ];
}

is( DBIO::MSSQL::Storage->_use_supports_exists_query, 1,
  'DBIO::MSSQL::Storage declares supports_exists_query as a class fact' );

is_deeply( declaring_classes('DBIO::MSSQL::Storage'),
  [ 'DBIO::MSSQL::Storage' ],
  '... on the transport-neutral base, because it is an engine fact' );

is( DBIO::MSSQL::Storage::ODBC->_use_supports_exists_query, 1,
  '... and the ODBC rebless target inherits the declaration' );

is_deeply( declaring_classes('DBIO::MSSQL::Storage::ODBC'),
  [ 'DBIO::MSSQL::Storage' ],
  '... reading it from DBIO::MSSQL::Storage, unshadowed' );

SKIP: {
  skip 'DBIO::Sybase not installed (optional dep), so the cross-dist half of '
     . 'this check did NOT run', 2
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  is( DBIO::MSSQL::Storage::Sybase->_use_supports_exists_query, 1,
    '... and so does the DBD::Sybase rebless target' );

  is_deeply( declaring_classes('DBIO::MSSQL::Storage::Sybase'),
    [ 'DBIO::MSSQL::Storage' ],
    '... also from DBIO::MSSQL::Storage, and not from DBIO::Sybase::Storage, '
  . 'which sits ahead of it and speaks DBD::Sybase to SQL Server, not to ASE' );
}

# --- the base rendering is inherited verbatim, on purpose -----------------
#
# Byte-exact rather than is_same_sql: this pins that the driver did NOT
# override _exists_value_sql, and that the string it inherits is the one
# checked against the T-SQL grammar -- a FROM-less SELECT (legal on SQL
# Server, unlike Oracle/DB2/Firebird) whose select list is a searched CASE
# over EXISTS (a Boolean_expression, which is what CASE WHEN takes).

is( DBIO::MSSQL::Storage->_exists_value_sql('(SELECT 42 FROM [artist] [me])'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM [artist] [me]) THEN 1 ELSE 0 END',
  'SQL Server inherits core\'s base EXISTS rendering unchanged' );

is( DBIO::MSSQL::Storage->can('_exists_value_sql'),
  DBIO::Storage::DBI->can('_exists_value_sql'),
  '... and does so by not overriding the hook at all' );

# --- end to end through the resultset ------------------------------------

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::MSSQL::Storage',
  no_deploy    => 1,
  quote_names  => 1,
);
my $storage = $schema->storage;

my $rs = $schema->resultset('Artist')->search({ name => 'foo' });

is_same_sql_bind(
  $rs->results_exist_as_query,
  q{( SELECT CASE WHEN EXISTS (
        SELECT 42 FROM [artist] [me] WHERE ( [name] = ? )
      ) THEN 1 ELSE 0 END )},
  [ [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'name' }
      => 'foo' ] ],
  'results_exist_as_query renders the CASE form with MSSQL bracket quoting',
);

$storage->mock(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);
$storage->reset_captured;

is $rs->results_exist, 1, 'results_exist reads the 1/0 the statement yields';

my @sql = map { $_->{sql} } $storage->captured_queries;
is scalar(@sql), 1, '... in exactly one statement';
is $sql[0],
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM [artist] [me] WHERE ( [name] = ? )) THEN 1 ELSE 0 END',
  '... which is the complete statement, with no derived-table wrapper around it';

# --- the one SQL Server restriction that reaches this path ----------------
#
# T-SQL forbids ORDER BY inside a subquery without TOP / OFFSET / FOR XML, so
# the inner query of an existence check may not carry one. This driver's
# ordered-subselect guard catches it while building as_query, before any
# EXISTS SQL exists. Pinned because it is engine-true and a caller who hits it
# needs to recognise the message.

$storage->reset_captured;

throws_ok {
  $schema->resultset('Artist')->search({}, { order_by => 'name' })
    ->results_exist_as_query
} qr/ordered subselect/,
  'an existence check on an ordered resultset is refused, not silently ordered';

is scalar($storage->captured_queries), 0, '... and issued no SQL';

done_testing;
