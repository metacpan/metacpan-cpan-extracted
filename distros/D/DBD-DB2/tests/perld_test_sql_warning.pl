########################################################################################################
## TESTCASE: 		perld_null_clob_test.pl
## DESCRIPTION: 	This test checks that warning codes are returned correctly in $sth->err when
#                       ever there is a SQL_SUCCESS_WITH_INFO
## EXPECTED RESULT: 	Success
########################################################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";

fvt_begin_testcase($tcname);

my $bind_value;

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$sth = $dbh->prepare("drop procedure warningproc");
$sth->execute();
$sth->finish;

$sth = $dbh->prepare("create procedure $USERID.warningproc(OUT output varchar(7)) LANGUAGE SQL SPECIFIC SPROC BEGIN SET output = 'seven+2'; END");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");
$sth->finish;

$sth = $dbh->prepare("call warningproc(?)");
check_error("PREPARE");
#Bind variable with lesser mem space(5 chars) than required (7 chars)
$sth->bind_param_inout( 1, \$bind_value, 5 );
$sth->execute();
$out = "no match";

if($sth->err == -99999) {
  $out = "Matched";
}
$sth->finish;

check_value("Execute Warning","out","Matched", TRUE, FALSE);
fvt_end_testcase($testcase, $success);
