#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Crypt::OpenSSL::PBKDF2		PACKAGE = Crypt::OpenSSL::PBKDF2		

#include <openssl/ssl.h>
#include <openssl/evp.h>
#include <openssl/err.h>

SV *
derive(pass, salt, saltlen, iter, hlen, ...)
	const char * pass
	unsigned char * salt
	int saltlen
	int iter
	int hlen
PREINIT:
	const char * alg = "sha1";
INIT:
	unsigned char * hash = NULL;
	int plen = strlen(pass);
	const EVP_MD *md;
CODE:
	if( items > 5 )
		alg = (const char *)SvPV_nolen(ST(5));
	if ((md = EVP_get_digestbyname(alg)) == NULL)
		croak("invalid hashing algorithm");

	if ( Newxz(hash, hlen, unsigned char) == NULL ) 
		croak("unable to allocate buffer for hash");
	SSL_library_init();
	ERR_load_crypto_strings();
	if (PKCS5_PBKDF2_HMAC(pass, plen, salt, saltlen, iter, md, hlen, hash) != 1)
		croak("an error occurred: %s", ERR_error_string(ERR_get_error(), NULL));
	RETVAL = newSVpv((char *)hash, hlen);
	ERR_free_strings();
	Safefree(hash);
OUTPUT:
	RETVAL

SV *
derive_bin(pass, passlen, salt, saltlen, iter, hlen, ...)
	unsigned char * pass
	int passlen
	unsigned char * salt
	int saltlen
	int iter
	int hlen
PREINIT:
	const char * alg = "sha1";
INIT:
	unsigned char * hash = NULL;
	const EVP_MD *md;
CODE:
	if( items > 6 )
		alg = (const char *)SvPV_nolen(ST(6));
	if ((md = EVP_get_digestbyname(alg)) == NULL)
		croak("invalid hashing algorithm");

	if ( Newxz(hash, hlen, unsigned char) == NULL ) 
		croak ("unable to allocate buffer for hash");
	SSL_library_init();
	ERR_load_crypto_strings();
	if (PKCS5_PBKDF2_HMAC((const char *)pass, passlen, salt, saltlen, iter, md, hlen, hash) != 1)
		croak ("an error occurred: %s", ERR_error_string(ERR_get_error(), NULL));
	RETVAL = newSVpv((char *)hash, hlen);
	ERR_free_strings();
	Safefree(hash);
OUTPUT:
	RETVAL
