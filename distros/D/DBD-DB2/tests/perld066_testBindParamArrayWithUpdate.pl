####################################################################
# TESTCASE: 		perld066_testBindParamArrayWithUpdate.pl
# DESCRIPTION: 		Test bind_param_array with UPDATE
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

@ids = (1, 2, 3, 4, 5, 6, 7);
@values = ('a', 'b', 'c', 'd', 'e', 'f', 'g');

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$stmt = "UPDATE ARRAYTEST SET VALUE=? WHERE ID=?";
$sth = $dbh->prepare($stmt);
check_error("PREPARE");
$sth->bind_param_array(1,['f', 'g']);
check_error("BIND PARAM ARRAY");
$sth->bind_param_array(2,[6, 7]);
check_error("BIND PARAM ARRAY");
$sth->execute_array({ArrayTupleStatus => \my @tuple_status});
check_error("EXECUTE ARRAY");

$stmt = "SELECT * FROM ARRAYTEST";
$sth = $dbh->prepare($stmt);
$sth->execute();

$counter = 0;
while(@row = $sth->fetchrow){
    $temp_id = $row[0];
    $temp_value = $row[1];
    check_error("FETCHROW");
    check_value("FETCHROW", "temp_id", $ids[$counter], , TRUE);
    check_value("FETCHROW", "temp_value", $values[$counter]);
    $counter++;
}

fvt_end_testcase($testcase, $success);
