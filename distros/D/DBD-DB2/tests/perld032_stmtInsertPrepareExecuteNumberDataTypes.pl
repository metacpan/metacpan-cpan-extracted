####################################################################
# TESTCASE: 		perld032_stmtInsertPrepareExecuteNumberDataTypes.pl
# DESCRIPTION: 		Prepare and execute an INSERT statement to populate
#                       table perld1t2.
#                       Note: DDCS database will not allow non-bound 
#                             numeric parameters, such as integer, 
#                             small and float. Therefore, bind_param()
#                             must be used before execute().
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

#
# INSERT statement with no parameter markers
#
$stmt = get_insert_stmt("perld1t2", $row, FALSE);

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

$sth->finish();
check_error("FINISH");

#
# First INSERT statement with parameter markers for the values
#
$stmt = get_insert_stmt("perld1t2", undef, TRUE);
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

#
# Use bind_param($param_num, $bind_value) and execute()
#
@column = @{$perld1t2};
print $attribute;
for ($row = 1; $row < ($ENV{DDCS} ? 9 : 5); $row++)
{
  @bind_values = get_values("perld1t2", $row);
  for ($i = 0; $i < @bind_values; $i++)
  {
    $sth->bind_param($i+1, $bind_values[$i], $attribute{$column[$i]});
    print $attribute{$column[$i]};
    check_error("Row = $row, BIND_PARAM $i");
  }
  $sth->execute();
  check_error("Row = $row, EXECUTE");
}

if (!$ENV{DDCS})
{
  #
  # Use execute(@bind_values)
  #
  for ($row = 5; $row < 9; $row++)
  {
    @bind_values = get_values("perld1t2", $row);
    $sth->execute(@bind_values);
    check_error("Row = $row, EXECUTE");
  }
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

}
