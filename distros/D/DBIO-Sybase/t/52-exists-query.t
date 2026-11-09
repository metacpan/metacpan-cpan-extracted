use strict;
use warnings;
use Test::More;
use DBIO::Test ':DiffSQL';

use mro ();

# Offline test of the supports_exists_query capability and the EXISTS
# rendering (ADR 0037). No database: the declaration is a static class fact
# and the rendering is a pure string transform, which is the whole point of
# the seam.

use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

# --- the declaration is the DRIVER's, not the mock's ---------------------
#
# DBIO::Test::Storage sets _use_supports_exists_query(1) on itself, so asking
# the hybrid storage of an init_schema() would answer 1 whatever this driver
# says. Ask the real class.

is( DBIO::Sybase::Storage::ASE->_use_supports_exists_query, 1,
  'DBIO::Sybase::Storage::ASE declares supports_exists_query as a class fact' );

is( DBIO::Sybase::Storage::ASE::NoBindVars->_use_supports_exists_query, 1,
  '... and the NoBindVars class inherits the declaration' )
  if eval { require DBIO::Sybase::Storage::ASE::NoBindVars; 1 };

# --- and it is an ASE fact, so it must not reach the MSSQL path -----------
#
# DBIO::Sybase::Storage is only the sp_server_info dispatcher: DBIO::MSSQL::
# Storage::Sybase is @ISA (DBIO::Sybase::Storage, DBIO::MSSQL::Storage) under
# c3, so anything declared on the dispatcher wins over the MSSQL half on a
# class that speaks DBD::Sybase to Microsoft SQL Server. An ASE engine fact
# there would be an answer about the wrong engine, so it lives on ::ASE.
#
# get_inherited() rather than the _use_ accessor on purpose: the accessor
# falls through to get_dbms_capability when nothing is declared, which needs a
# storage instance and a $dbh. The question here is only "is a value declared
# at or above this class", which is exactly what get_inherited answers.

is( DBIO::Sybase::Storage->get_inherited('_use_supports_exists_query'), undef,
  'the shared DBD::Sybase dispatcher declares no capability of its own' );

{
  my $isa = mro::get_linear_isa('DBIO::Sybase::Storage::ASE');
  ok( !(grep { $_ eq 'DBIO::MSSQL::Storage' } @$isa),
    'and the ASE class is not on the MSSQL storage path in the other direction' );
}

# --- the base rendering is inherited verbatim, on purpose -----------------
#
# Byte-exact rather than is_same_sql: this pins that the driver did NOT
# override _exists_value_sql, and that the string it inherits is the one
# checked against the ASE grammar -- a FROM-less select (the from_clause is
# optional in ASE's select production) whose select list is a searched case
# (which "can be used anywhere a value expression can be used") over an
# exists (<subquery>) search condition.

is( DBIO::Sybase::Storage::ASE->_exists_value_sql('(SELECT 42 FROM [artist] [me])'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM [artist] [me]) THEN 1 ELSE 0 END',
  'Sybase ASE inherits core\'s base EXISTS rendering unchanged' );

is( DBIO::Sybase::Storage::ASE->can('_exists_value_sql'),
  DBIO::Storage::DBI->can('_exists_value_sql'),
  '... and does so by not overriding the hook at all' );

# --- end to end through the resultset ------------------------------------

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::Sybase::Storage::ASE',
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
  'results_exist_as_query renders the CASE form with ASE bracket quoting',
);

$storage->mock(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);
$storage->reset_captured;

is $rs->results_exist, 1, 'results_exist reads the 1/0 the statement yields';

my @sql = map { $_->{sql} } $storage->captured_queries;
is scalar(@sql), 1, '... in exactly one statement';
is $sql[0],
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM [artist] [me] WHERE ( [name] = ? )) THEN 1 ELSE 0 END',
  '... which is the complete statement, with no derived-table wrapper around it';

done_testing;
