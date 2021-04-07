####################################################################
# TESTCASE: 		perld086_stmtInsertXMLColumn.pl
# DESCRIPTION: 		Prepare and execute an INSERT statement to populate
#                       an XML table (xmltest).
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

init();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");
$row = 0;

#
# INSERT statement with no parameter markers
#
$stmt = get_insert_stmt("xmltest", $row, FALSE);

$sth = $dbh->prepare($stmt);
check_error("Row = 1 PREPARE");

$sth->execute();
check_error("Row = 1 EXECUTE");

$sth->finish();
check_error("FINISH");

#
# First INSERT statement with parameter markers for the values
#
$stmt = get_insert_stmt("xmltest", undef, TRUE);

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$xmltest};
#
# Use bind_param($param_num, $bind_value) and execute()
#
for ($row = 1; $row < 4; $row++)
{
  @bind_values = get_values("xmltest", $row);
  for ($i = 0; $i < @bind_values; $i++)
  {
    $sth->bind_param($i+1, "$bind_values[$i]", $attribute{$column[$i]});
    check_error("Row = $row, BIND_PARAM $i");
  }
  $sth->execute();
  check_error("Row = $row, EXECUTE");
}

#
# Use execute(@bind_values)
#
for ($row = 4; $row < 9; $row++)
{
  @bind_values = get_values("xmltest", $row);
  $sth->execute(@bind_values);
  check_error("Row = $row, EXECUTE");
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

  #
  # Define column types for various tables
  #
  $xmltest = ['SMALLINT NOT NULL',
               'XML'];

  #
  # Define column values according to the column types.  The hex strings
  # represent the double-byte alphanumeric equivalent of 'graphic b',...,
  # 'graphic c',..., 'vargraphic b', 'vargraphic c',..., 'longvargraphic b',
  # 'longvargraphic c',... in codepage 954.
  # Note: There is no need to encode the characters for
  #       the first value of graphic data, as we are
  #       using n'data' in the INSERT statement. n'' also
  #       happens to map lower case characters in en_US to
  #       double-byte upper case correspondents in ja_JP.
  #
  %real_value = (
    'SMALLINT NOT NULL' => [1, 2, 3, 4, 5, 6, 7, 8, 9],
    'XML'               => ["$xml954<A1>A3E1</A1></value>",
                            "$xml954<A2>A3E2</A2></value>",
                            "$xml954<A3>A3E3</A3></value>",
                            "$xml954<A4>A3E4</A4></value>",
                            "$xml954<A5>A3E5</A5></value>",
                            "$xml954<A6>A3E6</A6></value>",
                            "$xml954<A7>A3E7</A7></value>",
                            "$xml954<A8>A3E8</A8></value>",
                            "$xml954<A9>A3E9</A9></value>"]

  );

}
