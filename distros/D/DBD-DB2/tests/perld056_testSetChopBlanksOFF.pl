####################################################################
# TESTCASE: 		perld056_testSetChopBlanksOFF.pl
# DESCRIPTION: 		Test ChopBlanks off
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
$sth = $dbh->prepare( 'SELECT * FROM perld017 order by 1' );
check_error( 'PREPARE' );

print "Testing ChopBlanks off\n";
$sth->{ChopBlanks} = 0;
$success = &dofetch($sth, $tcname);

fvt_end_testcase($testcase, $success);
