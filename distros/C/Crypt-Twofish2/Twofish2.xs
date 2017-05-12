#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* try to be compatible with older perls */
/* SvPV_nolen() macro first defined in 5.005_55 */
/* this is slow, not threadsafe, but works */
#include "patchlevel.h"
#if (PATCHLEVEL == 4) || ((PATCHLEVEL == 5) && (SUBVERSION < 55))
static STRLEN nolen_na;
# define SvPV_nolen(sv) SvPV ((sv), nolen_na)
#endif

#include "aes.h"
#include "twofish.c"

typedef struct cryptstate {
  keyInstance ki;
  cipherInstance ci;
} *Crypt__Twofish2;

MODULE = Crypt::Twofish2		PACKAGE = Crypt::Twofish2

PROTOTYPES: ENABLE

BOOT:
{
	HV *stash = gv_stashpv ("Crypt::Twofish2", 0);

	newCONSTSUB (stash, "keysize",   newSViv (32));
	newCONSTSUB (stash, "blocksize", newSViv (16));
	newCONSTSUB (stash, "MODE_ECB",  newSViv (MODE_ECB));
	newCONSTSUB (stash, "MODE_CBC",  newSViv (MODE_CBC));
	newCONSTSUB (stash, "MODE_CFB1", newSViv (MODE_CFB1));
}

Crypt::Twofish2
new(class, key, mode=MODE_ECB)
	SV *	class
	SV *	key
        int	mode
        CODE:
        {
          STRLEN keysize;
          
          if (!SvPOK (key))
            croak ("key must be a string scalar");

          keysize = SvCUR(key);

          if (keysize != 16 && keysize != 24 && keysize != 32)
            croak ("wrong key length: key must be 128, 192 or 256 bits long");
          if (mode != MODE_ECB && mode != MODE_CBC && mode != MODE_CFB1)
            croak ("illegal mode: mode must be MODE_ECB, MODE_2 or MODE_CFB1");

          Newz (0, RETVAL, 1, struct cryptstate); /* Newz required for defined IV */
          
          if (makeKey (&RETVAL->ki, DIR_ENCRYPT, keysize*8, SvPV_nolen(key)) != TRUE)
            croak ("Crypt::Twofish2: makeKey failed, please report!");
          if (cipherInit (&RETVAL->ci, mode, 0) != TRUE) /* no IV supported (yet) */
            croak ("Crypt::Twofish2: makeKey failed, please report!");
        }         
	OUTPUT:
        RETVAL

SV *
encrypt(self, data)
 	Crypt::Twofish2 self
        SV *	data
        ALIAS:
        	decrypt = 1
        CODE:
        {
          SV *res;
          STRLEN size;
          void *rawbytes = SvPV(data,size);

          if (size)
            {
              if (size % (BLOCK_SIZE >> 3))
                croak ("encrypt: datasize not multiple of blocksize (%d bits)", BLOCK_SIZE);

              RETVAL = NEWSV (0, size);
              SvPOK_only (RETVAL);
              (SvPVX (RETVAL))[size] = 0;
              SvCUR_set (RETVAL, size);

              if ((ix ? blockDecrypt : blockEncrypt)
                    (&self->ci, &self->ki, rawbytes, size << 3, (void *)SvPV_nolen(RETVAL)) < 0)
                croak ("block(De|En)crypt: unknown error, please report");
            }
          else
            RETVAL = newSVpv ("", 0);
        }
	OUTPUT:
        RETVAL

void
DESTROY(self)
        Crypt::Twofish2 self
        CODE:
        Safefree(self);




