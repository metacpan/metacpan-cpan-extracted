#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>

#if defined(__AVX2__) || defined(__SSE4_2__)
#include <immintrin.h>
#endif

/* Fetch the raw int64_t buffer behind a packed Perl string. rw forces
   the SV out of copy-on-write before we write into its buffer. */
static int64_t *
aeps_buf(pTHX_ SV *sv, IV window, int rw)
{
    STRLEN len;
    char *p = rw ? SvPV_force(sv, len) : SvPV(sv, len);
    if ((IV) len < window * (IV) sizeof(int64_t))
        croak("Algorithm::EventsPerSecond: ring buffer smaller than window");
    return (int64_t *) p;
}

static int64_t
aeps_count(int64_t *buckets, int64_t *stamps, IV window, IV oldest)
{
    int64_t sum = 0;
    IV i = 0;

#if defined(__AVX2__)
    /* 4 buckets per iteration: stamps >= oldest becomes an all-ones
       lane mask (>= via > oldest-1), which gates the bucket values
       feeding a vector accumulator. */
    {
        __m256i vsum   = _mm256_setzero_si256();
        __m256i cutoff = _mm256_set1_epi64x((int64_t) oldest - 1);
        int64_t lanes[4];
        for (; i + 4 <= window; i += 4) {
            __m256i s    = _mm256_loadu_si256((__m256i const *) (stamps + i));
            __m256i b    = _mm256_loadu_si256((__m256i const *) (buckets + i));
            __m256i keep = _mm256_cmpgt_epi64(s, cutoff);
            vsum = _mm256_add_epi64(vsum, _mm256_and_si256(b, keep));
        }
        _mm256_storeu_si256((__m256i *) lanes, vsum);
        sum = lanes[0] + lanes[1] + lanes[2] + lanes[3];
    }
#elif defined(__SSE4_2__)
    /* Same masked sum, 2 buckets per iteration. */
    {
        __m128i vsum   = _mm_setzero_si128();
        __m128i cutoff = _mm_set1_epi64x((int64_t) oldest - 1);
        int64_t lanes[2];
        for (; i + 2 <= window; i += 2) {
            __m128i s    = _mm_loadu_si128((__m128i const *) (stamps + i));
            __m128i b    = _mm_loadu_si128((__m128i const *) (buckets + i));
            __m128i keep = _mm_cmpgt_epi64(s, cutoff);
            vsum = _mm_add_epi64(vsum, _mm_and_si128(b, keep));
        }
        _mm_storeu_si128((__m128i *) lanes, vsum);
        sum = lanes[0] + lanes[1];
    }
#endif

    /* Tail (and whole loop when no intrinsics were compiled in);
       branchless so -O3 can auto-vectorize it. */
    for (; i < window; i++)
        sum += buckets[i] & -(int64_t) (stamps[i] >= (int64_t) oldest);

    return sum;
}

MODULE = Algorithm::EventsPerSecond::XS   PACKAGE = Algorithm::EventsPerSecond::XS

PROTOTYPES: DISABLE

void
_xs_mark(SV *buckets_sv, SV *stamps_sv, IV window, IV now, IV count)
    CODE:
    {
        int64_t *buckets = aeps_buf(aTHX_ buckets_sv, window, 1);
        int64_t *stamps  = aeps_buf(aTHX_ stamps_sv,  window, 1);
        IV i = now % window;

        if (stamps[i] != (int64_t) now) {
            buckets[i] = 0;
            stamps[i]  = (int64_t) now;
        }
        buckets[i] += (int64_t) count;
    }

IV
_xs_count(SV *buckets_sv, SV *stamps_sv, IV window, IV oldest)
    CODE:
        RETVAL = (IV) aeps_count(
            aeps_buf(aTHX_ buckets_sv, window, 0),
            aeps_buf(aTHX_ stamps_sv,  window, 0),
            window, oldest);
    OUTPUT:
        RETVAL

const char *
_xs_simd()
    CODE:
#if defined(__AVX2__)
        RETVAL = "AVX2";
#elif defined(__SSE4_2__)
        RETVAL = "SSE4.2";
#else
        RETVAL = "scalar";
#endif
    OUTPUT:
        RETVAL
