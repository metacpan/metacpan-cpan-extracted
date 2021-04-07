####################################################################
# TESTCASE: 		perld093_testStoredPrcMultResultset.pl
# DESCRIPTION: 		Testing Stored Procedures for Multiple Resultsets
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

$sth = $dbh->do( 'DROP PROCEDURE SP_TestResultSet' );

$statement = "create procedure SP_TestResultSet() language sql begin    declare c1 cursor with return to client for values( 'first record' );  declare c2 cursor with return to client for values( 'second', 'record' );    open c1;    open c2;    return 3; end";
$sth = $dbh->prepare( $statement );
check_error( 'PREPARE' );

$sth->execute();
check_error("EXECUTE CREATE procedure");

$sth = $dbh->prepare( '{ CALL SP_TestResultSet( ) }' );
check_error( 'PREPARE' );

$rv = $sth->execute();
check_error("EXECUTE CREATE procedure");

my $rs = 0;
do {
	$rs ++;
	my $rn = 1;
	while (@row = $sth-> fetchrow_array()) {
		if($rs == 1) {
			check_value("RESULTSET 1", "row[0]", "first record");
		}
		else {
			check_value("RESULTSET 2", "row[0]", "second");
			check_value("RESULTSET 2", "row[1]", "record");
		}
		$rn ++;
	}
} while ( $sth->{db2_more_results});
  
check_value("SP RETURN", "sth->{db2_call_return}", 3);

$sth->finish;
check_error("FINISH");

$dbh->disconnect;
check_error("DISCONNECT");

fvt_end_testcase($testcase, $success);

