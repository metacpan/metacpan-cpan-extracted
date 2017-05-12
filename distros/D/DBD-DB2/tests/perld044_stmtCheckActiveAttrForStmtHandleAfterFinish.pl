####################################################################
# TESTCASE: 		perld044_stmtCheckActiveAttrForStmtHandleAfterFinish.pl
# DESCRIPTION: 		Ensure that the Active attribute for the stmt
#                       handle is turned OFF after the call to finish().
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

$stmt = "SELECT empno, lastname FROM employee WHERE workdept = 'D11' order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->bind_columns(undef, \($empno, $lastname));

$sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "sth->{Active}", 1);

$ary_ref = $sth->fetch();
check_error("FETCH");
check_value("FETCH", "sth->{Active}", 1);

$sth->finish();
check_error("FINISH");
check_value("FINISH", "sth->{Active}", undef);

fvt_end_testcase($testcase, $success);
