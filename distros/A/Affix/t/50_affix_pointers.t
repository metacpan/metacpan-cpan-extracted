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
#plan skip_all => q[You use *BSD. You don't like nice things.] if $^O =~ /bsd/i;
#
diag __LINE__;
compile_test_lib('50_affix_pointers');
#
diag __LINE__;
subtest 'sv2ptr and ptr2sv' => sub {
    diag __LINE__;
    subtest 'double' => sub {
        diag __LINE__;
        my $ptr = Affix::sv2ptr( 50, Double );
        isa_ok $ptr, 'Affix::Pointer';
        is Affix::ptr2sv( $ptr, Double ), 50, 'Store and returned double in a pointer';
        diag __LINE__;
    };
    diag __LINE__;
    subtest 'struct with string pointer' => sub {
        diag __LINE__;
        affix( 't/50_affix_pointers', 'demo', [ Struct [ i => Int, Z => Str, ] ] => Bool );
        my $ptr = Affix::sv2ptr( { Z => 'Here. There. Everywhere.', i => 100 },
            Struct [ i => Int, Z => Str ] );
        ok demo( { Z => 'Here. There. Everywhere.', i => 100 } ),
            'passed struct with string pointer';
        diag __LINE__;
        isa_ok $ptr, 'Affix::Pointer';
        is_deeply Affix::ptr2sv( $ptr, Struct [ b => Int, c => Str ] ),
            { b => 100, c => 'Here. There. Everywhere.' }, 'Store and returned struct in a pointer';
    };
    diag __LINE__;
};
diag __LINE__;
#
sub pointer_test : Native('t/50_affix_pointers') :
    Signature([Pointer[Double], ArrayRef [ Int, 5 ], Int, CodeRef [ [ Int, Int ] => Double ] ] => Double);
sub dbl_ptr : Native('t/50_affix_pointers') : Signature([Pointer[Double]] => Str);
#
diag __LINE__;
subtest 'scalar ref' => sub {
    diag __LINE__;
    my $ptr = 100;
    is dbl_ptr($ptr), 'one hundred', 'dbl_ptr($ptr) where $ptr == 100';
    diag __LINE__;
    is $ptr, 1000, '$ptr was changed to 1000';
    diag __LINE__;
};
diag __LINE__;
subtest 'undefined scalar ref' => sub {
    diag __LINE__;
    my $ptr;
    is dbl_ptr($ptr), 'empty', 'dbl_ptr($ptr) where $ptr == undef';
    diag __LINE__;
    is $ptr, 1000, '$ptr was changed to 1000';
    diag __LINE__;
};
diag __LINE__;
subtest 'Dyn::Call::Pointer with a double' => sub {
    diag __LINE__;
    my $ptr = calloc( 1, 16 );
    {
        diag __LINE__;
        my $data = pack 'd', 100.04;
        memcpy( $ptr, $data, length $data );
    }
    is dbl_ptr($ptr), 'one hundred and change', 'dbl_ptr($ptr) where $ptr == malloc(...)';
    $ptr->dump(16);
    diag __LINE__;
    my $raw = $ptr->raw(16);
    is unpack( 'd', $raw ), 10000, '$ptr was changed to 10000';
    free $ptr;
    diag __LINE__;
};
diag __LINE__;
subtest 'ref Dyn::Call::Pointer with a double (should croak)' => sub {
    diag __LINE__;
    my $ptr = calloc( 1, 16 );
    {
        diag __LINE__;
        my $data = pack 'd', 9;
        memcpy( $ptr, $data, length $data );
    }
    diag __LINE__;
    is dbl_ptr($ptr), 'nine', 'dbl_ptr($ptr) where $ptr == malloc(...)';
    is unpack( 'd', $ptr->raw(16) ),
        ( $Config{usequadmath} ? 9876.54299999999966530594974756241 :
            $Config{uselongdouble} ? 9876.54299999999967 :
            9876.543 ), '$ptr is still 9';
    diag __LINE__;
    DumpHex( $ptr, 16 );
    diag __LINE__;
    free $ptr;
};
diag __LINE__;
{
    my $ptr = 99;
    diag __LINE__;
    is pointer_test(
        $ptr,
        [ 1 .. 5 ],
        5,
        sub {
            diag __LINE__;
            pass('our coderef was called');
            is_deeply \@_, [ 4, 8 ], '... and given correct arguments';
            diag __LINE__;
            50.25;
        }
        ),
        900, 'making call to test various types of pointers';
    diag __LINE__;
    is $ptr, 100.5, 'Pointer[Double] was updated!';
}
diag __LINE__;
{
    is pointer_test(
        undef,
        [ 1 .. 5 ],
        5,
        sub {
            diag __LINE__;
            pass('our coderef was called');
            is_deeply \@_, [ 4, 8 ], '... and given correct arguments';
            diag __LINE__;
            50.25;
        }
        ),
        -1, 'making call with an undef pointer passes a NULL';
}
diag __LINE__;
{
    my $data = pack 'd', 590343.12351;    # Test pumping raw, packed data into memory
    diag __LINE__;
    my $ptr = malloc length($data);
    diag __LINE__;
    memmove $ptr, $data, length $data;
    diag __LINE__;
    diag 'allocated ' . length($data) . ' bytes';
    diag __LINE__;
    is pointer_test(
        $ptr,
        [ 1 .. 5 ],
        5,
        sub {
            diag __LINE__;
            pass('our coderef was called');
            is_deeply \@_, [ 4, 8 ], '... and given correct arguments';
            50.25;
        }
        ),
        ( $Config{usequadmath} ? 18.3382499999999986073362379102036 :
            $Config{uselongdouble} ? 18.3382499999999986 :
            18.33825 ), 'making call with Dyn::Call::Pointer object with packed data';
    is unpack( 'd', $ptr ),
        ( $Config{usequadmath} ? 3.49299999999999988276044859958347 :
            $Config{uselongdouble} ? 3.49299999999999988 :
            3.493 ), 'Dyn::Call::Pointer updated';
    diag __LINE__;
    free $ptr;
    diag __LINE__;
}
diag __LINE__;
subtest struct => sub {
    diag __LINE__;
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
    diag __LINE__;
    diag 'sizeof in perl: ' . sizeof( massive() );
    sub massive_ptr : Native('t/50_affix_pointers') : Signature([] => Pointer[massive()]);
    sub sptr : Native('t/50_affix_pointers') : Signature([Pointer[massive()]] => Bool);
    ok sptr( { Z => 'Works!' } );
    my $ptr = massive_ptr();
    my $sv  = ptr2sv( $ptr, Pointer [ massive() ] );
    is $sv->{A}{i}, 50,                   'parsed pointer to sv and got .A.i [nested structs]';
    is $sv->{Z},    'Just a little test', 'parsed pointer to sv and got .Z';
};
diag __LINE__;
#
done_testing;
