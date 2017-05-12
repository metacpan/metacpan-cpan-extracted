#!perl -w
# $Id: 10general.t 550 2006-11-28 00:35:09Z wagnerch $

use Test::More;
use DBI;
unshift @INC, 't';

$| = 1;
plan tests => 33;


my ($sth, $tmp);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


## Set autocommit
$dbh->{AutoCommit} = 0;
is ($dbh->{AutoCommit}, 0, 'autocommit off ok');


## Create table
$dbh->{PrintError} = 0;
$dbh->do("DROP TABLE dbd_timesten_general_test");
$dbh->{PrintError} = 1;

$dbh->do("
   CREATE TABLE dbd_timesten_general_test (
       tcol1 INTEGER NOT NULL
      ,tcol2 VARCHAR(100)
   )
", undef);
ok(!$DBI::err, 'create table ok');


## Check error handling
my $warn = '';
eval {
   local $SIG{__WARN__} = sub { $warn = $_[0] };
   $dbh->{RaiseError} = 1;
   $dbh->do("some invalid sql statement");
};
ok($@    =~ /DBD::TimesTen::db do failed:/, "eval error: ``$@'' expected 'do failed:'");
ok($warn =~ /DBD::TimesTen::db do failed:/, "warn error: ``$warn'' expected 'do failed:'");
ok($DBI::err, 'invalid statement ok');
$dbh->{RaiseError} = 0;


## Check active state
$sth = $dbh->prepare("select * from tables");
ok($sth->execute, 'execute ok');
ok($sth->{Active}, 'active ok');
1 while ($sth->fetch);  # fetch through to end
ok(!$sth->{Active}, 'not active ok');
$sth->finish();


## Load test data
my (@test_data) = (
    [ 1, '1nh2u0hgajnf' ]
   ,[ 2, 'u390jhy09ejd' ]
   ,[ 3, 'jw908hg30ggd' ]
   ,[ 4, '098ghu20ygfc' ]
   ,[ 5, undef ]
);

foreach $data (@test_data)
{
   $dbh->do("
      INSERT INTO dbd_timesten_general_test (tcol1, tcol2)
      VALUES (?, ?)
   ", undef, $data->[0], $data->[1]);
   ok(!$DBI::err, 'insert ok');
}


## bind_col
my ($tcol1, $tcol2, $i);
$sth = $dbh->prepare("SELECT tcol1, tcol2 FROM dbd_timesten_general_test ORDER BY tcol1");
ok(!$DBI::err, 'prepare ok');
$sth->execute();
ok(!$DBI::err, 'execute ok');
$sth->bind_col(1, \$tcol1);
ok(!$DBI::err, 'bind_col 1 ok');
$sth->bind_col(2, \$tcol2);
ok(!$DBI::err, 'bind_col 2 ok');
$i=0;
while ($sth->fetch())
{
   cmp_ok($tcol1, 'eq', $test_data[$i]->[0], 'column 1 compare ok');
   cmp_ok($tcol2, 'eq', $test_data[$i]->[1], 'column 2 compare ok');
   $i++;
}
$sth->finish();


$dbh->do("DROP TABLE dbd_timesten_general_test");
ok(!$DBI::err, 'drop table ok');


## Test ping
ok($dbh->{Active}, 'active ok');
ok($dbh->ping, 'ping ok');
ok($dbh->disconnect(), 'disconnect ok');
ok(!$dbh->{Active}, 'not active ok');
ok(!$dbh->ping, 'no ping ok');

exit 0;
