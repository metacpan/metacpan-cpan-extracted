/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static const char bit_count[] = { 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
                                  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                                  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                                  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                                  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                                  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                                  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                                  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                                  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                                  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                                  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                                  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                                  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                                  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                                  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                                  4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8 };

static IV
bu_first(pTHX_ SV *bv, SV *start_sv) {
    STRLEN len;
    const char *bytes = SvPV_const(bv, len);
    char byte;
    IV byte_ix;
    IV bit_ix;
    IV start;

    if (start_sv) {
        start = SvIV(start_sv);
        if (start < 0) start = 0;
    }
    else start = 0;

    byte_ix = start / 8;
    if (byte_ix >= len) return -1;
    bit_ix = start & 7;

    while (byte_ix < len) {
        if (byte = bytes[byte_ix]) {
            while (bit_ix < 8) {
                if ((byte >> bit_ix) & 1)
                    return byte_ix * 8 + bit_ix;
                bit_ix++;
            }
        }
        bit_ix = 0;
        byte_ix++;
    }
    return -1;
}

static IV
bu_last(pTHX_ SV *bv, SV *end_sv) {
    STRLEN len;
    const char *bytes = SvPV_const(bv, len);
    char byte;
    IV byte_ix;
    IV bit_ix;
    IV end;

    if (end_sv) {
        end = SvIV(end_sv);
        if (end < 0) return -1;
        byte_ix = end / 8;
    }
    else end = len * 8;

    byte_ix = end / 8;
    if (byte_ix < len)
        bit_ix = end & 7;
    else  {
        byte_ix = len - 1;
        bit_ix = 7;
    }

    while (byte_ix >= 0) {
        if (byte = bytes[byte_ix]) {
            while (bit_ix >= 0) {
                if ((byte >> bit_ix) & 1)
                    return byte_ix * 8 + bit_ix;
                bit_ix--;
            }
        }
        bit_ix = 7;
        byte_ix--;
    }
    return -1;
}

static IV
bu_count(pTHX_ SV *bv, SV *start_sv, SV *end_sv) {
    STRLEN len;
    const unsigned char *bytes = SvPV_const(bv, len);
    IV start;
    IV end;
    IV byte_ix;
    IV last_byte;
    IV bit_ix;
    IV count = 0;
    IV mask;

    start = (start_sv ? SvIV(start_sv) : 0 );
    if (start < 0) start = 0;
    if (start >= len * 8) return 0;

    end = (end_sv ? SvIV(end_sv) : len * 8);
    if (end > len * 8) end = len * 8;
    if (end <= start) return 0;

    byte_ix = start / 8;
    bit_ix = start & 7;

    last_byte = (end + 7)/ 8;
    
    mask = ~ ((1 << bit_ix) - 1);
    count = bit_count[bytes[byte_ix] & mask];

    byte_ix ++;
    while (byte_ix < last_byte) {
        count += bit_count[bytes[byte_ix]];
        byte_ix++;
    }

    if (bit_ix = end & 7) {
        mask = ~ ((1 << bit_ix) - 1);
        count -= bit_count[bytes[byte_ix -1] & mask];
    }

    return count;
}

MODULE = Bit::Util		PACKAGE = Bit::Util		

SV *
bu_first(bv, start = NULL)
    SV *bv
    SV *start
PREINIT:
    IV ix;
CODE:
    ix = bu_first(aTHX_ bv, start);
RETVAL = (ix < 0 ? &PL_sv_undef : newSViv(ix));
OUTPUT:
    RETVAL

SV *
bu_last(bv, end = NULL)
    SV *bv
    SV *end
PREINIT:
    IV ix;
CODE:
    ix = bu_last(aTHX_ bv, end);
    RETVAL = (ix < 0 ? &PL_sv_undef : newSViv(ix));
OUTPUT:
    RETVAL

IV
bu_count(bv, start = NULL, end = NULL)
    SV *bv
    SV *start
    SV *end
CODE:
    RETVAL = bu_count(aTHX_ bv, start, end);
OUTPUT:
    RETVAL
