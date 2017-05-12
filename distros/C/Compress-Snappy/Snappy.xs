#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pvbyte
#include "ppport.h"

#include "src/csnappy_compress.c"
#include "src/csnappy_decompress.c"

MODULE = Compress::Snappy    PACKAGE = Compress::Snappy

PROTOTYPES: ENABLE

SV *
compress (sv)
    SV *sv
PREINIT:
    char *src, *dest;
    STRLEN src_len;
    uint32_t dest_len;
    void *working_memory;
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
    dest_len = csnappy_max_compressed_length(src_len);
    if (! dest_len)
        XSRETURN_UNDEF;
    Newx(working_memory, CSNAPPY_WORKMEM_BYTES, void *);
    if (! working_memory)
        XSRETURN_UNDEF;
    RETVAL = newSV(dest_len);
    dest = SvPVX(RETVAL);
    if (! dest)
        XSRETURN_UNDEF;
    csnappy_compress(src, src_len, dest, &dest_len, working_memory,
                     CSNAPPY_WORKMEM_BYTES_POWER_OF_TWO);
    Safefree(working_memory);
    SvCUR_set(RETVAL, dest_len);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

SV *
decompress (sv)
    SV *sv
ALIAS:
    uncompress = 1
PREINIT:
    char *src, *dest;
    STRLEN src_len;
    uint32_t dest_len;
    int header_len;
CODE:
    PERL_UNUSED_VAR(ix); /* -W */
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
    header_len = csnappy_get_uncompressed_length(src, src_len, &dest_len);
    if (0 > header_len || ! dest_len)
        XSRETURN_UNDEF;
    RETVAL = newSV(dest_len);
    dest = SvPVX(RETVAL);
    if (! dest)
        XSRETURN_UNDEF;
    if (csnappy_decompress_noheader(src + header_len, src_len - header_len,
                                    dest, &dest_len))
        XSRETURN_UNDEF;
    SvCUR_set(RETVAL, dest_len);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL
