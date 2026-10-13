####################################################################
# TESTCASE: 		perld017_disconWithAutocomOFFRollback.pl
# DESCRIPTION: 	        Exit the application without disconnect() after INSERT
#                       with AutoCommit OFF.
#                       Note: perld017.pl will verify that the transaction is
#                       rolled back
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {AutoCommit => 0});
check_error("CONNECT");
check_value("CONNECT", "dbh->{AutoCommit}", undef);

if ($DBI::err == 0)
{
  $stmt = "INSERT INTO staff (id) VALUES (402)";

  $sth = $dbh->prepare($stmt);
  check_error("PREPARE");

  $sth->execute();
  check_error("EXECUTE");

  $sth->finish();
  check_error("FINISH");
}

fvt_end_testcase($testcase, $success);
