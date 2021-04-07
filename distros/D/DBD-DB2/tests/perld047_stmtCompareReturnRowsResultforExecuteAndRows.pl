####################################################################
# TESTCASE: 		perld047_stmtCompareReturnRowsResultforExecuteAndRows.pl
# DESCRIPTION: 		Verify that $sth->execute() returns the number of rows
#                       affected for a non-select statement, and $sth->rows
#                       returns the same value.
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
$stmt = "DELETE FROM employee WHERE workdept = 'D11'";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", 9);
check_value("EXECUTE", "sth->rows", 9);

$dbh->rollback();
check_error("ROLLBACK");

$sth->finish();
check_error("FINISH");

fvt_end_testcase($testcase, $success);
