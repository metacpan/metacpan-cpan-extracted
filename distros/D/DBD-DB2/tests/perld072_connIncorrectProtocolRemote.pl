####################################################################
# TESTCASE: 		perld072_connIncorrectProtocolRemote.pl
# DESCRIPTION: 		Incorrect protocol in conn. string
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

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$fake_protocol; UID=$USERID; PWD=$PASSWORD;";
$dbh = DBI->connect($string, $userid, $password, {PrintError => 0});

check_value("CONNECT", "DBI::err", -1013);
$expMsg = "[IBM][CLI Driver] SQL1013N  The database alias name or database name \" \" could not be found.  SQLSTATE=42705\n";

check_value("CONNECT", "DBI::errstr", $expMsg);
check_value("CONNECT", "DBI::state", "08001");

fvt_end_testcase($testcase, $success);
