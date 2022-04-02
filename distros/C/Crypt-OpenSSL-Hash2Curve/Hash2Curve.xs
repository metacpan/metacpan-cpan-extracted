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

int sgn0_m_eq_1(BIGNUM *x)

int clear_cofactor(EC_GROUP *group, EC_POINT *P, EC_POINT *Q, BN_CTX* ctx)

BIGNUM* CMOV(BIGNUM *a, BIGNUM *b, int c)



int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BN_CTX *ctx)

int map_to_curve_sswu_straight_line(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int map_to_curve_sswu_not_straight_line(BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)
