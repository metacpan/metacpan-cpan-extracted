
use DBI;
use Net::LDAP;
use strict;


my $db = DBI->connect("DBI:SQLite:dbname=testdb","","");
my $ldap = Net::LDAP->new("127.0.0.1");

my $result = $ldap->bind(dn=>"cn=Manager,dc=g0n,dc=net",
			password=>"XXXX");
if ($result->code){die $result->error}


use Data::Sync;
my $filehandle;
open ($filehandle,">","logfile.txt");

my $synchandle = Data::Sync->new(log=>$filehandle);

$synchandle->source($ldap,{filter=>"(sn=*)",
				base=>'ou=testcontainer,dc=g0n,dc=net',
				scope=>'sub',
				attrs=>['cn','postalAddress','telephoneNumber'],
				batchsize=>5});
			
$synchandle->target($db,{'table'=>'target',
				'index'=>'NAME'});

$synchandle->mappings(cn=>'NAME',postalAddress=>'POSTAL',telephoneNumber=>'TELEPHONE');
$synchandle->transforms(telephoneNumber=>'s/^(\d) (\d\d\d)/$2 $1/ ');
 $synchandle->run;


# display the contents of testdb
my $sth = $db->prepare("select * from target");

my $result = $sth->execute();

my $line;
while ($line = $sth->fetchrow_arrayref)
{
        for my $attrib (@$line)
        {
                print "$attrib\t";
        }
        print "\n";
}

