####################################################################
# TESTCASE: 		perld058_testChangingOfChopBlanksValue.pl
# DESCRIPTION: 		Check that new dbh->ChopBlanks value is used by new
#                       statement
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

#***************************************************************************
# Create select statement
#***************************************************************************

print "Testing new statement picks up new dbh->ChopBlanks setting (on)\n";
$sth = $dbh->prepare( 'SELECT * FROM perld017 order by 1' );
check_error( 'PREPARE' );
$success = &dofetch($sth, $tcname);

fvt_end_testcase($testcase, $success);
