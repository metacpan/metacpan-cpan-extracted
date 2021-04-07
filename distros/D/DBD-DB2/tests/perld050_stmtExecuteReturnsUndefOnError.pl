####################################################################
# TESTCASE: 		perld050_stmtExecuteReturnsUndefOnError.pl
# DESCRIPTION: 		Verify that $sth->execute() returns undef on error.
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

$stmt = "SELEC empno FROM staff";

$rv = $dbh->do($stmt);
# Don't know what's going on here, in December 2000, MVS was returning -199,
# now MVS v5 and v6 consistently return -104, even with old build levels of
# DB2 Connect.  Unexplainable.
#if( $ENV{ DDCS } )
#{
#  check_error("DO", -199);
#}
#else
{
  check_error("DO", -104);
}
check_value("DO", "rv", undef);

# We need to rollback back this transaction otherwise the disconnect would
# result in an invalid transaction state error.
$dbh->rollback();
check_error("ROLLBACK");

fvt_end_testcase($testcase, $success);
