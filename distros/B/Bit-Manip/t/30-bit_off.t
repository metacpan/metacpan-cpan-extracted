use warnings;
use strict;

use Bit::Manip qw(:all);
use Test::More;

{   # 255

    my $d = 255;
    my @v = qw(
        254 253 251 247 
        239 223 191 127
    );

    for (0..7){
        my $x = bit_off($d, $_);
        is $x, $v[$_], "turning off bit $_ on $d ok";
    }
}

{ # 65535

    my $d = 65535;
    my @v = qw(
        65534 65533 65531 65527 65519 65503 65471
        65407 65279 65023 64511 63487 61439 57343
        49151 32767
   );

    for (0..15){
        my $x = bit_off($d, $_);
        is $x, $v[$_], "turning off bit $_ on $d ok";
    }
}

done_testing();

