#!perl

use strict;
use warnings;

use Test::More;    # just used for illustration purpose

use B::COW qw{:all};

if ( can_cow() ) {    # $] >= 5.020
    ok !is_cow(undef);

    my $str = "abcdef";
    ok is_cow($str);
    is cowrefcnt($str), 1;

    my @a;
    push @a, $str for 1 .. 100;

    ok is_cow($str);
    ok is_cow( $a[0] );
    ok is_cow( $a[99] );
    is cowrefcnt($str), 101;
    is cowrefcnt( $a[-1] ), 101;

    delete $a[99];
    is cowrefcnt($str), 100;
    is cowrefcnt( $a[-1] ), 100;

    {
        my %h = ( 'a' .. 'd' );
        foreach my $k ( sort keys %h ) {
            ok is_cow($k);
            is cowrefcnt($k), 0;
        }
    }

}
else {
    my $str = "abcdef";
    is is_cow($str),    undef;
    is cowrefcnt($str), undef;
    is cowrefcnt_max(), undef;
}

done_testing;
