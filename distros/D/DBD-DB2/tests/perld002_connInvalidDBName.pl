####################################################################
# TESTCASE: 		perld002_connInvalidDBName.pl
# DESCRIPTION: 		Invalid connection (invalid db name)
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

$DB = "BADDB";
$dbh = DBI->connect("dbi:DB2:$DB", "$USERID", "$PASSWORD", {PrintError => 0});
check_value("CONNECT", "dbh", undef);
check_value("CONNECT", "DBI::err", -1013);
expMsg = "[IBM][CLI Driver] SQL1531N  The connection failed because the name specified with the DSN connection string keyword could not be found in either the db2dsdriver.cfg configuration file or the db2cli.ini configuration file.  Data source name specified in the connection string: \"BADDB\".\n"
check_value("CONNECT", "DBI::errstr", $expMsg);
check_value("CONNECT", "DBI::state", "08001");

fvt_end_testcase($testcase, $success);
