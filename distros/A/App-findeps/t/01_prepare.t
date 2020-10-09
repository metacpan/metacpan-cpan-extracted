use strict;
use warnings;

use Test::More 0.98 tests => 24;
use FastGlob qw(glob);

my @files = &glob('t/scripts/*/*.pl');

for (@files) {
    my $done = qx"$^X $_ 2>&1";
    like $done, qr/^(?:Can't locate Dummy|Base class package "Dummy" is empty.)/,
        "test file $_ failed as expected";
}

done_testing;
