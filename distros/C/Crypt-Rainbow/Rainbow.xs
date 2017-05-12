#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_rainbow.c"

typedef struct rainbow {
    keyInstance keys;
    cipherInstance ciph;
}* Crypt__Rainbow;

MODULE = Crypt::Rainbow		PACKAGE = Crypt::Rainbow
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

Crypt::Rainbow
new(class, rawkey)
    SV* class
    SV* rawkey
    CODE:
    {
        STRLEN keyLength;
        int status;
        unsigned char inV[16] = {
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        };

        if (! SvPOK(rawkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(rawkey);
        if (keyLength != 16)
            croak("Key setup error: Key must be 16 bytes long!");

        Newz(0, RETVAL, 1, struct rainbow);
        status = makeKey(&RETVAL->keys, 0, 128, SvPV_nolen(rawkey));
        if (status != 1)
            croak("makeKey error!");

        status = cipherInit(&RETVAL->ciph, 1, inV);
        if (status != 1)
            croak("cipherInit error!");
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Rainbow self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        int status;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Encryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            status = blockEncrypt(&self->ciph, &self->keys,
                         intext, 128, SvPV_nolen(RETVAL));

            if (status != 1)
                croak("blockEncrypt error!");
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Rainbow self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        int status;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Decryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            status = blockDecrypt(&self->ciph, &self->keys,
                         intext, 128, SvPV_nolen(RETVAL));

            if (status != 1)
                croak("blockDecrypt error!");
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Rainbow self
    CODE:
        Safefree(self);

