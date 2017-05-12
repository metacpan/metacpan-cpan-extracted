####################################################################
# TESTCASE: 		perld006_connValidDBIEnvVarsEmptyUserIDPassword.pl
# DESCRIPTION: 		Valid connection with env. var. DBI_USER and
#                       DBI_PASS and empty $USERID, $PASSWORD
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

$ENV{DBI_USER} = $USERID;
$ENV{DBI_PASS} = $PASSWORD;
$u = $p = "";
if( $ENV{CLIENT_SERVER} )
{
  # Default userid not allowed for remote host connections
  $u = $userid;
  $p = $password;
}

$dbh = DBI->connect("dbi:DB2:$DATABASE", undef, undef, {PrintError => 0});
check_error("CONNECT");
if ($DBI::err == 0)
{
  $stmt = "SELECT * FROM org WHERE deptnumb = 10";
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");
  $sth->execute();
  check_error("EXECUTE");
  $success = check_results($sth, $testcase, "w");
}

$sth->finish;
check_error("FINISH");

$dbh->disconnect;
check_error("DISCONNECT");

$ENV{DBI_USER} = "";
$ENV{DBI_PASS} = "";

fvt_end_testcase($testcase, $success);
