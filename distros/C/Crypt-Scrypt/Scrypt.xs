#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pvbyte
#include "ppport.h"

#undef VERSION
#include "scrypt_platform.h"
#include "scryptenc.h"

MODULE = Crypt::Scrypt    PACKAGE = Crypt::Scrypt

PROTOTYPES: ENABLE

void
_encrypt (in, key, max_mem, max_mem_frac, max_time)
    SV *in
    SV *key
    size_t max_mem
    double max_mem_frac
    double max_time
PREINIT:
    char *in_str, *key_str, *out_str;
    STRLEN in_len, key_len;
    int status;
PPCODE:
    if (SvROK(in)) in = SvRV(in);
    in_str = SvPVbyte(in, in_len);
    key_str = SvPVbyte(key, key_len);
    Newx(out_str, 128 + in_len, char);
    status = scryptenc_buf((const uint8_t *)in_str, in_len,
                           (uint8_t *)out_str,
                           (const uint8_t *)key_str, key_len,
                           max_mem, max_mem_frac, max_time);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(status)));
    if (! status)
        PUSHs(sv_2mortal(newSVpvn(out_str, 128 + in_len)));
    Safefree(out_str);

void
_decrypt (in, key, max_mem, max_mem_frac, max_time)
    SV *in
    SV *key
    size_t max_mem
    double max_mem_frac
    double max_time
PREINIT:
    char *in_str, *key_str, *out_str;
    STRLEN in_len, key_len, out_len;
    int status;
PPCODE:
    if (SvROK(in)) in = SvRV(in);
    in_str = SvPVbyte(in, in_len);
    key_str = SvPVbyte(key, key_len);
    Newx(out_str, in_len - 128, char);
    status = scryptdec_buf((const uint8_t *)in_str, in_len,
                           (uint8_t *)out_str, &out_len,
                           (const uint8_t *)key_str, key_len,
                           max_mem, max_mem_frac, max_time);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(status)));
    if (! status)
        PUSHs(sv_2mortal(newSVpvn(out_str, out_len)));
    Safefree(out_str);
