use strict;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Test::Usage;

files(
    c => 0,
    d => "$Bin/../lib",
    i => "$Bin/../lib",
    t => {
        c => 0,
        v => 2,
    },
);

