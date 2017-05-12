####################################################################
# TESTCASE: 		perld026_stmtNumParamsNumFieldsWithParamMarkers.pl
# DESCRIPTION: 		Validate NUM_OF_PARAMS, NUM_OF_FIELDS attributes
#                       for SELECT statement with parameter markers.
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

$release = &get_release();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$stmt = "SELECT id, name, dept, job FROM staff WHERE dept = ? and job = ?";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");
check_value("PREPARE", "sth->{NUM_OF_PARAMS}", 2);
check_value("PREPARE", "sth->{NUM_OF_FIELDS}", 4);
check_value("PREPARE", "sth->{NULLABLE}->[0]", undef);
check_value("PREPARE", "sth->{NULLABLE}->[1]", 1);
check_value("PREPARE", "sth->{NULLABLE}->[2]", 1);
check_value("PREPARE", "sth->{NULLABLE}->[3]", 1);
if ( $release >= "8" )
{
  check_value("PREPARE", "sth->{CursorName}", "SQL_CURSH200C4");
}
else
{
  check_value("PREPARE", "sth->{CursorName}", "SQLLF0005");
}
check_value("PREPARE", "sth->{Statement}", $stmt);

fvt_end_testcase($testcase, $success);
