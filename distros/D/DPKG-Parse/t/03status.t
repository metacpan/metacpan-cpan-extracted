use Test::More tests => 10;

use Data::Dumper;
use DPKG::Parse::Status;

my $status = DPKG::Parse::Status->new('filename' => './t/data/status');
$status->parse;

isa_ok($status, "DPKG::Parse::Status");

my $array = $status->entryarray;
ok(scalar(@{$array}) == 4, "Parsed 4 Entries");

my $dlint      = $status->get_package('name' => 'dlint');
isa_ok($dlint, "DPKG::Parse::Entry");
is($dlint->package, "dlint", "Package name is dlint");

my $alsaplayer = $status->get_package('name' => 'alsaplayer');
isa_ok($alsaplayer, "DPKG::Parse::Entry");
is($alsaplayer->package, "alsaplayer", "Package name is alsaplayer");

my $counter = 0;
while (my $entry = $status->next_package) {
    if ($counter == 0) {
        is($entry->package, "cl-infix", "First is cl-infix");
    } elsif ($counter == 1) {
        is($entry->package, "dlint", "Second is dlint");
    } elsif ($counter == 2) {
        is($entry->package, "glotski", "Third is glotski");
    } elsif ($counter == 3) {
        is($entry->package, "alsaplayer", "Fourth is glotski");
    } else {
        die "Should not ever be here!";
    }
    $counter++;
}

