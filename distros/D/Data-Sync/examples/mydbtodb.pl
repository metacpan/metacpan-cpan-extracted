
use DBI;
use strict;


my $db = DBI->connect("DBI:mysql:dbname=testdb","root","");

use Data::Sync;
my $logfile;
open ($logfile,">","logfile.txt");

my $synchandle = Data::Sync->new(log=>$logfile,
				progressoutputs=>1);

$synchandle->source($db,
			{
				'select'=>"SELECT * from source",
				hashattributes=>["NAME","ADDRESS","PHONE"],
				index=>"NAME"
			} );

$synchandle->target($db,{'table'=>'target',
				'index'=>'NAME'});

$synchandle->mappings(NAME=>'NAME',ADDRESS=>'POSTAL',PHONE=>'TELEPHONE');
$synchandle->transforms(TELEPHONE=>'s/o/e/');

print $synchandle->run;

print $synchandle->error."\n";

# display the contents of testdb
my $sth = $db->prepare("select * from target");

my $result = $sth->execute();

my $line;
while ($line = $sth->fetchrow_arrayref)
{
	print join "\t",@$line;
	print "\n";
}

