####################################################################
# TESTCASE: 		perld051_verifyDBHandleOnInactiveDestroy.pl
# DESCRIPTION: 		Verify that when a database handle is destroyed and
#                       its InactiveDestroy attribute is set to ON, a
#                       disconnect from the database is not done.
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

print "Connecting to DB and preparing statement...\n";
$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");
print "  Connection InactiveDestroy=$dbh->{InactiveDestroy}\n";

$sth = $dbh->prepare( "select name from staff where job = 'Mgr' order by 1" );
check_error("PREPARE");
print "  Statement InactiveDestroy=$sth->{InactiveDestroy}\n";
print "\n";

fvt_removeFileLock("child.done");
$rc = 0;
if ($pid = fork())
{
  for($i=0; $i<360 && !fvt_checkFileLock("child.done"); $i++)
  {
    sleep 1;
  };

  print("Parent begins\n");
  print("  Connection InactiveDestroy=$dbh->{InactiveDestroy}\n");
  print("  Statement InactiveDestroy=$sth->{InactiveDestroy}\n");

  print "  Selecting all managers from staff...\n";
  $sth->execute();
  check_error("EXECUTE");

  $temp = $tcname."a";
  $success = check_results($sth, $temp);

#  while( @row = $sth->fetchrow_array() )
#  {
#    print "    @row\n";
#  }

  print "  Destroying DBI handles.  This should cause an implicit destruction\n";
  print "  of the corresponding DB2 statement and connection handles.\n";
  $sth->{Warn} = 0;
  $dbh->{Warn} = 0;
  undef $sth;
  undef $dbh;
  print("Parent ends\n");
}
elsif (defined($pid))
{
  print "Child begins\n";
  print "  Connection InactiveDestroy=$dbh->{InactiveDestroy}\n";
  print "  Statement InactiveDestroy=$sth->{InactiveDestroy}\n";
  print "  Setting InactiveDestroy on\n";
  $dbh->{InactiveDestroy} = 1;
  $sth->{InactiveDestroy} = 1;
  print "  Connection InactiveDestroy=$dbh->{InactiveDestroy}\n";
  print "  Statement InactiveDestroy=$sth->{InactiveDestroy}\n";

  print "  Destroying DBI handles.  DB2 handles should not be destroyed.\n";
  undef $sth;
  undef $dbh;

  print "  Getting new connection and statement...\n";
  $dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
  check_error("CONNECT");
  print "  Connection InactiveDestroy=$dbh->{InactiveDestroy}\n";

  print "  Destroying DBI handles.  DB2 handles should not be destroyed.\n";
  undef $sth;
  undef $dbh;

  print "  Getting new connection and statement...\n";
  $dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
  check_error("CONNECT");
  print "  Connection InactiveDestroy=$dbh->{InactiveDestroy}\n";

  $sth = $dbh->prepare( "select name from staff where job = 'Clerk' order by 1" );
  check_error("PREPARE");
  print "  Statement InactiveDestroy=$sth->{InactiveDestroy}\n";

  print "  Selecting all clerks from staff...\n";
  $sth->execute();
  check_error("EXECUTE");

  $temp = $tcname."b";
  $success = check_results($sth, $temp);

#  while( @row = $sth->fetchrow_array() )
#  {
#    print "    @row\n";
#  }

  $sth->finish();
  check_error("FINISH");

  $dbh->disconnect();
  check_error("DISCONNECT");

  fvt_createFileLock("child.done");
  print("Child ends\n");
  exit 0;
}
else
{
  print( "Fork error\n" );
  $rc = -1;
}

fvt_removeFileLock("child.done");

fvt_end_testcase($testcase, $success);
