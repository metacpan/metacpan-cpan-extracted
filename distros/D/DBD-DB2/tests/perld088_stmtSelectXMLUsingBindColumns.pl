####################################################################
# TESTCASE: 		perld088_stmtSelectXMLUsingBindColumns.pl
# DESCRIPTION: 		Prepare and execute a SELECT statement against
#                       table xmltest using bind_columns() to bind
#                       perl variables to the result columns.
#                       The column types are as follows:
#                         smallint
#                         XML
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

$stmt = "SELECT * FROM xmltest order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$xmltest};
for($i = 0; $i < @column-1; $i++)
{
  check_value("PREPARE", "sth->{TYPE}->[$i]", $type{$xmltest->[$i]});
  check_value("PREPARE", "sth->{PRECISION}->[$i]", $precision{$xmltest->[$i]});
  check_value("PREPARE", "sth->{SCALE}->[$i]", $scale{$xmltest->[$i]});
}

$sth->bind_columns(undef, \($smallint2, $xml2));
check_error("BIND_COLUMNS");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", -1);

for($i=1; $i<4; $i++)
{
  @row_ary = $sth->fetchrow_array();
  #check_error("FETCHROW_ARRAY $i");
  check_value("FETCHROW_ARRAY $i", "smallint2", $i);
  check_value("FETCHROW_ARRAY $i", "xml2", $real_value{XML}[$i-1], FALSE);
}

while (@row_arg = $sth->fetchrow())
{
  #check_error("FETCHROW $i");
  check_value("FETCHROW $i", "smallint2", $i);
  check_value("FETCHROW $i", "xml2", $real_value{XML}[$i-1], FALSE);
  $i++;
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

  #
  # Assign type constants to columns according to column types
  #
  %type = (
    'SMALLINT NOT NULL' => SQL_SMALLINT,
    'XML'               => SQL_XML
  );

  #
  # Assign precision values to columns according to column types
  #
  %precision = (
    'SMALLINT NOT NULL' => 5,
    'XML'               => 0
  );

  #
  # Assign scale values to columns according to column types
  #
  %scale = (
    'SMALLINT NOT NULL' => 0,
    'XML'               => 0
  );

  #
  # Assign attributes to columns according to column types
  #
  %attribute = (
    'SMALLINT NOT NULL' => $attrib_int,
    'XML'               => undef
  );

}
