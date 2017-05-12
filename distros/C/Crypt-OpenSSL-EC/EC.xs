#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <openssl/ec.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#include "const-c.inc"

MODULE = Crypt::OpenSSL::EC		PACKAGE = Crypt::OpenSSL::EC		

PROTOTYPES: ENABLE
INCLUDE: const-xs.inc

BOOT:
    ERR_load_crypto_strings();
    ERR_load_EC_strings();

const EC_METHOD *
EC_GFp_simple_method()

const EC_METHOD *
EC_GFp_mont_method()

const EC_METHOD *
EC_GFp_nist_method()

#ifndef OPENSSL_NO_EC2M

const EC_METHOD *
EC_GF2m_simple_method()

#endif

#ifndef OPENSSL_NO_BIO
int	
ECParameters_print(BIO *bp, const EC_KEY *key)

int	
EC_KEY_print(BIO *bp, const EC_KEY *key, int off)

#endif

#ifndef OPENSSL_NO_FP_API
int	
ECParameters_print_fp(FILE *fp, const EC_KEY *key)

int	
EC_KEY_print_fp(FILE *fp, const EC_KEY *key, int off)

#endif

unsigned long
ERR_get_error()

char *
ERR_error_string(error,buf=NULL)
     unsigned long      error
     char *             buf
     CODE:
     RETVAL = ERR_error_string(error,buf);
     OUTPUT:
     RETVAL



MODULE = Crypt::OpenSSL::EC		PACKAGE = Crypt::OpenSSL::EC::EC_GROUP	PREFIX=EC_GROUP_

EC_GROUP *
EC_GROUP_new(const EC_METHOD *meth)
    CODE:
	RETVAL = EC_GROUP_new(meth);
    OUTPUT:
	RETVAL

void 
EC_GROUP_DESTROY(EC_GROUP * group)
    CODE:
	EC_GROUP_free(group);

void 
EC_GROUP_free(EC_GROUP * group)

int 
EC_GROUP_copy(EC_GROUP *dst, const EC_GROUP *src)

EC_GROUP *
EC_GROUP_dup(const EC_GROUP *src)

const EC_METHOD *
EC_GROUP_method_of(const EC_GROUP *group)

int 
EC_METHOD_get_field_type(const EC_METHOD *meth)

int 
EC_GROUP_set_generator(EC_GROUP *group, const EC_POINT *generator, const BIGNUM *order, const BIGNUM *cofactor)

const EC_POINT *
EC_GROUP_get0_generator(const EC_GROUP *group)
    CODE:
        RETVAL = EC_POINT_dup(EC_GROUP_get0_generator(group), group);
    OUTPUT:
        RETVAL

int 
EC_GROUP_get_order(const EC_GROUP *group, BIGNUM *order, BN_CTX *ctx)

int 
EC_GROUP_get_cofactor(const EC_GROUP *group, BIGNUM *cofactor, BN_CTX *ctx)

void 
EC_GROUP_set_curve_name(EC_GROUP *group, int nid)

int 
EC_GROUP_get_curve_name(const EC_GROUP *group)

void 
EC_GROUP_set_asn1_flag(EC_GROUP *group, int flag)

int 
EC_GROUP_get_asn1_flag(const EC_GROUP *group);

void 
EC_GROUP_set_point_conversion_form(EC_GROUP *group, point_conversion_form_t theform)

point_conversion_form_t 
EC_GROUP_get_point_conversion_form(const EC_GROUP *group)

char *
EC_GROUP_get0_seed(const EC_GROUP *group)
	CODE:
		RETVAL = (char*)EC_GROUP_get0_seed(group); /* signedness issues */
	OUTPUT:
		RETVAL

size_t 
EC_GROUP_get_seed_len(const EC_GROUP *group)

size_t 
EC_GROUP_set_seed(EC_GROUP *group, const unsigned char *theseed, size_t length(theseed))

int 
EC_GROUP_set_curve_GFp(EC_GROUP *group, const BIGNUM *p, const BIGNUM *a, const BIGNUM *b, BN_CTX *ctx)

int 
EC_GROUP_get_curve_GFp(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx)

#ifndef OPENSSL_NO_EC2M

int 
EC_GROUP_set_curve_GF2m(EC_GROUP *group, const BIGNUM *p, const BIGNUM *a, const BIGNUM *b, BN_CTX *ctx)

int 
EC_GROUP_get_curve_GF2m(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx)

#endif

int 
EC_GROUP_get_degree(const EC_GROUP *group)

int 
EC_GROUP_check(const EC_GROUP *group, BN_CTX *ctx)

int 
EC_GROUP_check_discriminant(const EC_GROUP *group, BN_CTX *ctx)

int 
EC_GROUP_cmp(const EC_GROUP *a, const EC_GROUP *b, BN_CTX *ctx)

EC_GROUP *
EC_GROUP_new_curve_GFp(const BIGNUM *p, const BIGNUM *a, const BIGNUM *b, BN_CTX *ctx)

#ifndef OPENSSL_NO_EC2M

EC_GROUP *
EC_GROUP_new_curve_GF2m(const BIGNUM *p, const BIGNUM *a, const BIGNUM *b, BN_CTX *ctx)

#endif

EC_GROUP *
EC_GROUP_new_by_curve_name(int nid)

int 
EC_GROUP_precompute_mult(EC_GROUP *group, BN_CTX *ctx)

int 
EC_GROUP_have_precompute_mult(const EC_GROUP *group)


int 
EC_GROUP_get_basis_type(const EC_GROUP *group)

#ifndef OPENSSL_NO_EC2M

int 
EC_GROUP_get_trinomial_basis(const EC_GROUP *group, IN_OUT unsigned int k)
	CODE:
		RETVAL = EC_GROUP_get_trinomial_basis(group, &k);
	OUTPUT: 
		k sv_setiv(ST(1), k);
		RETVAL

int 
EC_GROUP_get_pentanomial_basis(const EC_GROUP *group, IN_OUT unsigned int k1, IN_OUT unsigned int k2, IN_OUT unsigned int k3)
	CODE:
		RETVAL = EC_GROUP_get_pentanomial_basis(group, &k1, &k2, &k3);
	OUTPUT: 
		k1 sv_setiv(ST(1), k1);
		k2 sv_setiv(ST(2), k2);
		k3 sv_setiv(ST(3), k3);
		RETVAL

#endif

#EC_GROUP *
#d2i_ECPKParameters(EC_GROUP **group, const unsigned char **in, long len)

#int 
#i2d_ECPKParameters(const EC_GROUP *group, unsigned char **out)

MODULE = Crypt::OpenSSL::EC		PACKAGE = Crypt::OpenSSL::EC::EC_POINT	PREFIX=EC_POINT_

EC_POINT *
EC_POINT_new(const EC_GROUP *group)
    CODE:
	RETVAL = EC_POINT_new(group);
    OUTPUT:
	RETVAL

void 
EC_POINT_DESTROY(EC_POINT *point)
    CODE:
	EC_POINT_free(point);

void 
EC_POINT_free(EC_POINT *point)

void 
EC_POINT_clear_free(EC_POINT *point)

int 
EC_POINT_copy(EC_POINT *dst, const EC_POINT *src)

EC_POINT *
EC_POINT_dup(const EC_POINT *src, const EC_GROUP *group)
 
const EC_METHOD *
EC_POINT_method_of(const EC_POINT *point)

int 
EC_POINT_set_to_infinity(const EC_GROUP *group, EC_POINT *point)

int 
EC_POINT_set_Jprojective_coordinates_GFp(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, const BIGNUM *z, BN_CTX *ctx)

int 
EC_POINT_get_Jprojective_coordinates_GFp(const EC_GROUP *group,	const EC_POINT *p, BIGNUM *x, BIGNUM *y, BIGNUM *z, BN_CTX *ctx)

int 
EC_POINT_set_affine_coordinates_GFp(const EC_GROUP *group, EC_POINT *p,	const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx)

int 
EC_POINT_get_affine_coordinates_GFp(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int 
EC_POINT_set_compressed_coordinates_GFp(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, int y_bit, BN_CTX *ctx)

#ifndef OPENSSL_NO_EC2M

int 
EC_POINT_set_affine_coordinates_GF2m(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx)

int 
EC_POINT_get_affine_coordinates_GF2m(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int 
EC_POINT_set_compressed_coordinates_GF2m(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, int y_bit, BN_CTX *ctx)

#endif

SV *
EC_POINT_point2oct(const EC_GROUP *group, const EC_POINT *p, point_conversion_form_t theform, BN_CTX *ctx)
	PREINIT:
		STRLEN len;
		char* buf;
	CODE:
		len = EC_POINT_point2oct(group, p, theform, NULL, 0, ctx);
		Newx(buf, len, char);
		len = EC_POINT_point2oct(group, p, theform, (unsigned char*)buf, len, ctx);
		RETVAL = newSVpv(buf, len);
		Safefree(buf);
	OUTPUT:
		RETVAL

int 
EC_POINT_oct2point(const EC_GROUP *group, EC_POINT *p, const unsigned char *buf, BN_CTX *ctx)
	PREINIT:
		STRLEN len;
	CODE: 
		SvPV(ST(2), len);
		RETVAL = EC_POINT_oct2point(group, p, buf, len, ctx);
	OUTPUT:
		RETVAL


BIGNUM *
EC_POINT_point2bn(const EC_GROUP *group, const EC_POINT *point, point_conversion_form_t theform, BIGNUM *bn, BN_CTX *ctx)

EC_POINT *
EC_POINT_bn2point(const EC_GROUP *group, const BIGNUM *bn, EC_POINT *point, BN_CTX *ctx)

char *
EC_POINT_point2hex(const EC_GROUP *group, const EC_POINT *point, point_conversion_form_t theform, BN_CTX *ctx)

EC_POINT *
EC_POINT_hex2point(const EC_GROUP *group, const char *buf, EC_POINT *point, BN_CTX *ctx)

int 
EC_POINT_add(const EC_GROUP *group, EC_POINT *r, const EC_POINT *a, const EC_POINT *b, BN_CTX *ctx)

int 
EC_POINT_dbl(const EC_GROUP *group, EC_POINT *r, const EC_POINT *a, BN_CTX *ctx)

int 
EC_POINT_invert(const EC_GROUP *group, EC_POINT *a, BN_CTX *ctx)

int 
EC_POINT_is_at_infinity(const EC_GROUP *group, const EC_POINT *p)

int 
EC_POINT_is_on_curve(const EC_GROUP *group, const EC_POINT *point, BN_CTX *ctx)

int 
EC_POINT_cmp(const EC_GROUP *group, const EC_POINT *a, const EC_POINT *b, BN_CTX *ctx)

int 
EC_POINT_make_affine(const EC_GROUP *group, EC_POINT *point, BN_CTX *ctx)

#if 0

int 
EC_POINTs_make_affine(const EC_GROUP *group, size_t num, EC_POINT *p[], BN_CTX *ctx)

int 
EC_POINTs_mul(const EC_GROUP *group, EC_POINT *r, const BIGNUM *n, size_t num, const EC_POINT *p[], const BIGNUM *m[], BN_CTX *ctx)

#endif

int 
EC_POINT_mul(const EC_GROUP *group, EC_POINT *r, const BIGNUM *n, const EC_POINT *q, const BIGNUM *m, BN_CTX *ctx)


#ifndef OPENSSL_NO_BIO

int     
ECPKParameters_print(BIO *bp, const EC_GROUP *x, int off)

#endif
#ifndef OPENSSL_NO_FP_API

int    
ECPKParameters_print_fp(FILE *fp, const EC_GROUP *x, int off)

#endif

MODULE = Crypt::OpenSSL::EC		PACKAGE = Crypt::OpenSSL::EC::EC_KEY	PREFIX=EC_KEY_

# EC_KEY functions 

EC_KEY *
EC_KEY_new()
    CODE:
	RETVAL = EC_KEY_new();
    OUTPUT:
	RETVAL

EC_KEY *
EC_KEY_new_by_curve_name(int nid)
    CODE:
	RETVAL = EC_KEY_new_by_curve_name(nid);
    OUTPUT:
	RETVAL

void 
EC_KEY_DESTROY(EC_KEY * key)
    CODE:	
	EC_KEY_free(key);

void 
EC_KEY_free(EC_KEY *key)

EC_KEY *
EC_KEY_copy(EC_KEY *dst, const EC_KEY *src)

EC_KEY *
EC_KEY_dup(const EC_KEY *src)

int 
EC_KEY_up_ref(EC_KEY *key)

const EC_GROUP *
EC_KEY_get0_group(const EC_KEY *key)

int 
EC_KEY_set_group(EC_KEY *key, const EC_GROUP *group)

const BIGNUM *
EC_KEY_get0_private_key(const EC_KEY *key)
    CODE:
        RETVAL = BN_dup(EC_KEY_get0_private_key(key));
    OUTPUT:
        RETVAL

int 
EC_KEY_set_private_key(EC_KEY *key, const BIGNUM *prv)

const EC_POINT *
EC_KEY_get0_public_key(const EC_KEY *key)
    CODE:
        RETVAL = EC_POINT_dup(EC_KEY_get0_public_key(key), EC_KEY_get0_group(key));
    OUTPUT:
        RETVAL

int 
EC_KEY_set_public_key(EC_KEY *key, const EC_POINT *pub)

unsigned 
EC_KEY_get_enc_flags(const EC_KEY *key)

void 
EC_KEY_set_enc_flags(EC_KEY *key, unsigned int flags)

point_conversion_form_t 
EC_KEY_get_conv_form(const EC_KEY *key)

void 
EC_KEY_set_conv_form(EC_KEY *key, point_conversion_form_t theform)

#void *
#EC_KEY_get_key_method_data(EC_KEY *key, void *(*dup_func)(void *), void (*free_func)(void *), void (*clear_free_func)(void *))

#void 
#EC_KEY_insert_key_method_data(EC_KEY *key, void *data, void *(*dup_func)(void *), void (*free_func)(void *), void (*clear_free_func)(void *))

void 
EC_KEY_set_asn1_flag(EC_KEY *key, int flag)

int 
EC_KEY_precompute_mult(EC_KEY *key, BN_CTX *ctx)

int 
EC_KEY_generate_key(EC_KEY *key)

int 
EC_KEY_check_key(const EC_KEY *key)

# de- and encoding functions for SEC1 ECPrivateKey          */

#EC_KEY *
#d2i_ECPrivateKey(EC_KEY **key, const unsigned char **in, long len)

#int 
#i2d_ECPrivateKey(EC_KEY *key, unsigned char **out)


# de- and encoding functions for EC parameters              */
#EC_KEY *
#d2i_ECParameters(EC_KEY **key, const unsigned char **in, long len)

#int 
#i2d_ECParameters(EC_KEY *key, unsigned char **out)

# de- and encoding functions for EC public key             */

#EC_KEY *
#o2i_ECPublicKey(EC_KEY **key, const unsigned char **in, long len)

#int 
#i2o_ECPublicKey(EC_KEY *key, unsigned char **out)

