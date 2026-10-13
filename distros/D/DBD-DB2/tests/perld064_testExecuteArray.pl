####################################################################
# TESTCASE: 		perld064_testExecuteArray.pl
# DESCRIPTION: 		Test execute_array
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

@temp_ids = (3, 4);
@temp_values = ('c', 'd');

$stmt = "INSERT INTO ARRAYTEST VALUES (?,?)";
$sth = $dbh->prepare($stmt);
check_error("PREPARE");
$sth->execute_array({ArrayTupleStatus => \my @tuple_status}, \@temp_ids, \@temp_values);
check_error("EXECUTE ARRAY");

fvt_end_testcase($testcase, $success);
