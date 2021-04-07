####################################################################
# TESTCASE: 		perld081_connWithSchema.pl
# DESCRIPTION: 		Connect to database with schema MAGIC
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

###################################################################
# Create schema and table within schema
###################################################################

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");
$dbh->do("DROP TABLE MAGIC.MAGICTEST");
$dbh->do("DROP SCHEMA MAGIC RESTRICT");

$stmt = "CREATE SCHEMA MAGIC";
$sth = $dbh->prepare($stmt);
check_error("PREPARE CREATE SCHEMA");
$sth->execute();
check_error("EXECUTE CREATE SCHEMA");

$stmt = "SET CURRENT SCHEMA MAGIC";
$sth = $dbh->prepare($stmt);
check_error("PREPARE SET SCHEMA");
$sth->execute();
check_error("EXECUTE SET SCHEMA");

$stmt = "CREATE TABLE MAGICTEST (ID INTEGER, VALUE CHAR)";
$sth = $dbh->prepare($stmt);
check_error("PREPARE CREATE TABLE");
$sth->execute();
check_error("EXECUTE CREATE TABLE");

$stmt = "INSERT INTO MAGICTEST VALUES (?,?)";
$sth = $dbh->prepare($stmt);
check_error("PREPARE");

$sth->bind_param(1,1);
check_error("BIND PARAM");
$sth->bind_param(2,'a');
check_error("BIND PARAM");
$sth->execute();
check_error("EXECUTE");

$sth->bind_param(1,2);
check_error("BIND PARAM");
$sth->bind_param(2,'b');
check_error("BIND PARAM");
$sth->execute();
check_error("EXECUTE");

$sth->bind_param(1,3);
check_error("BIND PARAM");
$sth->bind_param(2,'c');
check_error("BIND PARAM");
$sth->execute();
check_error("EXECUTE");

$sth->finish();
check_error("FINISH");

$dbh->disconnect();
check_error("DISCONNECT");

@ids = (1, 2, 3);
@values = ('a', 'b', 'c');

###################################################################
# Connect with schema MAGIC
###################################################################

my @row;
%ops = ( PrintError => 0,
         db2_set_schema => "MAGIC");
$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD, \%ops);
check_error("CONNECT");

if ($DBI::err == 0)
{

  my $stmt = "SELECT * FROM MAGICTEST";
  my $sth = $dbh->prepare($stmt);
  check_error("PREPARE");
  $sth->execute();

  my $counter = 0;
  while (my @row = $sth->fetchrow){
      $temp_id = $row[0];
      $temp_value = $row[1];
      check_error("FETCHROW");
      check_value("FETCHROW", "temp_id", $ids[$counter], TRUE, TRUE);
      check_value("FETCHROW", "temp_value", $values[$counter], TRUE, FALSE);
      $counter++;
  }

  $sth->finish();
  check_error("FINISH");

  $dbh->disconnect();
  check_error("DISCONNECT");

}

fvt_end_testcase($testcase, $success);
