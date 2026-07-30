use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
use Config;
#
$|++;
#
# Check for AVX2 support: GCC/Clang define __AVX2__ when -mavx2 is active
# MSVC defines __AVX2__ when /arch:AVX2 is active
# We compile the C code and check if the AVX functions were emitted.
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>

/* M256d = 4 doubles, M256 = 8 floats */
/* M512d = 8 doubles, M512 = 16 floats, M512i = 8 int64_t */

#if defined(__AVX2__) || defined(__AVX__)
#include <immintrin.h>

DLLEXPORT int has_avx2(void) { return 1; }

/* M256d operations (4 x double) */
DLLEXPORT __m256d add_m256d(__m256d a, __m256d b) { return _mm256_add_pd(a, b); }
DLLEXPORT __m256d mul_m256d(__m256d a, __m256d b) { return _mm256_mul_pd(a, b); }

/* M256 operations (8 x float) */
DLLEXPORT __m256 add_m256(__m256 a, __m256 b) { return _mm256_add_ps(a, b); }
DLLEXPORT __m256 mul_m256(__m256 a, __m256 b) { return _mm256_mul_ps(a, b); }

#else

DLLEXPORT int has_avx2(void) { return 0; }

#endif

#if defined(__AVX512F__)
#include <immintrin.h>

DLLEXPORT int has_avx512(void) { return 1; }

/* M512d operations (8 x double) */
DLLEXPORT __m512d add_m512d(__m512d a, __m512d b) { return _mm512_add_pd(a, b); }

/* M512 operations (16 x float) */
DLLEXPORT __m512 add_m512(__m512 a, __m512 b) { return _mm512_add_ps(a, b); }

#else

DLLEXPORT int has_avx512(void) { return 0; }

#endif
END_C
#
my $lib = compile_ok($C_CODE);
ok( $lib && -e $lib, 'Compiled shared library' );
#
subtest 'M256d (4 x double) -- AVX2' => sub {
    my $check = wrap( $lib, 'has_avx2', [] => Int );
    skip_all 'AVX2 not available' unless $check->();
    isa_ok my $add = wrap( $lib, 'add_m256d', [ M256d, M256d ] => M256d ), ['Affix'];
    isa_ok my $mul = wrap( $lib, 'mul_m256d', [ M256d, M256d ] => M256d ), ['Affix'];

    # M256d = 4 x double = 32 bytes
    is sizeof( M256d() ), 32, 'sizeof M256d is 32 bytes';

    # Pass as packed string (fast path)
    my $v1  = pack( 'd*', 1.0,  2.0,  3.0,  4.0 );
    my $v2  = pack( 'd*', 10.0, 20.0, 30.0, 40.0 );
    my $sum = add_m256d( $v1, $v2 );
    is ref($sum), 'ARRAY',     'add_m256d returns array ref';
    is $sum->[0], float(11.0), 'M256d add index 0';
    is $sum->[1], float(22.0), 'M256d add index 1';
    is $sum->[2], float(33.0), 'M256d add index 2';
    is $sum->[3], float(44.0), 'M256d add index 3';
    my $prod = mul_m256d( $v1, $v2 );
    is $prod->[0], float(10.0),  'M256d mul index 0';
    is $prod->[1], float(40.0),  'M256d mul index 1';
    is $prod->[2], float(90.0),  'M256d mul index 2';
    is $prod->[3], float(160.0), 'M256d mul index 3';
};
#
subtest 'M256 (8 x float) -- AVX2' => sub {
    my $check = wrap( $lib, 'has_avx2', [] => Int );
    skip_all 'AVX2 not available' unless $check->();
    isa_ok my $add = wrap( $lib, 'add_m256', [ M256, M256 ] => M256 ), ['Affix'];
    isa_ok my $mul = wrap( $lib, 'mul_m256', [ M256, M256 ] => M256 ), ['Affix'];
    is sizeof( M256() ), 32, 'sizeof M256 is 32 bytes';

    # 8 x float
    my $v1  = pack( 'f*', 1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0,  8.0 );
    my $v2  = pack( 'f*', 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0 );
    my $sum = add_m256( $v1, $v2 );
    is ref($sum),    'ARRAY',     'add_m256 returns array ref';
    is scalar @$sum, 8,           'M256 result has 8 elements';
    is $sum->[0],    float(11.0), 'M256 add index 0';
    is $sum->[7],    float(88.0), 'M256 add index 7';
    my $prod = mul_m256( $v1, $v2 );
    is $prod->[0], float(10.0),  'M256 mul index 0';
    is $prod->[7], float(640.0), 'M256 mul index 7';
};
#
subtest 'M256d -- pass as array ref (slow path)' => sub {
    my $check = wrap( $lib, 'has_avx2', [] => Int );
    skip_all 'AVX2 not available' unless $check->();
    isa_ok my $add = wrap( $lib, 'add_m256d', [ M256d, M256d ] => M256d ), ['Affix'];
    my $v1  = [ 1.5, 2.5, 3.5, 4.5 ];
    my $v2  = [ 0.5, 0.5, 0.5, 0.5 ];
    my $sum = add_m256d( $v1, $v2 );
    is $sum->[0], float(2.0), 'M256d array ref add index 0';
    is $sum->[1], float(3.0), 'M256d array ref add index 1';
    is $sum->[2], float(4.0), 'M256d array ref add index 2';
    is $sum->[3], float(5.0), 'M256d array ref add index 3';
};
#
subtest 'M512d (8 x double) -- AVX-512' => sub {
    my $check = wrap( $lib, 'has_avx512', [] => Int );
    skip_all 'AVX-512 not available' unless $check->();
    isa_ok my $add = wrap( $lib, 'add_m512d', [ M512d, M512d ] => M512d ), ['Affix'];
    is sizeof( M512d() ), 64, 'sizeof M512d is 64 bytes';
    my $v1  = pack( 'd*', 1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0,  8.0 );
    my $v2  = pack( 'd*', 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0 );
    my $sum = add_m512d( $v1, $v2 );
    is ref($sum),    'ARRAY',     'add_m512d returns array ref';
    is scalar @$sum, 8,           'M512d result has 8 elements';
    is $sum->[0],    float(11.0), 'M512d add index 0';
    is $sum->[7],    float(88.0), 'M512d add index 7';
};
#
subtest 'M512 (16 x float) -- AVX-512' => sub {
    my $check = wrap( $lib, 'has_avx512', [] => Int );
    skip_all 'AVX-512 not available' unless $check->();
    isa_ok my $add = wrap( $lib, 'add_m512', [ M512, M512 ] => M512 ), ['Affix'];
    is sizeof( M512() ), 64, 'sizeof M512 is 64 bytes';
    my @vals = ( 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0 );
    my $v1   = pack( 'f*', @vals );
    my $v2   = pack( 'f*', @vals );
    my $sum  = add_m512( $v1, $v2 );
    is ref($sum),    'ARRAY',     'add_m512 returns array ref';
    is scalar @$sum, 16,          'M512 result has 16 elements';
    is $sum->[0],    float(2.0),  'M512 add index 0';
    is $sum->[15],   float(32.0), 'M512 add index 15';
};
#
done_testing;
