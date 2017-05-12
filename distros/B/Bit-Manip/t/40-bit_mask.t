use warnings;
use strict;

use Bit::Manip qw(:all);
use Test::More;

my @d = <DATA>;
chomp @d;
my $c = 0;

{ # lsb 0

    my $lsb = 0;

    for (0..7){
        is bit_mask($_, $lsb), $d[$c], "mask for $_ on $lsb ok";
        $c++;
    }
}
{ # lsb 4

    my $lsb = 4;

    for (0..4){
        is bit_mask($_, $lsb), $d[$c], "mask for $_ on $lsb ok";
        $c++;
    }
}

{ # lsb 2

    my $lsb = 2;

    for (0..2){
        is bit_mask($_, $lsb), $d[$c], "mask for $_ on $lsb ok";
        $c++;
    }
}

done_testing();

__DATA__
0
1
3
7
15
31
63
127
0
16
48
112
240
0
4
12
