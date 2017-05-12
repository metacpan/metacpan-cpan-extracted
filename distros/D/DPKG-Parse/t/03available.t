use Test::More tests => 9;

use Data::Dumper;
use DPKG::Parse::Available;

my $available = DPKG::Parse::Available->new('filename' => './t/data/available');
$available->parse;

isa_ok($available, "DPKG::Parse::Available");

my $array = $available->entryarray;
ok(scalar(@{$array}) == 3, "Parsed 3 Entries");

my $dlint      = $available->get_package('name' => 'dlint');
isa_ok($dlint, "DPKG::Parse::Entry");
is($dlint->package, "dlint", "Package name is dlint");

my $glotski = $available->get_package('name' => 'glotski');
isa_ok($glotski, "DPKG::Parse::Entry");
is($glotski->package, "glotski", "Package name is glotski");

my $counter = 0;
while (my $entry = $available->next_package) {
    if ($counter == 0) {
        is($entry->package, "cl-infix", "First is cl-infix");
    } elsif ($counter == 1) {
        is($entry->package, "dlint", "Second is dlint");
    } elsif ($counter == 2) {
        is($entry->package, "glotski", "Third is glotski");
    } else {
        die "Should not ever be here!";
    }
    $counter++;
}

