#ifndef CRYPT_KEYCZAR_XS_OPENSSL_H
#define CRYPT_KEYCZAR_XS_OPENSSL_H 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/rand.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <openssl/sha.h>
#include <openssl/err.h>
#include <openssl/rsa.h>
#include <openssl/dsa.h>
#include <openssl/bn.h>
#include <openssl/engine.h>
#include "openssl/compat.h"


typedef struct Crypt__Keyczar__AesEngine_class {
    unsigned char *key;
    int key_length;
    unsigned char *iv;
    EVP_CIPHER_CTX *context;
} *Crypt__Keyczar__AesEngine;

typedef struct Crypt__Keyczar__HmacEngine_class {
    HMAC_CTX *context;
} *Crypt__Keyczar__HmacEngine;

typedef struct Crypt__Keyczar__RsaPrivateKeyEngine_class {
    RSA *rsa;
    EVP_MD_CTX *message;
} *Crypt__Keyczar__RsaPrivateKeyEngine;

typedef struct Crypt__Keyczar__RsaPublicKeyEngine_class {
    RSA *rsa;
    EVP_MD_CTX *message;
} *Crypt__Keyczar__RsaPublicKeyEngine;


typedef struct Crypt__Keyczar__DsaPrivateKeyEngine_class {
    DSA *dsa;
    EVP_MD_CTX *message;
} *Crypt__Keyczar__DsaPrivateKeyEngine;

typedef struct Crypt__Keyczar__DsaPublicKeyEngine_class {
    DSA *dsa;
    EVP_MD_CTX *message;
} *Crypt__Keyczar__DsaPublicKeyEngine;



void crypt__keyczar__util__croak_openssl()
{
    unsigned long rc;
    char buff[1024];

    ERR_load_crypto_strings();
    if ((rc = ERR_get_error()) != 0) {
        ERR_error_string_n(rc, buff, sizeof(buff));
        croak(buff);
    }
    else {
        croak("fail at openssl layer");
    }
}


SV *
crypt__keyczar__util__bignum2sv(BIGNUM *bn)
{
    unsigned char *buff;
    int l;
    SV *result;

    Newz(0, buff, BN_num_bytes(bn), unsigned char);
    if (!(l = BN_bn2bin(bn, buff))) {
	Safefree(buff);
        return NULL;
    }
    result = newSVpv((char *)buff, l);
    Safefree(buff);
    return result;
}


int
crypt__keyczar__util__bignum2hv(BIGNUM *bn, const char *key, HV *hv)
{
    SV *v;

    if ((v = crypt__keyczar__util__bignum2sv(bn)) == NULL) {
        return 0;
    }
    if (!hv_store(hv, key, strlen(key), v, 0)) {
        return 0;
    }
    return 1;
}


#if !defined(SHA256_DIGEST_LENGTH)
const EVP_MD *EVP_sha224(void)
{
    croak("unsupported digest name: SHA224, please update to OpenSSL 0.9.8 or later.");
}

const EVP_MD *EVP_sha256(void)
{
    croak("unsupported digest name: SHA256, please updage to OpenSSL 0.9.8 or later.");
}
#endif /* SHA256_DIGEST_LENGTH */


#ifndef SHA512_DIGEST_LENGTH
const EVP_MD *EVP_sha384(void)
{
    croak("unsupported digest name: SHA384, please updage to OpenSSL 0.9.8 or later.");
}

const EVP_MD *EVP_sha512(void)
{
    croak("unsupported digest name: SHA512, please updage to OpenSSL 0.9.8 or later.");
}
#endif /* SHA512_DIGEST_LENGTH */


#endif /* CRYPT_KEYCZAR_XS_OPENSSL_H */
