#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <openssl/ecdsa.h>
#include <openssl/err.h>
#include <openssl/bn.h>

#include "const-c.inc"


#if OPENSSL_VERSION_NUMBER >= 0x10100000L
#include <openssl/ec.h>
#else
/* ECDSA_SIG_get0() and ECDSA_SIG_set0() copied from OpenSSL 1.1.0b. */
static void ECDSA_SIG_get0(const ECDSA_SIG *sig, const BIGNUM **pr,
    const BIGNUM **ps) {
    if (pr != NULL)
        *pr = sig->r;
    if (ps != NULL)
        *ps = sig->s;
}

static int ECDSA_SIG_set0(ECDSA_SIG *sig, BIGNUM *r, BIGNUM *s)
{
    if (r == NULL || s == NULL)
        return 0;
    BN_clear_free(sig->r);
    BN_clear_free(sig->s);
    sig->r = r;
    sig->s = s;
    return 1;
}
#endif

MODULE = Crypt::OpenSSL::ECDSA		PACKAGE = Crypt::OpenSSL::ECDSA

PROTOTYPES: ENABLE
INCLUDE: const-xs.inc

BOOT:
    ERR_load_crypto_strings();
#if OPENSSL_VERSION_NUMBER >= 0x10002000L && OPENSSL_VERSION_NUMBER < 0x10100000L
    ERR_load_ECDSA_strings();
#endif

#ECDSA_SIG *
#ECDSA_SIG_new()

#void
#ECDSA_SIG_free(ECDSA_SIG *sig)

#int	  
#i2d_ECDSA_SIG(const ECDSA_SIG *sig, unsigned char **pp)

#ECDSA_SIG *
#d2i_ECDSA_SIG(ECDSA_SIG **sig, const unsigned char **pp, long len)

ECDSA_SIG *
ECDSA_do_sign(const unsigned char *dgst, EC_KEY *eckey)
        PREINIT:
                STRLEN dgst_len;
	CODE: 
                dgst = (const unsigned char *)SvPV(ST(0), dgst_len);
                RETVAL = ECDSA_do_sign(dgst, dgst_len, eckey);
	OUTPUT:
		RETVAL

ECDSA_SIG *
ECDSA_do_sign_ex(const unsigned char *dgst, const BIGNUM *kinv, const BIGNUM *rp, EC_KEY *eckey)
        PREINIT:
                STRLEN dgst_len;
	CODE: 
                dgst = (const unsigned char *)SvPV(ST(0), dgst_len);
                RETVAL = ECDSA_do_sign_ex(dgst, dgst_len, kinv, rp, eckey);
	OUTPUT:
		RETVAL

int	  
ECDSA_do_verify(const unsigned char *dgst, const ECDSA_SIG *sig, EC_KEY* eckey);
        PREINIT:
                STRLEN dgst_len;
	CODE: 
                dgst = (const unsigned char *)SvPV(ST(0), dgst_len);
                RETVAL = ECDSA_do_verify(dgst, dgst_len, sig, eckey);
	OUTPUT:
		RETVAL

# These ECDSA_METHOD functions only became available in 1.0.2,
# but some of them removed again in 1.1.0.

#if OPENSSL_VERSION_NUMBER >= 0x10002000L

int	  
ECDSA_size(const EC_KEY *eckey)

#if OPENSSL_VERSION_NUMBER < 0x10100000L

const ECDSA_METHOD *
ECDSA_OpenSSL()

void	  
ECDSA_set_default_method(const ECDSA_METHOD *meth)

const ECDSA_METHOD *
ECDSA_get_default_method()

int 	  
ECDSA_set_method(EC_KEY *eckey, const ECDSA_METHOD *meth)

ECDSA_METHOD *
ECDSA_METHOD_new(ECDSA_METHOD *ecdsa_method=0)

void 
ECDSA_METHOD_free(ECDSA_METHOD *ecdsa_method)

void 
ECDSA_METHOD_set_flags(ECDSA_METHOD *ecdsa_method, int flags)

void 
ECDSA_METHOD_set_name(ECDSA_METHOD *ecdsa_method, char *name)

void 
ERR_load_ECDSA_strings()

#endif
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


MODULE = Crypt::OpenSSL::ECDSA    PACKAGE = Crypt::OpenSSL::ECDSA::ECDSA_SIG

ECDSA_SIG *
new(CLASS)
        char * CLASS
    CODE:
	CLASS = CLASS; /* prevent unused warnings */
        RETVAL = ECDSA_SIG_new();
    OUTPUT:
        RETVAL

void
DESTROY(ecdsa_sig)
        ECDSA_SIG *ecdsa_sig
    CODE:
        ECDSA_SIG_free(ecdsa_sig);

SV *
get_r(ecdsa_sig)
        ECDSA_SIG *ecdsa_sig
    PREINIT:
        const BIGNUM *r;
        unsigned char *to;
        STRLEN len;
        int bnlen;
    CODE:
        ECDSA_SIG_get0(ecdsa_sig, &r, NULL);
        bnlen = BN_num_bytes(r);
        to = malloc(sizeof(char) * bnlen);
        len = BN_bn2bin(r, to);
        RETVAL = newSVpvn((const char*)to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_s(ecdsa_sig)
        ECDSA_SIG *ecdsa_sig
    PREINIT:
        const BIGNUM *s;
        unsigned char *to;
        STRLEN len;
        int bnlen;
    CODE:
        ECDSA_SIG_get0(ecdsa_sig, NULL, &s);
        bnlen = BN_num_bytes(s);
        to = malloc(sizeof(char) * bnlen);
        len = BN_bn2bin(s, to);
        RETVAL = newSVpvn((const char*)to, len);
        free(to);
    OUTPUT:
        RETVAL

void
set_r(ecdsa_sig, r_SV)
        ECDSA_SIG *ecdsa_sig
        SV * r_SV
    PREINIT:
	    char *string;
        STRLEN len;
        BIGNUM *r;
        BIGNUM *s;
        const BIGNUM *old_s;
    CODE:
        string = SvPV(r_SV, len);
        r = BN_bin2bn((const unsigned char *)string, len, NULL);
        if (NULL == r)
            croak("Could not convert ECDSA parameter string to big number");
        ECDSA_SIG_get0(ecdsa_sig, NULL, &old_s);
        if (NULL == old_s) {
            s = BN_new();
        } else {
            s = BN_dup(old_s);
        }
        if (NULL == s) {
            BN_free(r);
            croak("Could not duplicate unchanged ECDSA parameter");
        }
        if (!ECDSA_SIG_set0(ecdsa_sig, r, s)) {
            BN_free(r);
            BN_free(s);
            croak("Could not store ECDSA parameters");
        }

void
set_s(ecdsa_sig, s_SV)
        ECDSA_SIG *ecdsa_sig
        SV * s_SV
    PREINIT:
	    char *string;
        STRLEN len;
        BIGNUM *r;
        BIGNUM *s;
        const BIGNUM *old_r;
    CODE:
        string = SvPV(s_SV, len);
        s = BN_bin2bn((const unsigned char *)string, len, NULL);
        if (NULL == s)
            croak("Could not convert ECDSA parameter string to big number");
        ECDSA_SIG_get0(ecdsa_sig, &old_r, NULL);
        if (NULL == old_r) {
            r = BN_new();
        } else {
            r = BN_dup(old_r);
        }
        if (NULL == r) {
            BN_free(s);
            croak("Could not duplicate unchanged ECDSA parameter");
        }
        if (!ECDSA_SIG_set0(ecdsa_sig, r, s)) {
            BN_free(r);
            BN_free(s);
            croak("Could not store ECDSA parameters");
        }






