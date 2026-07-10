#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <math.h>

/* 32-bit FNV-1a. uint32_t arithmetic wraps mod 2**32 for free, which is both
 * faster and more robust than doing the masking by hand in pure Perl. The seed
 * is folded into the offset basis so two hashed columns can be decorrelated;
 * the pure-Perl fallback in Mungers.pm does the identical thing, so the two
 * paths agree bit for bit. */

MODULE = Algorithm::ToNumberMunger  PACKAGE = Algorithm::ToNumberMunger

PROTOTYPES: DISABLE

UV
_fnv1a_xs(str, seed)
    SV *str
    UV  seed
  PREINIT:
    STRLEN len;
    const unsigned char *p;
    U32 h;
    STRLEN i;
  CODE:
    /* Hash the UTF-8 byte encoding of the string's characters, regardless of
     * the scalar's internal flag. This is well-defined for any input (a wide
     * character would make SvPVbyte croak) and matches the pure-Perl fallback,
     * which utf8-encodes before hashing. */
    p = (const unsigned char *) SvPVutf8(str, len);
    h = (U32) 2166136261UL ^ (U32) seed;
    for (i = 0; i < len; i++) {
        h ^= (U32) p[i];
        h *= (U32) 16777619UL;
    }
    RETVAL = (UV) h;
  OUTPUT:
    RETVAL

NV
_entropy_xs(str)
    SV *str
  PREINIT:
    STRLEN len;
    const unsigned char *p;
    STRLEN i;
    UV counts[256];
    NV h, n, pr, ln2;
  CODE:
    /* Shannon entropy (in bits) over the UTF-8 bytes of the string, matching
     * the pure-Perl fallback's byte view. A single per-byte count pass plus a
     * pass over the (at most 256) seen values -- the loop and the log() per
     * distinct byte are what make this worth doing in C. */
    p = (const unsigned char *) SvPVutf8(str, len);
    if (len == 0) {
        RETVAL = 0.0;
    }
    else {
        Zero(counts, 256, UV);
        for (i = 0; i < len; i++)
            counts[p[i]]++;
        n   = (NV) len;
        ln2 = log((NV) 2.0);
        h   = 0.0;
        for (i = 0; i < 256; i++) {
            if (counts[i]) {
                pr = (NV) counts[i] / n;
                h -= pr * (log(pr) / ln2);
            }
        }
        RETVAL = h;
    }
  OUTPUT:
    RETVAL
