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

int sgn0_m_eq_1 (BIGNUM *x) {
    BN_ULONG r = BN_mod_word(x, 2);
    return (int) r;
}

BIGNUM* CMOV(BIGNUM *a, BIGNUM *b, int c){
    if(c){
        return b;
    }
    return a;
}

int clear_cofactor(EC_GROUP *group, EC_POINT *P, EC_POINT *Q, BN_CTX* ctx){
    const BIGNUM *cofactor = EC_GROUP_get0_cofactor(group);
    EC_POINT_mul(group, P, NULL, Q, cofactor, ctx);
    return 1;
}

int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BN_CTX *ctx)
{

    BN_mod_inverse(c1, a, p, ctx);
    BN_mod_mul(c1, c1, b, p, ctx);
    BN_set_negative(c1, 1);

    BN_mod_inverse(c2, z, p, ctx);
    BN_set_negative(c2, 1);

    return 1;
}

int 
map_to_curve_sswu_straight_line(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)
{
    BIGNUM *tv1, *tv2, *x1, *gx1, *gx2, *x2, *y2;

    tv1 = BN_new();
    BN_mod_sqr(tv1, u, p, ctx);
    BN_mod_mul(tv1, tv1, z, p, ctx);

    tv2 = BN_new();
    BN_mod_sqr(tv2, tv1, p, ctx);

    x1 = BN_new();
    BN_mod_add(x1, tv1, tv2, p, ctx);
    BN_mod_inverse(x1, x1, p, ctx);

    int e1 = BN_is_zero(x1); 
    BN_add_word(x1, 1);
    x1 = CMOV(x1, c2, e1);
    BN_mod_mul(x1, x1, c1, p, ctx);

    gx1 = BN_new();
    BN_mod_sqr(gx1, x1, p, ctx);
    BN_mod_add(gx1, gx1, a, p, ctx);
    BN_mod_mul(gx1, gx1, x1, p, ctx);
    BN_mod_add(gx1, gx1, b, p, ctx);

    x2 = BN_new();
    BN_mod_mul(x2, tv1, x1, p, ctx);
    BN_mod_mul(tv2, tv1, tv2, p, ctx);

    gx2 = BN_new();
    BN_mod_mul(gx2, gx1, tv2, p, ctx);

    BIGNUM *e2_bn = BN_new();
    BIGNUM *e2_ret = BN_mod_sqrt(e2_bn, gx1, p, ctx);
    BN_copy(x, CMOV(x2, x1, e2_ret!=NULL));

    y2 = CMOV(gx2, gx1, e2_ret!=NULL);
    BN_mod_sqrt(y, y2, p, ctx);

    if(sgn0_m_eq_1(u) != sgn0_m_eq_1(y)){
        BN_set_negative(y, 1);
        BN_mod_add(y, y, p, p, ctx);
    }

    BN_free(tv1);
    BN_free(tv2);
    BN_free(x1);
    BN_free(gx1);
    BN_free(x2);
    BN_free(gx2);
    BN_free(e2_bn);

    return 1;
}

int 
map_to_curve_sswu_not_straight_line(BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)
{
    BIGNUM *tmp1 = BN_new();
    BN_mod(tmp1, u, p, ctx);
    BN_mod_sqr(tmp1, tmp1, p, ctx);
    BN_mod_mul(tmp1, tmp1, z, p, ctx);

    BIGNUM *tv1 = BN_new();
    BN_copy(tv1, tmp1);
    BN_mod_sqr(tv1, tv1, p, ctx);
    BN_mod_add(tv1, tv1, tmp1, p, ctx);
    BN_mod_inverse(tv1, tv1, p, ctx);

    BN_copy(x, tv1);
    BN_add_word(x, 1);
    BN_mod_mul(x, x, b, p, ctx);
    BN_set_negative(x, 1);

    BIGNUM *a_inv = BN_new();
    BN_mod_inverse(a_inv, a, p, ctx);
    BN_mod_mul(x, x, a_inv, p, ctx);

    if(BN_is_zero(tv1)){
        BN_copy(x, z);
        BN_mod_inverse(x, x, p,ctx);
        BN_mod_mul(x, x, b, p, ctx);
        BN_mod_mul(x, x, a_inv, p, ctx);
    }

    BIGNUM *gx = BN_new();
    BN_copy(gx, x);
    BN_mod_sqr(gx, gx, p, ctx);
    BN_mod_add(gx, gx, a, p, ctx);
    BN_mod_mul(gx, gx, x, p, ctx);
    BN_mod_add(gx, gx, b, p, ctx);

    BN_mod_sqrt(y, gx, p, ctx);

    BIGNUM *y2 = BN_new();
    BN_mod_sqr(y2, y, p, ctx);
    if(BN_cmp(y2, gx)!=0){
        BN_mod_mul(x, x, tmp1, p, ctx);

        BN_copy(gx, x);
        BN_mod_sqr(gx, gx, p, ctx);
        BN_mod_add(gx, gx, a, p, ctx);
        BN_mod_mul(gx, gx, x, p, ctx);
        BN_mod_add(gx, gx, b, p, ctx);

        BN_mod_sqrt(y, gx, p, ctx);
        BN_mod_sqr(y2, y, p, ctx);
        if( BN_cmp(y2, gx)!=0 ){
            return 0;
        }
    }

    if(sgn0_m_eq_1(u) != sgn0_m_eq_1(y)){
        BN_set_negative(y, 1);
        BN_mod_add(y, y, p, p, ctx);
    }

    BN_free(tmp1);
    BN_free(tv1);
    BN_free(a_inv);
    BN_free(gx);
    BN_free(y2);
    return 1;
}



MODULE = Crypt::OpenSSL::Hash2Curve		PACKAGE = Crypt::OpenSSL::Hash2Curve		

int sgn0_m_eq_1(BIGNUM *x)

int clear_cofactor(EC_GROUP *group, EC_POINT *P, EC_POINT *Q, BN_CTX* ctx)

BIGNUM* CMOV(BIGNUM *a, BIGNUM *b, int c)

int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BN_CTX *ctx)

int map_to_curve_sswu_straight_line(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int map_to_curve_sswu_not_straight_line(BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)
