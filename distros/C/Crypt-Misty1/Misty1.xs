#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_misty1.c"

typedef struct misty1 {
    unsigned int key[32];
}* Crypt__Misty1;

MODULE = Crypt::Misty1		PACKAGE = Crypt::Misty1
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

Crypt::Misty1
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

        Newz(0, RETVAL, 1, struct misty1);
        keyinit(SvPV_nolen(rawkey), RETVAL->key);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Misty1 self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        void* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Encryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            misty1_encrypt(self->key, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Misty1 self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        void* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Decryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            misty1_decrypt(self->key, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Misty1 self
    CODE:
        Safefree(self);

