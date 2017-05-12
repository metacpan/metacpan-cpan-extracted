####################################################################
# TESTCASE: 		perld062_pingConnWithdb2stop.pl
# DESCRIPTION: 		ping connection following 'db2stop force'
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

# Only print messages in case of error so we can safely skip this step
# in client/server environments
if( !&is_client_server || &is_loopback )
{
  `db2stop force`;

  # Test connection, should get SQLSTATE=40003
  if( $dbh->ping )
  {
    print "Error: connection appears to be alive\n";
  }

  if( defined( $dbh->err ) && $dbh->err != 0 )
  {
    print "Error: unexpected SQLCODE: ", $dbh->err, "\n";
  }

  if( defined( $dbh->errstr ) && $dbh->errstr ne "" )
  {
    print "Error: unexpected error message: ", $dbh->errstr, "\n";
  }

  if( $dbh->state != "40003" )
  {
    print "Error: unexpected SQLSTATE: ", $dbh->state, "\n";
  }

  # Test connection again, should get SQLSTATE=08003
  if( $dbh->ping )
  {
    print "Error: connection appears to be alive\n";
  }

  if( defined( $dbh->err ) && $dbh->err != 0 )
  {
    print "Error: unexpected SQLCODE: ", $dbh->err, "\n";
  }

  if( defined( $dbh->errstr ) && $dbh->errstr ne "" )
  {
    print "Error: unexpected error message: ", $dbh->errstr, "\n";
  }

  if( $dbh->state != "08003"  && $dbh->state != "40003" )
  {
    print "Error: unexpected SQLSTATE: ", $dbh->state, "\n";
  }

  `db2start`;
}

$dbh->disconnect;

fvt_end_testcase($testcase, $success);
