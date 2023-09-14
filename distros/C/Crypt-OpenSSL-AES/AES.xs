#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/aes.h>
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
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
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
	EVP_CIPHER_CTX *enc_ctx;
	EVP_CIPHER_CTX *dec_ctx;
#else
	AES_KEY enc_key;
	AES_KEY dec_key;
#endif
} *Crypt__OpenSSL__AES;

MODULE = Crypt::OpenSSL::AES		PACKAGE = Crypt::OpenSSL::AES		

PROTOTYPES: ENABLE

BOOT:
{
	HV *stash = gv_stashpv("Crypt::OpenSSL::AES", 0);

	newCONSTSUB (stash, "keysize",   newSViv (32));
	newCONSTSUB (stash, "blocksize", newSViv (AES_BLOCK_SIZE));
}

Crypt::OpenSSL::AES
new(class, key)
	SV *  class
	SV *  key
CODE:
	{
		STRLEN keysize;

		if (!SvPOK (key))
			croak("Key must be a scalar");

		keysize = SvCUR(key);

		if (keysize != 16 && keysize != 24 && keysize != 32)
			croak ("The key must be 128, 192 or 256 bits long");

		Newz(0, RETVAL, 1, struct state);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
		/* Create and initialise the context */
		if(!(RETVAL->enc_ctx = EVP_CIPHER_CTX_new()))
			croak ("EVP_CIPHER_CTX_new failed for enc_ctx");

		if(!(RETVAL->dec_ctx = EVP_CIPHER_CTX_new()))
			croak ("EVP_CIPHER_CTX_new failed for dec_ctx");

		if(1 != EVP_EncryptInit_ex(RETVAL->enc_ctx, EVP_aes_256_ecb(),
                                        NULL, SvPVbyte_nolen(key), NULL))
			croak ("EVP_EncryptInit_ex failed");

		if(1 != EVP_DecryptInit_ex(RETVAL->dec_ctx, EVP_aes_256_ecb(),
                                        NULL, SvPVbyte_nolen(key), NULL))
			croak ("EVP_DecryptInit_ex failed");
#else
		AES_set_encrypt_key(SvPV_nolen(key),keysize*8,&RETVAL->enc_key);
		AES_set_decrypt_key(SvPV_nolen(key),keysize*8,&RETVAL->dec_key);
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
		int out_len = 0;
		int ciphertext_len = 0;
		unsigned char * ciphertext;
		unsigned char * plaintext = SvPVbyte(data,size);

		Newc(1, ciphertext, size, unsigned char, unsigned char);

		if (size)
		{
			if (size != AES_BLOCK_SIZE)
				croak ("AES: Datasize not exactly blocksize (%d bytes)", AES_BLOCK_SIZE);

			RETVAL = newSV (size);
			SvPOK_only (RETVAL);
			SvCUR_set (RETVAL, size);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
			EVP_CIPHER_CTX_set_padding(self->enc_ctx, 0);

			if(1 != EVP_EncryptUpdate(self->enc_ctx, ciphertext, &out_len, plaintext, size))
				croak("EVP_%sUpdate failed", "Encrypt");
			ciphertext_len += out_len;

			if(1 != EVP_EncryptFinal_ex(self->enc_ctx, ciphertext + out_len, &out_len))
				croak("EVP_%sFinal_ex failed", "Encrypt");

			sv_setpvn(RETVAL, ciphertext, ciphertext_len);
			Safefree(ciphertext);
#else
			AES_encrypt((unsigned char *) plaintext, SvPV_nolen(RETVAL), &self->enc_key);
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
		int out_len = 0;
		int plaintext_len = 0;
		unsigned char * plaintext;
		unsigned char * ciphertext = SvPVbyte(data,size);

		Newc(1, plaintext, size, unsigned char, unsigned char);

		if (size)
		{
			if (size != AES_BLOCK_SIZE)
				croak ("AES: Datasize not exactly blocksize (%d bytes)", AES_BLOCK_SIZE);

			RETVAL = newSV (size);
			SvPOK_only (RETVAL);
			SvCUR_set (RETVAL, size);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
			EVP_CIPHER_CTX_set_padding(self->dec_ctx, 0);
			if (1 != EVP_DecryptUpdate(self->dec_ctx, plaintext, &out_len, ciphertext, size))
				croak("EVP_%sUpdate failed", "Decrypt");
			plaintext_len = out_len;

			if(1 != EVP_DecryptFinal_ex(self->dec_ctx, plaintext + out_len, &out_len))
				croak("EVP_%sFinal_ex failed", "Decrypt");

			sv_setpvn(RETVAL, plaintext, plaintext_len);
			Safefree(plaintext);
#else
			AES_decrypt((unsigned char *) ciphertext, SvPV_nolen(RETVAL), &self->dec_key);
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
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
	Safefree(self->enc_ctx);
	Safefree(self->dec_ctx);
#endif
	Safefree(self);
