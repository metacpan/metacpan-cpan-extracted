####################################################################
# TESTCASE: 		perld052_verifyCachedKidsAttr.pl
# DESCRIPTION: 		Verify that a warning is returned if the cached
#                       statement handle being returned is still active and
#                       verify that the CachedKids attribute returns the
#                       correct information.
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");
check_value("CONNECT", "dbh->{CachedKids}", undef);


$stmt1 = "INSERT INTO staff (id, name, dept) VALUES (?, ?, ?)";
$sth1 = $dbh->prepare_cached($stmt1);
check_error("PREPARE_CACHED 1");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE_CACHED 1", "numCachedKids", 1);

$stmt1a = "INSERT INTO staff (id, name, dept) VALUES (?, ?, ?)";
$sth1a = $dbh->prepare_cached($stmt1a);
check_error("PREPARE_CACHED 1a");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE_CACHED 1", "numCachedKids", 1);
check_value("PREPARE_CACHED 1", "sth1", $sth1a);

$sth1->bind_param(1, 999,       $attrib_int);
print %$attrib_int;
check_error("BIND_PARAM 11");
$sth1->bind_param(2, "Huffman", $attrib_char);
check_error("BIND_PARAM 12");
$sth1->bind_param(3, 99,        $attrib_int);
check_error("BIND_PARAM 13");
$sth1->execute();
check_error("EXECUTE 1");

$sth1->finish();
check_error("FINISH 1");

$stmt2 = "SELECT id, name, dept FROM staff WHERE id = ?";
$sth2 = $dbh->prepare_cached($stmt2);
check_error("PREPARE_CACHED 2");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE_CACHED 2", "numCachedKids", 2);

$stmt2a = "SELECT id, name, dept FROM staff WHERE id = ?";
$sth2a = $dbh->prepare_cached($stmt2a);
check_error("PREPARE_CACHED 2a");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE_CACHED 2a", "numCachedKids", 2);
check_value("PREPARE_CACHED 2", "sth2", $sth2a);

$sth2->bind_param(1, 999, $attrib_int);
check_error("BIND_PARAM 21");
$sth2->execute();
check_error("EXECUTE 2");

$success = check_results($sth2, $testcase);

$stmt3 = "DELETE FROM staff WHERE id = ?";
$sth3 = $dbh->prepare($stmt3);
check_error("PREPARE 3");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE 3", "numCachedKids", 2);

$sth3->bind_param(1, 999, $attrib_int);
check_error("BIND_PARAM 31");
$sth3->execute();
check_error("EXECUTE 3");

$sth3->finish();
check_error("FINISH 3");

$stmt4 = "SELECT id, name, dept FROM staff WHERE id = ?";
$sth4 = $dbh->prepare_cached($stmt4);
check_error("PREPARE_CACHED 4");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE_CACHED 4", "numCachedKids", 2);
check_value("PREPARE_CACHED 4", "sth4", $sth2);

#
# In the future, execute() may return a warning message indicating that
# the cached statement handle being returned is still active due to the
# fact that finish() wasn't called for $sth2
#
$sth4->bind_param(1, 999, $attrib_int);
check_error("BIND_PARAM 41");
$sth4->execute();
check_error("EXECUTE 4");

$stmt1b = "INSERT INTO staff (id, name, dept) VALUES (?, ?, ?)";
$sth1b = $dbh->prepare_cached($stmt1);
check_error("PREPARE_CACHED 1b");
$numCachedKids = scalar(keys(%{$dbh->{CachedKids}}));
check_value("PREPARE_CACHED 1b", "numCachedKids", 2);
check_value("PREPARE_CACHED 1b", "sth1", $sth1b);

$sth2->finish();
check_error("FINISH 2");

$sth4->finish();
check_error("FINISH 4");

$dbh->disconnect();
check_error("DISCONNECT");
check_value("DISCONNECT", "dbh->{CachedKids}", undef);

fvt_end_testcase($testcase, $success);
