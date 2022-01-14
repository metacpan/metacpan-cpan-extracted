#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "crypt_blowfish.h"

#define BCRYPT_HASHSIZE 64

static int timing_safe_compare(const unsigned char *str1, const unsigned char *str2, STRLEN length) {
	int ret = 0;
	int i;

	for (i = 0; i < length; ++i)
		ret |= (str1[i] ^ str2[i]);

	return ret == 0;
}

MODULE = Crypt::Bcrypt              PACKAGE = Crypt::Bcrypt

PROTOTYPES: DISABLE

SV*
_bcrypt_hashpw(SV* password_sv, const char* settings)
CODE:
	char outhash[BCRYPT_HASHSIZE];
	const char* password = SvPVbyte_nolen(password_sv);
	const char* output = _crypt_blowfish_rn(password, settings, outhash, BCRYPT_HASHSIZE);
	if (output == NULL)
		Perl_croak(aTHX_ "Could not hash: %s", strerror(errno));
	RETVAL = newSVpv(outhash, 0);
OUTPUT:
	RETVAL

int
bcrypt_check(char* password, SV* hash_sv)
CODE:
	char outhash[BCRYPT_HASHSIZE];
	STRLEN hashlen;
	const char* hash = SvPVbyte(hash_sv, hashlen);
	const char* ret = _crypt_blowfish_rn(password, hash, outhash, BCRYPT_HASHSIZE);
	if (!ret || strlen(outhash) != hashlen)
		RETVAL = 0;
	else
		RETVAL = timing_safe_compare((const unsigned char *)hash, (const unsigned char *)outhash, hashlen);
OUTPUT:
	RETVAL
