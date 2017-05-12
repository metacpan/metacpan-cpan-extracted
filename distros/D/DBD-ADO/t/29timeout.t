#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 29;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Timeout tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

my $tbl = $DBD_TEST::table_name;

ok( DBD_TEST::tab_create( $dbh ),"CREATE TABLE $tbl");

is( $dbh->{ado_commandtimeout}, 30,'dbh ado_commandtimeout');
$dbh->{ado_commandtimeout} = 20;
is( $dbh->{ado_commandtimeout}, 20,'dbh ado_commandtimeout');
is( $dbh->{ado_conn}{CommandTimeout}, 20,'ADO Connection CommandTimeout');

my $sth = $dbh->prepare("SELECT * FROM $tbl");
ok( defined $sth,'Statement handle defined');

is( $sth->{ado_commandtimeout}, 20,'sth ado_commandtimeout');
$sth->{ado_commandtimeout} = 10;
is( $sth->{ado_commandtimeout}, 10,'sth ado_commandtimeout');
is( $sth->{ado_conn}{CommandTimeout}, 20,'ADO Connection CommandTimeout');
is( $sth->{ado_comm}{CommandTimeout}, 10,'ADO Command CommandTimeout');

$sth = undef;

SKIP: {
  skip('SQLOLEDB specific tests', 17 )
    if $dbh->{ado_conn}{Provider} !~ /^SQLOLEDB/;

  $dbh->{AutoCommit} = 0;

  my $proc = $DBD_TEST::table_name . '_WAIT';

  my $sql = "CREATE PROCEDURE $proc AS waitfor delay '00:00:07'";

  ok( $dbh->do( $sql ),"do: $sql");

  ok( $dbh->do( $proc ),"do: $proc");

  $dbh->{ado_commandtimeout} = 2;
  is( $dbh->{ado_commandtimeout}, 2,'dbh ado_commandtimeout');

  $dbh->{PrintError} = 0;
  $dbh->{Warn}       = 0;

  ok(!$dbh->do( $proc ),"do: $proc (timeout=$dbh->{ado_commandtimeout})");

  like( $dbh->errstr, qr/HYT00/          ,'Error expected: HYT00');
# like( $dbh->errstr, qr/Timeout expired/,'Error expected: Timeout expired');  # language dependent?
  is  ( $dbh->state ,'HYT00'             ,'SQLState');
  is  ( $dbh->err   , -2147217871        ,'Error Number');  # 0x80040E31

  my $sth = $dbh->prepare( $proc );
  is( $sth->{ado_commandtimeout}, 2,'sth ado_commandtimeout');

  ok(!$sth->execute,'execute');
  like( $sth->errstr, qr/HYT00/          ,'Error expected: HYT00');
  is  ( $sth->state ,'HYT00'             ,'SQLState');
  is  ( $sth->err   , -2147217871        ,'Error Number');

  $sth->{ado_commandtimeout} = 1;
  is( $sth->{ado_commandtimeout}, 1,'sth ado_commandtimeout');

  ok(!$sth->execute,'execute');
  like( $sth->errstr, qr/HYT00/          ,'Error expected: HYT00');
  is  ( $sth->state ,'HYT00'             ,'SQLState');
  is  ( $sth->err   , -2147217871        ,'Error Number');
}
ok( $dbh->disconnect,'Disconnect');
