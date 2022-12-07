use strict;
no warnings 'portable';
use Affix qw[:all];
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use File::Spec;
use t::lib::nativecall;
use Config;
$|++;
#
plan skip_all => q[You use *BSD. You don't like nice things.] if $^O =~ /bsd/i;
#
compile_test_lib('50_affix_pointers');
#
sub pointer_test : Native('t/50_affix_pointers') :
    Signature([Pointer[Double], ArrayRef [ Int, 5 ], Int, CodeRef [ [ Int, Int ] => Double ] ] => Double);
sub dbl_ptr : Native('t/50_affix_pointers') : Signature([Pointer[Double]] => Str);
subtest 'scalar ref' => sub {
    my $ptr = 100;
    is dbl_ptr($ptr), 'one hundred', 'dbl_ptr($ptr) where $ptr == 100';
    is $ptr,          1000,          '$ptr was changed to 1000';
};
subtest 'undefined scalar ref' => sub {
    my $ptr;
    is dbl_ptr($ptr), 'empty', 'dbl_ptr($ptr) where $ptr == undef';
    is $ptr,          1000,    '$ptr was changed to 1000';
};
subtest 'Dyn::Call::Pointer with a double' => sub {
    my $ptr = calloc( 1, 16 );
    {
        my $data = pack 'd', 100.04;
        memcpy( $ptr, $data, length $data );
    }
    is dbl_ptr($ptr), 'one hundred and change', 'dbl_ptr($ptr) where $ptr == malloc(...)';
    $ptr->dump(16);
    my $raw = $ptr->raw(16);
    is unpack( 'd', $raw ), 10000, '$ptr was changed to 10000';
    free $ptr;
};
subtest 'ref Dyn::Call::Pointer with a double (should croak)' => sub {
    my $ptr = calloc( 1, 16 );
    {
        my $data = pack 'd', 9;
        memcpy( $ptr, $data, length $data );
    }
    is dbl_ptr($ptr), 'nine', 'dbl_ptr($ptr) where $ptr == malloc(...)';
    is unpack( 'd', $ptr->raw(16) ), ( $Config{uselongdouble} ? 9876.54299999999967 : 9876.543 ),
        '$ptr is still 9';
    free $ptr;
};
{
    my $ptr = 99;
    is pointer_test(
        $ptr,
        [ 1 .. 5 ],
        5,
        sub {
            pass('our coderef was called');
            is_deeply \@_, [ 4, 8 ], '... and given correct arguments';
            50.25;
        }
        ),
        900, 'making call to test various types of pointers';
    is $ptr, 100.5, 'Pointer[Double] was updated!';
}
{
    is pointer_test(
        undef,
        [ 1 .. 5 ],
        5,
        sub {
            pass('our coderef was called');
            is_deeply \@_, [ 4, 8 ], '... and given correct arguments';
            50.25;
        }
        ),
        -1, 'making call with an undef pointer passes a NULL';
}
{
    my $data = pack 'd', 590343.12351;    # Test pumping raw, packed data into memory
    my $ptr  = malloc length($data);
    memmove $ptr, $data, length $data;
    diag 'allocated ' . length($data) . ' bytes';
    is pointer_test(
        $ptr,
        [ 1 .. 5 ],
        5,
        sub {
            pass('our coderef was called');
            is_deeply \@_, [ 4, 8 ], '... and given correct arguments';
            50.25;
        }
        ),
        ( $Config{uselongdouble} ? 18.3382499999999986 : 18.33825 ),
        'making call with Dyn::Call::Pointer object with packed data';
    is unpack( 'd', $ptr ), ( $Config{uselongdouble} ? 3.49299999999999988 : 3.493 ),
        'Dyn::Call::Pointer updated';
    free $ptr;
}
subtest struct => sub {
    typedef massive => Struct [
        B => Bool,
        c => Char,
        C => UChar,
        s => Short,
        S => UShort,
        i => Int,
        I => UInt,
        j => Long,
        J => ULong,
        l => LongLong,
        L => ULongLong,
        f => Float,
        d => Double,
        p => Pointer [Int],
        Z => Str,
        A => Struct [ i => Int ],
        u => Union [ i => Int, structure => Struct [ ptr => Pointer [Void], l => Long ] ]
    ];
    diag 'sizeof in perl: ' . sizeof( massive() );
    sub massive_ptr : Native('t/50_affix_pointers') : Signature([] => Pointer[massive()]);
    my $ptr = massive_ptr();
    my $sv  = cast( $ptr, Pointer [ massive() ] );
    is $sv->{A}{i}, 50,                   'parsed pointer to sv and got .A.i [nested structs]';
    is $sv->{Z},    'Just a little test', 'parsed pointer to sv and got .Z';
};
#
done_testing;
