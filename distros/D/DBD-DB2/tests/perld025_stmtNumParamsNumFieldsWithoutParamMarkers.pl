####################################################################
# TESTCASE: 		perld025_stmtNumParamsNumFieldsWithoutParamMarkers.pl
# DESCRIPTION: 		Validate NUM_OF_PARAMS, NUM_OF_FIELDS attributes
#                       for SELECT statement with no parameter markers.
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

$stmt = "SELECT id, name FROM staff WHERE dept = 15";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");
check_value("PREPARE", "sth->{NUM_OF_PARAMS}", 0);
check_value("PREPARE", "sth->{NUM_OF_FIELDS}", 2);

fvt_end_testcase($testcase, $success);
