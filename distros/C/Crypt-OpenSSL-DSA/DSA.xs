/* $Id: */


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/bn.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/dsa.h>
#include <openssl/ssl.h>
#include <openssl/opensslv.h>

#ifdef __cplusplus
}
#endif

#if OPENSSL_VERSION_NUMBER < 0x10100000L
static void DSA_get0_pqg(const DSA *d,
                  const BIGNUM **p, const BIGNUM **q, const BIGNUM **g)
{
    if (p != NULL)
        *p = d->p;
    if (q != NULL)
        *q = d->q;
    if (g != NULL)
        *g = d->g;
}

static int DSA_set0_pqg(DSA *d, BIGNUM *p, BIGNUM *q, BIGNUM *g)
{
    /* If the fields p, q and g in d are NULL, the corresponding input
     * parameters MUST be non-NULL.
     */
    if ((d->p == NULL && p == NULL)
        || (d->q == NULL && q == NULL)
        || (d->g == NULL && g == NULL))
        return 0;

    if (p != NULL) {
        BN_free(d->p);
        d->p = p;
    }
    if (q != NULL) {
        BN_free(d->q);
        d->q = q;
    }
    if (g != NULL) {
        BN_free(d->g);
        d->g = g;
    }

    return 1;
}

static void DSA_get0_key(const DSA *d,
                  const BIGNUM **pub_key, const BIGNUM **priv_key)
{
    if (pub_key != NULL)
        *pub_key = d->pub_key;
    if (priv_key != NULL)
        *priv_key = d->priv_key;
}

static int DSA_set0_key(DSA *d, BIGNUM *pub_key, BIGNUM *priv_key)
{
    /* If the field pub_key in d is NULL, the corresponding input
     * parameters MUST be non-NULL.  The priv_key field may
     * be left NULL.
     */
    if (d->pub_key == NULL && pub_key == NULL)
        return 0;

    if (pub_key != NULL) {
        BN_free(d->pub_key);
        d->pub_key = pub_key;
    }
    if (priv_key != NULL) {
        BN_free(d->priv_key);
        d->priv_key = priv_key;
    }

    return 1;
}

static void DSA_SIG_get0(const DSA_SIG *sig, const BIGNUM **pr,
     const BIGNUM **ps)
{
    if (pr != NULL)
        *pr = sig->r;
    if (ps != NULL)
        *ps = sig->s;
}

static int DSA_SIG_set0(DSA_SIG *sig, BIGNUM *r, BIGNUM *s)
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

MODULE = Crypt::OpenSSL::DSA         PACKAGE = Crypt::OpenSSL::DSA

PROTOTYPES: DISABLE

BOOT:
#if OPENSSL_VERSION_NUMBER < 0x10100000L
    ERR_load_crypto_strings();
#endif

DSA *
new(CLASS)
        char * CLASS
    CODE:
        RETVAL = DSA_new();
    OUTPUT:
        RETVAL

void
DESTROY(dsa)
        DSA *dsa
    CODE:
        DSA_free(dsa);

DSA *
generate_parameters(CLASS, bits, seed = NULL)
        char * CLASS
        int bits
        SV * seed
    PREINIT:
        DSA * dsa;
        STRLEN seed_len = 0;
        char * seedpv = NULL;
        unsigned long err;
    CODE:
        if (seed) {
          seedpv = SvPV(seed, seed_len);
        }
#if OPENSSL_VERSION_NUMBER < 0x10100000L
        dsa = DSA_generate_parameters(bits, seedpv, (int)seed_len, NULL, NULL, NULL, NULL);
        if (!dsa) {
#else
	dsa = DSA_new();
	if (!DSA_generate_parameters_ex(dsa, bits, seedpv, (int)seed_len, NULL, NULL, NULL)) {
#endif
          err = ERR_get_error();
          if (err == 0) {
            croak("DSA_generate_parameters() returned NULL");
          }
          else {
            croak("%s", ERR_reason_error_string(err));
          }
        }
        RETVAL = dsa;
    OUTPUT:
        RETVAL

int
generate_key(dsa)
        DSA * dsa
    CODE:
        RETVAL = DSA_generate_key(dsa);
    OUTPUT:
        RETVAL

DSA_SIG *
do_sign(dsa, dgst)
        DSA * dsa
        SV * dgst
    PREINIT:
        DSA_SIG * sig;
        char * CLASS = "Crypt::OpenSSL::DSA::Signature";
        char * dgst_pv = NULL;
        STRLEN dgst_len = 0;
    CODE:
        dgst_pv = SvPV(dgst, dgst_len);
        if (!(sig = DSA_do_sign((const unsigned char *) dgst_pv, (int)dgst_len, dsa))) {
          croak("Error in dsa_sign: %s",ERR_error_string(ERR_get_error(), NULL));
        }
        RETVAL = sig;
    OUTPUT:
        RETVAL

SV *
sign(dsa, dgst)
        DSA * dsa
        SV * dgst
    PREINIT:
        unsigned char *sigret;
        unsigned int siglen;
        char * dgst_pv = NULL;
        STRLEN dgst_len = 0;
    CODE:
        siglen = DSA_size(dsa);
        sigret = malloc(siglen);

        dgst_pv = SvPV(dgst, dgst_len);
        /* warn("Length of sign [%s] is %d\n", dgst_pv, dgst_len); */

        if (!(DSA_sign(0, (const unsigned char *) dgst_pv, (int)dgst_len, sigret, &siglen, dsa))) {
          croak("Error in DSA_sign: %s",ERR_error_string(ERR_get_error(), NULL));
        }
        RETVAL = newSVpvn(sigret, siglen);
        free(sigret);
    OUTPUT:
        RETVAL

int
verify(dsa, dgst, sigbuf)
        DSA * dsa
        SV *dgst
        SV *sigbuf
    PREINIT:
        char * dgst_pv = NULL;
        STRLEN dgst_len = 0;
        char * sig_pv = NULL;
        STRLEN sig_len = 0;
    CODE:
        dgst_pv = SvPV(dgst, dgst_len);
        sig_pv = SvPV(sigbuf, sig_len);
        RETVAL = DSA_verify(0, dgst_pv, (int)dgst_len, sig_pv, (int)sig_len, dsa);
        if (RETVAL == -1)
          croak("Error in DSA_verify: %s",ERR_error_string(ERR_get_error(), NULL));
    OUTPUT:
        RETVAL

int
do_verify(dsa, dgst, sig)
        DSA *dsa
        SV *dgst
        DSA_SIG *sig
    PREINIT:
        char * dgst_pv = NULL;
        STRLEN dgst_len = 0;
    CODE:
        dgst_pv = SvPV(dgst, dgst_len);
        RETVAL = DSA_do_verify(dgst_pv, (int)dgst_len, sig, dsa);
	if (RETVAL == -1)
	  croak("Error in DSA_do_verify: %s",ERR_error_string(ERR_get_error(), NULL));
    OUTPUT:
        RETVAL

DSA *
read_params(CLASS, filename)
        char *CLASS
        char *filename
    PREINIT:
        FILE *f;
    CODE:
        if(!(f = fopen(filename, "r")))
          croak("Can't open file %s", filename);
        RETVAL = PEM_read_DSAparams(f, NULL, NULL, NULL);
        fclose(f);
    OUTPUT:
        RETVAL

int
write_params(dsa, filename)
        DSA * dsa
        char *filename
    PREINIT:
        FILE *f;
    CODE:
        if(!(f = fopen(filename, "w")))
          croak("Can't open file %s", filename);
        RETVAL = PEM_write_DSAparams(f, dsa);
        fclose(f);
    OUTPUT:
        RETVAL

DSA *
_load_key(CLASS, private_flag_SV, key_string_SV)
        char *CLASS;
        SV * private_flag_SV;
        SV * key_string_SV;
    PREINIT:
        STRLEN key_string_length;  /* Needed to pass to SvPV */
        char *key_string;
        char private_flag;
        BIO *stringBIO;
    CODE:
        private_flag = SvTRUE( private_flag_SV );
        key_string = SvPV( key_string_SV, key_string_length );
        if( (stringBIO = BIO_new_mem_buf(key_string, (int)key_string_length)) == NULL )
            croak( "Failed to create memory BIO %s", ERR_error_string(ERR_get_error(), NULL));
        RETVAL = private_flag
            ? PEM_read_bio_DSAPrivateKey( stringBIO, NULL, NULL, NULL )
            : PEM_read_bio_DSA_PUBKEY( stringBIO, NULL, NULL, NULL );
        BIO_set_close(stringBIO, BIO_CLOSE);
        BIO_free( stringBIO );
        if ( RETVAL == NULL )
            croak( "Failed to read key %s", ERR_error_string(ERR_get_error(), NULL));
    OUTPUT:
        RETVAL

DSA *
read_pub_key(CLASS, filename)
        char *CLASS
        char *filename
    PREINIT:
        FILE *f;
    CODE:
        if(!(f = fopen(filename, "r")))
          croak("Can't open file %s", filename);
        RETVAL = PEM_read_DSA_PUBKEY(f, NULL, NULL, NULL);
        fclose(f);
    OUTPUT:
        RETVAL

int
write_pub_key(dsa, filename)
        DSA * dsa
        char *filename
    PREINIT:
        FILE *f;
    CODE:
        if(!(f = fopen(filename, "w")))
          croak("Can't open file %s", filename);
        RETVAL = PEM_write_DSA_PUBKEY(f, dsa);
        fclose(f);
    OUTPUT:
        RETVAL

DSA *
read_priv_key(CLASS, filename)
        char *CLASS
        char *filename
    PREINIT:
        FILE *f;
    CODE:
        if(!(f = fopen(filename, "r")))
          croak("Can't open file %s", filename);
        RETVAL = PEM_read_DSAPrivateKey(f, NULL, NULL, NULL);
        fclose(f);
    OUTPUT:
        RETVAL

int
write_priv_key(dsa, filename)
        DSA * dsa
        char *filename
    PREINIT:
        FILE *f;
    CODE:
        if(!(f = fopen(filename, "w")))
          croak("Can't open file %s", filename);
        RETVAL = PEM_write_DSAPrivateKey(f, dsa, NULL, NULL, 0, NULL, NULL);
        fclose(f);
    OUTPUT:
        RETVAL

SV *
get_p(dsa)
        DSA *dsa
    PREINIT:
        const BIGNUM *p;
        char *to;
        int len;
    CODE:
        DSA_get0_pqg(dsa, &p, NULL, NULL);
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(p, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_q(dsa)
        DSA *dsa
    PREINIT:
        const BIGNUM *q;
        char *to;
        int len;
    CODE:
        DSA_get0_pqg(dsa, NULL, &q, NULL);
        to = malloc(sizeof(char) * 20);
        len = BN_bn2bin(q, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_g(dsa)
        DSA *dsa
    PREINIT:
        const BIGNUM *g;
        char *to;
        int len;
    CODE:
        DSA_get0_pqg(dsa, NULL, NULL, &g);
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(g, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_pub_key(dsa)
        DSA *dsa
    PREINIT:
        const BIGNUM *pub_key;
        char *to;
        int len;
    CODE:
        DSA_get0_key(dsa, &pub_key, NULL);
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(pub_key, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_priv_key(dsa)
        DSA *dsa
    PREINIT:
        const BIGNUM *priv_key;
        char *to;
        int len;
    CODE:
        DSA_get0_key(dsa, NULL, &priv_key);
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(priv_key, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

void
set_p(dsa, p_SV)
        DSA *dsa
        SV * p_SV
    PREINIT:
        STRLEN len;
        BIGNUM *p;
        BIGNUM *q;
        BIGNUM *g;
        const BIGNUM *old_q;
        const BIGNUM *old_g;
    CODE:
        len = SvCUR(p_SV);
        p = BN_bin2bn(SvPV(p_SV, len), (int)len, NULL);
        DSA_get0_pqg(dsa, NULL, &old_q, &old_g);
        if (NULL == old_q) {
            q = BN_new();
        } else {
            q = BN_dup(old_q);
        }
        if (NULL == q) {
            BN_free(p);
            croak("Could not duplicate another prime");
        }
        if (NULL == old_g) {
            g = BN_new();
        } else {
            g = BN_dup(old_g);
        }
        if (NULL == g) {
            BN_free(p);
            BN_free(q);
            croak("Could not duplicate another prime");
        }
        if (!DSA_set0_pqg(dsa, p, q, g)) {
            BN_free(p);
            BN_free(q);
            BN_free(g);
            croak("Could not set a prime");
        }

void
set_q(dsa, q_SV)
        DSA *dsa
        SV * q_SV
    PREINIT:
        STRLEN len;
        BIGNUM *p;
        BIGNUM *q;
        BIGNUM *g;
        const BIGNUM *old_p;
        const BIGNUM *old_g;
    CODE:
        len = SvCUR(q_SV);
        q = BN_bin2bn(SvPV(q_SV, len), (int)len, NULL);
        DSA_get0_pqg(dsa, &old_p, NULL, &old_g);
        if (NULL == old_p) {
            p = BN_new();
        } else {
            p = BN_dup(old_p);
        }
        if (NULL == p) {
            BN_free(q);
            croak("Could not duplicate another prime");
        }
        if (NULL == old_g) {
            g = BN_new();
        } else {
            g = BN_dup(old_g);
        }
        if (NULL == g) {
            BN_free(p);
            BN_free(q);
            croak("Could not duplicate another prime");
        }
        if (!DSA_set0_pqg(dsa, p, q, g)) {
            BN_free(p);
            BN_free(q);
            BN_free(g);
            croak("Could not set a prime");
        }

void
set_g(dsa, g_SV)
        DSA *dsa
        SV * g_SV
    PREINIT:
        STRLEN len;
        BIGNUM *p;
        BIGNUM *q;
        BIGNUM *g;
        const BIGNUM *old_p;
        const BIGNUM *old_q;
    CODE:
        len = SvCUR(g_SV);
        g = BN_bin2bn(SvPV(g_SV, len), (int)len, NULL);
        DSA_get0_pqg(dsa, &old_p, &old_q, NULL);
        if (NULL == old_p) {
            p = BN_new();
        } else {
            p = BN_dup(old_p);
        }
        if (NULL == p) {
            BN_free(g);
            croak("Could not duplicate another prime");
        }
        if (NULL == old_q) {
            q = BN_new();
        } else {
            q = BN_dup(old_q);
        }
        if (NULL == q) {
            BN_free(p);
            BN_free(g);
            croak("Could not duplicate another prime");
        }
        if (!DSA_set0_pqg(dsa, p, q, g)) {
            BN_free(p);
            BN_free(q);
            BN_free(g);
            croak("Could not set a prime");
        }

void
set_pub_key(dsa, pub_key_SV)
        DSA *dsa
        SV * pub_key_SV
    PREINIT:
        STRLEN len;
	    BIGNUM *pub_key;
    CODE:
        len = SvCUR(pub_key_SV);
        pub_key = BN_bin2bn(SvPV(pub_key_SV, len), (int)len, NULL);
		if (!DSA_set0_key(dsa, pub_key, NULL)) {
			BN_free(pub_key);
			croak("Could not set a key");
		}

void
set_priv_key(dsa, priv_key_SV)
        DSA *dsa
        SV * priv_key_SV
    PREINIT:
        STRLEN len;
        const BIGNUM *old_pub_key;
        BIGNUM *pub_key;
        BIGNUM *priv_key;
    CODE:
        DSA_get0_key(dsa, &old_pub_key, NULL);
        if (NULL == old_pub_key) {
            pub_key = BN_new();
            if (NULL == pub_key) {
                croak("Could not create a dummy public key");
            }
            if (!DSA_set0_key(dsa, pub_key, NULL)) {
                BN_free(pub_key);
                croak("Could not set a dummy public key");
            }
        }
        len = SvCUR(priv_key_SV);
        priv_key = BN_bin2bn(SvPV(priv_key_SV, len), (int)len, NULL);
		if (!DSA_set0_key(dsa, NULL, priv_key)) {
			BN_free(priv_key);
			croak("Could not set a key");
		}

MODULE = Crypt::OpenSSL::DSA    PACKAGE = Crypt::OpenSSL::DSA::Signature

DSA_SIG *
new(CLASS)
        char * CLASS
    CODE:
        RETVAL = DSA_SIG_new();
    OUTPUT:
        RETVAL

void
DESTROY(dsa_sig)
        DSA_SIG *dsa_sig
    CODE:
        DSA_SIG_free(dsa_sig);

SV *
get_r(dsa_sig)
        DSA_SIG *dsa_sig
    PREINIT:
        const BIGNUM *r;
        char *to;
        int len;
    CODE:
        DSA_SIG_get0(dsa_sig, &r, NULL);
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(r, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

SV *
get_s(dsa_sig)
        DSA_SIG *dsa_sig
    PREINIT:
        const BIGNUM *s;
        char *to;
        int len;
    CODE:
        DSA_SIG_get0(dsa_sig, NULL, &s);
        to = malloc(sizeof(char) * 128);
        len = BN_bn2bin(s, to);
        RETVAL = newSVpvn(to, len);
        free(to);
    OUTPUT:
        RETVAL

void
set_r(dsa_sig, r_SV)
        DSA_SIG *dsa_sig
        SV * r_SV
    PREINIT:
        STRLEN len;
		BIGNUM *r;
        BIGNUM *s;
        const BIGNUM *old_s;
    CODE:
        len = SvCUR(r_SV);
        r = BN_bin2bn(SvPV(r_SV, len), (int)len, NULL);
        DSA_SIG_get0(dsa_sig, NULL, &old_s);
        if (NULL == old_s) {
            s = BN_new();
        } else {
            s = BN_dup(old_s);
        }
        if (NULL == s) {
            BN_free(r);
            croak("Could not duplicate another signature value");
        }
		if (!DSA_SIG_set0(dsa_sig, r, s)) {
			BN_free(r);
            BN_free(s);
			croak("Could not set a signature");
		}

void
set_s(dsa_sig, s_SV)
        DSA_SIG *dsa_sig
        SV * s_SV
    PREINIT:
        STRLEN len;
		BIGNUM *s;
		BIGNUM *r;
        const BIGNUM *old_r;
    CODE:
        len = SvCUR(s_SV);
        s = BN_bin2bn(SvPV(s_SV, len), (int)len, NULL);
        DSA_SIG_get0(dsa_sig, &old_r, NULL);
        if (NULL == old_r) {
            r = BN_new();
        } else {
            r = BN_dup(old_r);
        }
        if (NULL == r) {
            BN_free(s);
            croak("Could not duplicate another signature value");
        }
		if (!DSA_SIG_set0(dsa_sig, r, s)) {
			BN_free(s);
			croak("Could not set a signature");
		}
