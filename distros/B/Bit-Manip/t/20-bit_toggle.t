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
        my $x = bit_toggle($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}

{   # 0 - 8 bit

    my $d = 0;
    my @v = qw(
        1 2 4 8 16
        32 64 128
    );

    for (0..7){
        my $x = bit_toggle($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
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
        my $x = bit_toggle($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
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
        my $x = bit_toggle($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
    }
}

{   # 255

    my $d = 255;
    my @v = qw(
        254 253 251 247
        239 223 191 127
    );

    for (0..7){
        my $x = bit_toggle($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}

{   # tog() 0 - 8 bit

    my $d = 0;
    my @v = qw(
        1 2 4 8 16
        32 64 128
    );

    for (0..7){
        my $x = bit_tog($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}

{ # tog() 0 - 15 bits

    my $d = 0;
    my @v = qw(
        1 2 4 8 16 32 64 128
        256 512 1024 2048
        4096 8192 16384 32768
    );

    for (0..15){
        my $x = bit_tog($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}

{ # tog() 65535

    my $d = 65535;
    my @v = qw(
        65534 65533 65531 65527 65519 65503 65471
        65407 65279 65023 64511 63487 61439 57343
        49151 32767

   );

    for (0..15){
        my $x = bit_tog($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
    }
}
{   # tog() 255

    my $d = 255;
    my @v = qw(
        254 253 251 247
        239 223 191 127
    );

    for (0..7){
        my $x = bit_tog($d, $_);
        is $x, $v[$_], "toggling bit $_ on $d ok";
        # printf("%d: %b\n", $x, $x);
    }
}
done_testing();

