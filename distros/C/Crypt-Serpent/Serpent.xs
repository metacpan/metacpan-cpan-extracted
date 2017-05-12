/*
    author: John Hughes (jhughes@frostburg.edu)
    date: 11/01

    I am indebted to Marc Lehmann, the author of the Crypt::Twofish2
    module, as I used his code as a guide.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "patchlevel.h"
#if (PATCHLEVEL == 4) || ((PATCHLEVEL == 5) && (SUBVERSION < 55))
static STRLEN nolen_na;
#define SvPV_nolen(sv) SvPV((sv), nolen_na)
#endif

#include "_serpent.c"

typedef struct cryptstate
{
    keyInstance ki;
    cipherInstance ci;
}* Crypt__Serpent;

MODULE = Crypt::Serpent     PACKAGE = Crypt::Serpent

PROTOTYPES: ENABLE

BOOT:
{
	HV* stash = gv_stashpv("Crypt::Serpent", 0);

	newCONSTSUB(stash, "keysize", newSViv(32));
	newCONSTSUB(stash, "blocksize", newSViv(16));
}

Crypt::Serpent
new(class, key, mode=MODE_ECB)
	SV*	class
	SV*	key
    unsigned char mode

    CODE:
    {
        STRLEN keySize;
        char str[65];
          
        if (! SvPOK(key))
            croak("Error: key must be a string scalar!");

        keySize = SvCUR(key);

        if (keySize != 16 && keySize != 24 && keySize != 32)
            croak("Error: key must be 16, 24, or 32 bytes in length.");

        Newz(0, RETVAL, 1, struct cryptstate);
          
        serpent_convert_to_string(keySize << 3, SvPV_nolen(key), str);

        if (makeKey(&RETVAL->ki, DIR_ENCRYPT, keySize << 3, str) != TRUE)
            croak("Error: makeKey failed.");
        if (cipherInit(&RETVAL->ci, mode, 0) != TRUE)
            croak("Error: cipherInit failed.");
    }         
	OUTPUT:
        RETVAL

SV*
encrypt(self, data)
 	Crypt::Serpent self
    SV*	data
    ALIAS:
        decrypt = 1

    CODE:
    {
        STRLEN size;
        void* rawbytes = SvPV(data, size);

        if (size != 16)
        {
            croak("Error: block size must be 16 bytes.");
            RETVAL = newSVpv("", 0);
        }
        else
        {
            RETVAL = NEWSV(0, size);
            SvPOK_only(RETVAL);
            SvCUR_set(RETVAL, size);

            (ix ? blockDecrypt : blockEncrypt)
                (&self->ci, &self->ki, rawbytes, size << 3, (void*)SvPV_nolen(RETVAL));
        }
    }
	OUTPUT:
        RETVAL

void
DESTROY(self)
        Crypt::Serpent self
        CODE:
        Safefree(self);