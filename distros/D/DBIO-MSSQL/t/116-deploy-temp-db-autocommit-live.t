use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::MSSQL::Deploy;

# LIVE (karr k80), counterpart of t/115. A handle in an open transaction is
# refused (the row written in the transaction is still there, the transaction
# still open); an AutoCommit handle creates and drops the throwaway database.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0);
my $deploy = bless {}, 'DBIO::MSSQL::Deploy';

for my $p (@paths) {
  my ($dsn, $user, $pass) = @$p;
  my ($dbd) = $dsn =~ /^dbi:(\w+)/i;

  my $dbh = DBI->connect($dsn, $user, $pass, { %conn, AutoCommit => 1 });

  my $tx = DBI->connect($dsn, $user, $pass, { %conn, AutoCommit => 0 });
  # DBD::Sybase opens no transaction by itself for AutoCommit off: make sure one stands
  $tx->do("IF \@\@TRANCOUNT = 0 BEGIN TRANSACTION");
  $tx->do("CREATE TABLE #k80 (id INT)");
  $tx->do("INSERT INTO #k80 VALUES (7)");

  my $before = $tx->selectrow_array('SELECT @@TRANCOUNT');
  ok !eval { $deploy->_create_temp_db($tx); 1 }, "$dbd: _create_temp_db refuses a handle in a transaction";
  like "$@", qr/_create_temp_db/, "$dbd: ... naming the method";
  ok !eval { $deploy->_drop_temp_db($tx, '_dbio_tmp_none'); 1 }, "$dbd: _drop_temp_db refuses it too";
  like "$@", qr/_drop_temp_db/, "$dbd: ... naming the method";
  is $tx->{AutoCommit}, 0, "$dbd: the handle is still in its transaction mode";
  is $tx->selectrow_array(q{SELECT @@TRANCOUNT}), $before, "$dbd: the transaction count is unchanged ($before)";
  cmp_ok $before, q{>=}, 1, "$dbd: ... and it is open";
  is $tx->selectrow_array('SELECT id FROM #k80'), 7, "$dbd: the row of the transaction is still there";
  # ODBC tracks the transaction itself; DBD::Sybase has none of its own
  $dbd eq q{ODBC} ? $tx->rollback : $tx->do("ROLLBACK");
  $dbd eq q{ODBC} or $tx->{AutoCommit} = 1;
  $tx->disconnect;

  my $name = $deploy->_create_temp_db($dbh);
  my ($id) = $dbh->selectrow_array('SELECT DB_ID(?)', undef, $name);
  ok defined $id, "$dbd: AutoCommit handle: $name was created";
  $deploy->_drop_temp_db($dbh, $name);
  ($id) = $dbh->selectrow_array('SELECT DB_ID(?)', undef, $name);
  ok !defined $id, "$dbd: ... and dropped";

  $dbh->disconnect;
}

done_testing;
