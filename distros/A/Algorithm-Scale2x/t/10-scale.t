use Test::More tests => 5;

use strict;
use warnings;

BEGIN {
    use_ok( 'Algorithm::Scale2x' );
}

{   # case 1 == 7 and 3 == 5
    my @in         = qw( 0 1 0 2 0 2 0 1 0 );
    my @out_expect = ( 0 ) x 4;

    my @out = Algorithm::Scale2x::scale2x( @in );
    is_deeply( \@out, \@out_expect, 'scale2x' );
}

{   # case 1 != 7 and 3 != 5
    my @in         = qw( 0 1 0 2 0 1 0 2 0 );
    my @out_expect = qw( 0 1 2 0 );

    my @out = Algorithm::Scale2x::scale2x( @in );
    is_deeply( \@out, \@out_expect, 'scale2x' );
}

{   # case 1 == 7 and 3 == 5
    my @in         = qw( 0 1 0 2 0 2 0 1 0 );
    my @out_expect = ( 0 ) x 9;

    my @out = Algorithm::Scale2x::scale3x( @in );
    is_deeply( \@out, \@out_expect, 'scale3x' );
}

{   # case 1 != 7 and 3 != 5
    my @in         = qw( 0 1 0 2 0 1 0 2 0 );
    my @out_expect = qw( 0 0 1 0 0 0 2 0 0 );

    my @out = Algorithm::Scale2x::scale3x( @in );
    is_deeply( \@out, \@out_expect, 'scale3x' );
}
