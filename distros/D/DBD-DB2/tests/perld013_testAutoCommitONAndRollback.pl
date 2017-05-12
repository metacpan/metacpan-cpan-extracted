####################################################################
# TESTCASE: 		perld013_testAutoCommitONAndRollback.pl
# DESCRIPTION: 		Test autocommit on and then Rollback
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {AutoCommit => 1});
check_error("CONNECT");

if ($DBI::err == 0)
{
  $stmt = "DELETE FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $sth->finish();
  check_error("FINISH");

  $tmpfile = "$tcname.out";
  fvt_redirect_output("$tmpfile");
  $dbh->rollback();
  check_error("ROLLBACK");
  fvt_restore_output();
  $errmsg = get_msg($tmpfile);
  rm($tmpfile);
  $expMsg = "rollback ineffective with AutoCommit enabled";
  check_value("ROLLBACK", "errmsg", $expMsg, FALSE);

  $dbh->disconnect();
  check_error("DISCONNECT");

  #
  # Verify that the UPDATE statement is auto-commited
  #
  $dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD);
  check_error("CONNECT");

  $stmt = "SELECT * FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $success = check_results($sth, $testcase);

  $sth->finish();
  check_error("FINISH");

  $dbh->disconnect();
  check_error("DISCONNECT");
}

fvt_end_testcase($testcase, $success);
