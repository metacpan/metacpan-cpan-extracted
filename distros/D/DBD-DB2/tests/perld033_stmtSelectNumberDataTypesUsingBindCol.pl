####################################################################
# TESTCASE: 		perld033_stmtSelectNumberDataTypesUsingBindCol.pl
# DESCRIPTION: 		 Prepare and execute a SELECT statement against table
#                        perld1t2 using bind_columns() to bind perl variables
#                        to the result columns.
#                        The column types are as follows:
#                          numeric(16,8)
#                          decimal(9,3)
#                          bigint
#                          integer
#                          smallint
#                          float
#                          double
#                          real
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

$stmt = "SELECT * FROM perld1t2 order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$perld1t2};
for($i = 0; $i < @column; $i++)
{
  check_value("PREPARE", "sth->{TYPE}->[$i]", $type{$perld1t2->[$i]});
  check_value("PREPARE", "sth->{PRECISION}->[$i]", $precision{$perld1t2->[$i]});
  check_value("PREPARE", "sth->{SCALE}->[$i]", $scale{$perld1t2->[$i]});
}

$sth->bind_columns(undef, \($numeric2, $decimal2, $bigint2, $integer2, $smallint2, $float2, $double2, $real2));
check_error("BIND_COLUMNS");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", -1);

for($row=0; $row<5; $row++)
{
  @row_ary = $sth->fetchrow_array();
  @exp_value = get_values("perld1t2", $row);
  check_error("Row = $row, FETCHROW_ARRAY");
  check_value("Row = $row, FETCHROW_ARRAY", "numeric2",  $exp_value[0], TRUE, TRUE);
  check_value("Row = $row, FETCHROW_ARRAY", "decimal2",  $exp_value[1], TRUE, TRUE);
  check_value("Row = $row, FETCHROW_ARRAY", "bigint2",   $exp_value[2], TRUE, TRUE);
  check_value("Row = $row, FETCHROW_ARRAY", "integer2",  $exp_value[3], TRUE, TRUE);
  check_value("Row = $row, FETCHROW_ARRAY", "smallint2", $exp_value[4], TRUE, TRUE);
#  check_value("Row = $row, FETCHROW_ARRAY", "float2",    $exp_value[5], TRUE, TRUE);
#  check_value("Row = $row, FETCHROW_ARRAY", "double2",   $exp_value[6], TRUE, TRUE);
  check_value("Row = $row, FETCHROW_ARRAY", "real2",     $exp_value[7], TRUE, TRUE);
}

while (@row_ary = $sth->fetchrow())
{
  @exp_value = get_values("perld1t2", $row);
  check_error("Row = $row, FETCHROW");
  check_value("Row = $row, FETCHROW", "numeric2",  $exp_value[0], TRUE, TRUE);
  check_value("Row = $row, FETCHROW", "decimal2",  $exp_value[1], TRUE, TRUE);
  check_value("Row = $row, FETCHROW", "bigint2",   $exp_value[2], TRUE, TRUE);
  check_value("Row = $row, FETCHROW", "integer2",  $exp_value[3], TRUE, TRUE);
  check_value("Row = $row, FETCHROW", "smallint2", $exp_value[4], TRUE, TRUE);
#  check_value("Row = $row, FETCHROW", "float2",    $exp_value[5], TRUE, TRUE);
#  check_value("Row = $row, FETCHROW", "double2",   $exp_value[6], TRUE, TRUE);
  check_value("Row = $row, FETCHROW", "real2",     $exp_value[7], TRUE, TRUE);
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
  # Define column types for various tables
  #
  $perld1t2 = ['NUMERIC(16,8)',
               'DECIMAL(9,3)',
               # Since BIGINT is not supported on host systems yet,
               # have an extra integer column instead.
               $ENV{DDCS} ? 'INTEGER' : 'BIGINT',
               'INTEGER',
               'SMALLINT',
               'FLOAT',
               'DOUBLE',
               'REAL'];

  #
  # Define column values according to the column types
  # Use undef as NULL
  #
  %real_value = (
    'CHAR(10)'      => ['1 Char 10', '2 Char 10', '3 Char 10',
                        '4 Char 10', undef,       '6 Char 10',
                        '7 Char 10', '8 Char 10', '9 Char 10'],
    'DATE'          => ['09/11/1998', '09/12/1998', '09/13/1998',
                        '09/14/1998', '09/15/1998', '09/16/1998',
                        '09/17/1998', '09/18/1998', undef],
    'TIME'          => ['12.01.01', '12.02.02', undef,
                        '12.04.04', '12.05.05', '12.06.06',
                        '12.07.07', '12.08.08', '12.09.09'],
    'TIMESTAMP'     => ['1998-09-11-12.11.01', '1998-09-11-12.12.02', '1998-09-11-12.13.03',
                        '1998-09-11-12.14.04', '1998-09-11-12.15.05', '1998-09-11-12.16.06',
                        undef,                 '1998-09-11-12.18.08', '1998-09-11-12.19.09'],
    'VARCHAR(3000)' => ['1 varchar 3000', undef,            '3 varchar 3000',
                        '4 varchar 3000', '5 varchar 3000', '6 varchar 3000',
                        '7 varchar 3000', '8 varchar 3000', '9 varchar 3000'],
    'LONG VARCHAR'  => ['1 longvarchar', '2 longvarchar', '3 longvarchar',
                        '4 longvarchar', '5 longvarchar', undef,
                        '7 longvarchar', '8 longvarchar', '9 longvarchar'],
    'NUMERIC(16,8)' => [1111.8, 2222.8, 3333.8,
                        4444.8, 5555.8, 6666.8,
                        7777.8, 8888.8, 9999.9],
    'DECIMAL(9,3)'  => [1.3, 2.3, 3.3,
                        4.3, 5.3, 6.3,
                        7.3, 8,3, 9.3],
    'BIGINT'        => [1009999, 2009999, 3009999,
                        4009999, 5009999, 6009999,
                        7009999, 8009999, 9009999],
    'INTEGER'       => [19999, 29999, 39999,
                        49999, 59999, 69999,
                        79999, 89999, 99999],
    'SMALLINT'      => [1999, 2999, 3999,
                        4999, 5999, 6999,
                        7999, 8999, 9999],
    'FLOAT'         => [189.989, 289.989, 389.989,
                        489.989, 589.989, 689.989,
                        789.989, 889.989, 989.989],
    'DOUBLE'        => [19.19, 29.29, 39.39,
                        49.49, 59.59, 69.69,
                        79.79, 89.89, 99.99],
    'REAL'          => [1.5, 2.5, 3.5,
                        4.5, 5.5, 6.5,
                        7.5, 8.5, 9.5],
    'CHAR(100) FOR BIT DATA'     => ['aaaaa01234', 'bbbbb01234', 'ccccc01234',
                                     'ddddd01234', 'eeeee01234', 'fffff01234',
                                     'ggggg01234', 'hhhhh01234', 'iiiii01234'],
    'VARCHAR(3000) FOR BIT DATA' => ['AAAAA01234', 'BBBBB01234', 'CCCCC01234',
                                     'DDDDD01234', 'EEEEE01234', 'FFFFF01234',
                                     'GGGGG01234', 'HHHHH01234', 'IIIII01234']
  );


  #
  # Assign type constants to columns according to column types
  #
  %type = (
    'CHAR(10)'      => SQL_CHAR,
    'DATE'          => SQL_TYPE_DATE,
    'TIME'          => SQL_TYPE_TIME,
    'TIMESTAMP'     => SQL_TYPE_TIMESTAMP,
    'VARCHAR(3000)' => $ENV{DDCS} ? SQL_LONGVARCHAR : SQL_VARCHAR,
    'LONG VARCHAR'  => SQL_LONGVARCHAR,
    'NUMERIC(16,8)' => SQL_DECIMAL,
    'DECIMAL(9,3)'  => SQL_DECIMAL,
    'BIGINT'        => SQL_BIGINT,
    'INTEGER'       => SQL_INTEGER,
    'SMALLINT'      => SQL_SMALLINT,
    'FLOAT'         => SQL_DOUBLE,
    'DOUBLE'        => SQL_DOUBLE,
    'REAL'          => SQL_REAL,
    'CHAR(100) FOR BIT DATA'     => SQL_BINARY,
    'VARCHAR(3000) FOR BIT DATA' => $ENV{DDCS} ? SQL_LONGVARBINARY
                                               : SQL_VARBINARY,
  );

  #
  # Assign precision values to columns according to column types
  #
  %precision = (
    'CHAR(10)'      => 10,
    'DATE'          => 10,
    'TIME'          => 8,
    'TIMESTAMP'     => 26,
    'VARCHAR(3000)' => 3000,
    'LONG VARCHAR'  => 32700,
    'NUMERIC(16,8)' => 16,
    'DECIMAL(9,3)'  => 9,
    'BIGINT'        => 19,
    'INTEGER'       => 10,
    'SMALLINT'      => 5,
    'FLOAT'         => 15,
    'DOUBLE'        => 15,
    'REAL'          => 7,
    'CHAR(100) FOR BIT DATA'     => 100,
    'VARCHAR(3000) FOR BIT DATA' => 3000
  );

  #
  # Assign scale values to columns according to column types
  #
  %scale = (
    'CHAR(10)'      => 0,
    'DATE'          => 0,
    'TIME'          => 0,
    'TIMESTAMP'     => 6,
    'VARCHAR(3000)' => 0,
    'LONG VARCHAR'  => 0,
    'NUMERIC(16,8)' => 8,
    'DECIMAL(9,3)'  => 3,
    'BIGINT'        => 0,
    'INTEGER'       => 0,
    'SMALLINT'      => 0,
    'FLOAT'         => 0,
    'DOUBLE'        => 0,
    'REAL'          => 0,
    'CHAR(100) FOR BIT DATA'     => 0,
    'VARCHAR(3000) FOR BIT DATA' => 0
  );

  #
  # Assign attributes to columns according to column types
  #
  %attribute = (
    'CHAR(10)'      => $attrib_char,
    'DATE'          => $attrib_date,
    'TIME'          => $attrib_time,
    'TIMESTAMP'     => $attrib_ts,
    'VARCHAR(3000)' => $ENV{DDCS} ? $attrib_longvarchar : $attrib_varchar,
    'LONG VARCHAR'  => $attrib_longvarchar,
    'NUMERIC(16,8)' => $attrib_numeric,
    'DECIMAL(9,3)'  => $attrib_decimal,
    'BIGINT'        => $attrib_bigint,
    'INTEGER'       => $attrib_int,
    'SMALLINT'      => $attrib_smallint,
    'FLOAT'         => $attrib_float,
    'DOUBLE'        => $attrib_double,
    'REAL'          => $attrib_real,
    'CHAR(100) FOR BIT DATA'     => 0,
    'VARCHAR(3000) FOR BIT DATA' => 0
  );

  %exp_values = (
    'CHAR(100) FOR BIT DATA'     => [$ENV{DDCS} ? "\x81\x81\x81\x81\x81\xF0\xF1\xF2\xF3\xF4"
                                                : 'aaaaa01234',
                                     'bbbbb01234',
                                     'ccccc01234',
                                     'ddddd01234',
                                     'eeeee01234',
                                     'fffff01234',
                                     'ggggg01234',
                                     'hhhhh01234',
                                     'iiiii01234'],
    'VARCHAR(3000) FOR BIT DATA' => [$ENV{DDCS} ? "\xC1\xC1\xC1\xC1\xC1\xF0\xF1\xF2\xF3\xF4"
                                                : 'AAAAA01234',
                                     'BBBBB01234',
                                     'CCCCC01234',
                                     'DDDDD01234',
                                     'EEEEE01234',
                                     'FFFFF01234',
                                     'GGGGG01234',
                                     'HHHHH01234',
                                     'IIIII01234']
  );

}
