#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pvbyte
#include "ppport.h"

#include <lz4.h>
#include <lz4hc.h>

MODULE = Compress::LZ4    PACKAGE = Compress::LZ4

PROTOTYPES: ENABLE

SV *
compress (sv, level=0)
    SV *sv
    IV level
ALIAS:
    compress_hc = 1
    lz4_compress = 2
    lz4_compress_hc = 3
PREINIT:
    char *src, *dest;
    STRLEN src_len, dest_len;
    int hc;
CODE:
    SvGETMAGIC(sv);
    if (SvROK(sv) && ! SvAMAGIC(sv)) {
        sv = SvRV(sv);
        SvGETMAGIC(sv);
    }
    if (! SvOK(sv))
        XSRETURN_NO;
    src = SvPVbyte(sv, src_len);
    if (! src_len)
        XSRETURN_NO;
    dest_len = LZ4_compressBound(src_len);
    if (2 > ix)
        dest_len += 4;
    RETVAL = newSV(dest_len);
    dest = SvPVX(RETVAL);
    if (! dest)
        XSRETURN_UNDEF;

    hc = ix & 1;
    if (2 > ix) {
        /* Add the length header as 4 bytes in little endian. */
        dest[0] = src_len       & 0xff;
        dest[1] = (src_len>> 8) & 0xff;
        dest[2] = (src_len>>16) & 0xff;
        dest[3] = (src_len>>24) & 0xff;

        dest_len = hc ? LZ4_compress_HC(src, dest + 4, src_len, dest_len, level)
                    : LZ4_compress_fast(src, dest + 4, src_len, dest_len, level);
        dest_len += 4;
    }
    else {
        dest_len = hc ? LZ4_compress_HC(src, dest, src_len, dest_len, level)
                    : LZ4_compress_fast(src, dest, src_len, dest_len, level);
    }

    if (! dest_len) {
        SvREFCNT_dec(RETVAL);
        XSRETURN_UNDEF;
    }
    SvCUR_set(RETVAL, dest_len);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

SV *
decompress (sv, len=0)
    SV *sv
    int len
ALIAS:
    uncompress = 1
    lz4_decompress = 2
    lz4_uncompress = 3
PREINIT:
    char *src, *dest;
    STRLEN src_len, dest_len;
    int ret;
CODE:
    PERL_UNUSED_VAR(ix);  /* -W */
    SvGETMAGIC(sv);
    if (SvROK(sv) && ! SvAMAGIC(sv)) {
        sv = SvRV(sv);
        SvGETMAGIC(sv);
    }
    if (! SvOK(sv))
        XSRETURN_NO;
    src = SvPVbyte(sv, src_len);
    if (! src_len )
        XSRETURN_NO;

    if (1 == items) {
        if (src_len < 5)
            XSRETURN_NO;

        /* Decode the length header. */
        dest_len = (src[0] & 0xff) | (src[1] & 0xff) << 8 | (src[2] & 0xff) << 16
                                | (src[3] & 0xff) << 24;
    }
    else
        dest_len = len;

    if (0 >= dest_len)
        XSRETURN_NO;

    RETVAL = newSV(dest_len);
    dest = SvPVX(RETVAL);
    if (! dest)
        XSRETURN_UNDEF;

    if (1 == items)
        ret = LZ4_decompress_safe(src + 4, dest, src_len - 4, dest_len);
    else
        ret = LZ4_decompress_safe(src, dest, src_len, dest_len);

    if (0 > ret) {
        SvREFCNT_dec(RETVAL);
        XSRETURN_UNDEF;
    }
    SvCUR_set(RETVAL, ret);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL
