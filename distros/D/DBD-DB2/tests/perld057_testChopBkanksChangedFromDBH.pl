####################################################################
# TESTCASE: 		perld057_testChopBkanksChangedFromDBH.pl
# DESCRIPTION: 		Test ChopBlanks changed via dbh doesn't affect
#                       existing statement
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

print "Testing ChopBlanks set for dbh (on) doesn't affect existing statement (off)\n";
$dbh->{ChopBlanks} = 1;
$success = &dofetch($sth, $tcname);

fvt_end_testcase($testcase, $success);
