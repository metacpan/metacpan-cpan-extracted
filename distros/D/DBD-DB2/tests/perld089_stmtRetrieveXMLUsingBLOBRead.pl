####################################################################
# TESTCASE: 		perld089_stmtRetrieveXMLUsingBLOBRead.pl
# DESCRIPTION: 		Retrieve XML data using blob_read
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;
use DBD::DB2::Constants;

require 'connection.pl';
require 'perldutl.pl';

init();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$dbh->{LongReadLen}=0;
$stmt = "SELECT C1 FROM xmltest";
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

for($i=0; $i<$row;$i++){
# Do a fetch to get the XML locator variable loaded.
  $sth->fetchrow();

# Read the contents of the XML pointed to by 1st field
# of the statement using an offset of 0,
# reading a chunk of 4096 bytes each time.
  $buff = "";
  while ($buffer = $sth->blob_read(1, 100, 4096))
  {
    $rowValue = $i+1;
    $expMsg = "$xml954<A$rowValue>A3E$rowValue</A$rowValue></value>";
    $buff = $buff.$buffer;
  }
  check_value("FETCHROW $i", "buff", $expMsg);
}

$sth->finish();
check_error("FINISH");

fvt_end_testcase($testcase, $success);

#
# init() initializes some global arrays and hashes
# for values in some tables
#
sub init
{
  get_attributes();

  #
  # Double-byte alphanumeric strings in codepage 954 (one trailing
  # space included)
  #
  $xml954 = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><value><graphic954>graphic954</graphic954><vargraphic954>vargraphic954</vargraphic954><longvargraphic954>longvargraphic954</longvargraphic954>";

}
