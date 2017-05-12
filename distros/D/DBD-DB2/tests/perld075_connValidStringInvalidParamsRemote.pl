####################################################################
# TESTCASE: 		perld075_connValidStringInvalidParamsRemote.pl
# DESCRIPTION: 		Valid string, invalid parameters
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

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD";
$dbh = DBI->connect($string, $fake_user, $fake_password, {PrintError => 0});
check_error("CONNECT");

$dbh->disconnect();
check_error("DISCONNECT");

fvt_end_testcase($testcase, $success);
