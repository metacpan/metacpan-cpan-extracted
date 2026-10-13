####################################################################
# TESTCASE: 		perld048_stmtCompareReturnRowsResultforExecuteAndRows1.pl
# DESCRIPTION: 		Verify that $sth->execute() returns 0E0 when no rows
#                       are affected for a non-select statement, and $sth->rows
#                       returns 0.
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
$stmt = "DELETE FROM employee WHERE workdept = 'Z99'";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", "0E0");
check_value("EXECUTE", "sth->rows", 0);

$dbh->rollback();
check_error("ROLLBACK");

$sth->finish();
check_error("FINISH");

fvt_end_testcase($testcase, $success);
