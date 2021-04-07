####################################################################
# TESTCASE: 		perld008_connValid3ConnWithDiscon.pl
# DESCRIPTION: 		3 valid connections to the same db
#                       disconnecting each time
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

$dbh1 = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD);
check_error("CONNECT 1");
check_value("CONNECT 1", "dbh1->{Active}", 1);
check_value("CONNECT 1", "dbh1->{Name}", "$DATABASE");

$stmt = "SELECT * FROM org WHERE deptnumb = 10";
if ($DBI::err == 0)
{
  $sth1 = $dbh1->prepare($stmt);
  check_error("PREPARE 1");

  $sth1->execute();
  check_error("EXECUTE 1");

  $success = check_results($sth1, $testcase, "w");

  $sth1->finish();
  check_error("FINISH 1");

  $dbh1->disconnect();
  check_error("DISCONNECT 1");
  check_value("DISCONNECT 1", "dbh1->{Active}", undef);
}

$dbh2 = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD);
check_error("CONNECT 2");
check_value("CONNECT 2", "dbh2->{Active}", 1);
check_value("CONNECT 2", "dbh2->{Name}", "$DATABASE");

if ($DBI::err == 0)
{
  $sth2 = $dbh2->prepare($stmt);
  check_error("PREPARE 2");

  $sth2->execute();
  check_error("EXECUTE 2");

  $success = check_results($sth2, $testcase, "a");

  $sth2->finish();
  check_error("FINISH 2");

  $dbh2->disconnect();
  check_error("DISCONNECT 2");
  check_value("DISCONNECT 2", "dbh2->{Active}", undef);
}

$dbh3 = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD);
check_error("CONNECT 3");
check_value("CONNECT 3", "dbh3->{Active}", 1);
check_value("CONNECT 3", "dbh3->{Name}", "$DATABASE");

if ($DBI::err == 0)
{
  $sth3 = $dbh3->prepare($stmt);
  check_error("PREPARE 3");

  $sth3->execute();
  check_error("EXECUTE 3");

  $success = check_results($sth3, $testcase, "a");

  $sth3->finish();
  check_error("FINISH 3");

  $dbh3->disconnect();
  check_error("DISCONNECT 3");
  check_value("DISCONNECT 3", "dbh3->{Active}", undef);
}

fvt_end_testcase($testcase, $success);
