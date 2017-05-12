print "1..1\n";
my $result = 0;
END {print "not ok 1\n" unless $result}

use AddressBook;

my $habook = AddressBook->new(source => "HTML",
                              config_file => "t/t.conf") || die;
my $labook = AddressBook->new(source => "LDIF",	
                              config => $habook->{config}) || die;

while ($entry=$labook->read) {
  $habook->write($entry) || die;
}

print "not " unless 1;
print "ok 1\n";
$result=1;
