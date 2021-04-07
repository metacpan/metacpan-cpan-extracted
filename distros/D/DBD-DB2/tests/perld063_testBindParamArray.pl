####################################################################
# TESTCASE: 		perld063_testBindParamArray.pl
# DESCRIPTION: 		Test bind_param_array
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

$dbh->do("DROP TABLE ARRAYTEST");

$dbh->do("CREATE TABLE ARRAYTEST (ID INTEGER, VALUE CHAR)");
check_error("DO");

$stmt = "INSERT INTO ARRAYTEST VALUES (?,?)";
$sth = $dbh->prepare($stmt);
check_error("PREPARE");
$sth->bind_param_array(1,[1,2]);
check_error("BIND PARAM ARRAY");
$sth->bind_param_array(2,['a','b']);
check_error("BIND PARAM ARRAY");
$sth->execute_array({ArrayTupleStatus => \my @tuple_status});
check_error("EXECUTE ARRAY");

fvt_end_testcase($testcase, $success);
