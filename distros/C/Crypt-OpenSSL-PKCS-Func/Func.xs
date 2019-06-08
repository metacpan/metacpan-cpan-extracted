#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/pkcs12.h>
#include <openssl/crypto.h>

#define PACKAGE_NAME "Crypt::OpenSSL::PKCS::Func"


MODULE = Crypt::OpenSSL::PKCS::Func		PACKAGE = Crypt::OpenSSL::PKCS::Func
PROTOTYPES: DISABLE

unsigned char*
PKCS12_key_gen(password, salt_hexstr, id, iteration, outlen, digest_name)
    unsigned char *password;
    unsigned char *salt_hexstr;
    unsigned int id;
    unsigned int iteration;
    unsigned int outlen;
    unsigned char *digest_name;
  PREINIT:
    unsigned char *out_hexstr;
  CODE:
{
    int passlen = strlen(password);

    long salt_hexstr_len = strlen(salt_hexstr);
    unsigned char *salt = OPENSSL_hexstr2buf(salt_hexstr, &salt_hexstr_len);
    int saltlen = strlen(salt);

    const EVP_MD *digest = EVP_get_digestbyname(digest_name);

    unsigned char *out = OPENSSL_malloc(EVP_MAX_MD_SIZE); 
    PKCS12_key_gen(password, passlen, salt, saltlen, id, iteration, outlen, out, digest);
    out_hexstr = OPENSSL_buf2hexstr(out, outlen);

    OPENSSL_free(salt);
    OPENSSL_free(out);

    RETVAL = out_hexstr;
}
  OUTPUT:
    RETVAL 



unsigned char*
PKCS5_PBKDF2_HMAC(password, salt_hexstr, iteration, digest_name, outlen)
    unsigned char *password;
    unsigned char *salt_hexstr;
    unsigned int iteration;
    unsigned char *digest_name;
    unsigned int outlen;
  PREINIT:
    unsigned char *out_hexstr;
  CODE:
{
    int passlen = strlen(password);

    long salt_hexstr_len = strlen(salt_hexstr);
    unsigned char *salt = OPENSSL_hexstr2buf(salt_hexstr, &salt_hexstr_len);
    int saltlen = strlen(salt);

    const EVP_MD *digest = EVP_get_digestbyname(digest_name);

    unsigned char *out = OPENSSL_malloc(outlen); 
    PKCS5_PBKDF2_HMAC(password, passlen, salt, saltlen, iteration, digest, outlen, out);
    out_hexstr = OPENSSL_buf2hexstr(out, outlen);

    OPENSSL_free(salt);
    OPENSSL_free(out);

    RETVAL = out_hexstr;
}
  OUTPUT:
    RETVAL 
