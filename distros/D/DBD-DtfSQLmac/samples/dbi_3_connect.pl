#!perl -w

use DBI;
use strict;

my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$//; # get rid of the trailing colon, if any
my $db_name = $curdir . ':SampleDB.dtf';

die "The sample database 'SampleDB.dtf' doesn't exist in the current directory" unless (-e $db_name);

print "Sample: [Database: $db_name]\n";
print "        dtF/SQL allows only one connection at a time.\n";
print "        Let's see what happens if we try a second connection to a database.\n\n";


my $dsn = "dbi:DtfSQLmac:$db_name";

print "First connection ... ";
my $dbh1 = DBI->connect(	$dsn, 
							'dtfadm', 
							'dtfadm', 
							{RaiseError => 1, AutoCommit => 0} 
					   ) ||  die "Can't connect to database: " . DBI->errstr; 
print "ok.\n\n";

print "Try a second connection ...\nThis should fail. Please ignore the error message.\n\n";
 
eval { 
	my $dbh2 = DBI->connect($dsn, 'user', 'password', {AutoCommit => 0}) || die ;	
};


print "\n\nDisconnecting connection 1 ... ";
$dbh1->disconnect;
print "ok.\n\n";

print "Sent a ping to connection 1 to see if the connection is alive (this should fail).\n\n";
my $alive = $dbh1->ping();
print "ping ...";
($alive) ? print " still alive.\n\n" : print " connection dead.\n\n";


print "Try a second connection after the first has been closed (this should work) ... ";
my $dbh3 = DBI->connect(	$dsn, 
							'dtfadm', 
							'dtfadm', 
							{RaiseError => 1, AutoCommit => 0}
					   ) ||  die "Can't connect to database: " . DBI->errstr;
print "ok.\n\n";

print "Sent a ping to the second connection to see if connection is alive (this should work).\n\n";
$alive = $dbh3->ping();
print "ping ...";
($alive) ? print " still alive.\n\n" : print " connection dead.\n\n";

print "\nDisconnecting ... ";
$dbh3->disconnect;
print "ok.\n\n";

1;


