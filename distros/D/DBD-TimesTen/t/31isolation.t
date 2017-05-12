#!perl -w
# $Id: 31isolation.t 546 2006-11-26 17:51:19Z wagnerch $

use Test::More;
use DBI;
use DBD::TimesTen qw(:sql_isolation_options);
unshift @INC, 't';

$| = 1;
plan tests => 21;


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


## Check if we get a lock timeout
my ($st2);
$db2->{ttIsolationLevel} = SQL_TXN_SERIALIZABLE;
$db2->{RaiseError} = 0;
$db2->{PrintError} = 0;
$db2->do("CALL ttLockWait(0)", undef);
ok(!$DBI::err, 'ttLockWait ok');
$st2 = $db2->prepare("
   SELECT COUNT(*)
     FROM dbd_timesten_commit_test
");
ok(!$DBI::err, 'prepare ok');
$st2->execute();
ok(!$DBI::err, 'execute ok');
($tmp) = $st2->fetchrow_array();
ok($DBI::err, 'lock failed ok');
$st2->finish();


## Now commit
$db1->commit();
ok(!$DBI::err, 'commit ok');

## Check if we can fetch now
$st2 = $db2->prepare("
   SELECT COUNT(*)
     FROM dbd_timesten_commit_test
");
ok(!$DBI::err, 'prepare ok');
$st2->execute();
ok(!$DBI::err, 'execute ok');
($tmp) = $st2->fetchrow_array();
ok($tmp == 10, 'fetch ok');
$st2->finish();


## Done, drop table
$db1->do("DROP TABLE dbd_timesten_commit_test");
ok(!$DBI::err, 'drop table ok');
$db1->commit();
ok(!$DBI::err, 'commit ok');


$db1->disconnect();
$db2->disconnect();
exit 0;
