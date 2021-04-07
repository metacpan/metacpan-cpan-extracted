####################################################################
# TESTCASE: 		perld034_stmtReuseStmtHandle.pl
# DESCRIPTION: 		Verify reuse of statement handle.
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

# c4 is the SMALLINT column
$stmt = "SELECT c4 FROM perld1t2 WHERE c4 = ? or c4 = ? order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$rv = $sth->execute(1999, 3999);
check_error("EXECUTE");

$success = check_results($sth, $testcase);

$sth->finish();
check_error("FINISH");

$rv = $sth->execute(2999, 4999);
check_error("EXECUTE");

$success = check_results($sth, $testcase, "a");

$sth->finish();
check_error("FINISH");

fvt_end_testcase($testcase, $success);
