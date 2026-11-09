use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE (karr k54). The ODBC half of the declared way, against a real server.
# t/62-adapt-access-path.t pins offline which class a declared storage becomes
# for a dbi:ODBC: DSN, with DBI->connect replaced, and said of its ODBC branch
# that it was provable only there. This file is the counterpart of what
# t/60-connect-params-live.t holds for DBD::Sybase: a schema that loaded the
# MSSQL component -- the declaration of the driver (core ADR 0059) -- is the
# declared base class before its first use, DBIO::MSSQL::Storage::ODBC after
# it, over one connection, and core says nothing of a driver mismatch.
#
# The DSN is DBIO_TEST_MSSQL_ODBC_DSN, in whatever form DBD::ODBC takes
# (Driver=FreeTDS;Server=..., or DSN=<name>).

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MSSQL_ODBC_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER and _PASS to run this test'
  unless $dsn and defined $user and defined $pass;

plan skip_all => 'DBIO_TEST_MSSQL_ODBC_DSN is not a dbi:ODBC: DSN'
  unless $dsn =~ /\Adbi:ODBC:/i;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package T::K54::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

my $BASE = 'DBIO::MSSQL::Storage';
my $ODBC = 'DBIO::MSSQL::Storage::ODBC';

my $schema = T::K54::Schema->connect($dsn, $user, $pass);

is ref $schema->storage, $BASE,
  'before the first use the storage is the declared base class '
. '(the component pins it; connect asks nothing of the DSN)';

# every DBI->connect the storage makes, from the first use on
my $connect_count = 0;
{
  no warnings 'redefine';
  my $orig = \&DBI::connect;
  local *DBI::connect = sub { $connect_count++; goto &$orig };

  lives_ok { $schema->storage->ensure_connected }
    'the first use connects through DBD::ODBC';

  my ($one);
  lives_ok {
    $one = $schema->storage->dbh_do(sub { ($_[1]->selectrow_array('SELECT 1'))[0] });
  } 'a statement runs on the adapted storage';
  is $one, 1, 'and answers';
}

is $connect_count, 1, 'one connection made, for the adaptation and the use';

is ref $schema->storage, $ODBC,
  'after the first use the storage is DBIO::MSSQL::Storage::ODBC '
. '(decided from the DSN, not from a question to the server)';

isa_ok $schema->storage, $BASE, 'the adapted storage';

is $schema->storage->dbh->{Driver}{Name}, 'ODBC',
  'the connection runs on DBD::ODBC, the DBD the DSN names';

like +( $schema->storage->dbh->selectrow_array('SELECT @@VERSION') )[0],
  qr/Microsoft SQL Server/i, 'and the server is a SQL Server';

# a second statement, a transaction: nothing moves the class again
lives_ok {
  $schema->txn_do(sub { $schema->storage->dbh->do('SELECT 1') });
} 'a transaction runs';
is ref $schema->storage, $ODBC, 'the class stays what it became';

is_deeply [ @warnings ], [],
  'no warning at all -- in particular no "Driver mismatch for declared '
. 'storage class DBIO::MSSQL::Storage", which every declared MSSQL schema '
. 'got at its first use before it adapted to the access path';

done_testing;
