#!perl -w
# $Id$


use strict;
use DBI;

sub printtable($) {
   my $dbh = shift;
   my $sthread = $dbh->prepare("select TypeName, ProvLevel1, ProvLevel2, Action from perl_test_dbd1 order by typename");
   $sthread->execute;
   my @row;
   while (@row = $sthread->fetchrow_array) {
      print join(', ', @row), "\n";
   }
   print "-----\n";
}



my $dbh = DBI->connect();

$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
$dbh -> {LongReadLen} = 100000;
$dbh -> {LongTruncOk} = 0;

eval {$dbh->do("DROP TABLE perl_test_dbd1");};
eval {$dbh->do("DROP TABLE perl_test_dbd2");};

$dbh->do("CREATE TABLE perl_test_dbd1 (" .
	    " [TypeName] [varchar] (50) NOT NULL ," .
	    " [ProvLevel1] [money] NOT NULL ," .
	    " [ProvLevel2] [money] NOT NULL , " .
	    "[Action] [tinyint] NOT NULL) ");

$dbh->do("ALTER TABLE perl_test_dbd1 WITH NOCHECK ADD" .
	    " CONSTRAINT [PK_Test1] PRIMARY KEY  CLUSTERED" .
	    " ([TypeName])");

$dbh->do("ALTER TABLE perl_test_dbd1 WITH NOCHECK ADD" .
	    " CONSTRAINT [DF_Test1_ProvLevel1] DEFAULT (0.0000) FOR [ProvLevel1]," .
	    " CONSTRAINT [DF_Test1_ProvLevel2] DEFAULT (0.0000) FOR [ProvLevel2]," .
	    " CONSTRAINT [DF_Test1_Action] DEFAULT (0) FOR [Action]");

$dbh->do("CREATE TABLE perl_test_dbd2 (i INTEGER)");

unlink "dbitrace.log" if (-e "dbitrace.log");

$dbh->trace(9, "dbitrace.log");
# Insert a row into table1, either directly or indirectly:
my $direct = 0;

# check do first.
$dbh->do("INSERT INTO Perl_Test_Dbd1 (TypeName,ProvLevel1,ProvLevel2,Action) VALUES ('A',CONVERT(money,0),CONVERT(money,0),0)");
printtable($dbh);

my @types = ('B', 'C');
my $typename;

my $sth = $dbh->prepare("INSERT INTO Perl_Test_Dbd1 (TypeName,ProvLevel1,ProvLevel2,Action) VALUES (?,0,0,0)");
foreach $typename (@types) {
   $sth->execute($typename);
}
printtable($dbh);

my @types1 = ('D', 'E');
my @values1_1 = ("9.33", "1,323.01");
my @values1_2 = ("10.33", "1,324.01");
my $i = 0;
$sth = $dbh->prepare("INSERT INTO Perl_Test_Dbd1 (TypeName,ProvLevel1,ProvLevel2,Action) VALUES (?,CONVERT(money,?),CONVERT(money,?),0)");
for ($i = 0; $i < @types1; $i++) {
   $sth->execute($types1[$i], $values1_1[$i], $values1_2[$i]);
}
printtable($dbh);


my @types2 = ('A', 'B', 'C', 'D', 'E');
my @values2_1 = ("1.33", "1,333", "42", "53", "52");
my @values2_2 = ("2.33", "1,324.01", "234", "232", "220");
$i = 0;
$sth = $dbh->prepare("update Perl_Test_Dbd1 SET Provlevel1=CONVERT(money,?), provlevel2=CONVERT(money,?) where TypeName=?");
for ($i = 0; $i < @types2; $i++) {
   $sth->execute($values2_1[$i], $values2_2[$i], $types2[$i]);
}
printtable($dbh);


$dbh->disconnect;

