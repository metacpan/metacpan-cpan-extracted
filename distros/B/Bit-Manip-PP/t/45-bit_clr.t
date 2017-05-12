use warnings;
use strict;

use Bit::Manip::PP qw(:all);
use Test::More;

{
    # refs

    my $d;

    $d = 7;

    bit_clr(\$d, 0, 1, 0b1);
    is bit_bin($d), '110', "7, 0, 1 ref ok";

    bit_clr(\$d, 1, 1, 0b1);
    is bit_bin($d), '100', "7, 1, 1 ref ok";

    bit_clr(\$d, 2, 1, 0b1);
    is bit_bin($d), '0', "7, 2, 1 ref ok";

    $d = 65535;

    my @ret = qw (
        65534 65532 65528 65520 65504 65472
        65408 65280 65024 64512 63488 61440
        57344 49152 32768 0
        );

    my $c = 0;

    for (0 .. 15) {
        bit_clr(\$d, $_, 1, 0b1);
        is $d, $ret[$c], "65535, $_, 1 ref ok";
        $c++;
    }
}

is bin(bit_clr(7, 0, 1)), '110', "7, 0 ok";
is bin(bit_clr(7, 1, 1)), '101', "7, 1 ok";
is bin(bit_clr(7, 2, 1)), '11', "7, 2 ok";

is bin(bit_clr(63, 0, 3)), '111000', "63, 0, 3 ok";
is bin(bit_clr(63, 1, 3)), '110001', "63, 1, 3 ok";
is bin(bit_clr(63, 2, 1)), '111011', "63, 2, 1 ok";
is bin(bit_clr(63, 2, 3)), '100011', "63, 2, 3 ok";

is bin(bit_clr(1023, 0, 1)), '1111111110', "1023, 0, 1 ok";
is bin(bit_clr(1023, 1, 1)), '1111111101', "1023, 1, 1 ok";
is bin(bit_clr(1023, 2, 1)), '1111111011', "1023, 2, 1 ok";
is bin(bit_clr(1023, 3, 1)), '1111110111', "1023, 3, 1 ok";
is bin(bit_clr(1023, 4, 1)), '1111101111', "1023, 4, 1 ok";
is bin(bit_clr(1023, 5, 1)), '1111011111', "1023, 5, 1 ok";
is bin(bit_clr(1023, 6, 1)), '1110111111', "1023, 6, 1 ok";
is bin(bit_clr(1023, 7, 1)), '1101111111', "1023, 7, 1 ok";
is bin(bit_clr(1023, 8, 1)), '1011111111', "1023, 8, 1 ok";
is bin(bit_clr(1023, 9, 1)), '111111111', "1023, 9, 1 ok";


is bin(bit_clr(255, 0, 8)), '0', "255, 0, 8 ok";
is bin(bit_clr(255, 0, 2)), '11111100', "255, 0, 2 ok";
is bin(bit_clr(255, 0, 3)), '11111000', "255, 0, 3 ok";
is bin(bit_clr(255, 0, 4)), '11110000', "255, 0, 4 ok";

is bin(bit_clr(255, 3, 1)), '11110111', "255, 3, 1 ok";
is bin(bit_clr(255, 3, 2)), '11100111', "255, 3, 2 ok";
is bin(bit_clr(255, 3, 3)), '11000111', "255, 3, 3 ok";
is bin(bit_clr(255, 7, 1)), '1111111', "255, 7, 1 ok";

sub bin {
    return sprintf "%b", $_[0];
}

done_testing();
