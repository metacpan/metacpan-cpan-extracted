
use DBI;
use strict;


my $db = DBI->connect("DBI:SQLite:dbname=testdb","","");

use Data::Sync;
my $logfile;
open ($logfile,">","logfile.txt");

my $synchandle = Data::Sync->new(log=>$logfile);
				
$synchandle->load("config.dds") or die "can't load because ".$synchandle->error;
$synchandle->source($db);
$synchandle->target($db);
$synchandle->run();


# display the contents of testdb
my $sth = $db->prepare("select * from target");

my $result = $sth->execute();

my $line;
while ($line = $sth->fetchrow_arrayref)
{
	print join "\t",@$line;
	print "\n";
}

