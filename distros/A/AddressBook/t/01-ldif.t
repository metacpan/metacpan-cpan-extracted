print "1..1\n";
my $result = 0;
END {print "not ok 1\n" unless $result}

use AddressBook;

my $labook = AddressBook->new(source => "LDIF",
                              config_file => "t/t.conf") || die;
my $tabook = AddressBook->new(source => "Text",	
                              config_file => "t/t.conf") || die;
my $new_labook = AddressBook->new(source => "LDIF",
			      filename => "t/t.ldif.new",
			      config => $labook->{config}) || die;

$new_labook->truncate;
while ($entry=$labook->read) {
  $tabook->write($entry);
  $new_labook->write($entry);
}

my $entry=AddressBook::Entry->new( config=>$labook->{config},
	  			   attr=>{
					  fullname=>"user four",
					  email => "user4\@four.mail.com",
				         },
			         ) || die;
$new_labook->write($entry) || die ;

print "not " unless 1;
print "ok 1\n";
$result=1;
