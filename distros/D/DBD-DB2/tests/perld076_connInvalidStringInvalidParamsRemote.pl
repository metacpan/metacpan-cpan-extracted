####################################################################
# TESTCASE: 		perld076_connInvalidStringInvalidParamsRemote.pl
# DESCRIPTION: 		Invalid string, invalid parameters
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;
use DBD::DB2::Constants;

require 'connection.pl';
require 'perldutl.pl';

$release = &get_release();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$fake_user; PWD=$fake_password";
$dbh = DBI->connect($string, $USERID, $PASSWORD, {PrintError => 0});
$expMsg = "[IBM][CLI Driver] SQL30082N  Security processing failed with reason \"24\" (\"USERNAME AND/OR PASSWORD INVALID\").  SQLSTATE=08001\n";
check_value("CONNECT", "DBI::err", "-30082");
check_value("CONNECT", "DBI::errstr", $expMsg);

fvt_end_testcase($testcase, $success);
