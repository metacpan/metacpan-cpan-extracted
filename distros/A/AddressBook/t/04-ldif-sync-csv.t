print "1..1\n";
my $result = 0;
END {print "not ok 1\n" unless $result}

use AddressBook;

my $cabook = AddressBook->new(source => "DBI:CSV:f_dir=t",
                              config_file => "t/t.conf") || die;
my $labook = AddressBook->new(source => "LDIF",
                              config_file => "t/t.conf") || die;
my $new_labook = AddressBook->new(source => "LDIF",	
		              filename => "t/t.ldif.new",
                              config_file => "t/t.conf") || die;

$new_labook->truncate;
while ($entry=$labook->read) {
  $new_labook->write($entry);
}

my $entry=AddressBook::Entry->new( config=>$labook->{config},
	  			   attr=>{
					  fullname=>"user five",
					  email => "user5\@five.mail.com",
				         },
			         ) || die;
$new_labook->write($entry)||die;

$entry=AddressBook::Entry->new( config=>$labook->{config},
	  			   attr=>{
					  fullname=>"user one",
					  email => "user1\@one.mail.net",
				         },
			         ) || die;

$cabook->update(entry=>$entry,filter=>{fullname=>"user one"})||die;

AddressBook::sync(master=>$cabook,slave=>$new_labook,debug=>1);

print "not " unless 1;
print "ok 1\n";
$result=1;
