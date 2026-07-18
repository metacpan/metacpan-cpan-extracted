#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "fpe.h"

MODULE = Crypt::FPE::FF1  PACKAGE = Crypt::FPE::FF1
PROTOTYPES: ENABLE

SV*
__create_key(CLASS, key, tweak, radix)
    const char *CLASS
    SV* key
    SV* tweak
    unsigned int radix
  PREINIT:
    STRLEN keylen = 0, twklen = 0;
    const char *k = SvPV(key,   keylen);
    const char *t = SvPV(tweak, twklen);
    FPE_KEY *ks = NULL;
  CODE:
    ks = FPE_ff1_create_key(k, t, radix);
    if (!ks) croak("FPE_ff1_create_key failed");
    {
      SV *inner = newSViv(PTR2IV(ks));
      SV *rv    = newRV_noinc(inner);
      RETVAL = sv_bless(rv, gv_stashpv(CLASS, GV_ADD));
    }
  OUTPUT: RETVAL

unsigned int
__radix(self)
    SV* self
  PREINIT:
    FPE_KEY *ks = NULL;
  CODE:
    if (!SvROK(self)) croak("bad self");
    ks = INT2PTR(FPE_KEY*, SvIV(SvRV(self)));
    RETVAL = ks->radix;
  OUTPUT: RETVAL

void
DESTROY(self)
    SV* self
  PREINIT:
    FPE_KEY *ks = NULL;
  CODE:
    if (!SvROK(self)) XSRETURN_EMPTY;
    ks = INT2PTR(FPE_KEY*, SvIV(SvRV(self)));
    if (ks) FPE_ff1_delete_key(ks);

SV*
__encrypt(self, plaintext)
    SV* self
    SV* plaintext
  PREINIT:
    FPE_KEY *ks = NULL;
    STRLEN inlen = 0;
    char *in = NULL;
    char *out = NULL;
  CODE:
    if (!SvROK(self)) croak("bad self");
    ks = INT2PTR(FPE_KEY*, SvIV(SvRV(self)));
    in = SvPV(plaintext, inlen);
    out = (char*)safemalloc(inlen + 1);
    FPE_ff1_encrypt(in, out, ks);
    out[inlen] = '\0';
    RETVAL = newSVpv(out, 0);
    safefree(out);
  OUTPUT: RETVAL

SV*
__decrypt(self, ciphertext)
    SV* self
    SV* ciphertext
  PREINIT:
    FPE_KEY *ks = NULL;
    STRLEN inlen = 0;
    char *in = NULL;
    char *out = NULL;
  CODE:
    if (!SvROK(self)) croak("bad self");
    ks = INT2PTR(FPE_KEY*, SvIV(SvRV(self)));
    in = SvPV(ciphertext, inlen);
    out = (char*)safemalloc(inlen + 1);
    FPE_ff1_decrypt(in, out, ks);
    out[inlen] = '\0';
    RETVAL = newSVpv(out, 0);
    safefree(out);
  OUTPUT: RETVAL
