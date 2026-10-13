####################################################################
# TESTCASE: 		perld027_stmtNumParamsNumFieldsOnNonSelectWithParamMarkers.pl
# DESCRIPTION: 		Validate NUM_OF_PARAMS, NUM_OF_FIELDS attributes
#                       for non-SELECT statement with parameter markers.
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

$stmt = "INSERT INTO staff (id, name, dept) values (?, ?, 99)";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");
check_value("PREPARE", "sth->{NUM_OF_PARAMS}", 2);
#check_value("PREPARE", "sth->{NUM_OF_FIELDS}", 0);

fvt_end_testcase($testcase, $success);
