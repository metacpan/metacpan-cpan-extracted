#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_anubis.c"

typedef struct anubis {
    NESSIEstruct key;
}* Crypt__Anubis;

MODULE = Crypt::Anubis		PACKAGE = Crypt::Anubis
PROTOTYPES: DISABLE

int
keysize(...)
    CODE:
        RETVAL = 16;
    OUTPUT:
        RETVAL

int
blocksize(...)
    CODE:
        RETVAL = 16;
    OUTPUT:
        RETVAL

Crypt::Anubis
new(class, rawkey)
    SV* class
    SV* rawkey
    CODE:
    {
        STRLEN keyLength;
        if (! SvPOK(rawkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(rawkey);
        if (keyLength != 16)
            croak("Key setup error: Key must be 16 bytes long!");

        Newz(0, RETVAL, 1, struct anubis);
        NESSIEkeysetup(SvPV_nolen(rawkey), &RETVAL->key);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Anubis self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Encryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            NESSIEencrypt(&self->key, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Anubis self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Decryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            NESSIEdecrypt(&self->key, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Anubis self
    CODE:
        Safefree(self);

