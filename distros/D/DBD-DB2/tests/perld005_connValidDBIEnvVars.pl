####################################################################
# TESTCASE: 		perld005_connValidDBIEnvVars.pl
# DESCRIPTION: 		Valid connection with env. var. DBI_USER and
#                       DBI_PASS
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$ENV{DBI_USER} = $USERID;
$ENV{DBI_PASS} = $PASSWORD;
$dbh = DBI->connect("dbi:DB2:$DATABASE", undef, undef, {PrintError => 0});
check_error("CONNECT");

$ENV{DBI_USER} = "";
$ENV{DBI_PASS} = "";

fvt_end_testcase($testcase, $success);
