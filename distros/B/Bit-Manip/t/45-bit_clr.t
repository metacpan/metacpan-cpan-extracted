use warnings;
use strict;

use Bit::Manip qw(:all);
use Test::More;

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
