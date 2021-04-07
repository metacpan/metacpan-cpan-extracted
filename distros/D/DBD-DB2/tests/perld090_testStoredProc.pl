####################################################################
# TESTCASE: 		perld090_testStoredProc.pl
# DESCRIPTION: 		Testing Stored Procedures
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

$dbh->do( 'DROP PROCEDURE SP_Example' );

$statement = "CREATE PROCEDURE SP_Example () LANGUAGE SQL BEGIN RETURN 5; END";
$sth = $dbh->prepare( $statement );
check_error( 'PREPARE' );

$sth->execute();
check_error("EXECUTE CREATE procedure");

$sth = $dbh->prepare( '{ ? = CALL SP_Example( ) }' );
check_error( 'PREPARE' );

$sth->bind_param_inout( 1, \$output, 20, { 'db2_param_type' => SQL_PARAM_OUTPUT, 'db2_c_type' => SQL_C_LONG, 'db2_type' => SQL_INTEGER });
check_error("BIND_PARAM 1");

$rv = $sth->execute();
check_error("EXECUTE CREATE procedure");

printf ( "the output is %d ", $output );

$sth->finish;
check_error("FINISH");

$dbh->disconnect;
check_error("DISCONNECT");

fvt_end_testcase($testcase, $success);

