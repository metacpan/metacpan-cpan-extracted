#!perl -w
# $Id$

use strict;
use DBI;

# Connect to the database, and create a table and stored procedure:
my $dbh=DBI->connect("dbi:ODBC:PERL_TEST_SQLSERVER", $ENV{DBI_USER}, $ENV{DBI_PASS}, { RaiseError => 1 }) or die "Can't connect";
eval {$dbh->do("DROP PROCEDURE proc1");};
my $proc1 =
    "CREATE PROCEDURE proc1 ".
    "	\@MaxOrderID1      int OUTPUT, " .
    "	\@MaxOrderID2    varchar(32) OUTPUT AS " .
    "	SELECT \@MaxOrderid1 = 200 + 100 " . 
    "	SELECT \@MaxOrderid2 = '200' + '100' ".
    "   return (0) ";


eval {$dbh->do ($proc1);};
if ($@) {
   print "Error creating procedure.\n$@\n";
}

# Execute it:
if (-e "dbitrace.log") {
   unlink("dbitrace.log");
}
$dbh->trace(9, "dbitrace.log");
my $sth = $dbh->prepare ("{call proc1(?, ?) }");
my $retValue1;
my $retValue2;
$sth->bind_param_inout(1,\$retValue1, 32);
$sth->bind_param_inout(2,\$retValue2, 32);
$sth->execute;
print "$retValue1, $retValue2\n";
$dbh->disconnect;
