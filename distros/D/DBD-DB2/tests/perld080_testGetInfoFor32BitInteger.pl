####################################################################
# TESTCASE: 		perld080_testGetInfoFor32BitInteger.pl
# DESCRIPTION: 		Test get_info for a 32-bit integer
# EXPECTED RESULT: 	Success
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

if ($DBI::err == 0)
{

  $arr = $dbh->get_info(SQL_DROP_TABLE);
  check_error("GET INFO");
  check_value("GET INFO", "arr", 1, TRUE, FALSE);

}

fvt_end_testcase($testcase, $success);
