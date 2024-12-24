#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pqclean/crypto_sign/falcon-512/clean/api.h"
#include "pqclean/crypto_sign/falcon-1024/clean/api.h"
#include "pqclean/crypto_sign/ml-dsa-44/clean/api.h"
#include "pqclean/crypto_sign/ml-dsa-65/clean/api.h"
#include "pqclean/crypto_sign/ml-dsa-87/clean/api.h"
#include "pqclean/crypto_sign/sphincs-shake-128f-simple/clean/api.h"
#include "pqclean/crypto_sign/sphincs-shake-128s-simple/clean/api.h"
#include "pqclean/crypto_sign/sphincs-shake-192f-simple/clean/api.h"
#include "pqclean/crypto_sign/sphincs-shake-192s-simple/clean/api.h"
#include "pqclean/crypto_sign/sphincs-shake-256f-simple/clean/api.h"
#include "pqclean/crypto_sign/sphincs-shake-256s-simple/clean/api.h"

MODULE = Crypt::PQClean::Sign  PACKAGE = Crypt::PQClean::Sign

void
falcon512_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_FALCON512_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_FALCON512_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_FALCON512_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
falcon512_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_FALCON512_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_FALCON512_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
falcon512_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_FALCON512_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
falcon1024_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_FALCON1024_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_FALCON1024_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_FALCON1024_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_FALCON1024_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_FALCON1024_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
falcon1024_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_FALCON1024_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_FALCON1024_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_FALCON1024_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
falcon1024_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_FALCON1024_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_FALCON1024_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_FALCON1024_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
mldsa44_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_MLDSA44_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_MLDSA44_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_MLDSA44_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_MLDSA44_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_MLDSA44_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
mldsa44_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_MLDSA44_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_MLDSA44_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_MLDSA44_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
mldsa44_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_MLDSA44_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_MLDSA44_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_MLDSA44_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
mldsa65_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_MLDSA65_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_MLDSA65_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_MLDSA65_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_MLDSA65_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_MLDSA65_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
mldsa65_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_MLDSA65_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_MLDSA65_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_MLDSA65_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
mldsa65_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_MLDSA65_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_MLDSA65_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_MLDSA65_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
mldsa87_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_MLDSA87_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_MLDSA87_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_MLDSA87_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_MLDSA87_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_MLDSA87_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
mldsa87_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_MLDSA87_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_MLDSA87_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_MLDSA87_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
mldsa87_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_MLDSA87_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_MLDSA87_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_MLDSA87_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
sphincs_shake128f_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
sphincs_shake128f_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
sphincs_shake128f_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_SPHINCSSHAKE128FSIMPLE_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
sphincs_shake128s_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
sphincs_shake128s_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
sphincs_shake128s_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_SPHINCSSHAKE128SSIMPLE_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
sphincs_shake192f_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
sphincs_shake192f_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
sphincs_shake192f_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_SPHINCSSHAKE192FSIMPLE_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
sphincs_shake192s_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
sphincs_shake192s_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
sphincs_shake192s_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_SPHINCSSHAKE192SSIMPLE_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
sphincs_shake256f_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
sphincs_shake256f_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
sphincs_shake256f_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_SPHINCSSHAKE256FSIMPLE_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);

void
sphincs_shake256s_keypair()
    PPCODE:
        unsigned char pk[PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES];
        unsigned char sk[PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES];
        int ret = PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_crypto_sign_keypair(pk, sk);
        if (ret != 0) {
            croak("Key pair generation failed");
        }
        SV* pk_sv = newSVpvn((const char*)pk, PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn((const char*)sk, PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES);
        XPUSHs(sv_2mortal(pk_sv));
        XPUSHs(sv_2mortal(sk_sv));
        XSRETURN(2);

void
sphincs_shake256s_sign(message, sk)
    SV* message
    SV* sk
    PPCODE:
        STRLEN msg_len, sk_len;
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* sk_bytes = (unsigned char*)SvPVbyte(sk, sk_len);

        if (sk_len != PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_SECRETKEYBYTES) {
            croak("Invalid secret key size");
        }

        unsigned char sig[PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_BYTES];
        size_t sig_len = sizeof(sig);
        int ret = PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_crypto_sign_signature(
            sig, &sig_len, msg, msg_len, sk_bytes
        );
        if (ret != 0) {
            croak("Signing failed");
        }
        XPUSHs(sv_2mortal(newSVpvn((const char*)sig, sig_len)));
        XSRETURN(1);

int
sphincs_shake256s_verify(signature, message, pk)
    SV* signature
    SV* message
    SV* pk
    PPCODE:
        STRLEN sig_len, msg_len, pk_len;
        const unsigned char* sig = (unsigned char*)SvPVbyte(signature, sig_len);
        const unsigned char* msg = (unsigned char*)SvPVbyte(message, msg_len);
        const unsigned char* pk_bytes = (unsigned char*)SvPVbyte(pk, pk_len);

        if (pk_len != PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_PUBLICKEYBYTES) {
            croak("Invalid public key size");
        }

        if (sig_len > PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_CRYPTO_BYTES) {
            croak("Invalid signature size");
        }

        int ret = PQCLEAN_SPHINCSSHAKE256SSIMPLE_CLEAN_crypto_sign_verify(
            sig, sig_len, msg, msg_len, pk_bytes
        );

        XSRETURN_IV(ret == 0 ? 1 : 0);
