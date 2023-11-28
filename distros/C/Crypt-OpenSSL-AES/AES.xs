#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "openssl/opensslv.h"

#include <openssl/aes.h>
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
#include <openssl/evp.h>
#endif

#define NEED_newCONSTSUB
#include "ppport.h"

/*
*  Copyright (C) 2006-2023 DelTel, Inc.
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
#else
    AES_KEY enc_key;
    AES_KEY dec_key;
    int padding;
#endif
} *Crypt__OpenSSL__AES;

int get_option_ivalue (pTHX_ HV * options, char * name) {
    SV **svp;
    IV value;

    if (hv_exists(options, name, strlen(name))) {
        svp = hv_fetch(options, name, strlen(name), 0);
        if (SvIOKp(*svp)) {
            value = SvIV(*svp);
            return PTR2IV(value);
        }
    }
    return 0;
}

char * get_option_svalue (pTHX_ HV * options, char * name) {
    SV **svp;
    SV * value;

    if (hv_exists(options, name, strlen(name))) {
        svp = hv_fetch(options, name, strlen(name), 0);
        value = *svp;
        return SvPV_nolen(value);
    }

    return NULL;
}

#if OPENSSL_VERSION_NUMBER >= 0x00908000L
#ifdef LIBRESSL_VERSION_NUMBER
const EVP_CIPHER * get_cipher(pTHX_ HV * options, STRLEN keysize) {
#else
EVP_CIPHER * get_cipher(pTHX_ HV * options, STRLEN keysize) {
#endif
    char * name = get_option_svalue(aTHX_ options, "cipher");

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

char * get_cipher_name (pTHX_ HV * options, long long keysize) {
    char * value = get_option_svalue(aTHX_ options, "cipher");
    if (value == NULL)
        if (keysize == 16)
            return "AES-128-ECB";
        else if (keysize == 24)
            return "AES-192-ECB";
        else if (keysize == 32)
            return "AES-256-ECB";
        else
            croak ("get_cipher_name - Unsupported Key Size");

    return value;
}

unsigned char * get_iv(pTHX_ HV * options) {
    return (unsigned char * ) get_option_svalue(aTHX_ options, "iv");
}

int get_padding(pTHX_ HV * options) {
    return get_option_ivalue(aTHX_ options, "padding");
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
        STRLEN keysize;
        unsigned char * key;
        SV * self;
        HV * options = newHV();
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
#ifdef LIBRESSL_VERSION_NUMBER
        const EVP_CIPHER * cipher;
#else
        EVP_CIPHER * cipher;
#endif
        unsigned char * iv = NULL;
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

        Newz(0, RETVAL, 1, struct state);
        RETVAL->padding = get_padding(aTHX_ options);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        cipher = get_cipher(aTHX_ options, keysize);
        iv = get_iv(aTHX_ options);
        cipher_name = get_cipher_name(aTHX_ options, keysize);
        if ((strcmp(cipher_name, "AES-128-ECB") == 0 ||
            strcmp(cipher_name, "AES-192-ECB") == 0 ||
            strcmp(cipher_name, "AES-256-ECB") == 0)
            && hv_exists(options, "iv", strlen("iv")))
                croak ("%s does not use IV", cipher_name);

        /* Create and initialise the context */
        if(!(RETVAL->enc_ctx = EVP_CIPHER_CTX_new()))
            croak ("EVP_CIPHER_CTX_new failed for enc_ctx");

        if(!(RETVAL->dec_ctx = EVP_CIPHER_CTX_new()))
            croak ("EVP_CIPHER_CTX_new failed for dec_ctx");

        if(1 != EVP_EncryptInit_ex(RETVAL->enc_ctx, cipher,
                                        NULL, key, iv))
            croak ("EVP_EncryptInit_ex failed");

        if(1 != EVP_DecryptInit_ex(RETVAL->dec_ctx, cipher,
                                        NULL, key, iv))
            croak ("EVP_DecryptInit_ex failed");
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        EVP_CIPHER_free(cipher);
#endif
#else
        AES_set_encrypt_key(key,keysize*8,&RETVAL->enc_key);
        AES_set_decrypt_key(key,keysize*8,&RETVAL->dec_key);
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
        STRLEN size;
        unsigned char * plaintext = (unsigned char *) SvPVbyte(data,size);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        int out_len = 0;
        int ciphertext_len = 0;
        unsigned char * ciphertext;
        int block_size = EVP_CIPHER_CTX_block_size(self->enc_ctx);
        Newc(1, ciphertext, size + block_size, unsigned char, unsigned char);
#else
        int block_size = AES_BLOCK_SIZE;
#endif

        if (size)
        {
            if ((size % block_size != 0) && self->padding != 1)
                croak ("AES: Data size must be multiple of blocksize (%d bytes)", block_size);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
            EVP_CIPHER_CTX_set_padding(self->enc_ctx, self->padding);

            if(1 != EVP_EncryptUpdate(self->enc_ctx, ciphertext , &out_len, plaintext, size))
                croak("EVP_%sUpdate failed", "Encrypt");

            ciphertext_len += out_len;

            if(1 != EVP_EncryptFinal_ex(self->enc_ctx, ciphertext + ciphertext_len, &out_len))
                croak("EVP_%sFinal_ex failed", "Encrypt");

            ciphertext_len += out_len;

            RETVAL = newSV (ciphertext_len);
            SvPOK_only (RETVAL);
            SvCUR_set (RETVAL, ciphertext_len);
            sv_setpvn(RETVAL, (const char * const) ciphertext, ciphertext_len);
            Safefree(ciphertext);
#else
            RETVAL = newSV (size);
            SvPOK_only (RETVAL);
            SvCUR_set (RETVAL, size);
            AES_encrypt(plaintext, (unsigned char *) SvPV_nolen(RETVAL), &self->enc_key);
#endif
        }
        else
        {
            RETVAL = newSVpv ("", 0);
        }
    }
OUTPUT:
    RETVAL

SV *
decrypt(self, data)
    Crypt::OpenSSL::AES self
    SV *data
CODE:
    {
        STRLEN size;
        unsigned char * ciphertext = (unsigned char *) SvPVbyte(data,size);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
        int out_len = 0;
        int plaintext_len = 0;
        unsigned char * plaintext;
        int block_size = EVP_CIPHER_CTX_block_size(self->dec_ctx);
        Newc(1, plaintext, size, unsigned char, unsigned char);
#else
        int block_size = AES_BLOCK_SIZE;
#endif
        if (size)
        {
            if ((size % block_size != 0) && self->padding != 1)
                croak ("AES: Data size must be multiple of blocksize (%d bytes)", block_size);
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
            EVP_CIPHER_CTX_set_padding(self->dec_ctx, self->padding);
            if (1 != EVP_DecryptUpdate(self->dec_ctx, plaintext, &out_len, ciphertext, size))
                croak("EVP_%sUpdate failed", "Decrypt");

            plaintext_len += out_len;

            if(1 != EVP_DecryptFinal_ex(self->dec_ctx, plaintext + out_len, &out_len))
                croak("EVP_%sFinal_ex failed", "Decrypt");

            plaintext_len += out_len;

            RETVAL = newSV (plaintext_len);
            SvPOK_only (RETVAL);
            SvCUR_set (RETVAL, plaintext_len);
            sv_setpvn(RETVAL, (const char * const) plaintext, plaintext_len);
            Safefree(plaintext);
#else
            RETVAL = newSV (size);
            SvPOK_only (RETVAL);
            SvCUR_set (RETVAL, size);
            AES_decrypt(ciphertext, (unsigned char *) SvPV_nolen(RETVAL), &self->dec_key);
#endif
        }
        else
        {
            RETVAL = newSVpv ("", 0);
        }
    }
OUTPUT:
    RETVAL

void
DESTROY(self)
    Crypt::OpenSSL::AES self
CODE:
#if OPENSSL_VERSION_NUMBER >= 0x00908000L
    EVP_CIPHER_CTX_free(self->enc_ctx);
    EVP_CIPHER_CTX_free(self->dec_ctx);
#endif
    Safefree(self);
