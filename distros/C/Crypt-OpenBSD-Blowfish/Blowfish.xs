#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "src/blowfish.c"
#include "ppport.h"

typedef blf_ctx *Crypt__OpenBSD__Blowfish;

MODULE = Crypt::OpenBSD::Blowfish		PACKAGE = Crypt::OpenBSD::Blowfish		

PROTOTYPES: ENABLE

Crypt::OpenBSD::Blowfish
init()
CODE:
	{
		Newxz(RETVAL, 1, blf_ctx);
		Blowfish_initstate(RETVAL);
	}
OUTPUT:
	RETVAL

Crypt::OpenBSD::Blowfish
init_key(sv_key)
	SV *sv_key
CODE:
	{
		Newxz(RETVAL, 1, blf_ctx);
		STRLEN keylen; unsigned char *key = (unsigned char *) SvPVbyte(sv_key,keylen);
		blf_key(RETVAL,key,keylen);
	}
OUTPUT:
	RETVAL

void
DESTROY(self)
        Crypt::OpenBSD::Blowfish self
CODE:
        Safefree(self);

void
expandstate(self,sv_data,sv_key)
	Crypt::OpenBSD::Blowfish self
	SV *sv_data
	SV *sv_key
CODE:
	{
		STRLEN datalen; unsigned char *data = (unsigned char *) SvPVbyte(sv_data,datalen);
		STRLEN keylen; unsigned char *key = (unsigned char *) SvPVbyte(sv_key,keylen);
		Blowfish_expandstate(self, data, datalen, key, keylen);
	}

void
expand0state(self,sv_key)
	Crypt::OpenBSD::Blowfish self
	SV *sv_key
CODE:
	{
		STRLEN keylen;
		unsigned char *key = (unsigned char *) SvPVbyte(sv_key,keylen);
		Blowfish_expand0state(self,key,keylen);
	}

SV *
encrypt_iterate(self,sv_data,sv_rounds)
	Crypt::OpenBSD::Blowfish self
	SV *sv_data
	SV *sv_rounds
CODE:
	{
		STRLEN datalen;
		unsigned char *data = (unsigned char *) SvPVbyte(sv_mortalcopy(sv_data),datalen);
		if (datalen % 8)
			croak("data must be in 8-byte chunks");
		
		uint16_t words = datalen / 4;
		uint32_t cdata[words];
		uint16_t j = 0;
		int i;
		int rounds = SvIVx(sv_rounds);

		for (i=0; i<words; i++)
			cdata[i] = Blowfish_stream2word(data, datalen, &j);
		for (i=0; i<rounds; i++)
			blf_enc(self, cdata, sizeof(cdata) / sizeof(uint64_t));

		for (i=0; i<words; i++) {
			data[4 * i + 3] = (cdata[i] >> 24) & 0xff;
			data[4 * i + 2] = (cdata[i] >> 16) & 0xff;
			data[4 * i + 1] = (cdata[i] >>  8) & 0xff;
			data[4 * i ] = cdata[i] & 0xff;
		}
		RETVAL = newSVpvn ((char *) data, datalen);
	}
OUTPUT:
	RETVAL

SV *
encrypt(self,sv_data)
	Crypt::OpenBSD::Blowfish self
	SV *sv_data
CODE:
	{
		STRLEN datalen;
		unsigned char *data = (unsigned char *) SvPVbyte(sv_mortalcopy(sv_data),datalen);
		if (datalen % 8)
			croak("data must be in 8-byte chunks");

		blf_ecb_encrypt(self,data,datalen);
		
		RETVAL = newSVpvn ((char *) data, datalen);
	}
OUTPUT:
	RETVAL

SV *
decrypt(self,sv_data)
	Crypt::OpenBSD::Blowfish self
	SV *sv_data
CODE:
	{
		STRLEN datalen;
		unsigned char *data = (unsigned char *) SvPVbyte(sv_mortalcopy(sv_data),datalen);
		if (datalen % 8)
			croak("data must be in 8-byte chunks");
		
		blf_ecb_decrypt(self,data,datalen);

		RETVAL = newSVpvn ((char *) data, datalen);
	}
OUTPUT:
	RETVAL
