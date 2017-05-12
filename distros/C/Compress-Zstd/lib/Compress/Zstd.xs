#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define NEED_newCONSTSUB
#include "ppport.h"
#include "zstd.h"
#include "compress/zstdmt_compress.h"

MODULE = Compress::Zstd PACKAGE = Compress::Zstd

BOOT:
{
    HV* stash = gv_stashpv("Compress::Zstd", 1);
    newCONSTSUB(stash, "ZSTD_VERSION_NUMBER", newSViv(ZSTD_VERSION_NUMBER));
    newCONSTSUB(stash, "ZSTD_VERSION_STRING", newSVpvs(ZSTD_VERSION_STRING));
    newCONSTSUB(stash, "ZSTD_MAX_CLEVEL", newSViv(ZSTD_maxCLevel()));
}

PROTOTYPES: DISABLE

void
compress(source, level = 1)
    SV* source;
    int level;
PREINIT:
    const char* src;
    STRLEN src_len;
    SV* dest;
    char* dst;
    size_t bound, ret;
PPCODE:
    if (SvROK(source)) {
        source = SvRV(source);
    }
    if (!SvOK(source)) {
        XSRETURN_UNDEF;
    }
    src = SvPVbyte(source, src_len);
    bound = ZSTD_compressBound(src_len);
    dest = sv_2mortal(newSV(bound + 1));
    dst = SvPVX(dest);
    ret = ZSTD_compress(dst, bound + 1, src, src_len, level);
    if (ZSTD_isError(ret)) {
        XSRETURN_UNDEF;
    }
    dst[ret] = '\0';
    SvCUR_set(dest, ret);
    SvPOK_on(dest);
    EXTEND(SP, 1);
    PUSHs(dest);

void
compress_mt(source, nbThreads, level = 1)
    SV* source;
    unsigned int nbThreads;
    int level;
PREINIT:
    const char* src;
    STRLEN src_len;
    SV* dest;
    char* dst;
    size_t bound, ret;
    ZSTDMT_CCtx* cctx;
PPCODE:
    if (SvROK(source)) {
        source = SvRV(source);
    }
    if (!SvOK(source)) {
        XSRETURN_UNDEF;
    }
    cctx = ZSTDMT_createCCtx(nbThreads);
    src = SvPVbyte(source, src_len);
    bound = ZSTD_compressBound(src_len);
    dest = sv_2mortal(newSV(bound + 1));
    dst = SvPVX(dest);
    ret = ZSTDMT_compressCCtx(cctx, dst, bound + 1, src, src_len, level);
    ZSTDMT_freeCCtx(cctx);
    if (ZSTD_isError(ret)) {
        XSRETURN_UNDEF;
    }
    dst[ret] = '\0';
    SvCUR_set(dest, ret);
    SvPOK_on(dest);
    EXTEND(SP, 1);
    PUSHs(dest);

void
decompress(source)
    SV* source;
ALIAS:
    uncompress = 1
PREINIT:
    const char* src;
    STRLEN src_len;
    unsigned long long dest_len;
    SV* dest;
    char* dst;
    size_t ret;
PPCODE:
    if (SvROK(source)) {
        source = SvRV(source);
    }
    if (!SvOK(source)) {
        XSRETURN_UNDEF;
    }
    src = SvPVbyte(source, src_len);
    dest_len = ZSTD_getDecompressedSize(src, src_len);
    if (dest_len == ULLONG_MAX) {
        XSRETURN_UNDEF;
    }
    dest = sv_2mortal(newSV(dest_len + 1));
    dst = SvPVX(dest);
    ret = ZSTD_decompress(dst, dest_len + 1, src, src_len);
    if (ZSTD_isError(ret)) {
        XSRETURN_UNDEF;
    }
    dst[ret] = '\0';
    SvCUR_set(dest, ret);
    SvPOK_on(dest);
    EXTEND(SP, 1);
    PUSHs(dest);
