#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if USE_X64
#include "curve25519-donna-c64.c"
#else
#include "curve25519-donna.c"
#endif

static u8* S_get_buffer(pTHX_ SV* variable, const char* name) {
	STRLEN len;
	u8* ret = (u8*) SvPV(variable, len);
	if (len != 32)
		Perl_croak(aTHX_ "%s requires 32 bytes", name);
	return ret;
}
#define get_buffer(variable, name) S_get_buffer(aTHX_ variable, name)

typedef u8 keybuffer[32];
typedef const u8* keyptr;

static const keybuffer basepoint = {9};

MODULE = Crypt::Curve25519		PACKAGE = Crypt::Curve25519

PROTOTYPES: DISABLED

keybuffer
curve25519_public_key(secret, base = 9)
    keyptr secret = get_buffer(ST(0), "Secret key");
    keyptr base = items > 1 ? get_buffer(ST(1), "Basepoint") : basepoint;
    CODE:
    curve25519_donna(RETVAL, secret, base);
    OUTPUT:
    RETVAL

keybuffer
curve25519_shared_secret(secret, public)
    keyptr secret = get_buffer(ST(0), "Secret key");
    keyptr public = get_buffer(ST(1), "Public key");
    ALIAS:
        curve25519 = 1
    CODE:
    curve25519_donna(RETVAL, secret, public);
    OUTPUT:
    RETVAL
