#ifndef __CRYPT_DH_GMP_XS__
#define __CRYPT_DH_GMP_XS__

#include "dh_gmp.h"

void
PerlCryptDHGMP_mpz_rand_set(pTHX_ mpz_t *v, unsigned int bits)
{
    gmp_randstate_t state;

    gmp_randinit_default(state);
    /* Perl_seed should come with Perl 5.8.1. You shouldn't be using
       Perl older than that, or at least you should be supplying me with
       a patch
    */
    gmp_randseed_ui(state, Perl_seed(aTHX));
    mpz_urandomb(*v, state, bits);
    gmp_randclear(state);
}

char *
PerlCryptDHGMP_mpz2sv_str(mpz_t *v, unsigned int base, unsigned int *length)
{
    STRLEN len = 0;
    char *buf, *buf_end;

    /* len is always >= 1, and might be off (greater) by one than real len */
    len = mpz_sizeinbase(*v, base);
    Newxz(buf, len + 2, char);
    buf_end = buf + len - 1; /* end of storage (-1) */
    mpz_get_str(buf, base, *v);
    if (*buf_end == 0) {
       Renew(buf, len, char); /* got one shorter than expected */
       len--;
    }

    if (length != NULL)
        *length = len;

    return buf;
}

char *
PerlCryptDHGMP_mpz2sv_str_twoc(mpz_t *v)
{
    char *buf;
    unsigned int len = 0;
    unsigned int pad = 0;

    buf = PerlCryptDHGMP_mpz2sv_str(v, 2, &len);
    pad = (8 - len % 8);
    if (pad <= 0 && *buf == '1') {
        pad = 8;
    }

    if (pad > 0) {
        unsigned int ipad = 0;
        char *tmp;
        Newxz(tmp, len + pad + 1, char);
        for (ipad = 0; ipad < pad; ipad++)
            *(tmp + ipad) = '0';
        Copy(buf, tmp + pad, len + 1, char);
        Safefree(buf);
        return tmp;
    }

    return buf;
}

PerlCryptDHGMP *
PerlCryptDHGMP_create(char *p, char *g, char *priv_key)
{
    PerlCryptDHGMP *dh;

    Newxz(dh, 1, PerlCryptDHGMP);
    Newxz(PerlCryptDHGMP_P_PTR(dh),       1, mpz_t);
    Newxz(PerlCryptDHGMP_G_PTR(dh),       1, mpz_t);
    Newxz(PerlCryptDHGMP_PRIVKEY_PTR(dh), 1, mpz_t);
    Newxz(PerlCryptDHGMP_PUBKEY_PTR(dh),  1, mpz_t);

    mpz_init(PerlCryptDHGMP_PUBKEY(dh));
    mpz_init_set_str(PerlCryptDHGMP_P(dh), p, 0);
    mpz_init_set_str(PerlCryptDHGMP_G(dh), g, 0);
    if (priv_key != NULL) {
        mpz_init_set_str(PerlCryptDHGMP_PRIVKEY(dh), priv_key, 10);
    } else {
        mpz_init_set_ui(PerlCryptDHGMP_PRIVKEY(dh), 0);
    } 

    return dh;
}

PerlCryptDHGMP *
PerlCryptDHGMP_clone(PerlCryptDHGMP *o)
{
    PerlCryptDHGMP *dh;

    Newxz(dh, 1, PerlCryptDHGMP);
    Newxz(PerlCryptDHGMP_P_PTR(dh),       1, mpz_t);
    Newxz(PerlCryptDHGMP_G_PTR(dh),       1, mpz_t);
    Newxz(PerlCryptDHGMP_PRIVKEY_PTR(dh), 1, mpz_t);
    Newxz(PerlCryptDHGMP_PUBKEY_PTR(dh),  1, mpz_t);

    mpz_set(PerlCryptDHGMP_P(dh), PerlCryptDHGMP_P(o));
    mpz_set(PerlCryptDHGMP_G(dh), PerlCryptDHGMP_G(o));
    mpz_set(PerlCryptDHGMP_PRIVKEY(dh), PerlCryptDHGMP_PRIVKEY(o));
    mpz_set(PerlCryptDHGMP_PUBKEY(dh), PerlCryptDHGMP_PUBKEY(o));

    return dh;
}

void
PerlCryptDHGMP_generate_keys(pTHX_ PerlCryptDHGMP *dh )
{
    if (mpz_cmp_ui(PerlCryptDHGMP_PRIVKEY(dh), 0) == 0) {
        mpz_t max;

        /* not initialized, eh? */
        mpz_init(max);
        mpz_sub_ui(max, PerlCryptDHGMP_P(dh), 1);
        do {
            size_t p_size = mpz_sizeinbase(PerlCryptDHGMP_P(dh), 2);
            PerlCryptDHGMP_mpz_rand_set(aTHX_ PerlCryptDHGMP_PRIVKEY_PTR(dh), p_size);
        } while ( mpz_cmp(PerlCryptDHGMP_PRIVKEY(dh), max) > 0 );
    }

    mpz_powm(
        PerlCryptDHGMP_PUBKEY(dh),
        PerlCryptDHGMP_G(dh),
        PerlCryptDHGMP_PRIVKEY(dh),
        PerlCryptDHGMP_P(dh)
    );
}

char *
PerlCryptDHGMP_compute_key( PerlCryptDHGMP *dh, char * pub_key )
{
    char *ret;
    PerlCryptDHGMP_mpz_t mpz_ret;
    PerlCryptDHGMP_mpz_t mpz_pub_key;

    mpz_init(mpz_ret);
    mpz_init_set_str(mpz_pub_key, pub_key, 0);
    mpz_powm(mpz_ret, mpz_pub_key, PerlCryptDHGMP_PRIVKEY(dh), PerlCryptDHGMP_P(dh));
    ret = PerlCryptDHGMP_mpz2sv_str(&mpz_ret, 10, NULL);
    mpz_clear(mpz_ret);
    mpz_clear(mpz_pub_key);

    return ret;
}

char *
PerlCryptDHGMP_compute_key_twoc( PerlCryptDHGMP *dh, char * pub_key )
{
    char *ret;
    PerlCryptDHGMP_mpz_t mpz_ret;
    PerlCryptDHGMP_mpz_t mpz_pub_key;

    mpz_init(mpz_ret);
    mpz_init_set_str(mpz_pub_key, pub_key, 0);
    mpz_powm(mpz_ret, mpz_pub_key, PerlCryptDHGMP_PRIVKEY(dh), PerlCryptDHGMP_P(dh));
    ret = PerlCryptDHGMP_mpz2sv_str_twoc(&mpz_ret);
    mpz_clear(mpz_ret);
    mpz_clear(mpz_pub_key);

    return ret;
}

char *
PerlCryptDHGMP_priv_key( PerlCryptDHGMP *dh )
{
    return PerlCryptDHGMP_mpz2sv_str(PerlCryptDHGMP_PRIVKEY_PTR(dh), 10, NULL);
}

char *
PerlCryptDHGMP_pub_key( PerlCryptDHGMP *dh )
{
    return PerlCryptDHGMP_mpz2sv_str(PerlCryptDHGMP_PUBKEY_PTR(dh), 10, NULL);
}

char *
PerlCryptDHGMP_pub_key_twoc( PerlCryptDHGMP *dh )
{
    return PerlCryptDHGMP_mpz2sv_str_twoc(PerlCryptDHGMP_PUBKEY_PTR(dh));
}

char *
PerlCryptDHGMP_g( PerlCryptDHGMP *dh, char *v )
{
    char *ret;

    ret = PerlCryptDHGMP_mpz2sv_str(PerlCryptDHGMP_G_PTR(dh), 10, NULL);
    if (v != NULL) {
        mpz_init_set_str( PerlCryptDHGMP_G(dh), v, 0 );
    }
    return ret;
}

char *
PerlCryptDHGMP_p( PerlCryptDHGMP *dh, char *v )
{
    char *ret;

    ret = PerlCryptDHGMP_mpz2sv_str(PerlCryptDHGMP_P_PTR(dh), 10, NULL);
    if (v != NULL) {
        mpz_init_set_str( PerlCryptDHGMP_P(dh), v, 0 );
    }
    return ret;
}

#endif /* __CRYPT_DH_GMP_XS__ */


