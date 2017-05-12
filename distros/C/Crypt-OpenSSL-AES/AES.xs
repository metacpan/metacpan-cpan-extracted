#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/aes.h>

#include "ppport.h"

/*
*  Copyright (C) 2006-2007 DelTel, Inc.
*  
*  This library is free software; you can redistribute it and/or modify
*  it under the same terms as Perl itself, either Perl version 5.8.5 or,
*  at your option, any later version of Perl 5 you may have available.
*/

typedef struct state {
	AES_KEY enc_key;
	AES_KEY dec_key;
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
		AES_set_encrypt_key(SvPV_nolen(key),keysize*8,&RETVAL->enc_key);
		AES_set_decrypt_key(SvPV_nolen(key),keysize*8,&RETVAL->dec_key);
	}
OUTPUT:
	RETVAL

SV *
encrypt(self, data)
	Crypt::OpenSSL::AES self
	SV *data
ALIAS:
	decrypt = 1
CODE:
	{
		STRLEN size;
		void *bytes = SvPV(data,size);

		if (size)
		{
			if (size != AES_BLOCK_SIZE)
				croak ("AES: Datasize not exactly blocksize (%d bytes)", AES_BLOCK_SIZE);

			RETVAL = NEWSV (0, size);
			SvPOK_only (RETVAL);
			SvCUR_set (RETVAL, size); 
			(ix ? AES_decrypt : AES_encrypt) ((unsigned char *) bytes, SvPV_nolen(RETVAL), (ix ? &self->dec_key : &self->enc_key));
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
	Safefree(self);
