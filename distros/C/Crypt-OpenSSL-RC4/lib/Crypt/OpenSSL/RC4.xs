#ifdef __cplusplus
extern "C" {
#endif
#include <openssl/rc4.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    if (obj == NULL) { \
        sv_setsv(sv, &PL_sv_undef); \
    } else { \
        sv_setref_pv(sv, class, (void *) obj); \
    }

MODULE = Crypt::OpenSSL::RC4  PACKAGE = Crypt::OpenSSL::RC4

RC4_KEY*
Crypt::OpenSSL::RC4::new(SV* keysv)
PREINIT:
    RC4_KEY* self;
    STRLEN len;
    unsigned char *key;
CODE:
    key = (unsigned char*)SvPV(keysv, len);
    Newx(self, 1, RC4_KEY);
    RC4_set_key(
        self,
        len,
        key
    );
    RETVAL = self;
OUTPUT:
    RETVAL

void
DESTROY(RC4_KEY* self)
CODE:
    Safefree(self);

SV*
_rc4(RC4_KEY*self, SV* insv)
PREINIT:
    STRLEN len;
    unsigned char * indata;
CODE:
    unsigned char *buf;
    indata = (unsigned char*)SvPV(insv, len);
    Newx(buf, len, unsigned char);
    RC4(self, len, indata, buf);
    SV * ret = newSVpv((char*)buf, len);
    Safefree(buf);
    RETVAL = ret;
OUTPUT:
    RETVAL

