
use DBI;
use strict;


my $db = DBI->connect("DBI:SQLite:dbname=testdb","","");

use Data::Sync;
my $logfile;
open ($logfile,">","logfile.txt");

my $synchandle = Data::Sync->new(log=>$logfile);

$synchandle->source($db,{'select'=>"SELECT * from source"});
$synchandle->target($db,{'table'=>'target',
				'index'=>'NAME'});

$synchandle->mappings(NAME=>'NAME',ADDRESS=>'POSTAL',PHONE=>'TELEPHONE');
$synchandle->transforms(TELEPHONE=>'s/o/e/');

$synchandle->save("config.dds");

# display the contents of testdb
my $sth = $db->prepare("select * from target");

my $result = $sth->execute();

my $line;
while ($line = $sth->fetchrow_arrayref)
{
	print join "\t",@$line;
	print "\n";
}

