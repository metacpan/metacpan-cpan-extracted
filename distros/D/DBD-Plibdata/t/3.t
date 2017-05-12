use strict;
use lib 'lib';
use Plibwrap;

BEGIN { print "1..23\n"; }

my($sql,$db1,$dbh,$host,$port,$user,$pass,$row,$sth,$status,$err,$tabname,$tabid,$success);

$ENV{INFORMIXDB} or die "INFORMIXDB not defined\n";
$ENV{INFORMIXSERVER} or die "INFORMIXSERVER not defined\n";
$host = $ENV{PLBHOST} or die "PLBHOST not defined\n";
$port = $ENV{PLBPORT} or die "PLBPORT not defined\n";
$user = $ENV{PLBUSER} or die "PLBUSER not defined\n";
$pass = $ENV{PLBPASS} or die "PLBPASS not defined\n";

$db1 = Plibwrap->connect("dbi:Informix:$ENV{INFORMIXDB}", undef, undef, {PrintError => 0, AutoCommit => 0}) or print "not ok\n";
print "ok\n";

$sql = 'SELECT tabname, tabid FROM systables';

$success = 0;

if (($status = $db1->SQLExecSQL($sql)) < 0)
{
        $err = $db1->GetError();
}
else
{
	while ( ($status = $db1->SQLFetch()) == $Plibdata::RET_OK)
	{
		$tabname = $db1->{Row}->GetCharValue('tabname');
		$tabid = $db1->{Row}->GetCharValue('tabid');
		$success++;
	}
}
$success ? print "ok\n" : print "not ok\n";

$dbh = Plibwrap->connect("dbi:Plibdata:host=$host;port=$port", $user, $pass, {PrintError => 0, AutoCommit => 0}) or print "not ok\n";
print "ok\n";

$sql = 'SELECT tabname, tabid FROM systables';

if (($status = $dbh->SQLExecSQL($sql)) < 0)
{
        $err = $dbh->GetError();
        print "not ok\n";
}
else
{
	while ( ($status = $dbh->SQLFetch()) == $Plibdata::RET_OK)
	{
		$tabname = $dbh->{Row}->GetCharValue('tabname');
		$tabid = $dbh->{Row}->GetCharValue('tabid');
	}
	print "ok\n";
}

$sth = $dbh->prepare('SELECT * FROM systables') or print "not ok\n";
print "ok\n";

$sth->execute or print "not ok\n";
print "ok\n";

$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";
$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";
$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";

$sth->finish or print "not ok\n";
print "ok\n";

$row = $sth->fetchrow_arrayref;
$row ? print "not ok\n" : print "ok\n";

$sth = $dbh->prepare('SELECT * FROM syscolumns') or print "not ok\n";
print "ok\n";

$sth->execute or print "not ok\n";
print "ok\n";

$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";
$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";
$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";

$sth->finish or print "not ok\n";
print "ok\n";

$row = $sth->fetchrow_arrayref;
$row ? print "not ok\n" : print "ok\n";

$dbh->{AutoCommit} = 1 ? print "ok\n" : print "not ok\n";

$dbh->do('SELECT tabname FROM systables into temp a_0 with no log;') ? 
	print "not ok\n" : print "ok\n";
$db1->do('SELECT tabname FROM systables into temp a_0 with no log;') ? 
	print "ok\n" : print "not ok\n";

($db1->SQLClose == $Plibdata::RET_OK) ? print "ok\n" : print "not ok\n";
$dbh->disconnect ? print "ok\n" : print "not ok\n";
exit;

