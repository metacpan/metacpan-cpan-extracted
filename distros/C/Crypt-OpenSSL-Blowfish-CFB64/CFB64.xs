#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <openssl/blowfish.h>

typedef struct {
	char    ivec[8];
	BF_KEY *key;
	//char    key_len;
} blowfish;

MODULE = Crypt::OpenSSL::Blowfish::CFB64		PACKAGE = Crypt::OpenSSL::Blowfish::CFB64		

SV *
new(SV *pk, SV *key_sv, ...)
CODE:
	char *stashname = SvPV_nolen(pk);
	char *key; STRLEN key_len;
	char *ivec; STRLEN ivec_len;
	blowfish * bf;
	
	key  = SvPV(key_sv, key_len);
	
	if (items > 2) {
		ivec = SvPV(ST(2), ivec_len);
		if ( ivec_len != 8 ) {
			croak("Invalid ivec length: %d. Must be 8", ivec_len);
		}
	}
	else {
		ivec = "\0\0\0\0\0\0\0\0";
	}
	
	bf = safemalloc(sizeof(blowfish));
	bf->key = safemalloc(sizeof(BF_KEY));
	BF_set_key(bf->key, key_len, key);
	bf->ivec[0] = ivec[0]; bf->ivec[1] = ivec[1]; bf->ivec[2] = ivec[2]; bf->ivec[3] = ivec[3]; bf->ivec[4] = ivec[4]; bf->ivec[5] = ivec[5]; bf->ivec[6] = ivec[6]; bf->ivec[7] = ivec[7]; 
	
	HV *stash = gv_stashpv(stashname, TRUE);
	ST(0) = sv_2mortal (sv_bless (newRV_noinc (newSViv (PTR2IV( bf ))), stash));
	XSRETURN(1);

void
DESTROY(SV *self)
CODE:
	blowfish *bf = (blowfish *) SvUV( SvRV( self ) );
	//warn("Destroy %p (%s)..", bf, bf->key);
	safefree(bf->key);
	safefree(bf);

SV *encrypt(SV *self, SV *data_sv)
CODE:
	blowfish *bf = (blowfish *) SvUV( SvRV( self ) );
	char *data; size_t data_len;
	BF_KEY bf_key;
	int num = 0;
	unsigned char ivec[8];
	ivec[0] = bf->ivec[0];ivec[1] = bf->ivec[1];ivec[2] = bf->ivec[2];ivec[3] = bf->ivec[3];ivec[4] = bf->ivec[4];ivec[5] = bf->ivec[5];ivec[6] = bf->ivec[6];ivec[7] = bf->ivec[7];
	data = SvPV(data_sv,data_len);
	
	ST(0) = sv_2mortal( newSVpvn("",0) );
	unsigned char *out = (unsigned char *) SvGROW( ST(0), data_len + 1 );
	
	//warn("Encoding data='%s' (len=%d) with bf=%p (key=%s) ivec=[%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x]\n",data, data_len, bf, bf->key, ivec[0],ivec[1],ivec[2],ivec[3],ivec[4],ivec[5],ivec[6],ivec[7]);
	BF_cfb64_encrypt( data, out, data_len, bf->key, ivec, &num, BF_ENCRYPT );
	SvCUR_set( ST(0), data_len );
	XSRETURN(1);

SV *decrypt(SV *self, SV *data_sv)
CODE:
	blowfish *bf = (blowfish *) SvUV( SvRV( self ) );
	char *data; size_t data_len;
	BF_KEY bf_key;
	int num = 0;
	unsigned char ivec[8];
	ivec[0] = bf->ivec[0];ivec[1] = bf->ivec[1];ivec[2] = bf->ivec[2];ivec[3] = bf->ivec[3];ivec[4] = bf->ivec[4];ivec[5] = bf->ivec[5];ivec[6] = bf->ivec[6];ivec[7] = bf->ivec[7];
	data = SvPV(data_sv,data_len);
	
	ST(0) = sv_2mortal( newSVpvn("",0) );
	unsigned char *out = (unsigned char *) SvGROW( ST(0), data_len + 1 );
	
	//warn("Encoding data='%s' (len=%d) with bf=%p (key=%s) ivec=[%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x]\n",data, data_len, bf, bf->key, ivec[0],ivec[1],ivec[2],ivec[3],ivec[4],ivec[5],ivec[6],ivec[7]);
	BF_cfb64_encrypt( data, out, data_len, bf->key, ivec, &num, BF_DECRYPT );
	SvCUR_set( ST(0), data_len );
	XSRETURN(1);
