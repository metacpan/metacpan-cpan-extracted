#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <scrypt-1.2.1/lib/crypto/crypto_scrypt.h>

MODULE = Authen::Passphrase::Scrypt		PACKAGE = Authen::Passphrase::Scrypt

PROTOTYPES: DISABLE

SV*
crypto_scrypt(const uint8_t *passwd, size_t length(passwd), \
	const uint8_t *salt, size_t length(salt), \
	uint64_t N, uint32_t r, uint32_t p, size_t buflen)
CODE:
	uint8_t *buf;
	int err;
	Newx(buf, buflen, uint8_t);
	err = crypto_scrypt(passwd, XSauto_length_of_passwd, salt, XSauto_length_of_salt, N, r, p, buf, buflen);
	if(err < 0)
		croak("Error in crypto_scrypt");
	RETVAL = newSVpvn((const char* const)buf, buflen);
	Safefree(buf);
OUTPUT:
	RETVAL
