#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

#include <openssl/asn1.h>
#include <openssl/objects.h>
#include <openssl/bio.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/x509_vfy.h>

typedef X509 *Crypt__OpenSSL__X509;

struct OPTIONS {
   bool  trust_expired;
   bool  trust_no_local;
   bool  trust_onelogin;
};

=pod

=head1 NAME

Verify.xs - C interface to OpenSSL to verify certificates

=head1 METHODS

=head2 verify_cb(int ok, X509_STORE_CTX * ctx)
The C equivalent of the verify_callback perl sub
This code is due to be removed if the perl version
is permanent

=cut

#if DISABLED
int verify_cb(struct OPTIONS * options, int ok, X509_STORE_CTX * ctx)
{

    int cert_error = X509_STORE_CTX_get_error(ctx);

    if (!ok) {
        /*
         * Pretend that some errors are ok, so they don't stop further
         * processing of the certificate chain.  Setting ok = 1 does this.
         * After X509_verify_cert() is done, we verify that there were
         * no actual errors, even if the returned value was positive.
         */
        switch (cert_error) {
            case X509_V_ERR_NO_EXPLICIT_POLICY:
                /* fall thru */
            case X509_V_ERR_CERT_HAS_EXPIRED:
                if ( ! options->trust_expired ) {
                    break;
                }
                ok = 1;
                break;
                /* Continue even if the leaf is a self signed cert */
            case X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT:
                /* Continue after extension errors too */
            case X509_V_ERR_INVALID_CA:
            case X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE:
                if ( !options->trust_onelogin )
                    break;
                ok = 1;
                break;
            case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY:
                if ( !options->trust_no_local )
                    break;
                ok = 1;
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
#endif

=head2 int cb1(ok, ctx)

The link to the Perl verify_callback() sub.  This called by OpenSSL
during the verify of the certificates and in turn passes the parameters
to the Perl verify_callback() sub.  It gets a return code from Perl
and returns it to OpenSSL

=head3 Parameters

=over

=item * ok

    The result of the certificate verification in OpenSSL ok = 1, !ok =
    0

=item * ctx

    Pointer to the X509_Store_CTX that OpenSSL includes the error codes
    in

=back

=cut

static SV *callback = (SV *) NULL;

static int cb1(ok, ctx)
    int ok;
    IV *ctx;
{
    dSP;
    int count;
    int i;

    //printf("Callback pointer: %p\n", ctx);
    //printf("Callback INT of pointer %lu\n", (unsigned long) PTR2IV(ctx));
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);

    PUSHs(newSViv(ok));                 // Pass ok as integer on the stack
    PUSHs(newSViv(PTR2IV(ctx)));        // Pass pointer address as integer
    PUTBACK;

    count = call_sv(callback, G_SCALAR);  // Call the verify_callback()

    SPAGAIN;
    if (count != 1)
        croak("ERROR - Perl callback returned more than one value\n");

    i = POPi;   // Get the return code from Perl verify_callback()
    PUTBACK;
    FREETMPS;
    LEAVE;

    return i;
}

=head2 ssl_error(void)

Returns the string description of the ssl error

=cut

static const char *ssl_error(void)
{
    return ERR_error_string(ERR_get_error(), NULL);
}

=head2 ctx_error(void)

Returns the string description of the ctx error

=cut

static const char *ctx_error(X509_STORE_CTX * ctx)
{
    return X509_verify_cert_error_string(X509_STORE_CTX_get_error(ctx));
}

// Taken from p5-Git-Raw
STATIC HV *ensure_hv(SV *sv, const char *identifier) {
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
    croak("Invalid type for '%s', expected a hash", identifier);

    return (HV *) SvRV(sv);
}

static int ssl_store_destroy(pTHX_ SV* var, MAGIC* magic) {
    X509_STORE * store;

    store = (X509_STORE *) magic->mg_ptr;
    if (!store)
        return 0;

    X509_STORE_free(store);
    return 1;
}

static const MGVTBL store_magic = { NULL, NULL, NULL, NULL, ssl_store_destroy };

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

=head2 register_verify_cb()

Called by the Perl code to register which Perl sub is
the OpenSSL Verify Callback

=cut

void register_verify_cb(fn)
    SV *fn

    CODE:
        /* this code seems to work fine as the perl function is called */
        /* Remember the Perl sub */
        if (callback == (SV *) NULL)
            callback = newSVsv(fn);
        else
            SvSetSV(callback, fn);

=head1 new

Constructs the object ready to verify the certificates.
It also sets the callback function.

    Crypt::OpenSSL::Verify->new(CAfile, options);

For users coming from L<Crypt::OpenSSL::VerifyX509>, you should
instantiate the object using:

    Crypt::OpenSSL::Verify->new(CAfile, { strict_certs => 0 } );

User who do not want a CAfile but want to use the defaults please use:

    Crypt::OpenSSL::Verify->new(undef);

The object created is similar to running the following command with the
C<openssl verify> command line tool: C<< openssl verify [ -CApath
/path/to/certs ] [ -noCApath ] [ -noCAfile ] [ -CAfile /path/to/file ]
cert.pem >>

=cut

SV * new(class, ...)
    const char * class

    PREINIT:

        SV * CAfile = NULL;

        HV * options = newHV();

        X509_LOOKUP * cafile_lookup = NULL;
        X509_LOOKUP * cadir_lookup = NULL;
        X509_STORE * x509_store = NULL;
        SV **svp;
        SV *CApath = NULL;
        int noCApath = 0;
        int noCAfile = 0;
        int strict_certs = 1; // Default is strict openSSL verify
        SV * store = newSV(0);

    CODE:


        if (items > 1) {
            if (ST(1) != NULL) {
                // TODO: ensure_string_sv
                CAfile = ST(1);
                if (strlen(SvPV_nolen(CAfile)) == 0) {
                    CAfile = NULL;
                }
            }

            if (items > 2)
                options = ensure_hv(ST(2), "options");

        }

        if (hv_exists(options, "noCAfile", strlen("noCAfile"))) {
            svp = hv_fetch(options, "noCAfile", strlen("noCAfile"), 0);
            if (SvIOKp(*svp)) {
                noCAfile = SvIV(*svp);
            }
        }

        if (hv_exists(options, "CApath", strlen("CApath"))) {
            svp = hv_fetch(options, "CApath", strlen("CApath"), 0);
            CApath = *svp;
        }

        if (hv_exists(options, "noCApath", strlen("noCApath"))) {
            svp = hv_fetch(options, "noCApath", strlen("noCApath"), 0);
            if (SvIOKp(*svp)) {
                noCApath = SvIV(*svp);
            }
        }

        if (hv_exists(options, "strict_certs", strlen("strict_certs"))) {
            svp = hv_fetch(options, "strict_certs", strlen("strict_certs"), 0);
            if (SvIOKp(*svp)) {
                strict_certs = SvIV(*svp);
            }
        }

        x509_store = X509_STORE_new();

        if (x509_store == NULL) {
            X509_STORE_free(x509_store);
            croak("failure to allocate x509 store: %s", ssl_error());
        }

        if (!strict_certs)
            X509_STORE_set_verify_cb_func(x509_store, cb1);

        if (CAfile != NULL || !noCAfile) {
            cafile_lookup = X509_STORE_add_lookup(x509_store, X509_LOOKUP_file());
            if (cafile_lookup == NULL) {
                X509_STORE_free(x509_store);
                croak("failure to add lookup to store: %s", ssl_error());
            }
            if (CAfile != NULL) {
                if (!X509_LOOKUP_load_file(cafile_lookup, SvPV_nolen(CAfile), X509_FILETYPE_PEM)) {
                    X509_STORE_free(x509_store);
                    croak("Error loading file %s: %s\n", SvPV_nolen(CAfile),
                        ssl_error());
                }
            } else {
                X509_LOOKUP_load_file(cafile_lookup, NULL, X509_FILETYPE_DEFAULT);
            }
        }

        if (CApath != NULL || !noCApath) {
            cadir_lookup = X509_STORE_add_lookup(x509_store, X509_LOOKUP_hash_dir());
            if (cadir_lookup == NULL) {
                X509_STORE_free(x509_store);
                croak("failure to add lookup to store: %s", ssl_error());
            }
            if (CApath != NULL) {
                if (!X509_LOOKUP_add_dir(cadir_lookup, SvPV_nolen(CApath), X509_FILETYPE_PEM)) {
                    X509_STORE_free(x509_store);
                    croak("Error loading directory %s\n", SvPV_nolen(CApath));
                }
            } else {
                X509_LOOKUP_add_dir(cadir_lookup, NULL, X509_FILETYPE_DEFAULT);
            }
        }

        HV * attributes = newHV();

        SV *const self = newRV_noinc( (SV *)attributes );

        sv_magicext(store, NULL, PERL_MAGIC_ext,
            &store_magic, (const char *)x509_store, 0);

        if((hv_store(attributes, "STORE", 5, store, 0)) == NULL)
            croak("unable to init store");

        RETVAL = sv_bless( self, gv_stashpv( class, 0 ) );

        // Empty the currect thread error queue
        // https://www.openssl.org/docs/man1.1.1/man3/ERR_clear_error.html
        ERR_clear_error();

    OUTPUT:

        RETVAL

=head2 ctx_error_code(ctx)

Called by the Perl code's verify_callback() to get the error code
from SSL from the ctx

Receives the pointer to the ctx as an integer that is converted back
to the point address to be used

=cut

int ctx_error_code(ctx)
    IV ctx;

    PREINIT:

    CODE:
        /* printf("ctx_error_code - int holding pointer: %lu\n", (unsigned long) ctx); */
        /* printf("ctx_error_code - Pointer to ctx: %p\n", (void *) INT2PTR(SV * , ctx)); */

        RETVAL = X509_STORE_CTX_get_error((X509_STORE_CTX *) INT2PTR(SV *, ctx));

    OUTPUT:

        RETVAL

=head2 verify(self, x509)

The actual verify function that calls OpenSSL to verify the x509 Cert that
has been passed in as a parameter against the store that was setup in _new()

=head3 Parameters

=over

=item self - self object

Contains details about Crypt::OpenSSL::Verify including  the STORE

=item x509 - Crypt::OpenSSL::X509

Certificate to verify

=back

=cut

int verify(self, x509)
    HV * self;
    Crypt::OpenSSL::X509 x509;

    PREINIT:

        X509_STORE_CTX * csc;

    CODE:
        SV **svp;
        MAGIC* mg;
        X509_STORE * store = NULL;
        //bool strict_certs = 1;
        //struct OPTIONS trust_options;
        //trust_options.trust_expired = 0;
        //trust_options.trust_no_local = 0;
        //trust_options.trust_onelogin = 0r
        //

        if (x509 == NULL)
            croak("no cert to verify");

        csc = X509_STORE_CTX_new();
        if (csc == NULL)
            croak("X.509 store context allocation failed: %s", ssl_error());

        if (!hv_exists(self, "STORE", strlen("STORE")))
            croak("STORE not found in self!\n");

        svp = hv_fetch(self, "STORE", strlen("STORE"), 0);

        if (!SvMAGICAL(*svp) || (mg = mg_findext(*svp, PERL_MAGIC_ext, &store_magic)) == NULL)
            croak("STORE is invalid");

        store = (X509_STORE *) mg->mg_ptr;

        X509_STORE_set_flags(store, 0);

        if (!X509_STORE_CTX_init(csc, store, x509, NULL)) {
            X509_STORE_CTX_free(csc);
            croak("store ctx init: %s", ssl_error());
        }

        RETVAL = X509_verify_cert(csc);

        //if (hv_exists(self, "strict_certs", strlen("strict_certs"))) {
        //    svp = hv_fetch(self, "strict_certs", strlen("strict_certs"), 0);
        //    if (SvIOKp(*svp)) {
        //        strict_certs = SvIV(*svp);
        //    }
        //}
        //if (hv_exists(self, "trust_expired", strlen("trust_expired"))) {
        //    svp = hv_fetch(self, "trust_expired", strlen("trust_expired"), 0);
        //    if (SvIOKp(*svp)) {
        //        trust_options.trust_expired = SvIV(*svp);
        //    }
        //}
        //if (hv_exists(self, "trust_onelogin", strlen("trust_onelogin"))) {
        //    svp = hv_fetch(self, "trust_onelogin", strlen("trust_onelogin"), 0);
        //    if (SvIOKp(*svp)) {
        //        trust_options.trust_onelogin = SvIV(*svp);
        //    }
        //}
        //if (hv_exists(self, "trust_no_local", strlen("trust_no_local"))) {
        //    svp = hv_fetch(self, "trust_no_local", strlen("trust_no_local"), 0);
        //    if (SvIOKp(*svp)) {
        //        trust_options.trust_no_local = SvIV(*svp);
        //    }
        //}
        //
        //This actually does not accomplish what we want as it essentially
        //checks only the last certificate not the chain that might have
        //acceptable errors.  Original code considered errors on this last
        //certificate as real errors.
        //if ( !RETVAL && !strict_certs ) {
        //    int cb = verify_cb(&trust_options, RETVAL, csc);
        //    RETVAL = cb;
        //}

        if (!RETVAL)
            croak("verify: %s", ctx_error(csc));

        X509_STORE_CTX_free(csc);

    OUTPUT:

        RETVAL

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

