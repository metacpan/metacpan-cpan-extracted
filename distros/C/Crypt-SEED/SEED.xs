#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "SEED_KISA.h"
#include <string.h> 


MODULE = Crypt::SEED		PACKAGE = Crypt::SEED		

SV *
_roundKey(userKey)
	char* userKey;
	PREINIT:
		DWORD rkey[32];
		int i;
	CODE:
		SeedRoundKey(rkey, userKey); /*Call KISA function */
		RETVAL = newSVpvn((const char*)rkey,32*sizeof(DWORD));
	OUTPUT:
		RETVAL

SV *
_rkeyToString(rkeyStr)
	char* rkeyStr;
	PREINIT:
		DWORD* rkey;
		char output[256];
		char* p;
		int i;
	CODE:
		rkey = (DWORD*)rkeyStr;
		p = output;
		
		for (i=0;i<32;i++) {
			sprintf(p, "%08X", rkey[i]);
			p += 8;
		}
		RETVAL = newSVpvn((const char*)output, 256);
	OUTPUT:
		RETVAL


SV *
_encrypt(data,rkeyStr)
	SV* data;
	char* rkeyStr;
	PREINIT:
		DWORD* rkey;
		char buf[16];
		char* pdata;
		int len = 0;
	CODE:
		pdata = (char*)SvPV(data, len);
		if(len==16) {
			rkey = (DWORD*)rkeyStr;
			memcpy(buf, pdata, 16);
	
			SeedEncrypt(buf, rkey); /*Call KISA function */
			RETVAL = newSVpvn((const char*)buf, 16);
		}
		else
			XSRETURN_UNDEF;
	OUTPUT:
		RETVAL


SV *
_decrypt(cipher,rkeyStr)
	SV* cipher;
	char* rkeyStr;
	PREINIT:
		DWORD* rkey;
		char buf[16];
		char* pcipher;
		int len = 0;
	CODE:
		pcipher = (char*)SvPV(cipher, len);
		if(len==16) {
			rkey = (DWORD*)rkeyStr;
			memcpy(buf, pcipher, 16);

			SeedDecrypt(buf, rkey); /*Call KISA function */
			RETVAL = newSVpvn((const char*)buf, 16);
		}
		else
			XSRETURN_UNDEF;
	OUTPUT:
		RETVAL


