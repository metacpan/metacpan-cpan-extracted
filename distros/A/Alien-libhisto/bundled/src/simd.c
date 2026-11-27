/*
 * SIMD CPU feature detection, runtime dispatcher, and scalar fallback loops.
 */

#include "simd.h"

#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__) || defined(__clang__)
#if (defined(__x86_64__) || defined(__i386__)) && (defined(__clang__) || __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
#include <cpuid.h>
#endif
#endif

#if (defined(__x86_64__) || defined(__i386__)) && !defined(_MSC_VER) && defined(__GNUC__) && !(__GNUC__ >= 5 || defined(__clang__)) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
static unsigned long long histo_xgetbv0(void) {
    unsigned int eax = 0, edx = 0;
    __asm__ __volatile__("xgetbv" : "=a"(eax), "=d"(edx) : "c"(0));
    return ((unsigned long long)edx << 32) | eax;
}
#endif

bool histo_simd_has_avx2(void) {
#if (defined(__x86_64__) || defined(__i386__) || defined(_M_X64) || defined(_M_IX86))
#if defined(_MSC_VER)
    int cpu_info[4] = {0};
    __cpuid(cpu_info, 0);
    if (cpu_info[0] < 7) return false;
    __cpuid(cpu_info, 1);
    /* Check OSXSAVE (bit 27) and FMA (bit 12) in ECX */
    if ((cpu_info[2] & ((1 << 27) | (1 << 12))) != ((1 << 27) | (1 << 12))) return false;
    if ((_xgetbv(0) & 0x6ULL) != 0x6ULL) return false;
    __cpuidex(cpu_info, 7, 0);
    return (cpu_info[1] & (1 << 5)) != 0; /* AVX2 bit in EBX */
#elif defined(__GNUC__) && (__GNUC__ >= 5 || defined(__clang__))
    __builtin_cpu_init();
    return (__builtin_cpu_supports("avx2") != 0) && (__builtin_cpu_supports("fma") != 0);
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__)) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
    unsigned int eax = 0, ebx = 0, ecx = 0, edx = 0;
    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid(1, eax, ebx, ecx, edx);
        if ((ecx & ((1u << 27) | (1u << 12))) != ((1u << 27) | (1u << 12))) return false;
        if ((histo_xgetbv0() & 0x6ULL) != 0x6ULL) return false;
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
    if (cpu_info[0] < 7) return false;
    __cpuid(cpu_info, 1);
    /* Check OSXSAVE (bit 27) and FMA (bit 12) in ECX */
    if ((cpu_info[2] & ((1 << 27) | (1 << 12))) != ((1 << 27) | (1 << 12))) return false;
    if ((_xgetbv(0) & 0xE6ULL) != 0xE6ULL) return false;
    __cpuidex(cpu_info, 7, 0);
    return (cpu_info[1] & (1 << 16)) != 0; /* AVX512F bit in EBX */
#elif defined(__GNUC__) && (__GNUC__ >= 5 || defined(__clang__))
    __builtin_cpu_init();
    return (__builtin_cpu_supports("avx512f") != 0) && (__builtin_cpu_supports("fma") != 0);
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__)) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
    unsigned int eax = 0, ebx = 0, ecx = 0, edx = 0;
    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid(1, eax, ebx, ecx, edx);
        if ((ecx & ((1u << 27) | (1u << 12))) != ((1u << 27) | (1u << 12))) return false;
        if ((histo_xgetbv0() & 0xE6ULL) != 0xE6ULL) return false;
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
