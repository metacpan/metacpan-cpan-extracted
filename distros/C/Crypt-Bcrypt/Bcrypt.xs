#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "crypt_blowfish.h"

#define BCRYPT_HASHSIZE 64

static int timing_safe_strcmp(const char *str1, const char *str2) {
	const unsigned char *u1;
	const unsigned char *u2;
	int ret;
	int i;

	int len1 = strlen(str1);
	int len2 = strlen(str2);

	/* In our context both strings should always have the same length
	 * because they will be hashed passwords. */
	if (len1 != len2)
		return 1;

	/* Force unsigned for bitwise operations. */
	u1 = (const unsigned char *)str1;
	u2 = (const unsigned char *)str2;

	ret = 0;
	for (i = 0; i < len1; ++i)
		ret |= (u1[i] ^ u2[i]);

	return ret;
}

MODULE = Crypt::Bcrypt              PACKAGE = Crypt::Bcrypt

PROTOTYPES: DISABLE

SV*
_bcrypt_hashpw(const char* password, const char* settings)
CODE:
	char outhash[BCRYPT_HASHSIZE];
	const char* output = _crypt_blowfish_rn(password, settings, outhash, BCRYPT_HASHSIZE);
	if (output == NULL)
		Perl_croak(aTHX_ "Could not hash: %s", strerror(errno));
	RETVAL = newSVpv(outhash, 0);
OUTPUT:
	RETVAL

int
bcrypt_check(const char* password, const char* hash)
CODE:
	char outhash[BCRYPT_HASHSIZE];
	const char* ret = _crypt_blowfish_rn(password, hash, outhash, BCRYPT_HASHSIZE);
	RETVAL = ret && timing_safe_strcmp(hash, outhash) == 0;
OUTPUT:
	RETVAL
