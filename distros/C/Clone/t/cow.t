#!perl

use strict;
use warnings;

use Test::More;    # we should consider moving to Test2...
use Clone 'clone';

BEGIN {

    # Travis issue on 5.8.8 (maybe the module is too recent...)
    my $load_B_COW = eval { require B::COW; B::COW->import(q/:all/); 1 };

    if ( $@ || !$load_B_COW ) {
        plan skip_all => 'This test requires B::COW to run.';
    }
    if ( !B::COW::can_cow() ) {
        plan skip_all => 'This test is only designed to work on Perl Versions supporting COW';
    }
}

plan tests => 59;

{
    note "Simple SvPV";

    my $str = "abcdef";
    ok is_cow($str);
    is cowrefcnt($str), 1;

    my $clone = clone($str);
    ok is_cow($clone);
    is cowrefcnt($str),   2, q[the $str PV cowrefcnt is now at 2];
    is cowrefcnt($clone), 2, q[the $clone is sharing the same PV];
}

{
    note "COW SvPV used in Array";

    my $str = "abcdef";
    ok is_cow($str);
    is cowrefcnt($str), 1;

    my @a;
    push @a, $str for 1 .. 10;

    is cowrefcnt($str), 11;
    is cowrefcnt( $a[0] ),  11;
    is cowrefcnt( $a[-1] ), 11;

    my $clone_array = clone( \@a );

    is cowrefcnt($str), 21;
    is cowrefcnt( $a[-1] ), 21;
    is cowrefcnt( $clone_array->[-1] ), 21;
}

{
    note "COW SvPV used in Hashes";

    my $a_string = "something";

    my $h = {
        'a' .. 'd',
        k1        => $a_string,
        k2        => $a_string,
        $a_string => $a_string,
    };

    is cowrefcnt($a_string), 4, 'a_string PV is used 3 times';

    my $clone_h = clone($h);
    is cowrefcnt($a_string), 7, 'a_string PV is now used 5 times after clone';

    foreach my $k ( sort keys %$h ) {

        ok is_cow($k), "key is cow...";
        is cowrefcnt($k), 0, "cowrefcnt on key $k is 0...";

        my $clone_key = clone($k);
      TODO: {
            local $TODO = "losing the COW status when cowrefcnt=0...";
            ok !is_cow($clone_key), "clone_key lost its cow value (LEN=0)";
            is cowrefcnt($clone_key), undef, "clone_key has lost cow...";
        }
        is $clone_key, $k, " clone_key eq k";
    }

    my @keys       = sort keys %$h;
    my $clone_keys = clone( \@keys );
    is scalar @$clone_keys, scalar @keys, "clone keys array";

}

{
    # reproducing SEGV described as part of GH #10 - https://github.com/garu/Clone/issues/10
    note "hash with subs...";

    my $hash = {
        'caption' => {
            'db'      => 1,
            'default' => 1,
            'i18n'    => 1
        },
        'fix_db' => {
            'db'  => 1,
            'get' => sub { 1 }
        },
    };

    my $clone = clone($hash);
    ok ref $clone, "clone success - no SEGV";
}

{
    note "playing with the limit: cowrefcnt_max";

    my $max = cowrefcnt_max();
    ok $max, "we got a max";

    cmp_ok $max, '>', 2, "this should be greater than 2 :-)" or die;

    # first let's do a stop just before max
    my $str = "abcd";
    my @a;
    push @a, $str for 1 .. ( $max - 3 );
    is cowrefcnt($str), $max - 2, "we are at max-2";

    # now increase to max
    push @a, clone($str);
    is cowrefcnt($str), $max - 1, "we are now at max-1" or die;
    is cowrefcnt( $a[-1] ), $max - 1, "we are now at max-1: a[-1]";

    # now is time to bypass max
    for ( 1 .. 2 ) {
        push @a, clone($str);
        is cowrefcnt($str), $max - 1, "str stays at max -1";
        ok is_cow( $a[-1] ), "our clone is COWed when bypassing max";
        is cowrefcnt( $a[-1] ), 0, "cowrefcnt for a[-1] is 0";
    }

    is cowrefcnt( $a[-2] ), 0, "cowrefcnt for a[-2] is 0";
    is cowrefcnt( $a[-3] ), $max - 1, "cowrefcnt for a[-3] is max - 1";

    push @a, clone( $a[-1] );
    is cowrefcnt( $a[-1] ), 1, "cowrefcnt for a[-1] is 1";
    is cowrefcnt( $a[-2] ), 1, "cowrefcnt for a[-2] is 1";
    is cowrefcnt( $a[-3] ), 0, "cowrefcnt for a[-3] is 0";
    is cowrefcnt( $a[-4] ), $max - 1, "cowrefcnt for a[-4] is max - 1";

}
