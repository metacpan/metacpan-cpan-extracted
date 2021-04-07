####################################################################
# TESTCASE: 		perld004_connInvalidPassword.pl
# DESCRIPTION: 		Invalid connection (invalid password)
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$release = &get_release();
$success = "y";
fvt_begin_testcase($tcname);

$PWD = "BADPASSWORD";
$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PWD", {PrintError => 0});
check_value("CONNECT", "dbh", undef);
if ($ENV{DDCS})
{
  check_value("CONNECT", "DBI::err", -30082);
  #$expMsg = "[IBM][CLI Driver] SQL30082N  Attempt to establish connection failed with security reason \"2\" (\"PASSWORD INVALID\").  SQLSTATE=08001\n";
  #check_value("CONNECT", "DBI::errstr", $expMsg);
  check_value("CONNECT", "DBI::state", "08001");
}
else
{
  if ( $release >= "8" )
  {
    check_value("CONNECT", "DBI::err", -30082);
    if ( $release >= "9" )
    {
        $expMsg = "[IBM][CLI Driver] SQL30082N  Security processing failed with reason \"24\" (\"USERNAME AND\/OR PASSWORD INVALID\").  SQLSTATE=08001\n";
    }
    else
    {
        $expMsg = "[IBM][CLI Driver] SQL30082N  Attempt to establish connection failed with security reason \"24\" (\"USERNAME AND\/OR PASSWORD INVALID\").  SQLSTATE=08001\n";
    }
    check_value("CONNECT", "DBI::errstr", $expMsg);
    check_value("CONNECT", "DBI::state", "08001");
  }
  else
  {
    check_value("CONNECT", "DBI::err", -1403);
    $expMsg = "[IBM][CLI Driver] SQL1403N  The username and/or password supplied is incorrect.  SQLSTATE=08004\n";
    check_value("CONNECT", "DBI::errstr", $expMsg);
    check_value("CONNECT", "DBI::state", "08004");
  }
}

fvt_end_testcase($testcase, $success);
