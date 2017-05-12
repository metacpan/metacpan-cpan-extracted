#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "src/fastpbkdf2.h"

static void dump(const char *label, uint8_t *data, size_t n)
{
  printf("%s: ", label);
  for (size_t i = 0; i < n; i++)
    printf("%02x", data[i]);
  printf("\n");
}

MODULE = Crypt::OpenSSL::FASTPBKDF2		PACKAGE = Crypt::OpenSSL::FASTPBKDF2
PROTOTYPES: ENABLE

SV *
fastpbkdf2_hmac_interface(pw, salt, iterations, nout, IN_OUT data_buffer = newAV())
        SV * pw
        SV * salt
        uint32_t iterations
        STRLEN nout
        AV * &data_buffer
    PROTOTYPE: $$$$;\@
    PREINIT:
        STRLEN npw;
        STRLEN nsalt;
        uint8_t * cpw;
        uint8_t * csalt;
        uint8_t * hashPtr;
        SV * hash = newSVpv("",0);
    INIT:
        cpw = SvPVbyte(pw, npw);
        csalt = SvPVbyte(salt, nsalt);
        Newx(hashPtr, nout+1, uint8_t);
        sv_usepvn_flags(hash, hashPtr, nout, SV_SMAGIC | SV_HAS_TRAILING_NUL);
    C_ARGS:
        cpw, npw, csalt, nsalt, iterations, hashPtr, nout
    INTERFACE:
        fastpbkdf2_hmac_sha1 fastpbkdf2_hmac_sha256 fastpbkdf2_hmac_sha512
	POSTCALL:
        if(ST(5)) av_push(data_buffer, newSVpvn(hashPtr, nout)); // Append to @data_buffer array, if provided
        hashPtr[nout] = '\0'; // NUL-terminated string
        RETVAL = hash;