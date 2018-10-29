#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Devel::Peek;

use B::COW qw{:all};

if ( $] >= 5.020 ) {
    ok can_cow(), "can cow with Perl $]";    

    ok !is_cow(undef), "!is_cow(undef)";
    my $str = "abcdef";
    
    ok is_cow($str), "is_cow('abcdef')";
    is cowrefcnt( $str ), 1, "cowrefcnt is set to 1" or Dump($str);

    my $b = $str;

    ok is_cow($b), "is_cow('abcdef')";
    is cowrefcnt( $b ), 2, "cowrefcnt for b is set to 2" or Dump($b);
    is cowrefcnt( $str ), 2, "cowrefcnt for str is set to 2" or Dump($str);
    is cowrefcnt_max() , 255, "cowrefcnt_max: might need to adjust...";

    {
        my $c = $b . 'uncow';
        ok is_cow($b), "b is_cow";
        ok !is_cow($c), "c !is_cow";
        is cowrefcnt( $c ), undef, "cowrefcnt on uncowed SvPV";
    }

    {
        my $str = "this is a string";
        my @a;
        push @a, $str for 1..100;

        ok is_cow( $str);
        ok is_cow( $a[0] );
        ok is_cow( $a[99] );
        is cowrefcnt( $str ), 101;
        is cowrefcnt( $a[0] ), 101;
        is cowrefcnt( $a[99] ), 101;

        delete $a[99];
        is cowrefcnt( $str ), 100, "cowrefcnt decrease to 100";
        is cowrefcnt( $a[-1] ), 100, "cowrefcnt decrease to 100";

    }

    {
        my %h = ( 'a'..'d' );
        foreach my $k ( sort keys %h ) {
            ok is_cow( $k ), "key $k is cowed";
            is cowrefcnt( $k ), 0, "hash key $k cowrefcnt is 0" or Dump($k);
        }
    }

} else {
    ok !can_cow(), "cannot cow with Perl $]";
    my $str = "abcdef";
    is is_cow($str), undef, "is_cow";
    is cowrefcnt($str), undef, "cowrefcnt";
    is cowrefcnt_max(), undef, 'cowrefcnt_max'
}

done_testing;
