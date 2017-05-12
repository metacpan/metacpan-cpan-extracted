#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "xxcrypt.h"

MODULE = Crypt::XXTEA::CImpl		PACKAGE = Crypt::XXTEA::CImpl		

SV *
xxtea_encrypt(str,key)
	SV*  str
	SV*  key
PROTOTYPE: $$
INIT:
	void *strp,*keyp,*resp;
	int strl, keyl,resl;
	STRLEN strlo, keylo;
CODE:
    strp = (void *)SvPV(str, strlo);
    strl = (int)strlo;
    keyp = (void *)SvPV(key, keylo);
    keyl = (int)keylo;

	resl = c_xxtea_encrypt((char*)strp,strl,(char*)keyp,keyl,(char**)&resp);
	if(resl){
		RETVAL = newSVpv(resp,resl);
	}else{
		RETVAL = newSVpv("",0);
	}
	free(resp);
OUTPUT:
	RETVAL

SV *
xxtea_decrypt(str,key)
	SV*  str
	SV*  key
PROTOTYPE: $$
INIT:
	void *strp,*keyp,*resp;
	int strl, keyl,resl;
	STRLEN strlo, keylo;
CODE:
    strp = (void *)SvPV(str, strlo);
    strl = (int)strlo;
    keyp = (void *)SvPV(key, keylo);
    keyl = (int)keylo;

	resl = c_xxtea_decrypt((char*)strp,strl,(char*)keyp,keyl,(char**)&resp);
	if(resl){
		RETVAL = newSVpv(resp,resl);
	}else{
		RETVAL = newSVpv("",0);
	}
	free(resp);
OUTPUT:
	RETVAL

SV *
long2str(ary,w)
	SV*  ary
	int  w
PROTOTYPE: $$
INIT:
	char* strp;
	int strl;
	int vl;
	int *v;
	int i;
CODE:
	if(!SvROK(ary) || (SvTYPE(SvRV(ary)) != SVt_PVAV)){
		XSRETURN_UNDEF;
	}
	vl = av_len((AV *)SvRV(ary))+1;
	v =(int*)malloc(vl*4);
	for(i = vl - 1; i>=0; i--){
		v[i] = SvIV(*av_fetch((AV *)SvRV(ary), i, 0));
	}
	strl = c_long2str(v,vl,w,&strp);
	RETVAL = newSVpv(strp,strl);
	free(v);
	free(strp);
OUTPUT:
	RETVAL

SV *
str2long(str,w)
	SV*  str
	int  w
PROTOTYPE: $$
INIT:
	char* strp;
	int strl;
	int vl;
	int *v;
	int i;
	STRLEN strlo;
	AV* result;
CODE:
    strp = (void *)SvPV(str, strlo);
    strl = (int)strlo;
	vl = c_str2long(strp,strl,w,&v);
	result = (AV *)sv_2mortal((SV *)newAV());
	av_extend(result, vl);
	for(i = 0; i < vl; i++){
		av_push(result, newSViv(v[i]));
	}
	free(v);
	RETVAL = newRV((SV *)result);
OUTPUT:
	RETVAL
