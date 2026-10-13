####################################################################
# TESTCASE: 		perld065_testBindParamArray2.pl
# DESCRIPTION: 		Test bind_param_array differently
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

$stmt = "INSERT INTO ARRAYTEST VALUES (?,?)";
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->bind_param_array(1, [5, 6, 7]);
$sth->bind_param_array(2, "e");
$sth->execute_array({ArrayTupleStatus => \my @tuple_status});
check_error("EXECUTE ARRAY");

$stmt = "SELECT * FROM ARRAYTEST";
$sth = $dbh->prepare($stmt);
$sth->execute();

fvt_end_testcase($testcase, $success);
