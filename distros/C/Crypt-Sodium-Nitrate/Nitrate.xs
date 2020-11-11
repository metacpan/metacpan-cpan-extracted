#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* libsodium */
#include "sodium.h"

SV*
THX_sodium_encrypt(pTHX_ SV* msg, SV* nonce, SV* key)
#define sodium_encrypt(a,b,c) THX_sodium_encrypt(aTHX_ a,b,c)
{
    SV* encrypted_sv;
    STRLEN msg_len, nonce_len, key_len, enc_len;
    unsigned char *msg_buf, *nonce_buf, *key_buf;
    nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
    if ( nonce_len != crypto_secretbox_NONCEBYTES ) {
        croak("Invalid nonce");
    }

    key_buf = (unsigned char *)SvPV(key, key_len);
    if ( key_len != crypto_secretbox_KEYBYTES ) {
        croak("Invalid key");
    }

    msg_buf = (unsigned char *)SvPV(msg, msg_len);

    enc_len = crypto_secretbox_MACBYTES + msg_len;

    encrypted_sv = newSV(enc_len);
    SvUPGRADE(encrypted_sv, SVt_PV);
    SvPOK_on(encrypted_sv);
    SvCUR_set(encrypted_sv, enc_len);

    crypto_secretbox_easy(
        (unsigned char *)SvPVX(encrypted_sv),
        msg_buf,
        msg_len,
        nonce_buf,
        key_buf
    );

    return encrypted_sv;
}

SV*
THX_sodium_decrypt(pTHX_ SV* ciphertext, SV* nonce, SV* key)
#define sodium_decrypt(a,b,c)   THX_sodium_decrypt(aTHX_ a,b,c)
{
    SV* decrypted_sv;
    STRLEN dec_len, nonce_len, key_len, msg_len;
    int decrypt_result = 0;
    unsigned char *nonce_buf, *key_buf, *msg_buf;

    nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
    if ( nonce_len != crypto_secretbox_NONCEBYTES ) {
        croak("Invalid nonce: %"SVf, nonce);
    }

    key_buf = (unsigned char *)SvPV(key, key_len);
    if ( key_len != crypto_secretbox_KEYBYTES ) {
        croak("Invalid key");
    }

    msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);
    if ( msg_len < crypto_secretbox_MACBYTES ) {
        croak("Invalid ciphertext");
    }
    dec_len = msg_len - crypto_secretbox_MACBYTES;

    decrypted_sv = newSV(dec_len);
    SvUPGRADE(decrypted_sv, SVt_PV);
    SvPOK_on(decrypted_sv);

     decrypt_result = crypto_secretbox_open_easy(
        (unsigned char *)SvPVX(decrypted_sv),
        msg_buf,
        msg_len,
        nonce_buf,
        key_buf
    );

    if ( decrypt_result != 0 ) {
        sv_free(decrypted_sv);
        croak("Message forged");
    }

    SvCUR_set(decrypted_sv, dec_len);
    return decrypted_sv;
}

MODULE = Crypt::Sodium::Nitrate        PACKAGE = Crypt::Sodium::Nitrate

PROTOTYPES: DISABLE

void
encrypt(SV* msg, SV* nonce, SV* key)
INIT:
    SV* encrypted_sv;
PPCODE:
{
    encrypted_sv = sodium_encrypt(msg, nonce, key);
    mXPUSHs( encrypted_sv );
    XSRETURN(1);
}

void
decrypt(SV* ciphertext, SV* nonce, SV* key)
INIT:
    SV* decrypted_sv;
PPCODE:
{
    decrypted_sv = sodium_decrypt(ciphertext, nonce, key);
    mXPUSHs( decrypted_sv );
    XSRETURN(1);
}

BOOT:
{
    /* let's create a couple of constants for perl to use */
    HV *stash = gv_stashpvs("Crypt::Sodium::Nitrate", GV_ADD);

    newCONSTSUB(stash, "NONCEBYTES", newSViv(crypto_secretbox_NONCEBYTES));
    newCONSTSUB(stash, "KEYBYTES",   newSViv(crypto_secretbox_KEYBYTES));
    newCONSTSUB(stash, "MACBYTES",   newSViv(crypto_secretbox_MACBYTES));
}

