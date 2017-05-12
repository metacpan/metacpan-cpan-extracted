print "1..1\n";
$result = 0;
END {print "not ok 1\n" unless $result}

use AddressBook;

my $labook = AddressBook->new(source => "LDAP:127.0.0.1",
                              config_file => "t/t.ldap.conf") || die;

my $count = $labook->search() || die $labook->code;
print "$count entries found\n";

print "not " unless 1;
print "ok 1\n";
$result = 1;
