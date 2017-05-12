####################################################################
# TESTCASE: 		perld028_stmtCreateTableWithNonGraphicTypes.pl
# DESCRIPTION: 		Prepare and execute a CREATE TABLE stmt to 
#                       create table perld1t1 with non-graphic types
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

$dbh->do("DROP TABLE perld1t1");
$stmt = get_create_table_stmt("perld1t1");

$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->execute();
check_error("EXECUTE");

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
  $perld1t1 = ['CHAR(10)',
               'DATE',
               'TIME',
               'TIMESTAMP',
               'VARCHAR(3000)',
               'LONG VARCHAR'];
}
