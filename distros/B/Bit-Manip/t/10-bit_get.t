use strict;
use warnings;

use Bit::Manip qw(:all);
use Test::More;

{ # 0xFF

    my $d = 0xFFFF; # 65535
    my $s = 16;
    my $c = 16;

    for (0..15){
        my $exp = (2 ** $c) - 1;
        $c--;

        my $r = bit_get($d, $s, $_);
        is $r, $exp, "d: $d, s: $s, e: $_, == $r ok";
    }
}

{ # bad params

    my $d = 0xFF;
    my $ok;

    # msb == -1

    $ok = eval { bit_get($d, -1); 1; };
    is $ok, undef, "msb param -1 dies ok";
    like $@, qr/\$msb param/, "...with ok error";

    # lsb == -1

    $ok = eval { bit_get($d, 16, -1); 1; };
    is $ok, undef, "lsb param -1 dies ok";
    like $@, qr/\$lsb param/, "...with ok error";

    # lsb < msb

    $ok = eval { bit_get($d, 8, 9); 1; };
    is $ok, undef, "lsb < msb dies ok";
    like $@, qr/\$lsb param/, "...with ok error";

     # lsb == msb

    $ok = eval { bit_get($d, 8, 8); 1; };
    is $ok, 1, "lsb == msb dies ok";
}
done_testing();
