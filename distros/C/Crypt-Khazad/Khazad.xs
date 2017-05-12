#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_khazad.c"

typedef struct khazad {
    NESSIEstruct key;
}* Crypt__Khazad;

MODULE = Crypt::Khazad		PACKAGE = Crypt::Khazad
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
        RETVAL = 8;
    OUTPUT:
        RETVAL

Crypt::Khazad
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

        Newz(0, RETVAL, 1, struct khazad);
        NESSIEkeysetup(SvPV_nolen(rawkey), &RETVAL->key);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Khazad self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Encryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            NESSIEencrypt(&self->key, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Khazad self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Decryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            NESSIEdecrypt(&self->key, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Khazad self
    CODE:
        Safefree(self);

