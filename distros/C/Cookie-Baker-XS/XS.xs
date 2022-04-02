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
        if ((i + 2) < src_len && src[i] == '%' && isxdigit(src[i+1]) && isxdigit(src[i+2]) ) {
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
url_decode_val(pTHX_ const char *src, int src_len) {
    int dlen = 0, i = 0;
    char *d;
    SV * dst;

    // Values can be quoted
    if (src_len > 1 && src[0] == '"' && src[src_len-1] == '"' ) {
        src++;
        src_len -= 2;
    }

    dst = newSV(0);
    (void)SvUPGRADE(dst, SVt_PV);
    d = SvGROW(dst, src_len + 1);

    for (i = 0; i < src_len; i++ ) {
        if ( (i + 2) < src_len && src[i] == '%' && isxdigit(src[i+1]) && isxdigit(src[i+2]) ) {
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
    char *key, *key_p, *val_p, *val_end_p;
    int cur_len, key_len, val_len, key_size=64;
    STRLEN len_left_from_orig;
    HV *hv;
  CODE:
    hv = newHV();
    if ( SvOK(cookie) ) {
        Newx(key, key_size, char);
        key_p = (char *)SvPV(cookie, len_left_from_orig);

        while(len_left_from_orig > 0) {
            /* strip starting spaces */
            while(len_left_from_orig > 0 && (key_p[0] == ' ' || key_p[0] == ';')) {
                key_p++;
                len_left_from_orig--;
            }

            if (len_left_from_orig == 0) {
                break;
            }

            val_end_p = memchr(key_p, ';', len_left_from_orig);

            /* set cur_len to not count the ; */
            if (val_end_p == NULL) {
                cur_len = len_left_from_orig;
                val_end_p = key_p + cur_len;
                len_left_from_orig = 0;
            } else {
                cur_len = val_end_p - key_p;
                len_left_from_orig -= cur_len + 1;
            }

            val_p = memchr(key_p, '=', cur_len);
            if (val_p != NULL) {
                key_len = val_p - key_p;

                /* drop trailing spaces from key */
                while(key_len > 0 && key_p[key_len-1] == ' ') {
                    key_len--;
                }

                /* skip the = */
                val_p++;
                val_len = val_end_p - val_p;

                /* skip starting spaces from value */
                while(val_len > 0 && val_p[0] == ' ') {
                    val_p++;
                    val_len--;
                }
                /* skip trailing spaces from value */
                while(val_len > 0 && val_p[val_len-1] == ' ') {
                    val_len--;
                }

                renewmem(aTHX_ &key, &key_size, key_len);
                url_decode_key(key_p, key_len, key, &key_len);
                if ( !hv_exists(hv, key, key_len) ) {
                    (void)hv_store(hv, key, key_len,
                        url_decode_val(aTHX_ val_p, val_len), 0);
                }
            }

            if (len_left_from_orig == 0) {
                /* bypass bogus ptr math below */
                break;
            }

            key_p = val_end_p + 1;
        }

        Safefree(key);
    }
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

