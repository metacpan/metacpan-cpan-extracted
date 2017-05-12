########################################################################################################
## TESTCASE: 		perld_null_clob_test.pl
## DESCRIPTION: 	This test checks that rows with CLOB value null is retrieved without any errors
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$sth = $dbh->prepare("drop table nullclobtest");
$sth->execute();
$sth->finish;

$sth = $dbh->prepare("create table nullclobtest(col1 integer, col2 clob)");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");
$sth->finish;

$sth = $dbh->prepare("insert into nullclobtest (col1, col2) values (1, NULL)");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");
$sth->finish;

$sth = $dbh->prepare("select * from nullclobtest");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");

my @array = $sth->fetchrow();
$out = $array[0];
$sth->finish;

check_value("FETCH","out",1, TRUE, TRUE);
fvt_end_testcase($testcase, $success);
