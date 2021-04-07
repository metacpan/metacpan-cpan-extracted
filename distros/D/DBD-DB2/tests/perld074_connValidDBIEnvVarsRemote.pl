####################################################################
# TESTCASE: 		perld074_connValidDBIEnvVarsRemote.pl
# DESCRIPTION: 		Valid connection with env. var. DBI_USER and 
#                       DBI_PASS
# EXPECTED RESULT: 	Success
#                       Verify that DBI_USER has been used by comparing
#                       get_info(SQL_USER_NAME) with $userid
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

$ENV{DBI_USER} = $USERID;
$ENV{DBI_PASS} = $PASSWORD;

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL;";
$dbh = DBI->connect($string, undef, undef, {PrintError => 0});
check_error("CONNECT");

$check_user = $dbh->get_info(SQL_USER_NAME);
check_value("CONNECT", "check_user", $USERID);

$ENV{DBI_USER} = "";
$ENV{DBI_PASS} = "";

$dbh->disconnect();
check_error("DISCONNECT");

fvt_end_testcase($testcase, $success);
