####################################################################
# TESTCASE: 		perld082_connWithDefaultSchema.pl
# DESCRIPTION: 		Connect with default schema
# EXPECTED RESULT: 	Failure
####################################################################

use DBI;
use DBD::DB2;
use DBD::DB2::Constants;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD, {PrintError => 0} );
check_error("CONNECT");

if ($DBI::err == 0)
{

  $os = $dbh->get_info(SQL_DBMS_NAME);
  $temp_user = uc $USERID;

  $stmt = "SELECT * FROM MAGICTEST";
  $sth = $dbh->prepare($stmt);
  $expMsg = "[IBM][CLI Driver][$os] SQL0204N  \"$temp_user.MAGICTEST\" is an undefined name.  SQLSTATE=42704\n";
  check_value("PREPARE", "DBI::err", -204);
  check_value("PREPARE", "DBI::errstr", $expMsg);
  $sth->execute();
  check_value("EXECUTE", "DBI::errstr", $expMsg);

}

fvt_end_testcase($testcase, $success);
