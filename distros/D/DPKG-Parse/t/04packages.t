use Test::More tests => 9;

use Data::Dumper;
use DPKG::Parse::Packages;

my $packages = DPKG::Parse::Packages->new('filename' => './t/data/Packages');
$packages->parse;

isa_ok($packages, "DPKG::Parse::Packages");

my $array = $packages->entryarray;
ok(scalar(@{$array}) == 3, "Parsed 3 Entries");

my $dchess = $packages->get_package('name' => '3dchess');
isa_ok($dchess, "DPKG::Parse::Entry");
is($dchess->package, "3dchess", "Package name is 3dchess");

my $ddesktop = $packages->get_package('name' => '3ddesktop');
isa_ok($ddesktop, "DPKG::Parse::Entry");
is($ddesktop->package, "3ddesktop", "Package name is 3ddesktop");

my $counter = 0;
while (my $entry = $packages->next_package) {
    if ($counter == 0) {
        is($entry->package, "3dchess", "First is 3dchess");
    } elsif ($counter == 1) {
        is($entry->package, "3ddesktop", "Second is 3ddesktop");
    } elsif ($counter == 2) {
        is($entry->package, "44bsd-rdist", "Third is 44bsd-rdist");
    } else {
        die "Should not ever be here!";
    }
    $counter++;
}

