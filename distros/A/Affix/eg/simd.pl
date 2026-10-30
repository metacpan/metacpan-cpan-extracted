use v5.40;
use utf8;
use Affix qw[:all];
use Affix::Build;

# Compile the native SIMD library first
# We use standard GCC/Clang vector extensions on POSIX/MinGW, and SSE intrinsics (__m128) on MSVC so it compiles on any platform.
my $build = Affix::Build->new();
$build->add( \<<~'END_C', lang => 'c' );
    #if defined(_MSC_VER)
    #  include <xmmintrin.h>
       typedef __m128 vec4;
    #  define DLLEXPORT __declspec(dllexport)
       static inline vec4 v_add(vec4 a, vec4 b) { return _mm_add_ps(a, b); }
       static inline vec4 v_sub(vec4 a, vec4 b) { return _mm_sub_ps(a, b); }
       static inline vec4 v_mul(vec4 a, vec4 b) { return _mm_mul_ps(a, b); }
       static inline vec4 v_scale(vec4 a, float s) { return _mm_mul_ps(a, _mm_set1_ps(s)); }
    #else
    #  define DLLEXPORT __attribute__((visibility("default")))
       typedef float vec4 __attribute__((vector_size(16)));
       static inline vec4 v_add(vec4 a, vec4 b) { return a + b; }
       static inline vec4 v_sub(vec4 a, vec4 b) { return a - b; }
       static inline vec4 v_mul(vec4 a, vec4 b) { return a * b; }
       static inline vec4 v_scale(vec4 a, float s) { return a * (vec4){s, s, s, s}; }
    #endif

    // Vector Addition: out = a + b
    DLLEXPORT vec4 vec4_add(vec4 a, vec4 b) {
        return v_add(a, b);
    }

    // Scalar Multiplication: out = v * s
    DLLEXPORT vec4 vec4_scale(vec4 v, float s) {
        return v_scale(v, s);
    }

    // Linear Interpolation: out = a + (b - a) * t (useful for color/camera fading)
    DLLEXPORT vec4 vec4_lerp(vec4 a, vec4 b, float t) {
        return v_add(a, v_scale(v_sub(b, a), t));
    }

    // Dot Product: out = a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w
    DLLEXPORT float vec4_dot(vec4 a, vec4 b) {
        union { vec4 v; float f[4]; } u;
        u.v = v_mul(a, b);
        return u.f[0] + u.f[1] + u.f[2] + u.f[3];
    }
END_C
my $lib = $build->link;

# 128-bit vector composed of 4 single-precision floats
typedef Vec4 => Vector [ 4, Float ];
#
affix $lib, 'vec4_add',   [ Vec4(), Vec4() ]        => Vec4();
affix $lib, 'vec4_scale', [ Vec4(), Float ]         => Vec4();
affix $lib, 'vec4_lerp',  [ Vec4(), Vec4(), Float ] => Vec4();
affix $lib, 'vec4_dot',   [ Vec4(), Vec4() ]        => Float;
{
    # Ergonomic mode using array refs
    my $pos = [ 10.0, 20.0, 30.0, 1.0 ];
    my $vel = [ 1.5,  -2.0, 0.5,  0.0 ];

    # Vector addition in a single hardware SIMD register
    my $next_pos = vec4_add( $pos, $vel );
    say sprintf 'Position + Velocity: [%.2f, %.2f, %.2f, %.2f]', @$next_pos;

    # Color blending (RGBA lerp from Red to Sky Blue at t = 0.5)
    my $red  = [ 1.0, 0.0, 0.0, 1.0 ];
    my $blue = [ 0.0, 0.5, 1.0, 1.0 ];
    say '';
    say 'Generating RGBA Gradient (Linear Blend):';
    for my $step ( 0 .. 4 ) {
        my $t     = $step / 4.0;
        my $color = vec4_lerp( $red, $blue, $t );
        say sprintf '  t = %.2f -> R: %.2f, G: %.2f, B: %.2f, A: %.2f', $t, @$color;
    }
}
{
    # High-performance mode uses packed binary strings. When passing packed strings,
    # Affix copies the bytes directly into the SIMD registers without traversing or
    # allocating SV structures.
    say '';
    my $v1          = pack 'f4', 1.0, 2.0, 3.0, 4.0;
    my $v2          = pack 'f4', 2.0, 0.5, 1.0, 3.0;
    my $dot_product = vec4_dot( $v1, $v2 );
    say sprintf 'Vector Dot Product: %.2f', $dot_product;

    # Verify: (1.0*2.0) + (2.0*0.5) + (3.0*1.0) + (4.0*3.0) = 2 + 1 + 3 + 12 = 18.00
    say 'Expected:           18.00'
}
