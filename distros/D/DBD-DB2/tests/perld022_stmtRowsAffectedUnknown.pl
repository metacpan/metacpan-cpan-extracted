####################################################################
# TESTCASE: 		perld022_stmtRowsAffectedUnknown.pl
# DESCRIPTION: 		Test $dbh->do
#                       Verify that $dbh->do() returns -1 for a stmt
#                       for which the no. of rows affected is unknown.
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
$stmt = "CREATE TABLE perl_do (c1 smallint)";

$rv = $dbh->do($stmt);
check_error("DO");
check_value("DO", "rv", -1);

$dbh->rollback();
check_error("ROLLBACK");

fvt_end_testcase($testcase, $success);
