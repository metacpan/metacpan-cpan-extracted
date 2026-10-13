####################################################################
# TESTCASE: 		perld024_stmtWithParamMarkers.pl
# DESCRIPTION: 		Test $dbh->do
#                       Use $dbh->do() to execute a statement that has
#                       parameter markers
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

$dbh->{AutoCommit} = 0;
$stmt = "UPDATE staff SET dept = ?, job = ? WHERE id = ?";

$rv = $dbh->do($stmt, undef, 51, 'Mgr', 320);
check_error("DO");
check_value("DO", "rv", 1);

$dbh->rollback();
check_error("ROLLBACK");

fvt_end_testcase($testcase, $success);
