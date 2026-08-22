/*
 * SIMD CPU feature detection, runtime dispatcher, and scalar fallback loops.
 */

#include "simd.h"

bool histo_simd_has_avx2(void) {
#if (defined(__x86_64__) || defined(__i386__)) && (defined(__GNUC__) || defined(__clang__))
#if defined(__has_builtin)
#if __has_builtin(__builtin_cpu_supports)
    __builtin_cpu_init();
    return __builtin_cpu_supports("avx2");
#else
    return false;
#endif
#else
    __builtin_cpu_init();
    return __builtin_cpu_supports("avx2");
#endif
#else
    return false;
#endif
}

bool histo_simd_has_avx512(void) {
#if (defined(__x86_64__) || defined(__i386__)) && (defined(__GNUC__) || defined(__clang__))
#if defined(__has_builtin)
#if __has_builtin(__builtin_cpu_supports)
    __builtin_cpu_init();
    return __builtin_cpu_supports("avx512f");
#else
    return false;
#endif
#else
    __builtin_cpu_init();
    return __builtin_cpu_supports("avx512f");
#endif
#else
    return false;
#endif
}

bool histo_simd_has_neon(void) {
#if defined(__aarch64__) || defined(_M_ARM64) || defined(__ARM_NEON)
    return true;
#elif defined(LIBHISTO_ENABLE_NEON)
    return true;
#else
    return false;
#endif
}

#if !defined(LIBHISTO_ENABLE_AVX2)
bool histo_fill_uniform_avx2(histo_t *h, const double *x, size_t n) {
    (void)h; (void)x; (void)n; return false;
}
bool histo_fill_uniform_w2_avx2(histo_t *h, const double *x, const double *weights, size_t n) {
    (void)h; (void)x; (void)weights; (void)n; return false;
}
bool histo2d_fill_uniform_avx2(histo2d_t *h, const double *x, const double *y, size_t n) {
    (void)h; (void)x; (void)y; (void)n; return false;
}
bool histo2d_fill_uniform_w2_avx2(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n) {
    (void)h; (void)x; (void)y; (void)weights; (void)n; return false;
}
#endif

#if !defined(LIBHISTO_ENABLE_AVX512)
bool histo_fill_uniform_avx512(histo_t *h, const double *x, size_t n) {
    (void)h; (void)x; (void)n; return false;
}
bool histo_fill_uniform_w2_avx512(histo_t *h, const double *x, const double *weights, size_t n) {
    (void)h; (void)x; (void)weights; (void)n; return false;
}
bool histo2d_fill_uniform_avx512(histo2d_t *h, const double *x, const double *y, size_t n) {
    (void)h; (void)x; (void)y; (void)n; return false;
}
bool histo2d_fill_uniform_w2_avx512(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n) {
    (void)h; (void)x; (void)y; (void)weights; (void)n; return false;
}
#endif

#if !defined(LIBHISTO_ENABLE_NEON)
bool histo_fill_uniform_neon(histo_t *h, const double *x, size_t n) {
    (void)h; (void)x; (void)n; return false;
}
bool histo_fill_uniform_w2_neon(histo_t *h, const double *x, const double *weights, size_t n) {
    (void)h; (void)x; (void)weights; (void)n; return false;
}
bool histo2d_fill_uniform_neon(histo2d_t *h, const double *x, const double *y, size_t n) {
    (void)h; (void)x; (void)y; (void)n; return false;
}
bool histo2d_fill_uniform_w2_neon(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n) {
    (void)h; (void)x; (void)y; (void)weights; (void)n; return false;
}
#endif


