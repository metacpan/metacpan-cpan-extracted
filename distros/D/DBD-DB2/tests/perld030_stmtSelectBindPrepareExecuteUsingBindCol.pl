####################################################################
# TESTCASE: 		perld030_stmtSelectBindPrepareExecuteUsingBindCol.pl
# DESCRIPTION: 		Prepare and execute a SELECT statement against 
#                       table perld1t1 using separate calls to bind_col()
#                       to bind perl variables to the result columns.
#                       The column types are as follows:
#                         char (10)
#                         date
#                         time
#                         timestamp
#                         varchar(3000) becomes long varchar with OS/390
#                         long varchar 
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

$stmt = "SELECT * FROM perld1t1 order by 1";

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

@column = @{$perld1t1};
for($i = 0; $i < @column; $i++)
{
  check_value("PREPARE", "sth->{TYPE}->[$i]", $type{$perld1t1->[$i]});
  if( $ENV{DDCS} && $perld1t1->[$i] eq 'LONG VARCHAR' )
  {
    # The precision of a long varchar column varies on OS/390;
    # it depends on the other columns in the row, and the maximum record
    # size (assumed to be fixed at 4053)
    check_value("PREPARE", "sth->{PRECISION}->[$i]", 1010 );
  }
  else
  {
    check_value("PREPARE", "sth->{PRECISION}->[$i]", $precision{$perld1t1->[$i]});
  }
  check_value("PREPARE", "sth->{SCALE}->[$i]", $scale{$perld1t1->[$i]});
}

$sth->bind_col(1, \$char1);
check_error("BIND_COL 1");
$sth->bind_col(2, \$date1);
check_error("BIND_COL 2");
$sth->bind_col(3, \$time1);
check_error("BIND_COL 3");
$sth->bind_col(4, \$timestamp1);
check_error("BIND_COL 4");
$sth->bind_col(5, \$varchar1);
check_error("BIND_COL 5");
$sth->bind_col(6, \$longvarchar1);
check_error("BIND_COL 6");

$rv = $sth->execute();
check_error("EXECUTE");
check_value("EXECUTE", "rv", -1);

open(OUTPUT,">res/$tcname.res");
for($row=0; $row<5; $row++)
{
  $ary_ref = $sth->fetchrow_arrayref();
  $char1        = "NULL      " if (!defined($char1));
  $date1        = "NULL      " if (!defined($date1));
  $time1        = "NULL    " if (!defined($time1));
  $timestamp1   = "NULL                      " if (!defined($timestamp1));
  $varchar1     = "NULL          " if (!defined($varchar1));
  $longvarchar1 = "NULL        " if (!defined($longvarchar1));
  print OUTPUT "$char1 $date1 $time1 $timestamp1 $varchar1 $longvarchar1\n";
}

while ($ary_ref = $sth->fetch())
{
  check_error("Row = $row, FETCH");
  $char1        = "NULL      " if (!defined($char1));
  $date1        = "NULL      " if (!defined($date1));
  $time1        = "NULL    " if (!defined($time1));
  $timestamp1   = "NULL                      " if (!defined($timestamp1));
  $varchar1     = "NULL          " if (!defined($varchar1));
  $longvarchar1 = "NULL        " if (!defined($longvarchar1));
  print OUTPUT "$char1 $date1 $time1 $timestamp1 $varchar1 $longvarchar1\n";
  $row++;
}

$sth->finish();
check_error("FINISH");

$temp = system("diff -w exp/$tcname.exp res/$tcname.res > err/$tcname.err");

if( $temp == 0 )
{
  $success = "y";
} else {
  $success = "n";
}

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
  $perld1t1 = ['CHAR(10)',
               'DATE',
               'TIME',
               'TIMESTAMP',
               'VARCHAR(3000)',
               'LONG VARCHAR'];

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

}
