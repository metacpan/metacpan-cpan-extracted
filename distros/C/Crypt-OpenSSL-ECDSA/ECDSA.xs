#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <openssl/ecdsa.h>
#include <openssl/err.h>

#include "const-c.inc"

MODULE = Crypt::OpenSSL::ECDSA		PACKAGE = Crypt::OpenSSL::ECDSA

PROTOTYPES: ENABLE
INCLUDE: const-xs.inc

BOOT:
    ERR_load_crypto_strings();
    ERR_load_ECDSA_strings();

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

# These ECDSA_METHOD functions only became available in 1.0.2

#if OPENSSL_VERSION_NUMBER >= 0x10002000L

const ECDSA_METHOD *
ECDSA_OpenSSL()

void	  
ECDSA_set_default_method(const ECDSA_METHOD *meth)

const ECDSA_METHOD *
ECDSA_get_default_method()

int 	  
ECDSA_set_method(EC_KEY *eckey, const ECDSA_METHOD *meth)

int	  
ECDSA_size(const EC_KEY *eckey)

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
        unsigned char *to;
        STRLEN len;
    CODE:
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(ecdsa_sig->r, to);
        RETVAL = newSVpvn((const char*)to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_s(ecdsa_sig)
        ECDSA_SIG *ecdsa_sig
    PREINIT:
        unsigned char *to;
        STRLEN len;
    CODE:
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(ecdsa_sig->s, to);
        RETVAL = newSVpvn((const char*)to, len);
        free(to);
    OUTPUT:
        RETVAL

void
set_r(ecdsa_sig, r_SV)
        ECDSA_SIG *ecdsa_sig
        SV * r_SV
    PREINIT:
	char *s;
        STRLEN len;
    CODE:
        s = SvPV(r_SV, len);
        if (ecdsa_sig->r)
            BN_free(ecdsa_sig->r);
        ecdsa_sig->r = BN_bin2bn((const unsigned char *)s, len, NULL);

void
set_s(ecdsa_sig, s_SV)
        ECDSA_SIG *ecdsa_sig
        SV * s_SV
    PREINIT:
	char *s;
        STRLEN len;
    CODE:
        s = SvPV(s_SV, len);
        if (ecdsa_sig->s)
            BN_free(ecdsa_sig->s);
        ecdsa_sig->s = BN_bin2bn((const unsigned char *)s, len, NULL);






