#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "skip32.c"

static void my_croak(char* pat, ...) {
    va_list args;
    SV *error_sv;

    dTHX;
    dSP;

    error_sv = newSV(0);

    va_start(args, pat);
    sv_vsetpvf(error_sv, pat, &args);
    va_end(args);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(error_sv));
    PUTBACK;
    call_pv("Carp::croak", G_VOID | G_DISCARD);
    FREETMPS;
    LEAVE;
}

typedef struct skip32 {
    unsigned char key[10];
} *Crypt__Skip32__XS;

MODULE = Crypt::Skip32::XS    PACKAGE = Crypt::Skip32::XS

PROTOTYPES: DISABLE

Crypt::Skip32::XS
new (class, key)
    SV *class
    SV *key
PREINIT:
    STRLEN key_size;
    unsigned char *bytes;
CODE:
    if (! SvPOK(key)) {
        my_croak("key must be an untainted string scalar");
    }

    bytes = (unsigned char *)SvPV(key, key_size);
    if (10 != key_size) {
        my_croak("key must be 10 bytes long");
    }

    New(0, RETVAL, 1, struct skip32);
    Copy(bytes, RETVAL->key, key_size, unsigned char);
OUTPUT:
    RETVAL

int
keysize (...)
CODE:
    RETVAL = 10;
OUTPUT:
    RETVAL

int
blocksize (...)
CODE:
    RETVAL = 4;
OUTPUT:
    RETVAL

SV *
decrypt (self, input)
    Crypt::Skip32::XS self
    SV *input
ALIAS:
    encrypt = 1
PREINIT:
    STRLEN block_size;
CODE:
    block_size = SvCUR(input);
    if (4 != block_size) {
        my_croak("%stext must be 4 bytes long", ix ? "plain" : "cipher");
    }

    RETVAL = newSVsv(input);
    skip32(self->key, (unsigned char *)SvPV(RETVAL, block_size), ix);
OUTPUT:
    RETVAL

void
DESTROY (self)
    Crypt::Skip32::XS self
CODE:
    Safefree(self);
