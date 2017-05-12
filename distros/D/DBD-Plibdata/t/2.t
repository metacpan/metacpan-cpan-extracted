use strict;
use lib 'lib';
use DBI;

my($sql,$dbh,$host,$port,$user,$pass,$row,$sth,$cnt,$n);
$cnt = 255;

BEGIN {
my $cnt = 255;
## UNCOMMENT IF YOU WANT TO RUN THIS TEST. YOU NEED se_tslog_rec TO WORK.
#print '1..', $cnt * 5 + 4*5 + 4, "\n"; 
## COMMENT THESE IF YOU WANT TO RUN TEST  -----^
print "1..0 # Skip t/2.t Requires se_tslog_rec to test. See file for details.\n";
exit;
}

$host = $ENV{PLBHOST} or die "PLBHOST not defined\n";
$port = $ENV{PLBPORT} or die "PLBPORT not defined\n";
$user = $ENV{PLBUSER} or die "PLBUSER not defined\n";
$pass = $ENV{PLBPASS} or die "PLBPASS not defined\n";

$dbh = DBI->connect("dbi:Plibdata:host=$host;port=$port", $user, $pass, {PrintError => 0, AutoCommit => 0, plb_RowsPerPacket => -1});
$dbh ? print "not ok\n" : print "ok\n";

$dbh = DBI->connect("dbi:Plibdata:host=$host;port=$port", $user, $pass, {PrintError => 0, AutoCommit => 0, plb_RowsPerPacket => 256});
$dbh ? print "not ok\n" : print "ok\n";

$dbh = DBI->connect("dbi:Plibdata:host=$host;port=$port", $user, $pass, {PrintError => 0, AutoCommit => 0, plb_RowsPerPacket => $cnt});
$dbh ? print "ok\n" : print "not ok\n";

for $n (-2 .. 2)
{
	$sql =<<EOT;
DELETE FROM se_tslog_rec
WHERE	tshrs_no = 0
AND	stat = "E"
AND	mod_dt = "1971-01-01 00:00:00"
;
EOT

	$dbh->do($sql) ? print "ok\n" : print "not ok\n";
	$dbh->commit ? print "ok\n" : print "not ok\n";

	$sql =<<EOT;
INSERT INTO se_tslog_rec
(tshrs_no, stat, mod_id, mod_dt)
VALUES(0, "E", ?, "1971-01-01 00:00:00")
;
EOT

	$dbh->do($sql,undef,$_) ? print "ok\n" : print "not ok\n" 
		for (1 .. ($cnt + $n));

	$sql =<<EOT;
SELECT mod_dt, mod_id, stat, tshrs_no
FROM se_tslog_rec
WHERE tshrs_no = 0
AND stat = "E"
AND mod_dt = "1971-01-01 00:00:00"
;
EOT

	$row = $dbh->selectall_arrayref($sql);
	$row ? print "ok\n" : print "not ok\n"; 
	@$row == ($cnt + $n) ? print "ok\n" : print "not ok\n"; 
}

$dbh->disconnect ? print "ok\n" : print "not ok\n"; 


