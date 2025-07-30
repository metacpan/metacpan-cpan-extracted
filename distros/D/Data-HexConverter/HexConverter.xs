#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <tmmintrin.h>
#include <stdlib.h>

/*
 * This XS module exposes a single function, hex_to_binary(), which
 * converts an even-length ASCII hex string into a binary octet
 * sequence.  The implementation below is adapted from an OCI-based
 * function and rewritten to operate on plain C data.  It uses the
 * SSSE3 intrinsics _mm_shuffle_epi8() and friends to process 32
 * characters at a time.  Remaining bytes are handled with a
 * lookup table.  Before any conversions occur the lookup table is
 * initialised in BOOT: using init_hex_lookup_table().
 */

static unsigned char hex_lookup[256];
static int hex_lookup_initialised = 0;

/*
 * Determine at runtime whether the current CPU supports the SSSE3
 * instruction set.  These builtins query CPUID without needing
 * special privileges.  When unavailable (non-gcc/clang compilers),
 * assume false.
 */
static int
cpu_has_ssse3(void)
{
#if defined(__GNUC__) || defined(__clang__)
    __builtin_cpu_init();
    return __builtin_cpu_supports("ssse3");
#else
    return 0;
#endif
}

/*
 * Initialise the global lookup table mapping ASCII characters
 * '0'–'9', 'A'–'F' and 'a'–'f' to their numeric nibble values.  All
 * other values map to 0xFF to indicate invalid input.  This table
 * only needs to be initialised once and is invoked from BOOT:
 * during module loading.
 */
static void
init_hex_lookup_table(void)
{
    for (int i = 0; i < 256; i++)
        hex_lookup[i] = 0xFF;
    for (int i = '0'; i <= '9'; i++)
        hex_lookup[i] = (unsigned char)(i - '0');
    for (int i = 'A'; i <= 'F'; i++)
        hex_lookup[i] = (unsigned char)(i - 'A' + 10);
    for (int i = 'a'; i <= 'f'; i++)
        hex_lookup[i] = (unsigned char)(i - 'a' + 10);
    hex_lookup_initialised = 1;
}

/*
 * Convert a buffer of ASCII hex characters into its binary form.
 * The length n must be even.  binary_out must have at least n/2
 * bytes of space.  Returns 0 on success or -1 on error.  If an
 * invalid character is found, err_msg will point at a static
 * message; this pointer is never freed.
 */

MODULE = Data::HexConverter   PACKAGE = Data::HexConverter

BOOT:
    /* Ensure the lookup table is ready when the module is loaded */
    if (!hex_lookup_initialised) {
        init_hex_lookup_table();
    }

SV*
hex_to_binary(SV* hex_ref)
    PREINIT:
        SV    *sv_hex;
        STRLEN hex_len;
        unsigned char *hex_str;
        unsigned char *binary_out;
        char  *err_msg = NULL;
        int    rc;
        size_t i;
        int    has_ssse3;
    PPCODE:
        /* Validate that the argument is a reference to a scalar */
        if (!SvROK(hex_ref)) {
            croak("Argument must be a reference to a scalar containing a hex string");
        }
        sv_hex = SvRV(hex_ref);
        /* Trigger FETCH on tied values, if necessary */
        SvGETMAGIC(sv_hex);
        /* If the string is UTF-8, downgrade it to a byte string.  See perlguts
         * for more details on SvUTF8 and sv_utf8_downgrade().
         */
        if (SvUTF8(sv_hex) && !sv_utf8_downgrade(sv_hex, TRUE)) {
            croak("Input string must contain only ASCII characters and be downgradeable");
        }
        /* Retrieve the raw bytes and length from the SV.  Use SvPVbyte() to
         * obtain a pointer to the internal buffer and its length.  This macro
         * returns the byte string regardless of the UTF-8 flag and stores
         * the length in hex_len.
         */
        hex_str = (unsigned char *)SvPVbyte(sv_hex, hex_len);
        if (hex_len == 0) {
            /* An empty input yields an empty output */
            XPUSHs(sv_2mortal(newSVpvs("")));
            XSRETURN(1);
        }
        /* Ensure the input string has an even number of characters */
        if ((hex_len & 1) != 0) {
            croak("Hex string length must be even");
        }
        binary_out = (unsigned char *)malloc(hex_len / 2);
        if (!binary_out) {
            croak("Memory allocation failed");
        }
        has_ssse3 = cpu_has_ssse3();
        if (has_ssse3) {
            /* Perform SSSE3 conversion inline.  Process 32 input characters at
             * a time (16 output bytes per iteration).  idxEven and idxOdd
             * shuffle masks are defined once outside the loop.  */
            __m128i idxEven = _mm_setr_epi8(
                0,  2,  4,  6,  8, 10, 12, 14,
                (char)0x80,(char)0x80,(char)0x80,(char)0x80,
                (char)0x80,(char)0x80,(char)0x80,(char)0x80
            );
            __m128i idxOdd = _mm_setr_epi8(
                1,  3,  5,  7,  9, 11, 13, 15,
                (char)0x80,(char)0x80,(char)0x80,(char)0x80,
                (char)0x80,(char)0x80,(char)0x80,(char)0x80
            );
            for (i = 0; i + 32 <= (size_t)hex_len; i += 32) {
                __m128i block1 = _mm_loadu_si128((const __m128i *)(hex_str + i));
                __m128i block2 = _mm_loadu_si128((const __m128i *)(hex_str + i + 16));
                __m128i evens_block1 = _mm_shuffle_epi8(block1, idxEven);
                __m128i odds_block1  = _mm_shuffle_epi8(block1, idxOdd);
                __m128i evens_block2 = _mm_shuffle_epi8(block2, idxEven);
                __m128i odds_block2  = _mm_shuffle_epi8(block2, idxOdd);
                __m128i evens = _mm_or_si128(evens_block1,
                                             _mm_slli_si128(evens_block2, 8));
                __m128i odds  = _mm_or_si128(odds_block1,
                                             _mm_slli_si128(odds_block2,  8));
                __m128i zero = _mm_set1_epi8('0');
                evens = _mm_sub_epi8(evens, zero);
                odds  = _mm_sub_epi8(odds,  zero);
                __m128i chars_evens = _mm_add_epi8(evens, zero);
                __m128i chars_odds  = _mm_add_epi8(odds,  zero);
                __m128i upperA = _mm_set1_epi8('A' - 1);
                __m128i upperF = _mm_set1_epi8('F' + 1);
                __m128i lowerA = _mm_set1_epi8('a' - 1);
                __m128i lowerF = _mm_set1_epi8('f' + 1);
                __m128i ucase_mask_e = _mm_and_si128(_mm_cmpgt_epi8(chars_evens, upperA),
                                                     _mm_cmplt_epi8(chars_evens, upperF));
                __m128i lcase_mask_e = _mm_and_si128(_mm_cmpgt_epi8(chars_evens, lowerA),
                                                     _mm_cmplt_epi8(chars_evens, lowerF));
                __m128i ucase_mask_o = _mm_and_si128(_mm_cmpgt_epi8(chars_odds,  upperA),
                                                     _mm_cmplt_epi8(chars_odds,  upperF));
                __m128i lcase_mask_o = _mm_and_si128(_mm_cmpgt_epi8(chars_odds,  lowerA),
                                                     _mm_cmplt_epi8(chars_odds,  lowerF));
                evens = _mm_sub_epi8(evens,
                                     _mm_and_si128(ucase_mask_e,
                                                   _mm_set1_epi8(7)));
                odds  = _mm_sub_epi8(odds,
                                     _mm_and_si128(ucase_mask_o,
                                                   _mm_set1_epi8(7)));
                evens = _mm_sub_epi8(evens,
                                     _mm_and_si128(lcase_mask_e,
                                                   _mm_set1_epi8(39)));
                odds  = _mm_sub_epi8(odds,
                                     _mm_and_si128(lcase_mask_o,
                                                   _mm_set1_epi8(39)));
                __m128i high_shifted = _mm_slli_epi16(evens, 4);
                __m128i bytes = _mm_or_si128(high_shifted, odds);
                _mm_storeu_si128((__m128i *)(binary_out + i/2), bytes);
            }
        } else {
            /* SSSE3 not available: warn and start scalar conversion at i=0 */
            warn("Data::HexConverter: SSSE3 not supported, falling back to scalar implementation\n");
            i = 0;
        }
        /* Convert any remaining bytes or the entire buffer if no SSSE3 support */
        for (; i < (size_t)hex_len; i += 2) {
            unsigned char high = hex_lookup[hex_str[i]];
            unsigned char low  = hex_lookup[hex_str[i + 1]];
            if (high == 0xFF || low == 0xFF) {
                free(binary_out);
                croak("Invalid hex digit");
            }
            binary_out[i / 2] = (high << 4) | low;
        }
        {
            SV *result = newSVpvn((const char *)binary_out, hex_len/2);
            free(binary_out);
            XPUSHs(sv_2mortal(result));
            XSRETURN(1);
        }

SV*
binary_to_hex(SV* bin_ref)
    PREINIT:
        SV    *sv_bin;
        STRLEN bin_len;
        unsigned char *bin_str;
        unsigned char *hex_out;
        size_t i;
        int    has_ssse3;
    PPCODE:
        /* Validate argument: must be a reference to a scalar */
        if (!SvROK(bin_ref)) {
            croak("Argument must be a reference to a scalar containing binary data");
        }
        sv_bin = SvRV(bin_ref);
        SvGETMAGIC(sv_bin);
        /* Ensure a bytestring, not UTF-8 */
        if (SvUTF8(sv_bin) && !sv_utf8_downgrade(sv_bin, TRUE)) {
            croak("Binary data must be a bytestring");
        }
        bin_str = (unsigned char *)SvPVbyte(sv_bin, bin_len);
        if (bin_len == 0) {
            XPUSHs(sv_2mortal(newSVpvs("")));
            XSRETURN(1);
        }
        /* Allocate output: two hex characters per byte */
        hex_out = (unsigned char *)malloc(bin_len * 2);
        if (!hex_out) {
            croak("Memory allocation failed");
        }
        has_ssse3 = cpu_has_ssse3();
        if (has_ssse3) {
            /* SIMD: process 16 bytes at a time */
            __m128i mask0f = _mm_set1_epi8(0x0F);
            __m128i nine   = _mm_set1_epi8(9);
            __m128i ascii_zero    = _mm_set1_epi8('0');
            __m128i ascii_Aminus10 = _mm_set1_epi8('A' - 10);
            for (i = 0; i + 16 <= (size_t)bin_len; i += 16) {
                __m128i bytes = _mm_loadu_si128((const __m128i *)(bin_str + i));
                __m128i high_nibble = _mm_and_si128(_mm_srli_epi16(bytes, 4), mask0f);
                __m128i low_nibble  = _mm_and_si128(bytes, mask0f);
                __m128i gt9_hi = _mm_cmpgt_epi8(high_nibble, nine);
                __m128i base_hi = _mm_or_si128(
                    _mm_andnot_si128(gt9_hi, ascii_zero),
                    _mm_and_si128(gt9_hi, ascii_Aminus10)
                );
                __m128i ascii_hi = _mm_add_epi8(high_nibble, base_hi);
                __m128i gt9_lo = _mm_cmpgt_epi8(low_nibble, nine);
                __m128i base_lo = _mm_or_si128(
                    _mm_andnot_si128(gt9_lo, ascii_zero),
                    _mm_and_si128(gt9_lo, ascii_Aminus10)
                );
                __m128i ascii_lo = _mm_add_epi8(low_nibble, base_lo);
                __m128i interleaved_lo = _mm_unpacklo_epi8(ascii_hi, ascii_lo);
                __m128i interleaved_hi = _mm_unpackhi_epi8(ascii_hi, ascii_lo);
                _mm_storeu_si128((__m128i *)(hex_out + (i * 2)),      interleaved_lo);
                _mm_storeu_si128((__m128i *)(hex_out + (i * 2) + 16), interleaved_hi);
            }
        } else {
            /* Scalar fallback: warn user */
            warn("Data::HexConverter: SSSE3 not supported, falling back to scalar implementation\n");
            i = 0;
        }
        /* Scalar loop for remainder or entire input */
        for (; i < (size_t)bin_len; i++) {
            unsigned char b = bin_str[i];
            unsigned char high = (unsigned char)(b >> 4);
            unsigned char low  = (unsigned char)(b & 0x0F);
            hex_out[2 * i]     = (char)((high < 10) ? (high + '0') : (high + 'A' - 10));
            hex_out[2 * i + 1] = (char)((low  < 10) ? (low  + '0') : (low  + 'A' - 10));
        }
        {
            SV *result = newSVpvn((const char *)hex_out, bin_len * 2);
            free(hex_out);
            XPUSHs(sv_2mortal(result));
            XSRETURN(1);
        }
