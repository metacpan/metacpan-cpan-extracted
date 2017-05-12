print "1..1\n";
my $result = 0;
END {print "not ok 1\n" unless $result}

use AddressBook;

my $cabook = AddressBook->new(source => "DBI:CSV:f_dir=t",
                              config_file => "t/t.conf") || die;
my $labook = AddressBook->new(source => "LDIF",	
                              config_file => "t/t.conf") || die;

print "truncating CSV file\n";
$cabook->truncate;

while ($entry=$labook->read) {
  $cabook->add($entry);
  $added++;
}

print "$added records added to CSV file\n";
$count=$cabook->search();
print "$count records found in CSV file\n";
die if $count != $added;

print "not " unless 1;
print "ok 1\n";
$result=1;
