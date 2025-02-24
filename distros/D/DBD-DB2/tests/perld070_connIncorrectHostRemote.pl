####################################################################
# TESTCASE: 		perld070_connIncorrectHostRemote.pl
# DESCRIPTION: 		Incorrect hostname in conn. string
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

$release = &get_release();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$fakehost; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD;";
$dbh = DBI->connect($string, $userid, $password, {PrintError => 0});

check_value("CONNECT", "DBI::err", -1336);
$expMsg = "[IBM][CLI Driver] SQL1336N  The remote host \"$fakehost\" was not found.  SQLSTATE=08001\n";

check_value("CONNECT", "DBI::errstr", $expMsg);
check_value("CONNECT", "DBI::state", "08001");

fvt_end_testcase($testcase, $success);
