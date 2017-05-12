####################################################################
# TESTCASE:             perld092_typeDecfloat.pl
# DESCRIPTION:  	Testing the Implementation of Decfloat Datatype
# EXPECTED RESULT:      Success
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD, {"PrintError" => 0});
check_error("CONNECT");

$dbh->do("DROP TABLE stockprice");
$stmt = get_create_table_stmt("stockprice");

$dbh->do($stmt);
check_error("DO");

#
# INSERT statement with no parameter markers
#
$stmt = get_insert_stmt("stockprice", $row, FALSE);
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

$sth->finish();
check_error("FINISH");

#
# INSERT statement with parameter markers for the values
#
$stmt = get_insert_stmt("stockprice", undef, TRUE);
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

#
# Use bind_param($param_num, $bind_value) and execute()
#
@column = @{$stockprice};
print $attribute;
for ($row = 1; $row < 6 ; $row++)
{
  @bind_values = get_values("stockprice", $row);
  for ($i = 0; $i < @bind_values; $i++)
  {
    $sth->bind_param($i+1, $bind_values[$i], $attribute{$column[$i]});
    check_error("Row = $row, BIND_PARAM $i");
  }
  $sth->execute();
  check_error("Row = $row, EXECUTE");
}

$sth->finish();
check_error("FINISH");

$stmt = "SELECT * FROM stockprice order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$stockprice};
for($i = 0; $i < @column; $i++)
{
  check_value("PREPARE", "sth->{TYPE}->[$i]", $type{$stockprice->[$i]});
  check_value("PREPARE", "sth->{PRECISION}->[$i]", $precision{$stockprice->[$i]});
  check_value("PREPARE", "sth->{SCALE}->[$i]", $scale{$stockprice->[$i]});
}

$sth->bind_columns(undef, \($smallint2, $varchar2, $decimal2, $decfloat2));
check_error("BIND_COLUMNS");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", -1);

for($i=1; $i<7; $i++)
{
  @row_ary = $sth->fetchrow_array();
  #print "@row_ary \n";
  check_error("Row = $i, FETCHROW_ARRAY");
  check_value("Row = $i, FETCHROW_ARRAY", "smallint2",  $real_value{$stockprice->[0]}->[$i-1], TRUE, TRUE);
  check_value("Row = $i, FETCHROW_ARRAY", "varchar2",  $real_value{$stockprice->[1]}->[$i-1], TRUE, FALSE);
  check_value("Row = $i, FETCHROW_ARRAY", "decimal2",  $real_value{$stockprice->[2]}->[$i-1], TRUE, TRUE);
  check_value("Row = $i, FETCHROW_ARRAY", "decfloat2",  $real_value{$stockprice->[3]}->[$i-1], TRUE, FALSE);
}

while (@row_ary = $sth->fetchrow())
{
  @exp_value = get_values("perld1t2", $row);
  check_error("Row = $i, FETCHROW");
  check_value("Row = $i, FETCHROW", "smallint2", $real_value{$stockprice->[0]}->[$i-1], TRUE, TRUE);
  check_value("Row = $i, FETCHROW", "varchar2",  $real_value{$stockprice->[1]}->[$i-1], TRUE, FALSE);
  check_value("Row = $i, FETCHROW", "decimal2",  $real_value{$stockprice->[2]}->[$i-1], TRUE, TRUE);
  check_value("Row = $i, FETCHROW", "decfloat2", $real_value{$stockprice->[3]}->[$i-1], TRUE, FALSE);
  $row++;
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
  # Define column types for the stockprice table
  #
  $stockprice = ['SMALLINT',
               'VARCHAR(30)',
               'DECIMAL(9,3)',
               'DECFLOAT(16)'];

  #
  # Define column values according to the column types
  # Use undef as NULL
  #
  %real_value = (
    'SMALLINT'      => [10, 20, 30, 40, 50, 60],
    'VARCHAR(30)'   => ['Megadeth', 'Zaral', 'Megabyte', 'Visarsoft', 'Mailersoft', 'Kaerci'],
    'DECIMAL(9,3)'  => [100.002, 100.205, 98.65, 123.34, 134.22, 100.97],
    'DECFLOAT(16)'  => [990.24234242342423432, 100.234, 1002.112, 1652.345, 1643.126, 9876.765]
    );

  #
  # Assign type constants to columns according to column types
  #
  %type = (
    'SMALLINT'      => SQL_SMALLINT,
    'VARCHAR(30)'   => SQL_VARCHAR,
    'DECIMAL(9,3)'  => SQL_DECIMAL,
    'DECFLOAT(16)'  => SQL_DECFLOAT
  );

  #
  # Assign precision values to columns according to column types
  #
  %precision = (
    'SMALLINT'      => 5,
    'VARCHAR(30)'   => 30,
    'DECIMAL(9,3)'  => 9,
    'DECFLOAT(16)'  => 16
  );

  #
  # Assign scale values to columns according to column types
  #
  %scale = (
    'SMALLINT'      => 0,
    'VARCHAR(30)'   => 0,
    'DECIMAL(9,3)'  => 3,
    'DECFLOAT(16)'  => 0
  );

  #
  # Assign attributes to columns according to column types
  #
  %attribute = (
    'SMALLINT'      => $attrib_smallint,
    'VARCHAR(30)'   => $attrib_varchar,
    'DECIMAL(9,3)'  => $attrib_decimal,
    'DECFLOAT(16)'  => $attrib_decfloat
  );

}

