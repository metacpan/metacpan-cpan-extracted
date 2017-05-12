####################################################################
# TESTCASE: 		perld095_chopblanks_test.pl
# DESCRIPTION: 	This test checks that the ChopBlanks feature works fine
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
$str = "text with spaces         ";
$str1= "text with spaces";

fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$sth = $dbh->prepare("create table chopblnktest(id integer, str char(25))");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");
$sth->finish;

$sth = $dbh->prepare("insert into chopblnktest(id,str) values (1,'$str')");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");
$sth->finish;

$sth = $dbh->prepare("select str from chopblnktest where id = 1");
check_error("PREPARE");
$sth->{ChopBlanks} = 1;
$sth->execute();
check_error("EXECUTE");

my @array = $sth->fetchrow();
$out_str = $array[0];
$sth->finish;

$sth = $dbh->prepare("select str from chopblnktest where id = 1");
check_error("PREPARE");
$sth->{ChopBlanks} = 0;
$sth->execute();
check_error("EXECUTE");

my @array = $sth->fetchrow();
$out_str1 = $array[0];
$sth->finish;

$sth = $dbh->prepare("drop table chopblnktest");
check_error("PREPARE");
$sth->execute();
check_error("EXECUTE");
$sth->finish;

if( $str1 eq $out_str && $str eq $out_str1 ){
  $success = "y";
}else {
  $success = "n";
}

fvt_end_testcase($testcase, $success);
