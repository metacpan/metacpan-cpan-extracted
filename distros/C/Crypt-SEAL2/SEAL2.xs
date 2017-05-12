#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_seal2.c"

typedef struct seal2 {
    seal_ctx key;
}* Crypt__SEAL2;

MODULE = Crypt::SEAL2		PACKAGE = Crypt::SEAL2
PROTOTYPES: DISABLE

Crypt::SEAL2
new(class, rawkey)
    SV* class
    SV* rawkey
    CODE:
    {
        STRLEN keyLength;
        if (! SvPOK(rawkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(rawkey);
        if (keyLength != 20)
            croak("Key setup error: Key must be 20 bytes long!");

        Newz(0, RETVAL, 1, struct seal2);
        seal_key(&RETVAL->key, SvPV_nolen(rawkey));
    }

    OUTPUT:
        RETVAL

int
keysize(...)
    CODE:
        RETVAL = 20;
    OUTPUT:
        RETVAL

void
reset(self)
    Crypt::SEAL2 self
    CODE:
        seal_resynch(&self->key, 0);

void
repos(self, position)
    Crypt::SEAL2 self
    SV* position
    CODE:
        seal_repos(&self->key, SvUV(position));

SV*
encrypt(self, input)
    Crypt::SEAL2 self
    SV* input
    CODE:
    {
        STRLEN bufsize;
        unsigned char* intext = SvPV(input, bufsize);
        RETVAL = newSVpv("", bufsize);
        seal_encrypt(&self->key, intext, bufsize, SvPV_nolen(RETVAL));
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::SEAL2 self
    SV* input
    CODE:
    {
        STRLEN bufsize;
        unsigned char* intext = SvPV(input, bufsize);
        RETVAL = newSVpv("", bufsize);
        seal_encrypt(&self->key, intext, bufsize, SvPV_nolen(RETVAL));
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::SEAL2 self
    CODE:
        Safefree(self);

