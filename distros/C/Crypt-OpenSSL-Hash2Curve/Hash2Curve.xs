#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <openssl/ec.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/objects.h>
#include <openssl/pem.h>
#include <stdio.h>
#include <string.h>

#include "h2c.c"


MODULE = Crypt::OpenSSL::Hash2Curve		PACKAGE = Crypt::OpenSSL::Hash2Curve		


int OBJ_sn2nid (const char *s)

int EC_GROUP_get_curve(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx);

EC_GROUP *EC_GROUP_new_by_curve_name(int nid);



int sgn0_m_eq_1(BIGNUM *x)

int clear_cofactor(EC_GROUP *group, EC_POINT *P, EC_POINT *Q, BN_CTX* ctx)

BIGNUM* CMOV(BIGNUM *a, BIGNUM *b, int c)

int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BN_CTX *ctx)

int map_to_curve_sswu_optimized(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int map_to_curve_sswu(BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

const EVP_MD *EVP_get_digestbyname(const char *name)

int EVP_MD_size(const EVP_MD *md)

int EVP_MD_block_size(const EVP_MD *md)


SV*
digest(self, bin_SV)
    EVP_MD *self;
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

