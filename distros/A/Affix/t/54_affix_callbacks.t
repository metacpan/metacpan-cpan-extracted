use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix;
use Config;
$|++;
#
use t::lib::nativecall;
#
plan skip_all => 'no support for aggregates by value' unless Affix::Feature::AggrByVal();
#
my $lib = compile_test_lib('54_affix_callbacks');
diag $lib;

#~ {
#~ use Data::Dump;
#~ ddx CodeRef [ [ Pointer [Void], Int, Int ] => Int ];
#~ ddx CodeRef [ [ Double, Str, Bool ] => Bool ];
#~ }
#
is wrap( $lib, 'cb_pii_i', [ CodeRef [ [ Pointer [Void], Int, Int ] => Int ] ] => Int )->(
    sub {
        is_deeply( \@_, [ undef, 100, 200 ], '[ Pointer [Void], Int, Int ]' );
        return 4;
    }
    ),
    4,
    '    => Int';
ok !!wrap( $lib, 'cb_dZb_b', [ CodeRef [ [ Double, Str, Bool ] => Bool ] ] => Bool )->(
    sub {
        is_deeply(
            \@_,
            [   (
                    $Config{usequadmath}       ? 9.90000000000000035527136788005009 :
                        $Config{uselongdouble} ? 9.90000000000000036 :
                        9.9
                ),
                'Hi',
                !1
            ],
            '[ Double, Str, Bool ]'
        );
        return !0;
    }
    ),
    '    => Bool';
is wrap( $lib, 'cb_v_v', [ CodeRef [ [Void] => Void ] ] => Void )->(
    sub {
        is_deeply( \@_, [], '[ Void ]' );
        return;
    }
    ),
    undef, '    => Void';
ok wrap( $lib, 'cb_b_b', [ CodeRef [ [Bool] => Bool ] ] => Bool )->(
    sub {
        is_deeply( \@_, [ !0 ], '[ Bool ]' );
        return 1;
    }
    ),
    '    => Bool [true]';
ok !wrap( $lib, 'cb_b_b', [ CodeRef [ [Bool] => Bool ] ] => Bool )->(
    sub {
        is_deeply( \@_, [ !0 ], '[ Bool ]' );
        return 0;
    }
    ),
    '    => Bool [false]';
is wrap( $lib, 'cb_c_c', [ CodeRef [ [Char] => Char ] ] => Char )->(
    sub {
        is_deeply( \@_, [ -ord 'A' ], '[ Char ]' );
        return -ord 'B';
    }
    ),
    -ord 'B', '    => Char';
is wrap( $lib, 'cb_C_C', [ CodeRef [ [UChar] => UChar ] ] => UChar )->(
    sub {
        is_deeply( \@_, [ ord 'Q' ], '[ UChar ]' );
        return ord 'Z';
    }
    ),
    ord 'Z', '    => UChar';
is wrap( $lib, 'cb_s_s', [ CodeRef [ [Short] => Short ] ] => Short )->(
    sub {
        is_deeply( \@_, [-8], '[ Short ]' );
        return -49;
    }
    ),
    -49, '    => Short';
is wrap( $lib, 'cb_S_S', [ CodeRef [ [UShort] => UShort ] ] => UShort )->(
    sub {
        is_deeply( \@_, [16], '[ UShort ]' );
        return 32;
    }
    ),
    32, '    => UShort';
is wrap( $lib, 'cb_i_i', [ CodeRef [ [Int] => Int ] ] => Int )->(
    sub {
        is_deeply( \@_, [-20], '[ Int ]' );
        return -88;
    }
    ),
    -88, '    => Int';
is wrap( $lib, 'cb_I_I', [ CodeRef [ [UInt] => UInt ] ] => UInt )->(
    sub {
        is_deeply( \@_, [44], '[ UInt ]' );
        return 32;
    }
    ),
    32, '    => UInt';
is wrap( $lib, 'cb_j_j', [ CodeRef [ [Long] => Long ] ] => Long )->(
    sub {
        is_deeply( \@_, [-3219], '[ Long ]' );
        return -76;
    }
    ),
    -76, '    => Long';
is wrap( $lib, 'cb_J_J', [ CodeRef [ [ULong] => ULong ] ] => ULong )->(
    sub {
        is_deeply( \@_, [8990], '[ ULong ]' );
        return 32;
    }
    ),
    32, '    => ULong';
is wrap( $lib, 'cb_l_l', [ CodeRef [ [LongLong] => LongLong ] ] => LongLong )->(
    sub {
        is_deeply( \@_, [-47923], '[ LongLong ]' );
        return -760093;
    }
    ),
    -760093, '    => LongLong';
is wrap( $lib, 'cb_L_L', [ CodeRef [ [ULongLong] => ULongLong ] ] => ULongLong )->(
    sub {
        is_deeply( \@_, [93294], '[ ULongLong ]' );
        return 32232;
    }
    ),
    32232, '    => ULongLong';
is wrap( $lib, 'cb_f_f', [ CodeRef [ [Float] => Float ] ] => Float )->(
    sub {
        is_deeply(
            \@_,
            [   $Config{usequadmath}       ? -99.3000030517578125 :
                    $Config{uselongdouble} ? -99.3000030517578125 :
                    -99.3000030517578
            ],
            '[ Float ]'
        );
        return -100.5;
    }
    ),
    -100.5, '    => Float';
is wrap( $lib, 'cb_d_d', [ CodeRef [ [Double] => Double ] ] => Double )->(
    sub {
        is_deeply(
            \@_,
            [   $Config{usequadmath}       ? 200.300000000000011368683772161603 :
                    $Config{uselongdouble} ? 200.300000000000011 :
                    200.3
            ],
            '[ Double ]'
        );
        return 0.4;
    }
    ),
    ( $Config{usequadmath} ? 0.400000000000000022204460492503131 :
        $Config{uselongdouble} ? 0.400000000000000022 :
        .4 ), '    => Double';
is wrap( $lib, 'cb_Z_Z', [ CodeRef [ [Str] => Str ] ] => Str )->(
    sub {
        is_deeply( \@_, ['Ready!'], '[ Str ]' );
        return 'Go!';
    }
    ),
    'Go!', '    => Str';
#
is wrap( $lib, 'cb_A', [ Struct [ cb => CodeRef [ [Str] => Str ], i => Int ] ] => Str )->(
    {   cb => sub {
            is_deeply( \@_, ['Ready!'], '[ Str ]' );
            return 'Go!';
        },
        i => 100
    }
    ),
    'Go!', 'Callback inside struct';
#
Affix::typedef cv => CodeRef [ [] => Str ];
my $cv = sub { pass 'Callback!'; };
is wrap( $lib, 'cb_CV_Z', [ CodeRef [ [ Str, cv() ] => Str ], cv() ] => Str )->(
    sub {
        is_deeply( \@_, [ 'Ready!', $cv ], '[ Str, CodeRef ]' );
        return 'Go!';
    },
    $cv
    ),
    'Go!', '    => Str';
done_testing;
