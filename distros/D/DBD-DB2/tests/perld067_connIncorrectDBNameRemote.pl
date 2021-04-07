####################################################################
# TESTCASE: 		perld067_connIncorrectDBNameRemote.pl
# DESCRIPTION: 		Incorrect database in conn. string
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

$string = "dbi:DB2:DATABASE=$fakedb; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD;";
$dbh = DBI->connect($string, $userid, $password, {PrintError => 0});
check_value("CONNECT", "dbh", undef);
check_value("CONNECT", "DBI::err", -30061);
$expMsg = "[IBM][CLI Driver] SQL30061N  The database alias or database name \"BADDB             \" was not found at the remote node.  SQLSTATE=08004\n";
check_value("CONNECT", "DBI::errstr", $expMsg);
check_value("CONNECT", "DBI::state", "08004");

fvt_end_testcase($testcase, $success);
