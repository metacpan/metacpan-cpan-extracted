####################################################################
# TESTCASE: 		perld060_pingConnWithNormalDisconnect.pl
# DESCRIPTION: 		ping connection following normal disconnect
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

print "Testing connection... ";
if( $dbh->ping )
{
  print "okay\n";
}
else
{
  print "Error: connection appears to be dead.\n"
}
print "  err=", $dbh->err, "\n";
print "  errstr=", $dbh->errstr, "\n";
print "  state=", $dbh->state, "\n";

print "Disconnect\n";
$dbh->disconnect;
check_error( "DISCONNECT" );
if ($DBI::err != 0)
{
  goto end;
}

print "Testing connection... ";
if( $dbh->ping )
{
  print "Error: connection appears to be alive\n";
}
else
{
  print "disconnected.\n";
}
print "  err=", $dbh->err, "\n";
print "  errstr=", $dbh->errstr, "\n";
print "  state=", $dbh->state, "\n";

fvt_end_testcase($testcase, $success);
