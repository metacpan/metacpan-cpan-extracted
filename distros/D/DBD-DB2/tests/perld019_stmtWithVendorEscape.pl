####################################################################
# TESTCASE: 		perld019_stmtWithVendorEscape.pl
# DESCRIPTION: 		Test $dbh->do
#                       Ensure that a stmt with vendor escape is
#                       successful.
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

$stmt = "SELECT empno, lastname, birthdate FROM employee WHERE birthdate = {d'1956-12-18'}";

$rv = $dbh->do($stmt);
check_error("DO");
# rv returns -1 because no rows are really affected in the table
check_value("DO", "rv", -1);

fvt_end_testcase($testcase, $success);
