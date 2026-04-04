#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "openssl/opensslv.h"

#include <openssl/aes.h>
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
#include <openssl/evp.h>
#endif

#if OPENSSL_VERSION_NUMBER >= 0x10100000L
#include <openssl/rand.h>
#endif

#include "ppport.h"

/*
*  Copyright (C) 2006-2024 DelTel, Inc.
*
*  This library is free software; you can redistribute it and/or modify
*  it under the same terms as Perl itself, either Perl version 5.8.5 or,
*  at your option, any later version of Perl 5 you may have available.
*/

typedef struct state {
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
    EVP_CIPHER_CTX *enc_ctx;
    EVP_CIPHER_CTX *dec_ctx;
    int padding;
#ifdef USE_ITHREADS
    tTHX tid;
#endif
#else
    AES_KEY enc_key;
    AES_KEY dec_key;
    int padding;
#endif
} *Crypt__OpenSSL__AES;

#define THROW(p_result) if (!(p_result)) { error = 1; goto err; }

char * get_option_svalue (pTHX_ HV * options, char * name) {
    SV **svp;
    SV * value;

    if (!options) return NULL;
    if (hv_exists(options, name, strlen(name))) {
        svp = hv_fetch(options, name, strlen(name), 0);
        value = *svp;
        return SvPV_nolen(value);
    }

    return NULL;
}

#if OPENSSL_VERSION_NUMBER >= 0x30000000L

EVP_CIPHER * get_cipher(pTHX_ HV * options, STRLEN keysize) {
    char *name = get_option_svalue(aTHX_ options, "cipher");
    char *props = get_option_svalue(aTHX_ options, "provider_props"); /* e.g. "fips=yes" */
    char cipher_name[32];

    if (name == NULL) {
        if      (keysize == 16) snprintf(cipher_name, sizeof(cipher_name), "AES-128-ECB");
        else if (keysize == 24) snprintf(cipher_name, sizeof(cipher_name), "AES-192-ECB");
        else if (keysize == 32) snprintf(cipher_name, sizeof(cipher_name), "AES-256-ECB");
        else croak("Unsupported keysize");
        name = cipher_name;
    }

    /* Validate keysize matches the cipher name prefix */
    int cipher_bits = 0;
    if (sscanf(name, "AES-%d-", &cipher_bits) == 1) {
        if ((int)keysize * 8 != cipher_bits)
            croak("You specified an unsupported cipher for this keysize");
    } else {
        croak("You specified an unsupported cipher");
    }

    EVP_CIPHER *cipher = EVP_CIPHER_fetch(NULL, name, props);
    if (!cipher)
        croak("You specified an unsupported cipher: %s", name);

    return cipher;  /* caller must EVP_CIPHER_free() */
}

#else
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
#ifdef LIBRESSL_VERSION_NUMBER
const EVP_CIPHER * get_cipher(pTHX_ HV * options, STRLEN keysize) {
#else
EVP_CIPHER * get_cipher(pTHX_ HV * options, STRLEN keysize) {
#endif
    char * name = get_option_svalue(aTHX_ options, "cipher");
    char * props = get_option_svalue(aTHX_ options, "provider_props"); /* e.g. "fips=yes" */

    if (props != NULL) {
        croak ("provider_props fips=yes only supported on OpenSSL 3.0+");
    }

    if (keysize == 16) {
        if (name == NULL)
            return (EVP_CIPHER * ) EVP_aes_128_ecb();
        else if (strcmp(name, "AES-128-ECB") == 0)
            return (EVP_CIPHER * ) EVP_aes_128_ecb();
        else if (strcmp(name, "AES-128-CBC") == 0)
            return (EVP_CIPHER * ) EVP_aes_128_cbc();
        else if (strcmp(name, "AES-128-CFB") == 0)
            return (EVP_CIPHER * ) EVP_aes_128_cfb();
        else if (strcmp(name, "AES-128-CTR") == 0)
#if OPENSSL_VERSION_NUMBER >=  0x10001000L
            return (EVP_CIPHER * ) EVP_aes_128_ctr();
#else
            croak ("CTR ciphers not supported on this version of OpenSSL");
#endif
        else if (strcmp(name, "AES-128-OFB") == 0)
            return (EVP_CIPHER * ) EVP_aes_128_ofb();
        else
            croak ("You specified an unsupported cipher for this keysize: 16");
    } else if (keysize == 24) {
        if (name == NULL)
            return (EVP_CIPHER * ) EVP_aes_192_ecb();
        else if (strcmp(name, "AES-192-ECB") == 0)
            return (EVP_CIPHER * ) EVP_aes_192_ecb();
        else if (strcmp(name, "AES-192-CBC") == 0)
            return (EVP_CIPHER * ) EVP_aes_192_cbc();
        else if (strcmp(name, "AES-192-CFB") == 0)
            return (EVP_CIPHER * ) EVP_aes_192_cfb();
        else if (strcmp(name, "AES-192-CTR") == 0)
#if OPENSSL_VERSION_NUMBER >=  0x10001000L
            return (EVP_CIPHER * ) EVP_aes_192_ctr();
#else
            croak ("CTR ciphers not supported on this version of OpenSSL");
#endif
        else if (strcmp(name, "AES-192-OFB") == 0)
            return (EVP_CIPHER * ) EVP_aes_192_ofb();
        else
            croak ("You specified an unsupported cipher for this keysize: 24");
    } else if (keysize == 32) {
        if (name == NULL)
            return (EVP_CIPHER * ) EVP_aes_256_ecb();
        else if (strcmp(name, "AES-256-ECB") == 0)
            return (EVP_CIPHER * ) EVP_aes_256_ecb();
        else if (strcmp(name, "AES-256-CBC") == 0)
            return (EVP_CIPHER * ) EVP_aes_256_cbc();
        else if (strcmp(name, "AES-256-CFB") == 0)
            return (EVP_CIPHER * ) EVP_aes_256_cfb();
        else if (strcmp(name, "AES-256-CTR") == 0)
#if OPENSSL_VERSION_NUMBER >=  0x10001000L
            return (EVP_CIPHER * ) EVP_aes_256_ctr();
#else
        croak ("CTR ciphers not supported on this version of OpenSSL");
#endif
        else if (strcmp(name, "AES-256-OFB") == 0)
            return (EVP_CIPHER * ) EVP_aes_256_ofb();
        else
            croak ("You specified an unsupported cipher for this keysize: 32");
    }
    else
        croak ("You specified an unsupported keysize (16, 24 or 32 bytes only)");
}
#endif
#endif

char * get_cipher_name (pTHX_ HV * options, STRLEN keysize) {
    char * value = get_option_svalue(aTHX_ options, "cipher");
    if (value == NULL) {
        if (keysize == 16)
            return "AES-128-ECB";
        else if (keysize == 24)
            return "AES-192-ECB";
        else if (keysize == 32)
            return "AES-256-ECB";
        else
            croak ("get_cipher_name - Unsupported Key Size");
    }

    return value;
}

unsigned char * get_iv(pTHX_ HV * options, STRLEN *len) {
    SV **svp;
    if (options && hv_exists(options, "iv", 2 /* strlen("iv") */)) {
        svp = hv_fetch(options, "iv", 2 /* strlen("iv") */, 0);
        return (unsigned char *) SvPV(*svp, *len);
    }
    *len = 0;
    return NULL;
}

int get_padding(pTHX_ HV * options) {
    SV **svp;

    if (!options) return 0;

    if (hv_exists(options, "padding", 7 /* strlen("padding") */)) {
        svp = hv_fetch(options, "padding", 7 /* strlen("padding") */, 0);
        if (SvTRUE(*svp))
            return 1;
        else
            return 0;
    }
    return 0;
}

/* Taken from p5-Git-Raw */
STATIC HV *ensure_hv(pTHX_ SV *sv, const char *identifier) {
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Invalid type for '%s', expected a hash", identifier);

    return (HV *) SvRV(sv);
}

MODULE = Crypt::OpenSSL::AES        PACKAGE = Crypt::OpenSSL::AES

PROTOTYPES: ENABLE

BOOT:
{
    HV *stash = gv_stashpv("Crypt::OpenSSL::AES", 0);

    newCONSTSUB (stash, "keysize",   newSViv (32));
    newCONSTSUB (stash, "blocksize", newSViv (AES_BLOCK_SIZE));
}

Crypt::OpenSSL::AES
new(class, key_sv, ...)
    SV *  class
    SV *  key_sv
CODE:
    {
        PERL_UNUSED_ARG(class);
        STRLEN keysize;
        unsigned char * key;
        HV * options = NULL;
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
#ifdef LIBRESSL_VERSION_NUMBER
        const EVP_CIPHER * cipher;
#else
        EVP_CIPHER * cipher;
#endif
        unsigned char * iv = NULL;
        STRLEN iv_len = 0;
        char * cipher_name = NULL;
#endif
        if (items > 2)
            options = ensure_hv(aTHX_ ST(2), "options");

        if (!SvPOK (key_sv))
            croak("Key must be a scalar");

        key = (unsigned char *) SvPVbyte_nolen(key_sv);
        keysize = SvCUR(key_sv);

        if (keysize != 16 && keysize != 24 && keysize != 32)
            croak ("The key must be 128, 192 or 256 bits long");

        Newxz(RETVAL, 1, struct state);
        RETVAL->padding = get_padding(aTHX_ options);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        cipher_name = get_cipher_name(aTHX_ options, keysize);
        if ((strcmp(cipher_name, "AES-128-ECB") == 0 ||
            strcmp(cipher_name, "AES-192-ECB") == 0 ||
            strcmp(cipher_name, "AES-256-ECB") == 0)
            && (options && hv_exists(options, "iv", strlen("iv")))) {
                Safefree(RETVAL);
                croak ("%s does not use IV", cipher_name);
        }

        cipher = get_cipher(aTHX_ options, keysize);
        iv = get_iv(aTHX_ options, &iv_len);

        int cipher_iv_len = EVP_CIPHER_iv_length(cipher);
        if (cipher_iv_len > 0) {
            if (!iv) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
                EVP_CIPHER_free(cipher);
#endif
                Safefree(RETVAL);
                croak("Cipher %s requires an IV of %d bytes, but none was provided", cipher_name, cipher_iv_len);
            }
            if (iv_len != (STRLEN)cipher_iv_len) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
                EVP_CIPHER_free(cipher);
#endif
                Safefree(RETVAL);
                croak("Invalid IV length for %s: expected %d bytes, got %d",
                        cipher_name, cipher_iv_len, (int)iv_len);
            }
        }

        /* Create and initialise the context */
        if(!(RETVAL->enc_ctx = EVP_CIPHER_CTX_new())) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
            EVP_CIPHER_free(cipher);
#endif
            Safefree(RETVAL);
            croak ("EVP_CIPHER_CTX_new failed for enc_ctx");
        }

        if(!(RETVAL->dec_ctx = EVP_CIPHER_CTX_new())) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
            EVP_CIPHER_free(cipher);
#endif
            EVP_CIPHER_CTX_free(RETVAL->enc_ctx);
            Safefree(RETVAL);
            croak ("EVP_CIPHER_CTX_new failed for dec_ctx");
        }

        if(1 != EVP_EncryptInit_ex(RETVAL->enc_ctx, cipher,
                                        NULL, key, iv)) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
            EVP_CIPHER_free(cipher);
#endif
            EVP_CIPHER_CTX_free(RETVAL->enc_ctx);
            EVP_CIPHER_CTX_free(RETVAL->dec_ctx);
            Safefree(RETVAL);
            croak ("EVP_EncryptInit_ex failed");
        }

        if(1 != EVP_DecryptInit_ex(RETVAL->dec_ctx, cipher,
                                        NULL, key, iv)) {
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
            EVP_CIPHER_free(cipher);
#endif
            EVP_CIPHER_CTX_free(RETVAL->enc_ctx);
            EVP_CIPHER_CTX_free(RETVAL->dec_ctx);
            Safefree(RETVAL);
            croak ("EVP_DecryptInit_ex failed");
        }
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        EVP_CIPHER_free(cipher);
#endif
#else
        AES_set_encrypt_key(key,keysize*8,&RETVAL->enc_key);
        AES_set_decrypt_key(key,keysize*8,&RETVAL->dec_key);
#endif
#if defined(USE_ITHREADS) && (OPENSSL_VERSION_NUMBER >= 0x00908000L)
    /* Store the creating thread's ID so DESTROY can warn on misuse */
    RETVAL->tid = aTHX;
#endif
    }
OUTPUT:
    RETVAL

SV *
encrypt(self, data)
    Crypt::OpenSSL::AES self
    SV *data
CODE:
    {
        int error;
        STRLEN size;
        unsigned char * plaintext = (unsigned char *) SvPVbyte(data,size);
        const char * ciphertext;
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        int out_len = 0;
        int ciphertext_len = 0;
        int block_size = EVP_CIPHER_CTX_block_size(self->enc_ctx);
#else
        int block_size = AES_BLOCK_SIZE;
#endif
#if defined(USE_ITHREADS) && (OPENSSL_VERSION_NUMBER >= 0x00908000L)
        if (self->tid != aTHX)
            croak("Crypt::OpenSSL::AES: encrypt() called from a different "
                  "thread than the object was created in -- "
                  "EVP_CIPHER_CTX is not thread-safe");
#endif
        error = 0;
        if((size % block_size != 0) && self->padding != 1) {
            croak("AES: Data size must be multiple of blocksize (%d bytes)", block_size);
        }
        Newxc(ciphertext, size + block_size, unsigned char, const char);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        if (1 != EVP_EncryptInit_ex(self->enc_ctx, NULL, NULL, NULL, NULL)) {
            Safefree(ciphertext);
            croak("EVP_EncryptInit_ex re-init failed");
        }

        EVP_CIPHER_CTX_set_padding(self->enc_ctx, self->padding);

        THROW(EVP_EncryptUpdate(self->enc_ctx, (unsigned char *) ciphertext , &out_len, plaintext, size));

        ciphertext_len += out_len;

        THROW(EVP_EncryptFinal_ex(self->enc_ctx, (unsigned char *) ciphertext + ciphertext_len, &out_len));

        ciphertext_len += out_len;

        RETVAL = newSVpvn(ciphertext, ciphertext_len);
#else
        AES_encrypt(plaintext, ciphertext, &self->enc_key);
        RETVAL = newSVpvn((const unsigned char *) ciphertext, size);
#endif
        /* Cleanup both branches and error case */ 
        err:
            if (ciphertext != NULL) Safefree(ciphertext);
            if(error)
                croak("Unable to Encrypt");
    }
OUTPUT:
    RETVAL

SV *
decrypt(self, data)
    Crypt::OpenSSL::AES self
    SV *data
CODE:
    {
#if defined(USE_ITHREADS) && (OPENSSL_VERSION_NUMBER >= 0x00908000L)
        if (self->tid != aTHX)
            croak("Crypt::OpenSSL::AES: decrypt() called from a different "
                  "thread than the object was created in -- "
                  "EVP_CIPHER_CTX is not thread-safe");
#endif
        int error;
        STRLEN size;
        unsigned char * ciphertext = (unsigned char *) SvPVbyte(data,size);
        const char * plaintext;
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        int out_len = 0;
        int plaintext_len = 0;
        int block_size = EVP_CIPHER_CTX_block_size(self->dec_ctx);
#else
        int block_size = AES_BLOCK_SIZE;
#endif
        error = 0;
        if ((size % block_size != 0) && self->padding != 1) {
            croak("AES: Data size must be multiple of blocksize (%d bytes)", block_size);
        }
        Newxc(plaintext, size + block_size, const unsigned char, const char);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        if (1 != EVP_DecryptInit_ex(self->dec_ctx, NULL, NULL, NULL, NULL)) {
            Safefree(plaintext);
            croak("EVP_DecryptInit_ex re-init failed");
        }

        EVP_CIPHER_CTX_set_padding(self->dec_ctx, self->padding);

        THROW(EVP_DecryptUpdate(self->dec_ctx, (unsigned char *) plaintext, &out_len, ciphertext, size));

        plaintext_len += out_len;

        THROW(EVP_DecryptFinal_ex(self->dec_ctx, (unsigned char *) plaintext + plaintext_len, &out_len));

        plaintext_len += out_len;

        RETVAL = newSVpvn(plaintext, plaintext_len);
#else
        AES_decrypt(ciphertext, plaintext, &self->dec_key);
        RETVAL = newSVpvn((const unsigned char *) plaintext, size);
#endif
        /* Cleanup both branches and error case */ 
        err:
            if(plaintext != NULL) Safefree(plaintext);
            if(error)
                croak("Unable to Decrypt");
    }
OUTPUT:
    RETVAL

int
fips_mode()
CODE:
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    RETVAL = EVP_default_properties_is_fips_enabled(NULL);
#elif OPENSSL_VERSION_NUMBER >= 0x00908000L
    RETVAL = FIPS_mode();
#else
    RETVAL = 0;
#endif
OUTPUT:
    RETVAL

void
post_fork_init()
CODE:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
    RAND_poll();          /* re-seed PRNG from OS entropy */
#endif

void
DESTROY(self)
    Crypt::OpenSSL::AES self
CODE:
#if defined(USE_ITHREADS) && (OPENSSL_VERSION_NUMBER >= 0x00908000L)
    if (self->tid != aTHX)
        warn("Crypt::OpenSSL::AES: object destroyed in a different thread "
             "than it was created in -- EVP_CIPHER_CTX is not thread-safe");
#endif
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
    EVP_CIPHER_CTX_free(self->enc_ctx);
    EVP_CIPHER_CTX_free(self->dec_ctx);
#endif
    Safefree(self);
