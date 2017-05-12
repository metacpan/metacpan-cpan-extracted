use strict;
use warnings;

use Bit::Manip qw(:all);
use Test::More;

{ # valid

    is bit_count(0x01), 1, "0x01 is 1 bits";
    is bit_count(0x01, 1), 1, "set bits is 1";

    is bit_count(0x02), 2, "0x02 is 2 bits";
    is bit_count(0x02, 1), 1, "set bits is 1";

    is bit_count(0x03), 2, "0x03 is 2 bits";
    is bit_count(0x03, 1), 2, "set bits is 1";

    is bit_count(0x04), 3, "0x04 is 3 bits";
    is bit_count(0x04, 1), 1, "set bits is 1";

    is bit_count(0x05), 3, "0x05 is 3 bits";
    is bit_count(0x05, 1), 2, "set bits is 1";

    is bit_count(0x06), 3, "0x06 is 3 bits";
    is bit_count(0x06, 1), 2, "set bits is 1";

    is bit_count(0x07), 3, "0x07 is 3 bits";
    is bit_count(0x07, 1), 3, "set bits is 1";

    is bit_count(0x08), 4, "0x08 is 3 bits";
    is bit_count(0x08, 1), 1, "set bits is 1";

    is bit_count(0x09), 4, "0x09 is 3 bits";
    is bit_count(0x09, 1), 2, "set bits is 1";

    is bit_count(0x0a), 4, "0x0A is 3 bits";
    is bit_count(0x0a, 1), 2, "set bits is 1";

    is bit_count(0x0b), 4, "0x0B is 3 bits";
    is bit_count(0x0b, 1), 3, "set bits is 1";

    is bit_count(0x0c), 4, "0x0C is 3 bits";
    is bit_count(0x0c, 1), 2, "set bits is 1";

    is bit_count(0x0d), 4, "0x0D is 3 bits";
    is bit_count(0x0d, 1), 3, "set bits is 1";

    is bit_count(0x0e), 4, "0x0E is 3 bits";
    is bit_count(0x0e, 1), 3, "set bits is 1";

    is bit_count(0x0f), 4, "0x0F is 4 bits";
    is bit_count(0x0f, 1), 4, "set bits is 1";

    is bit_count(0x10), 5, "0x10 is 5 bits";
    is bit_count(0x20), 6, "0x20 is 6 bits";
    is bit_count(0x30), 6, "0x30 is 6 bits";
    is bit_count(0x40), 7, "0x40 is 7 bits";
    is bit_count(0x50), 7, "0x50 is 7 bits";
    is bit_count(0x60), 7, "0x60 is 7 bits";
    is bit_count(0x70), 7, "0x70 is 7 bits";
    is bit_count(0x80), 8, "0x80 is 8 bits";
    is bit_count(0x90), 8, "0x90 is 8 bits";


    is bit_count(0x100), 9, "0x100 is 9 bits";
    is bit_count(0x1ff), 9, "0x1FF is 9 bits";
    is bit_count(0x200), 10, "0x200 is 10 bits";

    is bit_count(0xC00), 12, "0xC00 is 12 bits";

    is bit_count(0xFF), 8, "0xFF is 8 bits";
    is bit_count(0xFFFF), 16, "0xFFFF is 16 bits";
    is bit_count(0xFFFFFF), 24, "0xFF is 24 bits";
    is bit_count(0xFFFFFFFF), 32, "0xFF is 32 bits";
}

{ # bad params

    my $ok;

    $ok = eval { bit_count(); 1; };
    is $ok, undef, "dies if no param";

    $ok = eval { bit_count('a'); 1; };
    is $ok, undef, "dies if param isn't a number ok";
}

done_testing();

