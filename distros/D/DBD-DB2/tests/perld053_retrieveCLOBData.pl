####################################################################
# TESTCASE: 		perld053_retrieveCLOBData.pl
# DESCRIPTION: 		Retrieve CLOB data
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

$dbh->{LongReadLen}=0;
$stmt = "SELECT resume FROM emp_resume WHERE empno = '000130' AND resume_format = 'ascii'" ;
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

# Do a fetch to get the clob locator variable loaded.
$sth->fetchrow();

# Read the contents of the clob pointed to by 1st field
# of the statement using an offset of 0,
# reading a chunk of 4096 bytes each time.
while ($buffer = $sth->blob_read(1, 100, 4096))
{
  $buff = "";
}

$sth->finish();
check_error("EXECUTE");

fvt_end_testcase($testcase, $success);
