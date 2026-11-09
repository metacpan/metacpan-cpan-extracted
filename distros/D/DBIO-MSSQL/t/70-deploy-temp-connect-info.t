use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Schema;
use DBIO::AccessBroker::Static;
use DBIO::MSSQL::Deploy;

# OFFLINE (karr k46). diff/upgrade deploy the desired schema into a throwaway
# database and connect to it with the live storage's connect info, the
# database name swapped in the DSN. The derivation knew two shapes of
# connect_info -- [ $dsn, $user, $pass ] and [ { dsn, user, password } ] -- and
# fell through on the two this driver supports since karr k37:
#
#   * an AccessBroker: connect_info is [ $broker ], the "DSN" was the broker
#     object, and DBI was handed "DBIO::AccessBroker::Static=HASH(..);Database=.."
#   * connection parameters without a dsn ({ dbname, host, port }): no DSN at
#     all, ";Database=<temp>" became the whole DSN
#
# in both cases AFTER the temporary database had been created. The temp
# connection now starts from the connect info the storage actually connects
# with (the broker's answer, the DSN built from the parameters), and a connect
# info that has no DSN to rewrite is refused before anything is created.
#
# Nothing here connects.

{
  package T::MSSQL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

# counts what reaches the server
{
  package T::Deploy;
  use base 'DBIO::MSSQL::Deploy';
  our @CREATED;
  sub _dbh { +{ AutoCommit => 1 } }   # a handle outside a transaction (core k365)
  sub _create_temp_db { push @CREATED, 'created'; die "stop: would create\n" }
}

sub deploy_for { DBIO::MSSQL::Deploy->new(schema => T::MSSQL::Schema->connect(@_)) }

sub info_for {
  my $deploy = deploy_for(@_[0 .. $#_ - 1]);
  return [ $deploy->_temp_connect_info($_[-1]) ];
}

my $T = '_dbio_tmp_1_2';

# --- the shapes that always worked, now through _temp_dsn ---
is_deeply info_for('dbi:Sybase:host=h;port=1433;database=app', 'u', 'p', $T),
  [ "dbi:Sybase:host=h;port=1433;database=$T", 'u', 'p' ],
  'array form, Sybase DSN: database= is replaced, in its own spelling';

is_deeply info_for({ dsn => 'dbi:Sybase:server=s', user => 'u', password => 'p' }, $T),
  [ "dbi:Sybase:server=s;database=$T", 'u', 'p' ],
  'hash form with dsn, Sybase DSN without a database: database= is appended';

is_deeply info_for('dbi:ODBC:Driver=FreeTDS;Server=h;Database=app;TDS_Version=7.4', 'u', 'p', $T),
  [ "dbi:ODBC:Driver=FreeTDS;Server=h;Database=$T;TDS_Version=7.4", 'u', 'p' ],
  'ODBC DSN: Database= is replaced';

is_deeply info_for('dbi:ODBC:DSN=mssql-dev', 'u', 'p', $T),
  [ "dbi:ODBC:DSN=mssql-dev;Database=$T", 'u', 'p' ],
  'ODBC DSN without a database: Database= is appended';

# --- the two shapes that fell through ---
is_deeply
  info_for(DBIO::AccessBroker::Static->new(
    host => 'h', port => 1433, dbname => 'app', username => 'bu', password => 'bp'), $T),
  [ "dbi:Sybase:host=h;port=1433;database=$T", 'bu', 'bp' ],
  'AccessBroker: the broker answer is the starting point, not the broker object';

is_deeply
  info_for({ dbname => 'app', host => 'h', port => 1433, user => 'u', password => 'p' }, $T),
  [ "dbi:Sybase:host=h;port=1433;database=$T", 'u', 'p' ],
  'connection parameters without a dsn: the DSN built from them is rewritten';

is_deeply
  info_for(DBIO::AccessBroker::Static->new(host => 'h', port => 1433, username => 'bu', password => 'bp'), $T),
  [ "dbi:Sybase:host=h;port=1433;database=$T", 'bu', 'bp' ],
  'AccessBroker without dbname: database= is appended';

is_deeply
  info_for({ dbname => 'dbi:ODBC:Driver=FreeTDS;Server=h;Database=app', user => 'u', password => 'p' }, $T),
  [ "dbi:ODBC:Driver=FreeTDS;Server=h;Database=$T", 'u', 'p' ],
  'a dbname that is a whole DSN: rewritten like a dsn';

# --- refused before the temp database exists ---
{
  my $schema = T::MSSQL::Schema->connect(sub { die 'no connection in this test' });
  my $deploy = T::Deploy->new(schema => $schema);
  @T::Deploy::CREATED = ();
  throws_ok { $deploy->_build_target_model } qr/coderef DSN/,
    'a coderef connect info is refused';
  is_deeply \@T::Deploy::CREATED, [],
    '... before the temp database is created';
}

{
  my $deploy = T::Deploy->new(schema => T::MSSQL::Schema->connect('dbi:Sybase:server=s', 'u', 'p'));
  @T::Deploy::CREATED = ();
  throws_ok { $deploy->_build_target_model } qr/stop: would create/,
    'a usable connect info goes on to create the temp database';
  is_deeply \@T::Deploy::CREATED, ['created'], '... exactly once';
}

done_testing;
