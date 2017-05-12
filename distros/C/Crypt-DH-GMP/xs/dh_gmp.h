#ifndef __CRYPT_DH_GMP_H__
#define __CRYPT_DH_GMP_H__

#include <gmp.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef char *  PerlCryptDHGMP_value;
typedef mpz_t   PerlCryptDHGMP_mpz_t;

typedef struct {
    mpz_t *p;
    mpz_t *g;
    mpz_t *priv_key;
    mpz_t *pub_key;
} PerlCryptDHGMP;

#define PerlCryptDHGMP_G(x)       *((x)->g)
#define PerlCryptDHGMP_P(x)       *((x)->p)
#define PerlCryptDHGMP_PRIVKEY(x) *((x)->priv_key)
#define PerlCryptDHGMP_PUBKEY(x)  *((x)->pub_key)

#define PerlCryptDHGMP_G_PTR(x)       (x)->g
#define PerlCryptDHGMP_P_PTR(x)       (x)->p
#define PerlCryptDHGMP_PRIVKEY_PTR(x) (x)->priv_key
#define PerlCryptDHGMP_PUBKEY_PTR(x)  (x)->pub_key

PerlCryptDHGMP *PerlCryptDHGMP_clone(PerlCryptDHGMP *p);
PerlCryptDHGMP *PerlCryptDHGMP_create(char *p, char *g, char *priv_key);
char *PerlCryptDHGMP_compute_key( PerlCryptDHGMP *dh, char * pub_key );
void PerlCryptDHGMP_generate_keys(pTHX_ PerlCryptDHGMP *dh );
char *PerlCryptDHGMP_compute_key_twoc( PerlCryptDHGMP *dh, char * pub_key );
char *PerlCryptDHGMP_priv_key( PerlCryptDHGMP *dh );
char *PerlCryptDHGMP_pub_key( PerlCryptDHGMP *dh );
char *PerlCryptDHGMP_pub_key_twoc( PerlCryptDHGMP *dh );
char *PerlCryptDHGMP_g( PerlCryptDHGMP *dh, char *v );
char *PerlCryptDHGMP_p( PerlCryptDHGMP *dh, char *v );

#endif /* __CRYPT_DH_GMP_H__ */

