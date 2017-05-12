/*
      author: John Hughes (jhughes@frostburg.edu)
    modified: 11/01

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

#include "_rc6.c"

typedef struct rc6_stuff  /* This struct holds the key schedule. */
{
    unsigned int S[44];
}* Crypt__RC6;

MODULE = Crypt::RC6     PACKAGE = Crypt::RC6

PROTOTYPES: ENABLE

BOOT:
{
	HV* stash = gv_stashpv("Crypt::RC6", 0);

	newCONSTSUB(stash, "keysize", newSViv(32));
	newCONSTSUB(stash, "blocksize", newSViv(16));
}

Crypt::RC6
new(class, key)
	SV*	class
	SV*	key
    
    CODE:
    {
        STRLEN keyLength;
          
        if (! SvPOK(key))
            croak("Error: key must be a string scalar!");

        keyLength = SvCUR(key);

        if (keyLength != 16 && keyLength != 24 && keyLength != 32)
            croak("Error: key must be 16, 24, or 32 bytes in length.");

        Newz(0, RETVAL, 1, struct rc6_stuff);
          
        rc6_generateKeySchedule(SvPV_nolen(key), keyLength, RETVAL->S);
    }         
	OUTPUT:
        RETVAL

SV*
encrypt(self, input)
 	Crypt::RC6 self
    SV* input
       
    CODE:
    {
        STRLEN blockSize;
        void* rawbytes = SvPV(input, blockSize);
        
        if (blockSize != 16)
        {
            croak("Error: block size must be 16 bytes.");
            RETVAL = newSVpv("", 0);
        }
        else
        {
            RETVAL = NEWSV(0, 16);
            SvPOK_only(RETVAL);
            SvCUR_set(RETVAL, 16);

            rc6_encrypt(rawbytes, self->S, SvPV_nolen(RETVAL));
        }
    }
	OUTPUT:
        RETVAL

SV*
decrypt(self, input)
 	Crypt::RC6 self
    SV* input
       
    CODE:
    {
        STRLEN blockSize;
        void* rawbytes = SvPV(input, blockSize);
        
        if (blockSize != 16)
        {
            croak("Error: block size must be 16 bytes.");
            RETVAL = newSVpv("", 0);
        }
        else
        {
            RETVAL = NEWSV(0, 16);
            SvPOK_only(RETVAL);
            SvCUR_set(RETVAL, 16);

            rc6_decrypt(rawbytes, self->S, SvPV_nolen(RETVAL));
        }
    }
	OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::RC6 self

    CODE:
        Safefree(self);