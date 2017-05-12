#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_shark.c"

typedef struct shark {
    ddword roundkey_enc[14];
    ddword roundkey_dec[14];
}* Crypt__Shark;

MODULE = Crypt::Shark		PACKAGE = Crypt::Shark
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

Crypt::Shark
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

        Newz(0, RETVAL, 1, struct shark);
        init();
        key_init(SvPV_nolen(rawkey), RETVAL->roundkey_enc);
        box_init(RETVAL->roundkey_enc, RETVAL->roundkey_dec);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Shark self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Encryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            encryption(intext, self->roundkey_enc, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Shark self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 8) {
            croak("Decryption error: Block size must be 8 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            decryption(intext, self->roundkey_dec, SvPV_nolen(RETVAL));
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Shark self
    CODE:
        Safefree(self);

