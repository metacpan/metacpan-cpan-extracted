####################################################################
# TESTCASE: perld099_set_schema_overflow.pl
# DESCRIPTION: Connect with an oversized db2_set_schema value
# EXPECTED RESULT: Success (no buffer overflow)
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

###################################################################
# Connect with schema names up to and beyond the internal buffer
# size; the connect result is not checked as DBI ignores a failed
# STORE at connect time. The test fails only if the process aborts.
###################################################################

foreach my $len (100, 1000, 8192, 100000)
{
  %ops = ( PrintError => 0,
           db2_set_schema => "A" x $len);
  $dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD, \%ops);
  $dbh->disconnect() if defined($dbh);
}

###################################################################
# Normal connection must still work afterwards
###################################################################

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

$dbh->disconnect();
check_error("DISCONNECT");

fvt_end_testcase($testcase, $success);