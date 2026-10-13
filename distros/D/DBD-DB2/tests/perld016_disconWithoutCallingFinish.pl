####################################################################
# TESTCASE: 		perld016_disconWithoutCallingFinish.pl
# DESCRIPTION: 		Test $dbh->disconnect() without calling 
#                       finish
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

if ($DBI::err == 0)
{
  $stmt = "INSERT INTO staff (id) VALUES (400)";

  $sth1 = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth1->execute();
  check_error("EXECUTE");

  $stmt = "INSERT INTO staff (id) VALUES (401)";

  $sth2 = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth2->execute();
  check_error("EXECUTE");

  $tmpfile = "$tcname.out";
  fvt_redirect_output($tmpfile);

  $dbh->disconnect();
  check_error("DISCONNECT");

  fvt_restore_output();

  $errmsg = get_msg($tmpfile);
  rm("$tmpfile");

  # message changed in 0.75b
  if( lc( $DBD::DB2::VERSION ) ge "0.75b" )
  {
    $expMsg = "invalidates 2 active statement handles " .
              "(either destroy statement handles or " .
              "call finish on them before disconnecting)";
  }
  else
  {
    $expMsg = "invalidates 2 active statements. " .
              "Either destroy statement handles or call " .
              "finish on them before disconnecting.";
  }
  check_value("DISCONNECT", "errmsg", $expMsg, FALSE);
}

fvt_end_testcase($testcase, $success);
