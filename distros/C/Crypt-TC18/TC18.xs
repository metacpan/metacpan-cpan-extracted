#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_tc18.c"

typedef struct tc18 {
    tc18_key key;
}* Crypt__TC18;

MODULE = Crypt::TC18		PACKAGE = Crypt::TC18
PROTOTYPES: DISABLE

Crypt::TC18
new(class, inkey)
    SV* inkey
    CODE:
    {
        STRLEN keyLength;
        if (! SvPOK(inkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(inkey);
        if (keyLength != 8)
            croak("Key setup error: Key must be 8 bytes long!");

        Newz(0, RETVAL, 1, struct tc18);
        setup(SvPV_nolen(inkey), 8, &RETVAL->key);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::TC18 self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Encryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            tc18_enc(intext, SvPV_nolen(RETVAL), &self->key);
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::TC18 self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Decryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            tc18_dec(intext, SvPV_nolen(RETVAL), &self->key);
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::TC18 self
    CODE:
        Safefree(self);

