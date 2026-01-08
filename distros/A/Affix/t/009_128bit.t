use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
my $c_source = <<'END_C';
#include "std.h"
//ext: .c

#include <stdio.h>
#include <stdint.h>

/* 128-bit Integers */
#ifdef __SIZEOF_INT128__
    typedef __int128_t int128;
    typedef __uint128_t uint128;

    DLLEXPORT int has_int128() { return 1; }

    DLLEXPORT int128 add_i128(int128 a, int128 b) {
        return a + b;
    }

    DLLEXPORT uint128 add_u128(uint128 a, uint128 b) {
        return a + b;
    }

    // Helper to verify value passed correctly (returns high 64 bits cast to 64)
    DLLEXPORT int64_t high_bits_i128(int128 v) {
        return (int64_t)(v >> 64);
    }
#else
    DLLEXPORT int has_int128() { return 0; }
#endif
END_C

# Compile the library
my $lib = compile_ok($c_source);

# Check if the C compiler supported it
my $check = wrap( $lib, 'has_int128', [] => Int );
if ( !$check->() ) {
    skip_all "Compiler does not support __int128_t";
}

# Bind functions
# Note: Passed/Returned as Strings in Perl
isa_ok my $add_i = wrap( $lib, 'add_i128',       [ Int128,  Int128 ]  => Int128 ),  ['Affix'];
isa_ok my $add_u = wrap( $lib, 'add_u128',       [ UInt128, UInt128 ] => UInt128 ), ['Affix'];
isa_ok my $high  = wrap( $lib, 'high_bits_i128', [Int128] => Int64 ), ['Affix'];

# Test Signed Addition
# 2^100 approx 1.26e30
my $v1  = "1267650600228229401496703205376";
my $v2  = "1";
my $sum = $add_i->( $v1, $v2 );
is $sum, "1267650600228229401496703205377", "Signed 128-bit add worked";

# Test Unsigned Overflow wrapping (if applicable) or just large numbers
# Max uint64 is 18446744073709551615
my $u_large = "184467440737095516150";      # > UINT64_MAX
my $u_sum   = $add_u->( $u_large, "10" );
is $u_sum, "184467440737095516160", "Unsigned 128-bit add large numbers";

# Test passing bits (Shift check)
# 1 << 80 = 1208925819614629174706176
my $shifted = "1208925819614629174706176";

# High bits should be 1 << (80-64) = 1 << 16 = 65536
is $high->($shifted), 65536, "Verified high bits of passed 128-bit int in C";
#
done_testing;
