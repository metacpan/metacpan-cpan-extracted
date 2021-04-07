####################################################################
# TESTCASE: 		perld039_stmtInsertPrepareExecuteGraphicDataTypes.pl
# DESCRIPTION: 		Prepare and execute an INSERT statement to populate
#                       table perld3t1.
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
$stmt = get_insert_stmt("perld3t1", $row, FALSE);

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

$sth->finish();
check_error("FINISH");

#
# First INSERT statement with parameter markers for the values
#
$stmt = get_insert_stmt("perld3t1", undef, TRUE);

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$perld3t1};
#
# Use bind_param($param_num, $bind_value) and execute()
#
for ($row = 1; $row < 5; $row++)
{
  @bind_values = get_values("perld3t1", $row);
  for ($i = 0; $i < @bind_values; $i++)
  {
    $sth->bind_param($i+1, "$bind_values[$i]", $attribute{$column[$i]});
    print $attribute{$column[$i]};
    check_error("Row = $row, BIND_PARAM $i");
  }
  $sth->execute();
  check_error("Row = $row, EXECUTE");
}

#
# Use execute(@bind_values)
#
for ($row = 5; $row < 9; $row++)
{
  @bind_values = get_values("perld3t1", $row);

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
  $graphic954 = "\xA3\xE7\xA3\xF2\xA3\xE1\xA3\xF0\xA3\xE8\xA3\xE9\xA3\xE3\xA1\xA1";
  $vargraphic954 = "\xA3\xF6\xA3\xE1\xA3\xF2$graphic954";
  $longvargraphic954 = "\xA3\xEC\xA3\xEF\xA3\xEE\xA3\xE7$vargraphic954";

  #
  # Define column types for various tables
  #
  $perld3t1 = ['SMALLINT NOT NULL',
               'GRAPHIC(127)',
               'VARGRAPHIC(127)',
               'LONG VARGRAPHIC'];

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
    'GRAPHIC(127)'      => ['graphic a',
                            "$graphic954\xA3\xE2",
                            "$graphic954\xA3\xE3",
                            "$graphic954\xA3\xE4",
                            "$graphic954\xA3\xE5",
                            "$graphic954\xA3\xE6",
                            "$graphic954\xA3\xE7",
                            "$graphic954\xA3\xE8",
                            "$graphic954\xA3\xE9"],
    'VARGRAPHIC(127)'   => ['vargraphic a',
                            "$vargraphic954\xA3\xE2",
                            "$vargraphic954\xA3\xE3",
                            "$vargraphic954\xA3\xE4",
                            "$vargraphic954\xA3\xE5",
                            "$vargraphic954\xA3\xE6",
                            "$vargraphic954\xA3\xE7",
                            "$vargraphic954\xA3\xE8",
                            "$vargraphic954\xA3\xE9"],
    'LONG VARGRAPHIC'   => ['longvargraphic a',
                            "$longvargraphic954\xA3\xE2",
                            "$longvargraphic954\xA3\xE3",
                            "$longvargraphic954\xA3\xE4",
                            "$longvargraphic954\xA3\xE5",
                            "$longvargraphic954\xA3\xE6",
                            "$longvargraphic954\xA3\xE7",
                            "$longvargraphic954\xA3\xE8",
                            "$longvargraphic954\xA3\xE9"]
  );

}
