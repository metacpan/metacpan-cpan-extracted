#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Crypt::OpenSSL::PBKDF2		PACKAGE = Crypt::OpenSSL::PBKDF2		

#include <openssl/ssl.h>
#include <openssl/evp.h>
#include <openssl/err.h>

SV *
derive(pass, salt, saltlen, iter, hlen)
	const char * pass
	unsigned char * salt
	int saltlen
	int iter
	int hlen
INIT:
	unsigned char * hash = NULL;
	int plen = strlen(pass);
CODE:
	if ( Newxz(hash, hlen, unsigned char) == NULL ) 
		croak ("unable to allocate buffer for hash");
	SSL_library_init();
	ERR_load_crypto_strings();
	if (PKCS5_PBKDF2_HMAC_SHA1(pass, plen, salt, saltlen, iter, hlen, hash) != 1)
		croak ("an error occurred: %s", ERR_error_string(ERR_get_error(), NULL));
	RETVAL = newSVpv((char *)hash, hlen);
	ERR_free_strings();
	Safefree(hash);
OUTPUT:
	RETVAL

SV *
derive_bin(pass, passlen, salt, saltlen, iter, hlen)
	unsigned char * pass
	int passlen
	unsigned char * salt
	int saltlen
	int iter
	int hlen
INIT:
	unsigned char * hash = NULL;
CODE:
	if ( Newxz(hash, hlen, unsigned char) == NULL ) 
		croak ("unable to allocate buffer for hash");
	SSL_library_init();
	ERR_load_crypto_strings();
	if (PKCS5_PBKDF2_HMAC_SHA1((const char *)pass, passlen, salt, saltlen, iter, hlen, hash) != 1)
		croak ("an error occurred: %s", ERR_error_string(ERR_get_error(), NULL));
	RETVAL = newSVpv((char *)hash, hlen);
	ERR_free_strings();
	Safefree(hash);
OUTPUT:
	RETVAL
