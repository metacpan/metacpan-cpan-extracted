####################################################################
# TESTCASE: 		perld071_connIncorrectPortRemote.pl
# DESCRIPTION: 		Incorrect port in conn. string
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;
use Socket;

require 'connection.pl';
require 'perldutl.pl';

$release = &get_release();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$fakeport; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD;";
$dbh = DBI->connect($string, $userid, $password, {PrintError => 0});

$hostaddr = gethostbyname($HOSTNAME);
$ipaddr = inet_ntoa($hostaddr);

check_value("CONNECT", "DBI::err", -30081);
$expMsg = "[IBM][CLI Driver] SQL30081N  A communication error has been detected.  Communication protocol being used: \"TCP/IP\".  Communication API being used: \"SOCKETS\".  Location where the error was detected: \"$ipaddr\".  Communication function detecting the error: \"connect\".  Protocol specific error code(s): \"111\", \"*\", \"*\".  SQLSTATE=08001\n";

check_value("CONNECT", "DBI::errstr", $expMsg);
check_value("CONNECT", "DBI::state", "08001");

fvt_end_testcase($testcase, $success);
