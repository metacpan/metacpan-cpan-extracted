####################################################################
# TESTCASE: 		perld021_stmtUpdateReturnRowsAffected.pl
# DESCRIPTION: 		Test $dbh->do
#                       Verify that a non-query statement returns
#                       the number of rows affected
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
$stmt = "UPDATE staff SET dept = 83 WHERE dept = 38";

$rv = $dbh->do($stmt);
check_error("DO");
check_value("DO", "rv", 5);

$dbh->rollback();
check_error("ROLLBACK");

fvt_end_testcase($testcase, $success);
