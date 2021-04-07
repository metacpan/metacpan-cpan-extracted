####################################################################
# TESTCASE: 		perld077_conn7ConnectionsRemote.pl
# DESCRIPTION: 		7 valid connections to the same database
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;
use DBD::DB2::Constants;

require 'connection.pl';
require 'perldutl.pl';

$release = &get_release();
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

@dbh;
$num_conn = 7;

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD";
$name = "DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$USERID; PWD=$PASSWORD";
for($i=0; $i<$num_conn; $i++){
    $dbh[$i]= DBI->connect($string, $USERID, $PASSWORD );
    check_error("CONNECT $i");
    check_value("CONNECT $i", "dbh[$i]->{Active}", 1);
    check_value("CONNECT $i", "dbh[$i]->{Name}", $name);
}

$stmt = "SELECT * FROM ORG WHERE DEPTNUMB = 10";

for($i=0; $i<$num_conn; $i++){
    $sth = $dbh[$i]->prepare($stmt);
    check_error("PREPARE $i");

    $sth->execute();
    check_error("EXECUTE $i");

    check_results($sth, $testcase);

    $sth->finish();
    check_error("FINISH $i");

    $dbh[$i]->disconnect();
    check_error("DISCONNECT");
    check_value("DISCONNECT $i", "dbh[$i]->{Active}", undef);

}

fvt_end_testcase($testcase, $success);
