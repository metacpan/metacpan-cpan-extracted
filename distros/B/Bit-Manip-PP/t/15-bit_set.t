use warnings;
use strict;

use Bit::Manip::PP qw(:all);
use Test::More;

is bin(bit_set(8, 0, 1, 0b1)), '1001', "8, 0, 1 ok";
is bin(bit_set(8, 1, 1, 0b1)), '1010', "8, 1, 1 ok";
is bin(bit_set(8, 2, 1, 0b1)), '1100', "8, 2, 1 ok";

is bin(bit_set(8, 0, 3, 0b111)), '1111', "8, 0, 0b111 ok";
is bin(bit_set(8, 1, 3, 0b011)), '110', "8, 1, 0b011 ok";
is bin(bit_set(8, 2, 1, 0b1)), '1100', "8, 2, 0b01 ok";
is bin(bit_set(8, 2, 3, 0b101)), '10100', "8, 2, 0b01 ok";

is bin(bit_set(256, 0, 1, 0b1)), '100000001', "256, 0, 1 ok";
is bin(bit_set(256, 1, 1, 0b1)), '100000010', "256, 1, 1 ok";
is bin(bit_set(256, 2, 1, 0b1)), '100000100', "256, 2, 1 ok";
is bin(bit_set(256, 3, 1, 0b1)), '100001000', "256, 3, 1 ok";
is bin(bit_set(256, 4, 1, 0b1)), '100010000', "256, 4, 1 ok";
is bin(bit_set(256, 5, 1, 0b1)), '100100000', "256, 5, 1 ok";
is bin(bit_set(256, 6, 1, 0b1)), '101000000', "256, 6, 1 ok";
is bin(bit_set(256, 7, 1, 0b1)), '110000000', "256, 7, 1 ok";

is bin(bit_set(256, 0, 8, 0xFF)), '111111111', "256, 0, 255 ok";
is bin(bit_set(256, 0, 2, 0b11)), '100000011', "256, 0, 0b11 ok";
is bin(bit_set(256, 0, 3, 0b111)), '100000111', "256, 0, 0b111 ok";
is bin(bit_set(256, 0, 4, 0b1111)), '100001111', "256, 0, 0b1111 ok";

is bin(bit_set(256, 3, 1, 0b01)), '100001000', "256, 3, 0b01 ok";
is bin(bit_set(256, 3, 2, 0b10)), '100010000', "256, 3, 0b10 ok";
is bin(bit_set(256, 3, 2, 0b11)), '100011000', "256, 3, 0b11 ok";
is bin(bit_set(256, 3, 3, 0b101)), '100101000', "256, 3, 0b101 ok";
is bin(bit_set(256, 3, 3, 0b111)), '100111000', "256, 3, 0b111 ok";

is bin(bit_set(256, 7, 1, 0b1)), '110000000', "256, 7, 0b1 ok";

is bin(bit_set(32768, 7, 3, 0b001)), '1000000010000000', "32768, 7, 0b001 ok";
is bin(bit_set(32768, 7, 3, 0b010)), '1000000100000000', "32768, 7, 0b010 ok";
is bin(bit_set(32768, 7, 3, 0b011)), '1000000110000000', "32768, 7, 0b011 ok";
is bin(bit_set(32768, 7, 3, 0b100)), '1000001000000000', "32768, 7, 0b100 ok";
is bin(bit_set(32768, 7, 3, 0b100)), '1000001000000000', "32768, 7, 0b100 ok";
is bin(bit_set(32768, 7, 3, 0b101)), '1000001010000000', "32768, 7, 0b101 ok";
is bin(bit_set(32768, 7, 3, 0b110)), '1000001100000000', "32768, 7, 0b110 ok";
is bin(bit_set(32768, 7, 3, 0b111)), '1000001110000000', "32768, 7, 0b111 ok";

# bad bit count

is bin(bit_set(7, 0, 3, 0b011)), '11', "leading zero set ok";

# bad number of params

my $ok = eval {
    bit_set(1, 2, 3);
    1;
};

is $ok, undef, "dies if we don't have enough params";
like $@, qr/requires four params/, "...and error message is ok";

$ok = eval {
    bit_set(1, 2, 3, 4, 5);
    1;
};

is $ok, undef, "dies with too many params";
like $@, qr/requires four params/, "...and error message is ok";

# scalar reference

my $test_data_ref = 32768;

bit_set(\$test_data_ref, 7, 3, 0b111);
is bin($test_data_ref), '1000001110000000', "32768, 7, 0b111 ok as scalar ref";

sub bin {
    return sprintf "%b", $_[0];
}

done_testing();
