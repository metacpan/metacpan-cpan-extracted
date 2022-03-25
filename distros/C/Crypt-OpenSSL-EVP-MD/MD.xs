#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/err.h>
#include <openssl/evp.h>

#define checkOpenSslCall( result ) if( ! ( result ) ) \
  croak( "OpenSSL error: %s", ERR_reason_error_string( ERR_get_error() ) );

typedef EVP_MD *Crypt__OpenSSL__EVP__MD;
typedef EVP_MD_CTX *Crypt__OpenSSL__EVP__MD__CTX;

MODULE = Crypt::OpenSSL::EVP::MD      PACKAGE = Crypt::OpenSSL::EVP::MD   PREFIX = EVP_MD_
BOOT:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)
    OPENSSL_init_crypto(0, NULL);
#else
    ERR_load_crypto_strings();
#endif



Crypt::OpenSSL::EVP::MD
new(CLASS, hash_name)
    char* hash_name;
  PREINIT:
    EVP_MD* md;
  CODE:
    md = (EVP_MD*) EVP_get_digestbyname(hash_name);
    RETVAL = md;
  OUTPUT:
    RETVAL

SV*
digest(self, bin_SV)
    Crypt::OpenSSL::EVP::MD self;
    SV* bin_SV;
  PREINIT:
    SV* res;
    unsigned char* dgst;
    unsigned int dgst_length;
    unsigned char* bin;
    STRLEN bin_length;
  CODE:
    bin = (unsigned char*) SvPV( bin_SV, bin_length );
    dgst = malloc(EVP_MD_size(self));
    EVP_Digest(bin, bin_length, dgst, &dgst_length, self, NULL);
    res = newSVpv(dgst, dgst_length);
    RETVAL = res;
  OUTPUT:
    RETVAL


int
EVP_MD_size(Crypt::OpenSSL::EVP::MD self)

int
EVP_MD_block_size(Crypt::OpenSSL::EVP::MD self)


MODULE = Crypt::OpenSSL::EVP::MD  PACKAGE = Crypt::OpenSSL::EVP::MD::CTX

Crypt::OpenSSL::EVP::MD::CTX
new(CLASS)
    CODE:
        RETVAL = EVP_MD_CTX_new();
    OUTPUT:
        RETVAL

void
DESTROY(Crypt::OpenSSL::EVP::MD::CTX self)
    CODE:
        EVP_MD_CTX_free(self);
