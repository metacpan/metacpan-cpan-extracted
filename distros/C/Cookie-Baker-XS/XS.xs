#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

static char hextbl[256] = 
/*  0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f */
{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 0 */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 1 */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 2 */ 
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, /* 3 0-9 */ 
    0,10,11,12,13,14,15, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 4 @,A-Z */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 5 */
    0,10,11,12,13,14,15, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 6 `,a-z */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 7 */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 8 */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 9 */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* a */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* b */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* c */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* d */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* e */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* f */
};

static
void
url_decode_key(const char *src, int src_len, char *d, int *key_len) {
    int i, dlen=0;
    for (i = 0; i < src_len; i++ ) {
        if ( src[i] == '%' && isxdigit(src[i+1]) && isxdigit(src[i+2]) ) {
            d[dlen++] = hextbl[(U8)src[i+1]] * 16 + hextbl[(U8)src[i+2]];
            i += 2;
        }
        else {
            d[dlen++] = src[i];
        }
    }
    *key_len = dlen;
}

static SV *
url_decode_val(pTHX_ const char *src, int start, int end) {
    int dlen = 0, i = 0;
    char *d;
    SV * dst;

    // Values can be quoted
    if ( src[start] == '"' && src[end-1] == '"' ) {
        start++;
        --end;
    }

    dst = newSV(0);
    (void)SvUPGRADE(dst, SVt_PV);
    d = SvGROW(dst, (end - start) * 3 + 1);

    for (i = start; i < end; i++ ) {
        if ( src[i] == '%' && isxdigit(src[i+1]) && isxdigit(src[i+2]) ) {
            d[dlen++] = hextbl[(U8)src[i+1]] * 16 + hextbl[(U8)src[i+2]];
            i += 2;
        }
        else {
            d[dlen++] = src[i];
        }
    }

    SvCUR_set(dst, dlen);
    *SvEND(dst) = '\0';
    SvPOK_only(dst);
    return dst;
}


static
void
renewmem(pTHX_ char **d, int *cur, const int req) {
    if ( req > *cur ) {
        *cur = req;
        Renew(*d, *cur, char);
    }
}


MODULE = Cookie::Baker::XS    PACKAGE = Cookie::Baker::XS

PROTOTYPES: DISABLE

SV *
crush_cookie(cookie)
    SV *cookie
  PREINIT:
    char *src, *prev, *p, *key;
    int i, prev_s=0, la, key_len, key_size=64;
    STRLEN src_len;
    HV *hv;
  CODE:
    hv = newHV();
    if ( SvOK(cookie) ) {
        Newx(key, key_size, char);
        src = (char *)SvPV(cookie,src_len);
        prev = src;
        for ( i=0; i<src_len; i++ ) {
            if ( src[i] == ';' ) {
                while ( prev[0] == ' ' ) {
                    prev++;
                    prev_s++;
                }
                la = i - prev_s;
                while ( prev[la-1] == ' ' ) {
                    --la;
                }
                p = memchr(prev, '=', i - prev_s);
                if ( p != NULL ) {
                    renewmem(aTHX_ &key, &key_size, (p - prev)*3+1);
                    url_decode_key(prev, p - prev, key, &key_len);
                    if ( !hv_exists(hv, key, key_len) ) {
                        (void)hv_store(hv, key, key_len,
                            url_decode_val(aTHX_ prev, p - prev + 1, la ), 0);
                    }
                }
                prev = &src[i+1];
                prev_s = i + 1;
            }
        }
        if ( i > prev_s ) {
            while ( prev[0] == ' ' ) {
                prev++;
                prev_s++;
            }
            la = i - prev_s;
            while ( prev[la-1] == ' ' ) {
                --la;
            }
            p = memchr(prev, '=', i - prev_s);
            if ( p != NULL ) {
                renewmem(aTHX_ &key, &key_size, (p - prev)*3+1);
                url_decode_key(prev, p - prev, key, &key_len);
                if ( !hv_exists(hv, key, key_len) ) {
                    (void)hv_store(hv, key, key_len,
                        url_decode_val(aTHX_ prev, p - prev + 1, la ), 0);
                }
            }
        }
        Safefree(key);
    }
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

