#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/asn1.h>
#include <openssl/objects.h>
#include <openssl/bio.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

typedef X509_STORE *Crypt__OpenSSL__Verify;
typedef X509 *Crypt__OpenSSL__X509;

int strict_certs = 1;
int trust_expired = 0;
int trust_no_local = 0;
int trust_onelogin = 0;

int verify_cb(int ok, X509_STORE_CTX * ctx)
{

    int cert_error = X509_STORE_CTX_get_error(ctx);

    if (!ok) {
        /*
         * Pretend that some errors are ok, so they don't stop further
         * processing of the certificate chain.  Setting ok = 1 does this.
         * After X509_verify_cert() is done, we verify that there were
         * no actual errors, even if the returned value was positive.
         */
        printf("trust_expired: %d\n", trust_expired);
        printf("strict_certs: %d\n", strict_certs);
        printf("trust_no_local: %d\n", trust_no_local);
        printf("trust_onelogin: %d\n", trust_onelogin);
        switch (cert_error) {
            case X509_V_ERR_NO_EXPLICIT_POLICY:
                /* fall thru */
            case X509_V_ERR_CERT_HAS_EXPIRED:
                printf("    Expired: %d - ", cert_error);
                if (!trust_expired || strict_certs) {
                    break;
                }
                printf("ok\n");
                ok = 1;
                break;
                /* Continue even if the leaf is a self signed cert */
            case X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT:
                /* Continue after extension errors too */
            case X509_V_ERR_INVALID_CA:
            case X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE:
                printf("    Onelogin: %d - ", cert_error);
                if (!trust_onelogin || strict_certs)
                    break;
                printf("ok\n");
                ok = 1;
                break;
            case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY:
                printf("    Local: %d - ", cert_error);
                if (!trust_no_local || strict_certs)
                    break;
                ok = 1;
                printf("ok\n");
                break;
            case X509_V_ERR_INVALID_NON_CA:
            case X509_V_ERR_PATH_LENGTH_EXCEEDED:
            case X509_V_ERR_INVALID_PURPOSE:
            case X509_V_ERR_CRL_HAS_EXPIRED:
            case X509_V_ERR_CRL_NOT_YET_VALID:
            case X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION:
                ok = 1;
        }
        return ok;
    }
    return ok;
}

static SV *callback = (SV *) NULL;

static int cb1(ok, ctx)
    int ok;
    UV *ctx;
{
    dSP;
    int count;
    int i;

    /* printf("Callback pointer: %p\n", ctx); */
    /* printf("Callback UL of pointer %lu\n", PTR2UV(ctx)); */
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);

    PUSHs(newSVuv(ok));
    PUSHs(newSVuv(PTR2UV(ctx)));
    PUTBACK;

    count = call_sv(callback, G_SCALAR);

    SPAGAIN;
    if (count != 1)
        croak("ERROR - Perl callback returned more than one value\n");

    i = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return i;
}

static const char *ssl_error(void)
{
    return ERR_error_string(ERR_get_error(), NULL);
}

static const char *ctx_error(X509_STORE_CTX * ctx)
{
    return X509_verify_cert_error_string(X509_STORE_CTX_get_error(ctx));
}

MODULE = Crypt::OpenSSL::Verify    PACKAGE = Crypt::OpenSSL::Verify

PROTOTYPES: DISABLE

#if OPENSSL_API_COMPAT >= 0x10100000L
#undef ERR_load_crypto_strings
#define ERR_load_crypto_strings()    /* nothing */
#undef OpenSSL_add_all_algorithms
#define OpenSSL_add_all_algorithms()    /* nothing */
#endif
BOOT:
    ERR_load_crypto_strings();
    ERR_load_ERR_strings();
    OpenSSL_add_all_algorithms();

void register_verify_cb(fn)
    SV *fn

    CODE:
        /* this code seems to work fine as the perl function is called */
        /* Remember the Perl sub */
        if (callback == (SV *) NULL)
            callback = newSVsv(fn);
        else
            SvSetSV(callback, fn);

Crypt::OpenSSL::Verify _new(class, options)
    SV *class
    SV *options

    PREINIT:

        X509_LOOKUP * lookup = NULL;
        HV *myhash;
        SV **svp;
        SV *CAfile = NULL;
        SV *CApath = NULL;
        int noCApath = 0, noCAfile = 0;

    CODE:

        (void)SvPV_nolen(class);
        myhash = (HV *) SvRV(options);

        if (hv_exists(myhash, "CAfile", strlen("CAfile"))) {
            svp = hv_fetch(myhash, "CAfile", strlen("CAfile"), 0);
            CAfile = *svp;
        }

        if (hv_exists(myhash, "noCAfile", strlen("noCAfile"))) {
            svp = hv_fetch(myhash, "noCAfile", strlen("noCAfile"), 0);
            if (SvIOKp(*svp)) {
                noCAfile = SvIV(*svp);
            }
        }

        if (hv_exists(myhash, "CApath", strlen("CApath"))) {
            svp = hv_fetch(myhash, "CApath", strlen("CApath"), 0);
            CApath = *svp;
        }

        if (hv_exists(myhash, "noCApath", strlen("noCApath"))) {
            svp = hv_fetch(myhash, "noCApath", strlen("noCApath"), 0);
            if (SvIOKp(*svp)) {
                noCApath = SvIV(*svp);
            }
        }
#if DISABLED
        if (hv_exists(myhash, "trust_no_local", strlen("trust_no_local"))) {
            svp = hv_fetch(myhash, "trust_no_local", strlen("trust_no_local"), 0);
            if (SvIOKp(*svp)) {
                trust_no_local = SvIV(*svp);
            }
        }
        if (hv_exists(myhash, "trust_expired", strlen("trust_expired"))) {
            svp = hv_fetch(myhash, "trust_expired", strlen("trust_expired"), 0);
            if (SvIOKp(*svp)) {
                trust_expired = SvIV(*svp);
            }
        }
        if (hv_exists(myhash, "trust_onelogin", strlen("trust_onelogin"))) {
            svp = hv_fetch(myhash, "trust_onelogin", strlen("trust_onelogin"), 0);
            if (SvIOKp(*svp)) {
                trust_onelogin = SvIV(*svp);
            }
        }
        if (hv_exists(myhash, "strict", strlen("strict"))) {
            svp = hv_fetch(myhash, "strict", strlen("strict"), 0);
            if (SvIOKp(*svp)) {
                strict = SvIV(*svp);
            }
        }
#endif

    /* BEGIN Source apps.c setup_verify() */
    RETVAL = X509_STORE_new();

    if (RETVAL == NULL) {
        X509_STORE_free(RETVAL);
        croak("failure to allocate x509 store: %s", ssl_error());
    }

    X509_STORE_set_verify_cb_func(RETVAL, cb1);

    /* Load the CAfile to the store as a certificate to lookup against */
    if (CAfile != NULL || !noCAfile) {
        /* Add a lookup structure to the store to load a file */
        lookup = X509_STORE_add_lookup(RETVAL, X509_LOOKUP_file());
        if (lookup == NULL) {
            X509_STORE_free(RETVAL);
            croak("failure to add lookup to store: %s", ssl_error());
        }
        if (CAfile != NULL) {
            if (!X509_LOOKUP_load_file
                (lookup, SvPV_nolen(CAfile), X509_FILETYPE_PEM)) {
                X509_STORE_free(RETVAL);
                croak("Error loading file %s: %s\n", SvPV_nolen(CAfile),
                    ssl_error());
            }
        } else {
            X509_LOOKUP_load_file(lookup, NULL, X509_FILETYPE_DEFAULT);
        }
    }

    /* Load the CApath to the store as a hash dir lookup against */
    if (CApath != NULL || !noCApath) {
        /* Add a lookup structure to the store to load hash dir */
        lookup = X509_STORE_add_lookup(RETVAL, X509_LOOKUP_hash_dir());
        if (lookup == NULL) {
            X509_STORE_free(RETVAL);
            croak("failure to add hash_dir lookup to store: %s", ssl_error());
        }
        if (CApath != NULL) {
            if (!X509_LOOKUP_add_dir(lookup, SvPV_nolen(CApath),
                    X509_FILETYPE_PEM)) {
                croak("Error loading directory %s\n", SvPV_nolen(CApath));
            }
        } else {
            X509_LOOKUP_add_dir(lookup, NULL, X509_FILETYPE_DEFAULT);
        }
    }

    ERR_clear_error();
    /* END Source apps.c setup_verify() */

    OUTPUT:

        RETVAL

int ctx_error_code(ctx)
    UV ctx;

    PREINIT:

    CODE:
        /* printf("ctx_error_code - UL holding pointer: %lu\n", ctx); */
        /* printf("ctx_error_code - Pointer to ctx: %p\n", (void *) INT2PTR(UV , ctx)); */
        RETVAL = X509_STORE_CTX_get_error((X509_STORE_CTX *) INT2PTR(UV, ctx));

    OUTPUT:

        RETVAL

int verify(store, x509)
    Crypt::OpenSSL::Verify store;
    Crypt::OpenSSL::X509 x509;

    PREINIT:

        X509_STORE_CTX * csc;

    CODE:

        if (x509 == NULL)
        {
            croak("no cert to verify");
        }
#if DISABLED
       // SV* strict_certs;
       //int strict_certs = SvIV(get_sv("Crypt::OpenSSL::Verify::strict_certs", 0));
       // SV* trust_expired;
       //int trust_expired = SvIV(get_sv("Crypt::OpenSSL::Verify::trust_expired", 0));
       // SV* trust_no_local;
       //int trust_no_local = SvIV(get_sv("Crypt::OpenSSL::Verify::trust_no_local", 0));
       //SV* trust_onelogin;
       //int trust_onelogin = SvIV(get_sv("Crypt::OpenSSL::Verify::trust_onelogin", 0));
#endif

        csc = X509_STORE_CTX_new();
        if (csc == NULL) {
            croak("X.509 store context allocation failed: %s", ssl_error());
        }

        X509_STORE_set_flags(store, 0);

        if (!X509_STORE_CTX_init(csc, store, x509, NULL)) {
            X509_STORE_CTX_free(csc);
            croak("store ctx init: %s", ssl_error());
        }

        RETVAL = X509_verify_cert(csc);

        X509_STORE_CTX_free(csc);

        if (!RETVAL)
            croak("verify: %s", ctx_error(csc));

    OUTPUT:

        RETVAL

void DESTROY(store)
    Crypt::OpenSSL::Verify store;

    PPCODE:

        if (store)
            X509_STORE_free(store);
        store = 0;


#if OPENSSL_API_COMPAT >= 0x10100000L
void __X509_cleanup(void)

    PPCODE:
        /* deinitialisation is done automatically */

#else
void __X509_cleanup(void)

    PPCODE:

    CRYPTO_cleanup_all_ex_data();
    ERR_free_strings();
    ERR_remove_state(0);
    EVP_cleanup();

#endif

