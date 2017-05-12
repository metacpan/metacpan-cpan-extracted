use warnings;
use strict;

use Bit::Manip qw(:all);
use Test::More;

{   # 0..255

    my $d = 0;
    my @v = qw(
        1 2 4 8 16 32 64 128
    );

    for (0..7){
        my $x = bit_on($d, $_);
        is $x, $v[$_], "turning on bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}

{ # 0 - 15 bits

    my $d = 0;
    my @v = qw(
        1 2 4 8 16 32 64 128
        256 512 1024 2048
        4096 8192 16384 32768
    );

    for (0..15){
        my $x = bit_on($d, $_);
        is $x, $v[$_], "turning on bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}

done_testing();

