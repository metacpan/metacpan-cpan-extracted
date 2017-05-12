#!perl -w
# $Id: 30commit.t 546 2006-11-26 17:51:19Z wagnerch $

use Test::More;
use DBI;
unshift @INC, 't';

$| = 1;
plan tests => 20;


my ($sth, $tmp);

## Connect
my $db1 = DBI->connect();
unless ($db1)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}

my $db2 = DBI->connect();
unless ($db2)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


$db1->{PrintError} = 0;
$db1->do("DROP TABLE dbd_timesten_commit_test");
$db1->{PrintError} = 1;

$db1->do("
   CREATE TABLE dbd_timesten_commit_test (
       tcol1 INTEGER NOT NULL
   )
", undef);
ok(!$DBI::err, 'create table ok');

$db1->{AutoCommit} = 0;


## Load table
my ($i);
for ($i = 0; $i < 10; $i++)
{
   $db1->do("
      INSERT INTO dbd_timesten_commit_test (tcol1)
      VALUES (?)
   ", undef, $i);
   ok(!$DBI::err, 'insert ok');
}


## Check data is not committed
my ($st2);
$st2 = $db2->prepare("
   SELECT COUNT(*)
     FROM dbd_timesten_commit_test
");
ok(!$DBI::err, 'prepare ok');
$st2->execute();
ok(!$DBI::err, 'execute ok');
($tmp) = $st2->fetchrow_array();
ok($tmp == 0, 'no rows ok');
$st2->finish();


## Now commit
$db1->commit();
ok(!$DBI::err, 'commit ok');

## Check data is committed
$st2 = $db2->prepare("
   SELECT COUNT(*)
     FROM dbd_timesten_commit_test
");
ok(!$DBI::err, 'prepare ok');
$st2->execute();
ok(!$DBI::err, 'execute ok');
($tmp) = $st2->fetchrow_array();
ok($tmp == 10, 'rows fetched ok');
$st2->finish();


## Done, drop table
$db1->do("DROP TABLE dbd_timesten_commit_test");
ok(!$DBI::err, 'drop table ok');
$db1->commit();
ok(!$DBI::err, 'commit ok');


$db1->disconnect();
$db2->disconnect();
exit 0;
