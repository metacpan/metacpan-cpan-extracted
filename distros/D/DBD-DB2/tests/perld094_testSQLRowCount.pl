####################################################################
# TESTCASE: 		perld094_testSQLRowCount.pl
# DESCRIPTION: 		Testing SQLRowCount to prefetch the number of rows
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;
use DBD::DB2::Constants;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$sth = $dbh->prepare( 'SELECT * FROM stockprice' );
check_error( 'PREPARE' );

# Put the prefetch for rowcount to 1 and check the result
$sth->STORE("db2_rowcount_prefetch" => 1);
$sth->execute();
check_error("EXECUTE");
  
check_value("RowCount", "sth->rows", 6);

$sth->finish;
check_error("FINISH");

# Put the prefetch for rowcount to 0 and check the result
$sth->{db2_rowcount_prefetch} = 0;
$sth->execute();
check_error("EXECUTE");
  
check_value("RowCount", "sth->rows", -1);

$sth->finish;
check_error("FINISH");

# Put the prefetch for rowcount to 1 again and check the result
$sth->{db2_rowcount_prefetch} = 1;
$sth->execute();
check_error("EXECUTE");
  
check_value("RowCount", "sth->rows", 6);

$sth->finish;
check_error("FINISH");

$dbh->disconnect;
check_error("DISCONNECT");

fvt_end_testcase($testcase, $success);

