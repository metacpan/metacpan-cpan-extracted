use strict;
use lib 'lib';
use DBI;

BEGIN { print "1..19\n"; }

my($sql,$dbh,$host,$port,$user,$pass,$row,$sth);

$host = $ENV{PLBHOST} or die "PLBHOST not defined\n";
$port = $ENV{PLBPORT} or die "PLBPORT not defined\n";
$user = $ENV{PLBUSER} or die "PLBUSER not defined\n";
$pass = $ENV{PLBPASS} or die "PLBPASS not defined\n";

$dbh = DBI->connect("dbi:Plibdata:host=$host;port=$port", $user, $pass, {PrintError => 0, AutoCommit => 1}) or print "not ok\n";

print "ok\n";

$dbh->disconnect ? print "ok\n" : print "not ok\n";

$dbh = DBI->connect("dbi:Plibdata:host=$host;port=$port", $user, $pass, {PrintError => 0, AutoCommit => 0}) or print "not ok\n";

print "ok\n";

($a) = $dbh->selectrow_array('SELECT * FROM systables');
print "ok\n" if $a;

$sth = $dbh->prepare('SELECT * FROM systables') or print "not ok\n";
print "ok\n";

$sth->execute or print "not ok\n";
print "ok\n";

$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";
$row = $sth->fetchrow_arrayref or print "not ok\n";
print "ok\n";
$row = $sth->fetchrow_arrayref or print "not ok\n";

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
