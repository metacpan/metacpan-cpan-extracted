#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "aes.h"
#include "aes.c"


void make_aes_key(char *key, char *secret, size_t secret_size)
{
	uint8_t i, m, n;
	// make a 32 bytes key from secret.
	if(secret_size >= 32) {
		memcpy(key, secret, 32);
	}
	else {
		m = 32 % secret_size;
		n = (32 - m) / secret_size;
		for(i = 0; i < n; i++) {
			memcpy(key + secret_size * i, secret, secret_size);
		}
		memcpy(key + secret_size * i, secret, m);
	}
}

MODULE = AES128		PACKAGE = AES128		

TYPEMAP: <<END
const char *    T_PV
const uint8_t *    T_PV
uint8_t * T_PV
END

SV *
AES128_CTR_encrypt(SV *sv_plain_text, SV *sv_secret)
	CODE:
		STRLEN text_size, secret_size;
		uint8_t i;
		struct AES_ctx ctx;
		char *plain_text, *secret, *output;

		plain_text = (char *)SvPVbyte(sv_plain_text, text_size);
		secret     = (char *)SvPVbyte(sv_secret, secret_size);
		char key[32];
		make_aes_key(key, secret, secret_size);

		uint8_t padding_len = 16 - text_size % 16;

		output = (char *)malloc(text_size + padding_len);
		memcpy(output, plain_text, text_size);
		for(i = 0; i < padding_len; i++) 
			output[text_size + i] = padding_len;

		AES_init_ctx_iv(&ctx, key, key + 16);
		AES_CTR_xcrypt_buffer(&ctx, output, text_size + padding_len);
		RETVAL = newSVpv(output, text_size + padding_len);
		free(output);
	OUTPUT:
		RETVAL

SV *
AES128_CTR_decrypt(SV *sv_cipher_text, SV *sv_secret)
	CODE:
		STRLEN text_size, secret_size;
		char *cipher_text, *secret;
		struct AES_ctx ctx;
		char key[32];

		cipher_text = (char *)SvPVbyte(sv_cipher_text, text_size);
		secret = (char *)SvPVbyte(sv_secret, secret_size);
		if(text_size % 16 != 0)
			croak("Corrupted cipher text!");

		make_aes_key(key, secret, secret_size);

		AES_init_ctx_iv(&ctx, key, key + 16);
		AES_CTR_xcrypt_buffer(&ctx, cipher_text, text_size);
		uint8_t padding_len = cipher_text[text_size -1];
		RETVAL = newSVpv(cipher_text, text_size - padding_len);
	OUTPUT:
		RETVAL
