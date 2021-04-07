####################################################################
# TESTCASE: 		perld042_stmtTryFetchWithoutExecute.pl
# DESCRIPTION: 		Try to do a fetch without issuing an execute call first.
# EXPECTED RESULT: 	Failure
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

$stmt = "SELECT empno, lastname FROM employee WHERE workdept = 'C01'";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->bind_columns(undef, \($empno, $lastname));

$ary_ref = $sth->fetch();
check_value("FETCH", "arg_ref", undef);

$sth->finish();
check_error("FINISH");

fvt_end_testcase($testcase, $success);
