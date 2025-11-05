// hexsimd.c
// SIMD-accelerated hex<->bin with runtime dispatch.
// Build modes controlled by Makefile (UNIVERSAL vs NATIVE).
// make -f make-dist.mk demo

#include "hexsimd.h"
#include <stdlib.h>   // getenv
#include <strings.h>  // strcasecmp (or use strcmp if you prefer exact case)
#include <string.h>  // for memcpy
#include <stdio.h>
#include <stdint.h>

#if defined(_MSC_VER)
  #include <intrin.h>
#else
  #include <immintrin.h>
#endif

/* decide once. at compile time. whether AVX512 code exists in this file */
#ifdef HEXSIMD_ENABLE_AVX512
#  define HEXSIMD_HAVE_AVX512 1
#else
#  define HEXSIMD_HAVE_AVX512 0
#endif

// -------------------------
// CPUID / XGETBV helpers
// -------------------------
static void cpuid_x86(unsigned leaf, unsigned subleaf, unsigned regs[4]) {
#if defined(_MSC_VER)
    int cpuInfo[4];
    __cpuidex(cpuInfo, (int)leaf, (int)subleaf);
    regs[0]=(unsigned)cpuInfo[0]; regs[1]=(unsigned)cpuInfo[1];
    regs[2]=(unsigned)cpuInfo[2]; regs[3]=(unsigned)cpuInfo[3];
#else
    unsigned a,b,c,d;
    __asm__ volatile("cpuid" : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
                               : "a"(leaf), "c"(subleaf));
    regs[0]=a; regs[1]=b; regs[2]=c; regs[3]=d;
#endif
}

static unsigned long long xgetbv_x86(unsigned idx) {
#if defined(_MSC_VER)
    return _xgetbv(idx);
#else
    unsigned eax, edx;
    __asm__ volatile (".byte 0x0f, 0x01, 0xd0" : "=a"(eax), "=d"(edx) : "c"(idx));
    return ((unsigned long long)edx << 32) | eax;
#endif
}

typedef struct {
    int sse2, avx, avx2, avx512bw, avx512vl;
} isa_t;

static isa_t detect_isa_runtime(void) {
    isa_t f = {0};
    unsigned r[4] = {0};
    cpuid_x86(1,0,r);
    int osxsave = (r[2] & (1u<<27)) != 0;
    f.sse2 = (r[3] & (1u<<26)) != 0;

    if (osxsave) {
        unsigned long long xcr0 = xgetbv_x86(0);
        int os_avx = ((xcr0 & 0x6) == 0x6);
        if (os_avx && (r[2] & (1u<<28))) f.avx = 1;

        cpuid_x86(7,0,r);
        if (f.avx) f.avx2 = (r[1] & (1u<<5)) != 0;

        int os_avx512 = ((xcr0 & 0xE0) == 0xE0);
        if (os_avx512) {
            f.avx512bw = (r[1] & (1u<<30)) != 0;
            f.avx512vl = (r[1] & (1u<<31)) != 0;
        }
    }
    return f;
}

// -------------------------
// Scalar reference
// -------------------------
static inline int nibble_from_ascii(unsigned char c, unsigned char* out) {
    if (c >= '0' && c <= '9') { *out = (unsigned char)(c - '0'); return 1; }
    unsigned char u = (unsigned char)(c & ~0x20u);
    if (u >= 'A' && u <= 'F') { *out = (unsigned char)(10 + (u - 'A')); return 1; }
    return 0;
}

__attribute__((target("default")))
static ptrdiff_t hex_to_bytes_scalar_impl(const char* src, size_t len, uint8_t* dst, bool strict) {
    if (len & 1) return -1;
    size_t o=0;
    for (size_t i=0;i<len;i+=2) {
        unsigned char hi=0, lo=0;
        int v1 = nibble_from_ascii((unsigned char)src[i], &hi);
        int v2 = nibble_from_ascii((unsigned char)src[i+1], &lo);
        if (strict && (!v1 || !v2)) return -1;
        if (!v1) hi = 0; 
	if (!v2) lo = 0;
        dst[o++] = (uint8_t)((hi<<4)|lo);
    }
    return (ptrdiff_t)o;
}

__attribute__((target("default")))
static ptrdiff_t bytes_to_hex_scalar_impl(const uint8_t* src, size_t len, char* dst) {
    static const char HEX[16] = "0123456789ABCDEF";
    for (size_t i=0;i<len;i++) {
        uint8_t b = src[i];
        dst[2*i+0] = HEX[b>>4];
        dst[2*i+1] = HEX[b & 0x0F];
    }
    return (ptrdiff_t)(2*len);
}

// Names for debugging
static const char *g_hex2bin_name = "scalar";
static const char *g_bin2hex_name = "scalar";

// -------------------------
// SSE2 (128b)  — enabled per function via target pragma
// -------------------------
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC push_options
#pragma GCC target("sse2")
#endif
#if (defined(__SSE2__) || defined(__GNUC__) || defined(__clang__) || defined(_M_X64) || defined(_M_IX86))
#include <emmintrin.h>

static inline __m128i sse2_toNib(__m128i x, __m128i *valid, int want_valid) {
    const __m128i c0 = _mm_set1_epi8('0'), c9p1=_mm_set1_epi8('9'+1);
    const __m128i cA = _mm_set1_epi8('A'), cFp1=_mm_set1_epi8('F'+1);
    const __m128i casebit=_mm_set1_epi8(0x20), ten=_mm_set1_epi8(10);

    __m128i upper = _mm_andnot_si128(casebit, x);
    __m128i ge0 = _mm_cmpeq_epi8(_mm_max_epu8(x,c0), x);
    __m128i lt10= _mm_cmpeq_epi8(_mm_min_epu8(x,c9p1), x);
    __m128i isd = _mm_and_si128(ge0, lt10);

    __m128i geA = _mm_cmpeq_epi8(_mm_max_epu8(upper,cA), upper);
    __m128i ltG = _mm_cmpeq_epi8(_mm_min_epu8(upper,cFp1), upper);
    __m128i isa = _mm_and_si128(geA, ltG);

    __m128i dval = _mm_sub_epi8(x, c0);
    __m128i lval = _mm_add_epi8(_mm_sub_epi8(upper, cA), ten);
    __m128i nib  = _mm_or_si128(_mm_and_si128(isd, dval),
                                _mm_andnot_si128(isd, lval));
    nib = _mm_and_si128(nib, _mm_set1_epi8(0x0F));

    if (want_valid && valid) *valid = _mm_or_si128(isd, isa);
    return nib;
}


static inline __m128i sse2_pack_pairs(__m128i n) {
    __m128i even = _mm_and_si128(n, _mm_set1_epi16(0x00FF));
    __m128i odd  = _mm_and_si128(_mm_srli_epi16(n,8), _mm_set1_epi16(0x00FF));
    __m128i w16  = _mm_or_si128(_mm_slli_epi16(even,4), odd);
    return _mm_packus_epi16(w16, _mm_setzero_si128());
}

__attribute__((target("sse2")))
static ptrdiff_t hex_to_bytes_sse2_impl(const char* src, size_t len, uint8_t* dst, bool strict) {
    if (len & 1) return -1;
    size_t i=0,o=0;
    for (; i+16<=len; i+=16, o+=8) {
        __m128i x = _mm_loadu_si128((const __m128i*)(src+i));
        __m128i valid;
        __m128i n = sse2_toNib(x, &valid, strict);
        if (strict) {
            __m128i all = _mm_cmpeq_epi8(valid, _mm_set1_epi8((char)0xFF));
            if ((unsigned)_mm_movemask_epi8(all) != 0xFFFFu) return -1;
        }
        __m128i out = sse2_pack_pairs(n);
        _mm_storel_epi64((__m128i*)(dst+o), out);
    }
    if (i<len) {
        ptrdiff_t t = hex_to_bytes_scalar_impl(src+i, len-i, dst+o, strict);
        if (t<0) return -1;
        o += (size_t)t;
    }
    return (ptrdiff_t)o;
}

// bytes -> hex (SSE2, arithmetic map; no SSSE3 needed)
__attribute__((target("sse2")))
static ptrdiff_t bytes_to_hex_sse2_impl(const uint8_t* src, size_t len, char* dst) {
    size_t i=0, o=0;
    const __m128i mask0F = _mm_set1_epi8(0x0F);
    const __m128i add30 = _mm_set1_epi8(0x30);
    const __m128i add7  = _mm_set1_epi8(0x07);
    const __m128i nine  = _mm_set1_epi8(9);

    for (; i+16<=len; i+=16, o+=32) {
        __m128i b = _mm_loadu_si128((const __m128i*)(src+i));
        __m128i lo = _mm_and_si128(b, mask0F);
        __m128i hi = _mm_and_si128(_mm_srli_epi16(b,4), mask0F);

        // map nibble -> ASCII '0'..'9','A'..'F' = nib + 0x30 + (nib>9?0x07:0)
        __m128i lo_gt9 = _mm_cmpgt_epi8(lo, nine);
        __m128i hi_gt9 = _mm_cmpgt_epi8(hi, nine);

        lo = _mm_add_epi8(lo, add30);
        hi = _mm_add_epi8(hi, add30);
        lo = _mm_add_epi8(lo, _mm_and_si128(lo_gt9, add7));
        hi = _mm_add_epi8(hi, _mm_and_si128(hi_gt9, add7));

        // interleave [hi0 lo0 hi1 lo1 ...]
        __m128i lo_i = _mm_unpacklo_epi8(hi, lo);
        __m128i hi_i = _mm_unpackhi_epi8(hi, lo);

        _mm_storeu_si128((__m128i*)(dst+o+0),  lo_i);
        _mm_storeu_si128((__m128i*)(dst+o+16), hi_i);
    }
    // tail
    for (; i<len; ++i, o+=2) {
        uint8_t b = src[i];
        uint8_t h = (b>>4), l = (b&0x0F);
        dst[o+0] = (char)(h + 0x30 + (h>9 ? 0x07 : 0));
        dst[o+1] = (char)(l + 0x30 + (l>9 ? 0x07 : 0));
    }
    return (ptrdiff_t)o;
}
#endif
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC pop_options
#endif

// -------------------------
// AVX2 (256b)
// -------------------------
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC push_options
#pragma GCC target("avx2")
#endif
#if defined(__AVX2__) || (defined(__GNUC__) || defined(__clang__))
static ptrdiff_t hex_to_bytes_avx2_impl(const char* src, size_t len, uint8_t* dst, bool strict) {
    if (len & 1) return -1;
    size_t i=0,o=0;
    const __m256i c0=_mm256_set1_epi8('0'), c9p1=_mm256_set1_epi8('9'+1);
    const __m256i cA=_mm256_set1_epi8('A'), cFp1=_mm256_set1_epi8('F'+1);
    const __m256i casebit=_mm256_set1_epi8(0x20), ten=_mm256_set1_epi8(10);
    const __m256i mask0F=_mm256_set1_epi8(0x0F);
    const __m256i pack016=_mm256_setr_epi8(
        16, 1, 16, 1, 16, 1, 16, 1,
        16, 1, 16, 1, 16, 1, 16, 1,
        16, 1, 16, 1, 16, 1, 16, 1,
        16, 1, 16, 1, 16, 1, 16, 1
    );
    const __m256i all_ff=_mm256_set1_epi32(-1);
    for (; i+32<=len; i+=32, o+=16) {
        __m256i x = _mm256_loadu_si256((const __m256i*)(src+i));
        __m256i upper = _mm256_andnot_si256(casebit, x);
        __m256i isd = _mm256_and_si256(
            _mm256_cmpeq_epi8(_mm256_max_epu8(x,c0), x),
            _mm256_cmpeq_epi8(_mm256_min_epu8(x,c9p1), x));
        __m256i isa = _mm256_and_si256(
            _mm256_cmpeq_epi8(_mm256_max_epu8(upper,cA), upper),
            _mm256_cmpeq_epi8(_mm256_min_epu8(upper,cFp1), upper));
        if (strict) {
            __m256i valid = _mm256_or_si256(isd, isa);
            if (!_mm256_testc_si256(valid, all_ff)) return -1;
        }
        __m256i dval = _mm256_sub_epi8(x,c0);
        __m256i lval = _mm256_add_epi8(_mm256_sub_epi8(upper,cA), ten);
        __m256i nib  = _mm256_or_si256(_mm256_and_si256(isd,dval),
                                       _mm256_andnot_si256(isd,lval));
        nib = _mm256_and_si256(nib, mask0F);

        __m256i pairs = _mm256_maddubs_epi16(nib, pack016);
        __m128i lo16 = _mm256_castsi256_si128(pairs);
        __m128i hi16 = _mm256_extracti128_si256(pairs,1);
        __m128i out8 = _mm_packus_epi16(lo16, hi16);
        _mm_storeu_si128((__m128i*)(dst+o), out8);
    }
    if (i<len) {
        ptrdiff_t t = hex_to_bytes_scalar_impl(src+i, len-i, dst+o, strict);
        if (t<0) return -1; 
	o += (size_t)t;
    }
    return (ptrdiff_t)o;
}

static ptrdiff_t bytes_to_hex_avx2_impl(const uint8_t* src, size_t len, char* dst) {
    size_t i=0, o=0;
    const __m128i mask0F = _mm_set1_epi8(0x0F);
    const __m128i add30  = _mm_set1_epi8(0x30);
    const __m128i add7   = _mm_set1_epi8(0x07);
    const __m128i nine   = _mm_set1_epi8(9);

    for (; i + 32 <= len; i += 32, o += 64) {
        __m256i b256 = _mm256_loadu_si256((const __m256i*)(src + i));

        // lane 0 (lower 128)
        __m128i b0  = _mm256_castsi256_si128(b256);
        __m128i lo0 = _mm_and_si128(b0, mask0F);
        __m128i hi0 = _mm_and_si128(_mm_srli_epi16(b0, 4), mask0F);

        __m128i lo0_gt9 = _mm_cmpgt_epi8(lo0, nine);
        __m128i hi0_gt9 = _mm_cmpgt_epi8(hi0, nine);

        lo0 = _mm_add_epi8(lo0, add30);
        hi0 = _mm_add_epi8(hi0, add30);
        lo0 = _mm_add_epi8(lo0, _mm_and_si128(lo0_gt9, add7));
        hi0 = _mm_add_epi8(hi0, _mm_and_si128(hi0_gt9, add7));

        __m128i out0_lo = _mm_unpacklo_epi8(hi0, lo0);  // pairs 0..7 of lane0
        __m128i out0_hi = _mm_unpackhi_epi8(hi0, lo0);  // pairs 8..15 of lane0

        _mm_storeu_si128((__m128i*)(dst + o +  0), out0_lo);
        _mm_storeu_si128((__m128i*)(dst + o + 16), out0_hi);

        // lane 1 (upper 128)
        __m128i b1  = _mm256_extracti128_si256(b256, 1);
        __m128i lo1 = _mm_and_si128(b1, mask0F);
        __m128i hi1 = _mm_and_si128(_mm_srli_epi16(b1, 4), mask0F);

        __m128i lo1_gt9 = _mm_cmpgt_epi8(lo1, nine);
        __m128i hi1_gt9 = _mm_cmpgt_epi8(hi1, nine);

        lo1 = _mm_add_epi8(lo1, add30);
        hi1 = _mm_add_epi8(hi1, add30);
        lo1 = _mm_add_epi8(lo1, _mm_and_si128(lo1_gt9, add7));
        hi1 = _mm_add_epi8(hi1, _mm_and_si128(hi1_gt9, add7));

        __m128i out1_lo = _mm_unpacklo_epi8(hi1, lo1);  // pairs 0..7 of lane1
        __m128i out1_hi = _mm_unpackhi_epi8(hi1, lo1);  // pairs 8..15 of lane1

        _mm_storeu_si128((__m128i*)(dst + o + 32), out1_lo);
        _mm_storeu_si128((__m128i*)(dst + o + 48), out1_hi);
    }

    // tail
    for (; i < len; ++i, o += 2) {
        uint8_t b = src[i];
        uint8_t h = b >> 4, l = b & 0x0F;
        dst[o+0] = (char)(h + 0x30 + (h > 9 ? 0x07 : 0));
        dst[o+1] = (char)(l + 0x30 + (l > 9 ? 0x07 : 0));
    }
    return (ptrdiff_t)o;
}

#endif
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC pop_options
#endif

// -------------------------
// AVX-512BW+VL helpers (MUST be compiled with avx512bw,avx512vl)
// -------------------------
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC push_options
#pragma GCC target("avx512bw,avx512vl")
#endif

static inline __m512i pack_pairs_avx512_pack(__m512i nib) {
    // Pair adjacent nibbles from bytes into 16-bit words, then pack to bytes.
    const __m512i maskFF = _mm512_set1_epi16(0x00FF);
    __m512i even = _mm512_and_si512(nib, maskFF);                         // low byte = even nibble
    __m512i odd  = _mm512_and_si512(_mm512_srli_epi16(nib, 8), maskFF);   // low byte = odd nibble
    __m512i hi   = _mm512_slli_epi16(even, 4);
    __m512i w16  = _mm512_or_si512(hi, odd);                              // 32x u16 words
    return _mm512_packus_epi16(w16, _mm512_setzero_si512());              // low 32 bytes are outputs
}

/* Only build AVX512 version if
 *  - the compiler is already compiling with AVX512BW+VL,
 *  - or the build system explicitly asked for it.
 */

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC pop_options
#endif

//#if (defined(__AVX512BW__) && defined(__AVX512VL__)) || defined(HEXSIMD_ENABLE_AVX512)
#if HEXSIMD_HAVE_AVX512
// -------------------------
// AVX-512BW+VL (512b math, 128/256/512 lanes)
// -------------------------
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC push_options
#pragma GCC target("avx512bw,avx512vl")
#endif


static ptrdiff_t hex_to_bytes_avx512_impl(const char* src, size_t len, uint8_t* dst, bool strict) {
    if (len & 1) return -1;
    size_t i = 0, o = 0;
    const size_t CH = 64; // 64 ASCII -> 32 bytes

    const __m512i c0      = _mm512_set1_epi8('0');
    const __m512i c9      = _mm512_set1_epi8('9');
    const __m512i cA      = _mm512_set1_epi8('A');
    const __m512i cF      = _mm512_set1_epi8('F');
    const __m512i casebit = _mm512_set1_epi8(0x20);
    const __m512i ten     = _mm512_set1_epi8(10);

    // Main 64-char chunks
    for (; i + CH <= len; i += CH, o += 32) {
        __m512i x = _mm512_loadu_si512((const void*)(src + i));
        __m512i upper = _mm512_andnot_si512(casebit, x);

        __mmask64 is_digit = _mm512_cmp_epu8_mask(x,     c0, _MM_CMPINT_GE)
                           & _mm512_cmp_epu8_mask(x,     c9, _MM_CMPINT_LE);
        __mmask64 is_alpha = _mm512_cmp_epu8_mask(upper, cA, _MM_CMPINT_GE)
                           & _mm512_cmp_epu8_mask(upper, cF, _MM_CMPINT_LE);

        if (strict && (is_digit | is_alpha) != ~(__mmask64)0) return -1;

        __m512i dval   = _mm512_sub_epi8(x, c0);
        __m512i lval   = _mm512_add_epi8(_mm512_sub_epi8(upper, cA), ten);
        __m512i nib    = _mm512_mask_blend_epi8(is_digit, lval, dval);
        nib            = _mm512_and_si512(nib, _mm512_set1_epi8(0x0F));

        // (even<<4) | odd in 16-bit lanes
        const __m512i maskFF = _mm512_set1_epi16(0x00FF);
        __m512i even = _mm512_and_si512(nib, maskFF);
        __m512i odd  = _mm512_and_si512(_mm512_srli_epi16(nib, 8), maskFF);
        __m512i w16  = _mm512_or_si512(_mm512_slli_epi16(even, 4), odd);

        // Pack each 128-bit lane to bytes and store its lower 8 bytes.
        // This yields 4 * 8 = 32 output bytes in proper order.
        for (int lane = 0; lane < 4; ++lane) {
            __m128i w16_lane   = _mm512_extracti32x4_epi32(w16, lane);
            __m128i packed128  = _mm_packus_epi16(w16_lane, _mm_setzero_si128()); // 16B: low 8B are valid
            _mm_storel_epi64((__m128i*)(dst + o + lane*8), packed128);
        }
	//o += 32;

    }

        // Tail (0..63 chars) — process in 16-char chunks via SSE2, then scalar.
        size_t rem = len - i;
        if (rem) {
            const char* p = src + i;
        
            while (rem >= 16) {
                __m128i x128 = _mm_loadu_si128((const __m128i*)p);
                __m128i valid128;
                __m128i n128 = sse2_toNib(x128, &valid128, /*want_valid=*/strict);
                if (strict) {
                    __m128i all = _mm_cmpeq_epi8(valid128, _mm_set1_epi8((char)0xFF));
                    if ((unsigned)_mm_movemask_epi8(all) != 0xFFFFu) return -1;
                }
                __m128i out128 = sse2_pack_pairs(n128);
                _mm_storel_epi64((__m128i*)(dst + o), out128);  // 8 output bytes
                p   += 16;
                o   += 8;
                rem -= 16;
            }

            if (rem) {
                ptrdiff_t t = hex_to_bytes_scalar_impl(p, rem, dst + o, strict);
                if (t < 0) return -1;
                o += (size_t)t;
            }
        }
        return (ptrdiff_t)o;

}


static ptrdiff_t bytes_to_hex_avx512_impl(const uint8_t* src, size_t len, char* dst) {
    size_t i=0, o=0;
    const __m128i mask0F = _mm_set1_epi8(0x0F);
    const __m128i add30  = _mm_set1_epi8(0x30);
    const __m128i add7   = _mm_set1_epi8(0x07);
    const __m128i nine   = _mm_set1_epi8(9);

    for (; i + 64 <= len; i += 64, o += 128) {
        __m512i b512 = _mm512_loadu_si512((const void*)(src + i));

        // process 4 lanes: idx = 0..3
        for (int lane = 0; lane < 4; ++lane) {
            __m128i b  = _mm512_extracti32x4_epi32(b512, lane);
            __m128i lo = _mm_and_si128(b, mask0F);
            __m128i hi = _mm_and_si128(_mm_srli_epi16(b, 4), mask0F);

            __m128i lo_gt9 = _mm_cmpgt_epi8(lo, nine);
            __m128i hi_gt9 = _mm_cmpgt_epi8(hi, nine);

            lo = _mm_add_epi8(lo, add30);
            hi = _mm_add_epi8(hi, add30);
            lo = _mm_add_epi8(lo, _mm_and_si128(lo_gt9, add7));
            hi = _mm_add_epi8(hi, _mm_and_si128(hi_gt9, add7));

            __m128i out_lo = _mm_unpacklo_epi8(hi, lo); // pairs 0..7 of this lane
            __m128i out_hi = _mm_unpackhi_epi8(hi, lo); // pairs 8..15 of this lane

            // each lane yields 32 chars
            _mm_storeu_si128((__m128i*)(dst + o + lane*32 +  0), out_lo);
            _mm_storeu_si128((__m128i*)(dst + o + lane*32 + 16), out_hi);
        }
    }

    // tail (<=63 bytes): scalar is fine
    for (; i < len; ++i, o += 2) {
        uint8_t b = src[i];
        uint8_t h = b >> 4, l = b & 0x0F;
        dst[o+0] = (char)(h + 0x30 + (h > 9 ? 0x07 : 0));
        dst[o+1] = (char)(l + 0x30 + (l > 9 ? 0x07 : 0));
    }
    return (ptrdiff_t)o;
}

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC pop_options
#endif

#endif // HEXSIMD_HAVE_AVX512


// -------------------------
// Dispatcher
// -------------------------
typedef ptrdiff_t (*hex2bin_fn)(const char*, size_t, uint8_t*, bool);
typedef ptrdiff_t (*bin2hex_fn)(const uint8_t*, size_t, char*);

static hex2bin_fn g_hex2bin = NULL;
static bin2hex_fn g_bin2hex = NULL;

static void pick_impls(void) {
    if (g_hex2bin) return;

    isa_t f = detect_isa_runtime();

    // Defaults
    g_hex2bin = hex_to_bytes_scalar_impl;
    g_bin2hex = bytes_to_hex_scalar_impl;
    g_hex2bin_name = "scalar";
    g_bin2hex_name = "scalar";

    const char* force = getenv("HEXSIMD_FORCE");
    if (force && *force) {
        // normalize desired path
        if (!strcasecmp(force, "scalar")) {
            return; // already set
        }
        if (!strcasecmp(force, "sse2") && f.sse2) {
            extern ptrdiff_t hex_to_bytes_sse2_impl(const char*, size_t, uint8_t*, bool);
            extern ptrdiff_t bytes_to_hex_sse2_impl(const uint8_t*, size_t, char*);
            g_hex2bin = hex_to_bytes_sse2_impl; g_bin2hex = bytes_to_hex_sse2_impl;
            g_hex2bin_name = "sse2"; g_bin2hex_name = "sse2"; return;
        }
        if (!strcasecmp(force, "avx2") && f.avx2) {
            extern ptrdiff_t hex_to_bytes_avx2_impl(const char*, size_t, uint8_t*, bool);
            extern ptrdiff_t bytes_to_hex_avx2_impl(const uint8_t*, size_t, char*);
            g_hex2bin = hex_to_bytes_avx2_impl; g_bin2hex = bytes_to_hex_avx2_impl;
            g_hex2bin_name = "avx2"; g_bin2hex_name = "avx2"; return;
        }
#if HEXSIMD_HAVE_AVX512
        if (!strcasecmp(force, "avx512") && f.avx512bw && f.avx512vl) {
            extern ptrdiff_t hex_to_bytes_avx512_impl(const char*, size_t, uint8_t*, bool);
            extern ptrdiff_t bytes_to_hex_avx512_impl(const uint8_t*, size_t, char*);
            g_hex2bin = hex_to_bytes_avx512_impl; g_bin2hex = bytes_to_hex_avx512_impl;
            g_hex2bin_name = "avx512bw"; g_bin2hex_name = "avx512bw"; return;
        }
#endif // HEXSIMD_HAVE_AVX512
        // If forced path isn’t compiled in or supported, we’ll fall through
        // to auto-select below.
    }

#if HEXSIMD_HAVE_AVX512
    if (f.avx512bw && f.avx512vl) {
        extern ptrdiff_t hex_to_bytes_avx512_impl(const char*, size_t, uint8_t*, bool);
        extern ptrdiff_t bytes_to_hex_avx512_impl(const uint8_t*, size_t, char*);
        g_hex2bin = hex_to_bytes_avx512_impl; g_bin2hex = bytes_to_hex_avx512_impl;
        g_hex2bin_name = "avx512bw"; g_bin2hex_name = "avx512bw"; return;
    }
#endif // HEXSIMD_HAVE_AVX512
    if (f.avx2) {
        extern ptrdiff_t hex_to_bytes_avx2_impl(const char*, size_t, uint8_t*, bool);
        extern ptrdiff_t bytes_to_hex_avx2_impl(const uint8_t*, size_t, char*);
        g_hex2bin = hex_to_bytes_avx2_impl; g_bin2hex = bytes_to_hex_avx2_impl;
        g_hex2bin_name = "avx2"; g_bin2hex_name = "avx2"; return;
    }
    if (f.sse2) {
        extern ptrdiff_t hex_to_bytes_sse2_impl(const char*, size_t, uint8_t*, bool);
        extern ptrdiff_t bytes_to_hex_sse2_impl(const uint8_t*, size_t, char*);
        g_hex2bin = hex_to_bytes_sse2_impl; g_bin2hex = bytes_to_hex_sse2_impl;
        g_hex2bin_name = "sse2"; g_bin2hex_name = "sse2"; return;
    }
}


ptrdiff_t hex_to_bytes(const char *src, size_t len, uint8_t *dst, bool strict) {
    pick_impls();
    return g_hex2bin(src, len, dst, strict);
}
ptrdiff_t bytes_to_hex(const uint8_t *src, size_t len, char *dst) {
    pick_impls();
    return g_bin2hex(src, len, dst);
}

const char* hexsimd_hex2bin_impl_name(void) { pick_impls(); return g_hex2bin_name; }
const char* hexsimd_bin2hex_impl_name(void) { pick_impls(); return g_bin2hex_name; }
//
// -------------------------
// Optional micro-test
// -------------------------
#ifdef TEST_HEX
extern const char* hexsimd_hex2bin_impl_name(void);

static void dump_features(void){
    isa_t f = detect_isa_runtime();
    printf("ISA: sse2=%d avx=%d avx2=%d avx512bw=%d avx512vl=%d\n",
           f.sse2, f.avx, f.avx2, f.avx512bw, f.avx512vl);
}


int main(void){
    dump_features(); 
    char *hx = "32D45FA2883337F16CAF523264E538D1AD89BD2924B67693AF1A7BCE7C6041AC96528A702C1FCAB51F75B14B6A5F20B1BAAFD93E9AC30769247EB6FAF408087F38E4BFB318CFA3A38FBA7206081ECEB9E7C4BC25201A14D5BCC6A6590B96A4738C9BCE941C541D688C8195550F6EF9CEEDD06353FB7A033AF63B40701632049C";
    size_t BIN_LEN = strlen(hx)+1;
    uint8_t *bin = malloc(BIN_LEN);
    char *back = malloc( (BIN_LEN * 2) +1);
    memset(back, 0x5A, BIN_LEN * 2);
		   
    //ptrdiff_t n = hex_to_bytes(hx, strlen(hx), bin, true);
    ptrdiff_t n = hex_to_bytes(hx, BIN_LEN-1, bin, true);
    if (n < 0) { puts("parse failed"); return 1; }
    ptrdiff_t m = bytes_to_hex(bin, (size_t)n, back);
    back[m] = 0;
    puts(hexsimd_hex2bin_impl_name());

    int match = strcmp(hx,back);

    if (match == 0 ){
        puts(back);
    } else {
	printf("match: %d\n", match);
        printf("Source: %s\n",hx);
        printf("  Dest: %s\n",back);
        printf("Error! Src and Dest do not match\n");
	// use scalar to convert back to hex and compare, as we know that works
	char *scalar_compare  = malloc( (BIN_LEN * 2) +1);
        memset(scalar_compare, 0x5A, BIN_LEN * 2);
	ptrdiff_t t = bytes_to_hex_scalar_impl(bin, (size_t)n,scalar_compare);
	scalar_compare[t] = 0;
	match = strcmp(hx,scalar_compare);
        if (match == 0 ){
            printf("Hex2Bin OK\n");
	} else {
            printf("Hex2Bin NOT OK\n");
	    printf("hx: %s\n", hx);
	    printf("sc: %s\n", scalar_compare);
	}
	return 1;
    }

    return 0;
}

#endif
