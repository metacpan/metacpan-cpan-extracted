####################################################################
# TESTCASE: 		perld023_stmtReturnsUndefOnError.pl
# DESCRIPTION: 		Test $dbh->do
#                       Verify that $dbh->do() returns undef on error.
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
$stmt = "DROP TABLE perl_od"; # an invalid table name

$rv = $dbh->do($stmt);
check_error("DO", -204);
check_value("DO", "rv", undef);

fvt_end_testcase($testcase, $success);
