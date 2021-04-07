####################################################################
# TESTCASE: 		perld084_testDB2LoginTimeoutRemote.pl
# DESCRIPTION: 		Test db2_login_timeout on remotehost
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

%ops = (db2_login_timeout => 5,
        PrintError => 0);

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$remotehost; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD;";
$dbh = DBI->connect($string, $USERID, $PASSWORD, \%ops);
$expMsg = "[IBM][CLI Driver] SQL30081N  A communication error has been detected.  Communication protocol being used: \"TCP/IP\".  Communication API being used: \"SOCKETS\".  Location where the error was detected: \"129.42.58.212\".  Communication function detecting the error: \"selectForConnectTimeout\".  Protocol specific error code(s): \"*\", \"*\", \"*\".  SQLSTATE=08001\n";
check_value("CONNECT", "DBI::err", -30081);

fvt_end_testcase($testcase, $success);
