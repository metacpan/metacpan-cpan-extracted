####################################################################
# TESTCASE: 		perld041stmt_SelectGraphicDataTypesUsingBindColumns.pl
# DESCRIPTION: 		Prepare and execute a SELECT statement against table
#                       perld3t1 using bind_columns() to bind perl variables
#                       to the result columns.
#                       The column types are as follows:
#                         smallint
#                         graphic(127)
#                         vargraphic(127)
#                         long vargraphic(127)
#                         dbclob(1K)
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

$stmt = "SELECT * FROM perld3t1 order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$perld3t1};
for($i = 0; $i < @column; $i++)
{
  check_value("PREPARE", "sth->{TYPE}->[$i]", $type{$perld3t1->[$i]});
  check_value("PREPARE", "sth->{PRECISION}->[$i]", $precision{$perld3t1->[$i]});
  check_value("PREPARE", "sth->{SCALE}->[$i]", $scale{$perld3t1->[$i]});
}

$sth->bind_columns(undef, \($smallint2, $graphic2, $vargraphic2, $longvargraphic2));
check_error("BIND_COLUMNS");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", -1);

for($i=1; $i<4; $i++)
{
  @row_ary = $sth->fetchrow_array();
  check_error("FETCHROW_ARRAY $i");
  check_value("FETCHROW_ARRAY $i", "smallint2", $i);
  check_value("FETCHROW_ARRAY $i", "graphic2", $real_value{$perld3t1->[1]}->[$i-1], FALSE);
  check_value("FETCHROW_ARRAY $i", "vargraphic2", $real_value{$perld3t1->[2]}->[$i-1], FALSE);
  check_value("FETCHROW_ARRAY $i", "longvargraphic2", $real_value{$perld3t1->[3]}->[$i-1], FALSE);
}

while (@row_arg = $sth->fetchrow())
{
  check_error("FETCHROW $i");
  check_value("FETCHROW $i", "smallint2", $i);
  check_value("FETCHROW $i", "graphic2", $real_value{$perld3t1->[1]}->[$i-1], FALSE);
  check_value("FETCHROW $i", "vargraphic2", $real_value{$perld3t1->[2]}->[$i-1], FALSE);
  check_value("FETCHROW $i", "longvargraphic2", $real_value{$perld3t1->[3]}->[$i-1], FALSE);
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

  #
  # Assign type constants to columns according to column types
  #
  %type = (
    'SMALLINT NOT NULL' => SQL_SMALLINT,
    'GRAPHIC(127)'      => SQL_GRAPHIC,
    'VARGRAPHIC(127)'   => SQL_VARGRAPHIC,
    'LONG VARGRAPHIC'   => SQL_LONGVARGRAPHIC
  );

  #
  # Assign precision values to columns according to column types
  #
  %precision = (
    'SMALLINT NOT NULL' => 5,
    'GRAPHIC(127)'      => 127,
    'VARGRAPHIC(127)'   => 127,
    'LONG VARGRAPHIC'   => 16350
  );

  #
  # Assign scale values to columns according to column types
  #
  %scale = (
    'SMALLINT NOT NULL' => 0,
    'GRAPHIC(127)'      => 0,
    'VARGRAPHIC(127)'   => 0,
    'LONG VARGRAPHIC'   => 0
  );

  #
  # Assign attributes to columns according to column types
  #
  %attribute = (
    'SMALLINT NOT NULL' => $attrib_int,
    'GRAPHIC(127)'      => undef,
    'VARGRAPHIC(127)'   => undef,
    'LONG VARGRAPHIC'   => undef,
  );

}
