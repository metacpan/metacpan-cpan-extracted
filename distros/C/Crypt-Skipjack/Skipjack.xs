#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_skipjack.c"

typedef struct skipjack {
    unsigned char tab[10][256];
}* Crypt__Skipjack;

MODULE = Crypt::Skipjack		PACKAGE = Crypt::Skipjack
PROTOTYPES: DISABLE

int
keysize(...)
    CODE:
        RETVAL = 10;
    OUTPUT:
        RETVAL

int
blocksize(...)
    CODE:
        RETVAL = 8;
    OUTPUT:
        RETVAL

Crypt::Skipjack
new(class, rawkey)
    SV* class
    SV* rawkey
    CODE:
    {
        STRLEN keyLength;
        if (! SvPOK(rawkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(rawkey);
        if (keyLength != 10)
            croak("Key setup error: Key must be 10 bytes long!");

        Newz(0, RETVAL, 1, struct skipjack);
        makeKey(SvPV_nolen(rawkey), RETVAL->tab);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Skipjack self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Encryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            skip_encrypt(self->tab, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Skipjack self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Decryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            skip_decrypt(self->tab, intext, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Skipjack self
    CODE:
        Safefree(self);

