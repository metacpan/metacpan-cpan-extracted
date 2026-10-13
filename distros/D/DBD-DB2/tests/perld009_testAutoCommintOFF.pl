####################################################################
# TESTCASE: 		perld009_testAutoCommintOFF.pl
# DESCRIPTION: 		Test autocommit off
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
  check_value("CONNECT", "dbh->{AutoCommit}", undef);
  check_value("CONNECT", "dbh->{Active}", 1);

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
  check_value("DISCONNECT", "dbh->{Active}", 1);

  $dbh->rollback();
  check_error("ROLLBACK");

  $dbh->disconnect();
  check_error("DISCONNECT");
  check_value("DISCONNECT", "dbh->{Active}", undef);

  #
  # Verify that the INSERT statement is rolled back,
  # therefore, the DELETE statement should fail
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
