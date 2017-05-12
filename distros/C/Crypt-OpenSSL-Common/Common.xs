#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/ssl.h>
#include <openssl/crypto.h>
#include <openssl/err.h>

MODULE = Crypt::OpenSSL::Common	    PACKAGE = Crypt::OpenSSL::Common

PROTOTYPES: DISABLE

long version()
    CODE:
	RETVAL = SSLeay();
    OUTPUT:
	RETVAL

long version_atbuild()
    CODE:
	RETVAL = OPENSSL_VERSION_NUMBER;
    OUTPUT:
	RETVAL

long 
get_error()
    CODE:
	RETVAL = ERR_get_error();
    OUTPUT:
	RETVAL

char *
error_string(code)
    long code;
    CODE:
	RETVAL = ERR_error_string(code, NULL);
    OUTPUT:
	RETVAL

void
load_crypto_strings()
    CODE:
	ERR_load_crypto_strings();

BOOT:
{
  SSL_library_init();
}
