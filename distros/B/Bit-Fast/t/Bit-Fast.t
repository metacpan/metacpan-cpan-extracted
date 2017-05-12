use strict;
use warnings;

use Config;
use Test::More tests => 200;
#use Test::More qw(no_plan);
BEGIN {
    if (8 == $Config{longsize}) {
        use_ok('Bit::Fast', 'popcount', 'popcountl');
    } else {
        use_ok('Bit::Fast', 'popcount');
    }
}

is popcount(0),     0, "number of 1-bits in 0 is 0";
is popcount(1),     1, "number of 1-bits in 1 is 1";
is popcount(2),     1, "number of 1-bits in 2 is 1";
is popcount(3),     2, "number of 1-bits in 3 is 2";
is popcount(31),    5, "number of 1-bits in 31 is 5";
is popcount(32),    1, "number of 1-bits in 32 is 1";
is popcount(129),   2, "number of 1-bits in 129 is 2";

for (my $i = 0; $i < 32; ++$i) {
    my $n = 1 << $i;
    is popcount($n), 1, "number of bits in $n is 1";
    --$n;
    is popcount($n), $i, "number of bits in $n is $i";
}

SKIP: {
    skip "32-bit build of Perl", 128 if $Config{longsize} == 4;
    for (my $i = 0; $i < 32; ++$i) {
        my $n = 1 << $i;
        is popcountl($n), 1, "number of bits in $n is 1";
        --$n;
        is popcountl($n), $i, "number of bits in $n is $i";
    }
    for (my $i = 32; $i < 63; ++$i) {
        my $n = 1 << $i;
        is popcountl($n), 1, "number of bits in $n is 1";
        --$n;
        is popcountl($n), $i, "number of bits in $n is $i";
    }
    is popcountl((129 << 32) | 129), 4;
    is popcountl((3 << 60) | (129 << 32) | 129), 6;
};
