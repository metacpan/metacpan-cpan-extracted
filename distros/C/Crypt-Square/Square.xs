#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_square.c"

typedef struct square {
    squareKeySchedule enckey;
    squareKeySchedule deckey;
}* Crypt__Square;

MODULE = Crypt::Square		PACKAGE = Crypt::Square
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

Crypt::Square
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

        Newz(0, RETVAL, 1, struct square);
        squareGenerateRoundKeys(SvPV_nolen(rawkey), RETVAL->enckey,
            RETVAL->deckey);
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Square self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Encryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            squareEncrypt((unsigned long *)intext,
                (unsigned long *)SvPV_nolen(RETVAL), self->enckey);
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Square self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Decryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            squareDecrypt((unsigned long *)intext,
                (unsigned long *)SvPV_nolen(RETVAL), self->deckey);
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Square self
    CODE:
        Safefree(self);

