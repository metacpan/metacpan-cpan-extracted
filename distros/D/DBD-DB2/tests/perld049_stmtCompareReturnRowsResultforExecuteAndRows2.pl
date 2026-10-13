####################################################################
# TESTCASE: 		perld049_stmtCompareReturnRowsResultforExecuteAndRows2.pl
# DESCRIPTION: 		Verify that $sth->execute() returns -1 when the number
#                       of rows affected by a statement is unknown, and
#                       $sth->rows returns -1.
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
$stmt = "SELECT firstnme, lastname FROM employee WHERE job = 'DESIGNER'";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", -1);
check_value("EXECUTE", "sth->rows", -1);

$dbh->rollback();
check_error("ROLLBACK");

$sth->finish();
check_error("FINISH");

fvt_end_testcase($testcase, $success);
