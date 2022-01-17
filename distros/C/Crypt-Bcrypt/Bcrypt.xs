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

const char* _bcrypt_hashpw(const char* password, const char* settings)
CODE:
	char outhash[BCRYPT_HASHSIZE];
	const char* output = _crypt_blowfish_rn(password, settings, outhash, BCRYPT_HASHSIZE);
	if (output == NULL)
		Perl_croak(aTHX_ "Could not hash: %s", strerror(errno));
	RETVAL = outhash;
OUTPUT:
	RETVAL

int bcrypt_check(const char* password, const char* hash, STRLEN length(hash))
CODE:
	char outhash[BCRYPT_HASHSIZE];
	STRLEN hashlen;
	const char* ret = _crypt_blowfish_rn(password, hash, outhash, BCRYPT_HASHSIZE);
	if (!ret || strlen(outhash) != STRLEN_length_of_hash)
		RETVAL = 0;
	else
		RETVAL = timing_safe_compare((const unsigned char *)hash, (const unsigned char *)outhash, STRLEN_length_of_hash);
OUTPUT:
	RETVAL
