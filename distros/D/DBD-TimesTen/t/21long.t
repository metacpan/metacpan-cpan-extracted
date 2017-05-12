#!perl -w
# $Id: 21long.t 555 2006-11-30 23:42:45Z wagnerch $

use Test::More;
use DBI;
unshift @INC, 't';

$| = 1;
plan tests => 8;


my ($sth, $tmp);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


$dbh->{PrintError} = 0;
$dbh->do("DROP TABLE dbd_timesten_long_test");
$dbh->{PrintError} = 1;

$dbh->do("
   CREATE TABLE dbd_timesten_long_test (
       tcol1 VARCHAR(4194304) NOT NULL
   )
", undef);
ok(!$DBI::err, 'create table ok');

$tmp = 'A' x 4194304;
$dbh->do("
   INSERT INTO dbd_timesten_long_test (tcol1)
   VALUES (?)
", undef, $tmp);
ok(!$DBI::err, 'insert ok');

$sth = $dbh->prepare("
   SELECT tcol1
     FROM dbd_timesten_long_test
");
ok($sth, 'prepare ok');
ok($sth->execute(), 'execute ok');
my ($row) = $sth->fetchrow_arrayref();
ok($row, 'row fetch ok');
$sth->finish();
cmp_ok(length($row->[0]), '==', 4194304, 'length ok');

$dbh->do("DROP TABLE dbd_timesten_long_test");
ok(!$DBI::err, 'drop table ok');

ok($dbh->disconnect(), 'disconnect ok');
exit 0;
