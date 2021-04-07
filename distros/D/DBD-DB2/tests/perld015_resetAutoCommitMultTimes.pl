####################################################################
# TESTCASE: 		perld015_resetAutoCommitMultTimes.pl
# DESCRIPTION: 		Reset autocommit multiple times
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
  check_value("CONNECT", "dbh->{AutoCommit}", 1);

  # Delete the insert row above
  $stmt = "DELETE FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $sth->finish();
  check_error("FINISH");

  #
  # Verify that the DELETE statement is commited
  #
  $stmt = "SELECT * FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $success = check_results($sth, $testcase, "w" );

  $sth->finish();
  check_error("FINISH");

  #
  # Turn AutoCommit to OFF
  #
  $dbh->{AutoCommit} = 0;
  check_value("SETTING AutoCommit", "dbh->{AutoCommit}", undef);

  # Insert a row
  $stmt = "INSERT INTO staff (id) VALUES (400)";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $sth->finish();
  check_error("FINISH");

  $dbh->disconnect();
  check_error("DISCONNECT",
              "[IBM][CLI Driver] CLI0116E  Invalid transaction state. SQLSTATE=25000",
              "DBI::errstr");

  $dbh->commit();
  check_error("COMMIT");

  #
  # Verify that the INSERT statement is commited
  #
  $stmt = "SELECT * FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $success = check_results($sth, $testcase, "a" );

  $sth->finish();
  check_error("FINISH");

  #
  # Turn AutoCommit to ON
  #
  $dbh->{AutoCommit} = 1;
  check_value("SETTING AutoCommit", "dbh->{AutoCommit}", 1);

  # Delete the inserted row
  $stmt = "DELETE FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $sth->finish();
  check_error("FINISH");

  #
  # Verify that the DELETE statement is commited
  #
  $stmt = "SELECT * FROM staff WHERE id = 400";

  undef($sth);
  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $success = check_results($sth, $testcase, "a" );

  $sth->finish();
  check_error("FINISH");

  $dbh->disconnect();
  check_error("DISCONNECT");
}

fvt_end_testcase($testcase, $success);
