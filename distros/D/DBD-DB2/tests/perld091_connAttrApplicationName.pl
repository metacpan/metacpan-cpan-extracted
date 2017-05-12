####################################################################
# TESTCASE: 		perld091_connAttrApplicationName.pl
# DESCRIPTION: 		Check Connection Attributes Values Application ProgramName
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$release = &get_release();
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0, "db2_info_applname" => 'perlapplname', "db2_info_programname" => 'perldatabase'});
check_error("CONNECT");

check_value("CONNECT ATTRIBUTE", "dbh->{db2_info_applname}", "perlapplname");
check_value("CONNECT ATTRIBUTE", "dbh->{db2_info_programname}", "perldatabase");

fvt_end_testcase($testcase, $success);
