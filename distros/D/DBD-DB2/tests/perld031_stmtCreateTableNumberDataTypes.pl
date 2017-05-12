####################################################################
# TESTCASE: 		perld031_stmtCreateTableNumberDataTypes.pl
# DESCRIPTION: 		Do a CREATE TABLE statement to create table .
#                       perld1t2.
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

$dbh->do("DROP TABLE perld1t2");
$stmt = get_create_table_stmt("perld1t2");

$dbh->do($stmt);
check_error("DO");

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
}
