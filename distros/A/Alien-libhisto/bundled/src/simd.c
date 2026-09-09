/*
 * SIMD CPU feature detection, runtime dispatcher, and scalar fallback loops.
 */

#include "simd.h"

#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__) || defined(__clang__)
#if (defined(__x86_64__) || defined(__i386__))
#include <cpuid.h>
#endif
#endif

bool histo_simd_has_avx2(void) {
#if (defined(__x86_64__) || defined(__i386__) || defined(_M_X64) || defined(_M_IX86))
#if defined(_MSC_VER)
    int cpu_info[4] = {0};
    __cpuid(cpu_info, 0);
    int nIds = cpu_info[0];
    if (nIds < 7) return false;
    __cpuidex(cpu_info, 7, 0);
    return (cpu_info[1] & (1 << 5)) != 0; /* AVX2 bit in EBX */
#elif defined(__GNUC__) && (__GNUC__ >= 5 || defined(__clang__))
    __builtin_cpu_init();
    return __builtin_cpu_supports("avx2") != 0;
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__))
    unsigned int eax = 0, ebx = 0, ecx = 0, edx = 0;
    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid_count(7, 0, eax, ebx, ecx, edx);
        return (ebx & (1u << 5)) != 0; /* AVX2 bit 5 in EBX */
    }
    return false;
#else
    return false;
#endif
#else
    return false;
#endif
}

bool histo_simd_has_avx512(void) {
#if (defined(__x86_64__) || defined(__i386__) || defined(_M_X64) || defined(_M_IX86))
#if defined(_MSC_VER)
    int cpu_info[4] = {0};
    __cpuid(cpu_info, 0);
    int nIds = cpu_info[0];
    if (nIds < 7) return false;
    __cpuidex(cpu_info, 7, 0);
    return (cpu_info[1] & (1 << 16)) != 0; /* AVX512F bit in EBX */
#elif defined(__GNUC__) && (__GNUC__ >= 5 || defined(__clang__))
    __builtin_cpu_init();
    return __builtin_cpu_supports("avx512f") != 0;
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__))
    unsigned int eax = 0, ebx = 0, ecx = 0, edx = 0;
    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid_count(7, 0, eax, ebx, ecx, edx);
        return (ebx & (1u << 16)) != 0; /* AVX512F bit 16 in EBX */
    }
    return false;
#else
    return false;
#endif
#else
    return false;
#endif
}

bool histo_simd_has_neon(void) {
#if defined(__aarch64__) || defined(_M_ARM64)
    return true;
#elif defined(LIBHISTO_ENABLE_NEON) && (defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86))
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
bool histo2d_fill_uniform_neon(histo2d_t *h2d, const double *x, const double *y, size_t n) {
    (void)h2d; (void)x; (void)y; (void)n; return false;
}
bool histo2d_fill_uniform_w2_neon(histo2d_t *h2d, const double *x, const double *y, const double *weights, size_t n) {
    (void)h2d; (void)x; (void)y; (void)weights; (void)n; return false;
}
#endif
