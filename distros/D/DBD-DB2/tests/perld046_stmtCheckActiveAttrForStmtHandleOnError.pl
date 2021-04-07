####################################################################
# TESTCASE: 		perld046_stmtCheckActiveAttrForStmtHandleOnError.pl
# DESCRIPTION: 	         Ensure that the Active attribute for the statement
#                        handle is turned OFF when an error occurs at fetch time
#                        (that is, the database driver automatically calls
#                        finish when the error during fetching occurs).
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

$dbh->{AutoCommit} = 0;
$stmt = "INSERT INTO staff (id) VALUES (999)";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "sth->{Active}", 1);

@row_ary = $sth->fetchrow();
check_error("FETCHROW",
            "[IBM][CLI Driver] CLI0115E  Invalid cursor state. SQLSTATE=24000",
            "DBI::errstr");
check_value("FETCHROW", "row_ary", undef);
check_value("FETCHROW", "sth->{Active}", undef);

$sth->finish();
check_error("FINISH");
check_value("FINISH", "sth->{Active}", undef);

$dbh->rollback();
check_error("ROLLBACK");

fvt_end_testcase($testcase, $success);
