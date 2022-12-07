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
compile_test_lib('51_affix_sizeof');
my $lib = 't/51_affix_sizeof';
subtest 'fundamental types' => sub {
    is sizeof(Bool),     wrap( $lib, 's_bool',     [], Size_t )->(),  'sizeof(Bool)';
    is sizeof(Char),     wrap( $lib, 's_char',     [], Size_t )->(),  'sizeof(Char)';
    is sizeof(Short),    wrap( $lib, 's_short',    [], Size_t )->(),  'sizeof(Short)';
    is sizeof(Int),      wrap( $lib, 's_int',      [], Size_t )->(),  'sizeof(Int)';
    is sizeof(Long),     wrap( $lib, 's_long',     [], Size_t )->(),  'sizeof(Long)';
    is sizeof(LongLong), wrap( $lib, 's_longlong', [], Size_t )->(),  'sizeof(LongLong)';
    is sizeof(Float),    wrap( $lib, 's_float',    [], Size_t )->(),  'sizeof(Float)';
    is sizeof(Double),   wrap( $lib, 's_double',   [], Size_t )->(),  'sizeof(Double)';
    is sizeof(SSize_t),  wrap( $lib, 's_ssize_t',  [], SSize_t )->(), 'sizeof(SSize_t)';
    is sizeof(Size_t),   wrap( $lib, 's_size_t',   [], Size_t )->(),  'sizeof(Size_t)';
};
subtest 'aggregates' => sub {
    my $struct1 = Struct [ c => ArrayRef [ Char, 3 ] ];
    my $struct2 = Struct [ c => ArrayRef [ Int,  3 ] ];
    my $struct3 = Struct [ d => Double, c => ArrayRef [ Int, 3 ] ];
    my $struct4 = Struct [ y => $struct3 ];    # Make sure we are padding cached size data
    my $struct5 = Struct [ y => Struct [ d => Double, c => ArrayRef [ Int, 3 ] ] ];
    my $struct6 = Struct [ y => $struct3, s => $struct4, c => Char ];
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
    subtest 'structs' => sub {
        is sizeof($struct1), wrap( $lib, 's_struct1', [], Size_t )->(), 'sizeof(struct1)';
        is sizeof($struct2), wrap( $lib, 's_struct2', [], Size_t )->(), 'sizeof(struct2)';
        is sizeof($struct3), wrap( $lib, 's_struct3', [], Size_t )->(), 'sizeof(struct3)';
        is sizeof($struct4), wrap( $lib, 's_struct4', [], Size_t )->(), 'sizeof(struct4)';
        is sizeof($struct5), wrap( $lib, 's_struct5', [], Size_t )->(), 'sizeof(struct5)';
    SKIP: {
            skip 'perl defined bad var sizes with -Duselongdouble before 5.36.x', 2
                if $Config{uselongdouble} && $^V lt v5.36.1;
            is sizeof($struct6),    wrap( $lib, 's_struct6', [], Size_t )->(), 'sizeof(struct6)';
            is sizeof( massive() ), wrap( $lib, 's_massive', [], Size_t )->(), 'sizeof(massive)';
        }
    };
    subtest 'arrays' => sub {
        my $array1 = ArrayRef [ Struct [ d => Double, c => ArrayRef [ Int, 3 ] ], 3 ];
        is sizeof($array1), wrap( $lib, 's_array1', [], Size_t )->(), 'sizeof(array1)';
    };
    subtest 'unions' => sub {
        my $union1 = Union [ i => Int, d => Float ];
        my $union2 = Union [ i => Int, s => $struct1, d => Float ];
        my $union3 = Union [ i => Int, s => $struct3, d => Float ];
        my $union4 = Union [ i => Int, s => ArrayRef [ $struct1, 5 ], d => Float ];
        is sizeof($union1), wrap( $lib, 's_union1', [], Size_t )->(), 'sizeof(union1)';
        is sizeof($union2), wrap( $lib, 's_union2', [], Size_t )->(), 'sizeof(union2)';
    SKIP: {
            skip 'perl defined bad var sizes with -Duselongdouble before 5.36.x', 2
                if $Config{uselongdouble} && $^V lt v5.36.1;
            is sizeof($union3), wrap( $lib, 's_union3', [], Size_t )->(), 'sizeof(union3)';
            is sizeof($union4), wrap( $lib, 's_union4', [], Size_t )->(), 'sizeof(union4)';
        }
    };
    is sizeof( Pointer [Void] ), wrap( $lib, 's_voidptr', [], Size_t )->(), 'sizeof(void *)';
};
#
done_testing;
