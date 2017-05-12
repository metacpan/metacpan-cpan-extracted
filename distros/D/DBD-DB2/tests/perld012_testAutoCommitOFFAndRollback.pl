####################################################################
# TESTCASE: 		perld012_testAutoCommitOFFAndRollback.pl
# DESCRIPTION: 		Test autocommit off and then Rollback
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {AutoCommit => 0, PrintError => 0});
check_error("CONNECT");

if ($DBI::err == 0)
{
  $stmt = "UPDATE staff SET job = 'Mgr' where id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $sth->finish();
  check_error("FINISH");

  $dbh->rollback();
  check_error("ROLLBACK");

  $dbh->disconnect();
  check_error("DISCONNECT");

  #
  # Verify that the UPDATE statement is rolled back
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
