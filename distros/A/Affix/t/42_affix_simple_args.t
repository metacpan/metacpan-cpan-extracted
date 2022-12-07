use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:all];
use File::Spec;
use t::lib::nativecall;
use experimental 'signatures';
$|++;
#
compile_test_lib('42_simple_args');

# Int related
sub TakeInt : Native('t/42_simple_args') : Signature([Int]=>Int);
sub TakeUInt : Native('t/42_simple_args') : Signature([UInt]=>Int);
sub TakeTwoShorts : Native('t/42_simple_args') : Signature([Short, Short] => Long);
sub AssortedIntArgs : Native('t/42_simple_args') : Signature([Long, Short, Char]=>Long);
#
is TakeInt(42),                          1, 'passed int 42';
is TakeUInt(42),                         1, 'passed int 42';
is TakeTwoShorts( 10, 20 ),              2, 'passed two shorts';
is AssortedIntArgs( 101, 102, chr 103 ), 3, 'passed an int32, int16 and int8';

# Float related
sub TakeADouble : Native('t/42_simple_args') : Signature([Double]=>Int);
sub TakeADoubleNaN : Native('t/42_simple_args') : Signature([Double]=>Int);
sub TakeAFloat : Native('t/42_simple_args') : Signature([Float]=>Int);
sub TakeAFloatNaN : Native('t/42_simple_args') : Signature([Float]=>Int);
is TakeADouble(-6.9e0),   4, 'passed a double';
is TakeADoubleNaN('NaN'), 4, 'passed a NaN (double)';
is TakeAFloat(4.2e0),     5, 'passed a float';
is TakeAFloatNaN('NaN'),  5, 'passed a NaN (float)';

# String related
sub TakeAString : Native('t/42_simple_args') : Signature([Str]=>Int);
is TakeAString('ok 6 - passed a string'), 6, 'passed a string';

# Explicitly managing strings
sub SetString : Native('t/42_simple_args') : Signature([Str]=>Int);
sub CheckString : Native('t/42_simple_args') : Signature([]=>Int);
my $str = 'ok 7 - checked previously passed string';

#explicitly-manage($str); # https://docs.raku.org/routine/explicitly-manage
SetString($str);
is CheckString(), 7, 'checked previously passed string';

# Make sure wrapped subs work
sub wrapped : Native('t/42_simple_args') : Signature([Int]=>Int);
sub wrapper ($arg) { is wrapped($arg), 8, 'wrapped sub' }
wrapper(42);
TODO: {
    local $TODO = 'Some platforms choke on 64bit math';

    # 64-bit integer
    sub TakeInt64 : Native('t/42_simple_args') : Signature([Long]=>Long);
    {
        no warnings 'portable';
        is TakeInt64(0xFFFFFFFFFF), 9, 'passed int64 0xFFFFFFFFFF';
    }
}

# Unsigned integers.
sub TakeUint8 : Native('t/42_simple_args') : Signature([UChar]=>Int);
sub TakeUint16 : Native('t/42_simple_args') : Signature([UShort]=>Int);
sub TakeUint32 : Native('t/42_simple_args') : Signature([ULong]=>Int);
SKIP: {
    #skip 'Cannot test TakeUint8(0xFE) on OS X with -O3', 1 if $^O eq 'darwin';
    #
    # For some reason, on OS X with clang, the following test fails with -O3
    # specified.  One can only assume this is some weird compiler issue (tested
    # on Apple LLVM version 6.1.0 (clang-602.0.49) (based on LLVM 3.6.0svn).
    #
    is TakeUint8( chr 0xFE ), 10, 'passed uint8 0xFE';
}

# R#2124 https://github.com/rakudo/rakudo/issues/2124
#skip("Cannot test TakeUint16(0xFFFE) with clang without -O0");
is TakeUint16(0xFFFE),     11, 'passed uint16 0xFFFE';
is TakeUint32(0xFFFFFFFE), 12, 'passed uint32 0xFFFFFFFE';
sub TakeSizeT : Native('t/42_simple_args') : Signature([Int]=>ULong);
is TakeSizeT(42), 13, 'passed size_t 42';
sub TakeSSizeT : Native('t/42_simple_args') : Signature([Int]=>ULong);
is TakeSSizeT(-42), 14, 'passed ssize_t -42';

# https://docs.raku.org/type/Proxy - Sort of like a magical tied hash?
#my $arg := Proxy.new(
#    FETCH => -> $ {
#        42
#    },
#    STORE => -> $, $val {
#        die "STORE NYI";
#    },
#);
#is TakeInt($arg), 1, 'Proxy works';
done_testing;
