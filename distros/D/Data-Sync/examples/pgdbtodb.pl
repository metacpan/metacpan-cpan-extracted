
use DBI;
use strict;


my $db = DBI->connect("DBI:Pg:dbname=testdb","","");
$db->{RaiseError}=1;

use Data::Sync;
my $logfile;
open ($logfile,">","logfile.txt");

my $synchandle = Data::Sync->new(log=>$logfile,
				progressoutputs=>1);

$synchandle->source($db,
			{
				'select'=>"SELECT * from source",
				hashattributes=>["name","address","phone"],
				index=>"name"
			} );

$synchandle->target($db,{'table'=>'target',
				'index'=>'name'});

$synchandle->mappings(name=>'name',address=>'postal',phone=>'telephone');
$synchandle->transforms(telephone=>'s/o/e/');

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

