#!perl -w
# $Id$

use DBI;

my $dbh = DBI->connect()
	or die "$DBI::errstr\n";

$dbh->{PrintError} = 0;
eval {
   # if it's not already created, the eval will silently ignore this
   $dbh->do("drop table longtest;");
};

$dbh->{RaiseError} = 1;
$dbh->do("create table longtest (id integer primary key, value CLOB)");

my %foo;

$foo{2} = "Hello there.";
$foo{1} = "This is a test of CLOB.  "x200;
my $tracefile = "dbitrace.log";
if (-e $tracefile) {
   unlink($tracefile);
}
DBI->trace(9,$tracefile);
my $sth = $dbh->prepare("insert into longtest values (?, ?)");
$sth->execute((2, $foo{2}));
$sth->execute((1, $foo{1}));

$dbh->{LongReadLen} = 2000000;
my $sth2 = $dbh->prepare("select id, value from longtest order by id");
$sth2->execute;
my @row;
while (@row = $sth2->fetchrow_array) {
   print join(', ', @row), "\n";
}

$dbh->disconnect;

