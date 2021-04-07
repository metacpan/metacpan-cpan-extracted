####################################################################
# TESTCASE: 		perld043_stmtTryFetchForNonSelect.pl
# DESCRIPTION: 		Try to do a fetch for a NON-SELECT statement.
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

$dbh->{AutoCommit} = 0;
$stmt = "INSERT INTO staff (id) VALUES (999)";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

@row_ary = $sth->fetchrow();
check_error("FETCHROW",
            "[IBM][CLI Driver] CLI0115E  Invalid cursor state. SQLSTATE=24000",
            "DBI::errstr");
check_value("FETCHROW", "row_ary", undef);

$sth->finish();
check_error("FINISH");

$dbh->rollback();
check_error("ROLLBACK");

fvt_end_testcase($testcase, $success);
