#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <oqs/oqs.h>

MODULE = Crypt::Liboqs::Sign  PACKAGE = Crypt::Liboqs::Sign

void
_oqs_keypair(alg_name)
    const char* alg_name
    PPCODE:
        OQS_SIG *sig = OQS_SIG_new(alg_name);
        if (sig == NULL) {
            croak("Unsupported or disabled algorithm: %s", alg_name);
        }
        unsigned char *pk = NULL;
        unsigned char *sk = NULL;
        Newx(pk, sig->length_public_key, unsigned char);
        Newx(sk, sig->length_secret_key, unsigned char);
        OQS_STATUS rc = OQS_SIG_keypair(sig, pk, sk);
        if (rc != OQS_SUCCESS) {
            Safefree(pk);
            Safefree(sk);
            OQS_SIG_free(sig);
            croak("Key pair generation failed for %s", alg_name);
        }
        SV *pk_sv = newSVpvn((const char*)pk, sig->length_public_key);
        SV *sk_sv = newSVpvn((const char*)sk, sig->length_secret_key);
        Safefree(pk);
        Safefree(sk);
        OQS_SIG_free(sig);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
_oqs_sign(alg_name, message, sk)
    const char* alg_name
    SV* message
    SV* sk
    PPCODE:
        OQS_SIG *sig = OQS_SIG_new(alg_name);
        if (sig == NULL) {
            croak("Unsupported or disabled algorithm: %s", alg_name);
        }
        STRLEN msg_len, sk_len;
        const unsigned char *msg = (const unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char *sk_bytes = (const unsigned char*)SvPVbyte(sk, sk_len);
        if (sk_len != sig->length_secret_key) {
            size_t expected = sig->length_secret_key;
            OQS_SIG_free(sig);
            croak("Invalid secret key size for %s (got %lu, expected %lu)",
                  alg_name, (unsigned long)sk_len, (unsigned long)expected);
        }
        unsigned char *signature = NULL;
        Newx(signature, sig->length_signature, unsigned char);
        size_t actual_sig_len = 0;
        OQS_STATUS rc = OQS_SIG_sign(sig, signature, &actual_sig_len, msg, msg_len, sk_bytes);
        if (rc != OQS_SUCCESS) {
            Safefree(signature);
            OQS_SIG_free(sig);
            croak("Signing failed for %s", alg_name);
        }
        SV *sig_sv = newSVpvn((const char*)signature, actual_sig_len);
        Safefree(signature);
        OQS_SIG_free(sig);
        XPUSHs(sv_2mortal(sig_sv));
        XSRETURN(1);

int
_oqs_verify(alg_name, signature, message, pk)
    const char* alg_name
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        OQS_SIG *sig = OQS_SIG_new(alg_name);
        if (sig == NULL) {
            croak("Unsupported or disabled algorithm: %s", alg_name);
        }
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char *sig_bytes = (const unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char *msg = (const unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char *pk_bytes = (const unsigned char*)SvPVbyte(pk, pk_len);
        if (pk_len != sig->length_public_key) {
            size_t expected = sig->length_public_key;
            OQS_SIG_free(sig);
            croak("Invalid public key size for %s (got %lu, expected %lu)",
                  alg_name, (unsigned long)pk_len, (unsigned long)expected);
        }
        if (sig_len > sig->length_signature) {
            size_t max_len = sig->length_signature;
            OQS_SIG_free(sig);
            croak("Invalid signature size for %s (got %lu, max %lu)",
                  alg_name, (unsigned long)sig_len, (unsigned long)max_len);
        }
        OQS_STATUS rc = OQS_SIG_verify(sig, msg, msg_len, sig_bytes, sig_len, pk_bytes);
        OQS_SIG_free(sig);
        XSRETURN_IV(rc == OQS_SUCCESS ? 1 : 0);

void
_oqs_alg_list()
    PPCODE:
        int count = OQS_SIG_alg_count();
        int i;
        for (i = 0; i < count; i++) {
            const char *name = OQS_SIG_alg_identifier(i);
            if (OQS_SIG_alg_is_enabled(name)) {
                XPUSHs(sv_2mortal(newSVpv(name, 0)));
            }
        }

int
_oqs_alg_is_enabled(alg_name)
    const char* alg_name
    CODE:
        RETVAL = OQS_SIG_alg_is_enabled(alg_name);
    OUTPUT:
        RETVAL
