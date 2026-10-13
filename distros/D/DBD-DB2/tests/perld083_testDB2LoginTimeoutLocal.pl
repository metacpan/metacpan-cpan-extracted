####################################################################
# TESTCASE: 		perld083_testDB2LoginTimeoutLocal.pl
# DESCRIPTION: 		Test db2_login_timeout on localhost
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

%ops = (db2_login_timeout => 2,
        PrintError => 0);

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD;";
$dbh = DBI->connect($string, $USERID, $PASSWORD, \%ops);
check_error("CONNECT");

fvt_end_testcase($testcase, $success);
