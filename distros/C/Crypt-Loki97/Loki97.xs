#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_loki97.c"

typedef struct loki97 {
    keyInstance enc_key, dec_key;
    cipherInstance cipher;
}* Crypt__Loki97;

MODULE = Crypt::Loki97		PACKAGE = Crypt::Loki97
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

Crypt::Loki97
new(class, rawkey)
    SV* class
    SV* rawkey
    CODE:
    {
        STRLEN keyLength;
        int st;

        if (! SvPOK(rawkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(rawkey);
        if (keyLength != 16)
            croak("Key setup error: Key must be 16 bytes long!");

        Newz(0, RETVAL, 1, struct loki97);
        st = cipherInit(&RETVAL->cipher, 1, "");
        if (st != 1)
            croak("cipherInit() error");

        st = makeKey(&RETVAL->enc_key, 0, 128, SvPV_nolen(rawkey));
        if (st != 1)
            croak("Encryption makeKey() error");

        st = makeKey(&RETVAL->dec_key, 1, 128, SvPV_nolen(rawkey));
        if (st != 1)
            croak("Decryption makeKey() error");
    }

    OUTPUT:
        RETVAL

SV*
encrypt(self, input)
    Crypt::Loki97 self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        int st;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Encryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            st = blockEncrypt(&self->cipher,
                    &self->enc_key,
                    intext, blockSize*8, SvPV_nolen(RETVAL));

            if (st != 1)
                croak("Encryption error");
        }
    }

    OUTPUT:
        RETVAL

SV*
decrypt(self, input)
    Crypt::Loki97 self
    SV* input
    CODE:
    {
        STRLEN blockSize;
        int st;
        unsigned char* intext = SvPV(input, blockSize);
        if (blockSize != 16) {
            croak("Decryption error: Block size must be 16 bytes long!");
        } else {
            RETVAL = newSVpv("", blockSize);
            st = blockDecrypt(&self->cipher,
                    &self->dec_key,
                    intext, blockSize*8, SvPV_nolen(RETVAL));

            if (st != 1)
                croak("Decryption error");
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Loki97 self
    CODE:
        Safefree(self);

