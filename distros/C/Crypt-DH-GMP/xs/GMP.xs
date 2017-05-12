#include "dh_gmp.h"

static int
PerlCryptDHGMP_mg_free(pTHX_ SV *const sv, MAGIC* const mg)
{
    PerlCryptDHGMP* const dh = (PerlCryptDHGMP*) mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    mpz_clear(PerlCryptDHGMP_P(dh));
    mpz_clear(PerlCryptDHGMP_G(dh));
    mpz_clear(PerlCryptDHGMP_PUBKEY(dh));
    mpz_clear(PerlCryptDHGMP_PRIVKEY(dh));
    Safefree(PerlCryptDHGMP_P_PTR(dh));
    Safefree(PerlCryptDHGMP_G_PTR(dh));
    Safefree(PerlCryptDHGMP_PRIVKEY_PTR(dh));
    Safefree(PerlCryptDHGMP_PUBKEY_PTR(dh));
    Safefree(dh);
    return 0;
}       

static int
PerlCryptDHGMP_mg_dup(pTHX_ MAGIC *const mg, CLONE_PARAMS *const param)
{
#ifdef USE_ITHREADS
    PerlCryptDHGMP* const dh = (PerlCryptDHGMP*) mg->mg_ptr;
    PerlCryptDHGMP* newdh;    
            
    PERL_UNUSED_VAR(param);
    newdh = PerlCryptDHGMP_clone(dh);
    mg->mg_ptr = (char *) newdh;
#else       
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param); 
#endif
    return 0;   
}
            
static MAGIC*
PerlCryptDHGMP_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("PerlMeCab: Invalid PerlMeCab object was passed");
    return NULL; /* not reached */
}

static MGVTBL PerlCryptDHGMP_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlCryptDHGMP_mg_free, /* free */
    NULL, /* copy */
    PerlCryptDHGMP_mg_dup, /* dup */
    NULL,  /* local */
};

MODULE = Crypt::DH::GMP       PACKAGE = Crypt::DH::GMP  PREFIX = PerlCryptDHGMP_

PROTOTYPES: DISABLE 

PerlCryptDHGMP *
PerlCryptDHGMP__xs_create(class_sv, p, g, priv_key = NULL)
        SV *class_sv;
        char *p;
        char *g;
        char *priv_key;
    CODE:
        RETVAL = PerlCryptDHGMP_create(p, g, priv_key);
    OUTPUT:
        RETVAL

PerlCryptDHGMP *
PerlCryptDHGMP_clone(self)
        PerlCryptDHGMP *self;
    PREINIT:
        SV *class_sv;

void
PerlCryptDHGMP_generate_keys(dh)
        PerlCryptDHGMP *dh;
    CODE:
        PerlCryptDHGMP_generate_keys(aTHX_ dh);

char *
PerlCryptDHGMP_compute_key(dh, pub_key)
        PerlCryptDHGMP *dh;
        char * pub_key;

char *
PerlCryptDHGMP_compute_key_twoc(dh, pub_key)
        PerlCryptDHGMP *dh;
        char * pub_key;

char *
PerlCryptDHGMP_priv_key(dh)
        PerlCryptDHGMP *dh;

char *
PerlCryptDHGMP_pub_key(dh)
        PerlCryptDHGMP *dh;

char *
PerlCryptDHGMP_pub_key_twoc(dh)
        PerlCryptDHGMP *dh;

char *
PerlCryptDHGMP_g(dh, ...)
        PerlCryptDHGMP *dh;
    PREINIT:
        STRLEN n_a;
        char *v = NULL;
    CODE:
        if (items > 1) {
            v = (char *) SvPV(ST(1), n_a);
        }
        RETVAL = PerlCryptDHGMP_g(dh, v);
    OUTPUT:
        RETVAL

char *
PerlCryptDHGMP_p(dh, ...)
        PerlCryptDHGMP *dh;
    PREINIT:
        STRLEN n_a;
        char *v = NULL;
    CODE:
        if (items > 1) {
            v = (char *) SvPV(ST(1), n_a);
        }
        RETVAL = PerlCryptDHGMP_p(dh, v);
    OUTPUT:
        RETVAL

