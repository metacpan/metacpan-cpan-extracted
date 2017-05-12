#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <lzmalib.h>
#include <stdlib.h>


MODULE = Compress::LZMA::Simple		PACKAGE = Compress::LZMA::Simple
PROTOTYPES: DISABLE


void
pl_lzma_compress(sv)
	SV *	sv
PREINIT:
	STRLEN isiz;
	const char *ibuf;
	char *obuf;
	int osiz;
PPCODE:
	sv = (SV *)SvRV(sv);
	ibuf = SvPV(sv, isiz);
	obuf = lzma_compress(ibuf, (int)isiz, &osiz);
	if(obuf){
	  XPUSHs(newRV_noinc(newSVpvn(obuf, osiz)));
	  lzma_free(obuf);
	} else {
	  XPUSHs((SV *)&PL_sv_undef);
	}
	XSRETURN(1);


void
pl_lzma_decompress(sv)
	SV *	sv
PREINIT:
	STRLEN isiz;
	const char *ibuf;
	char *obuf;
	int osiz;
PPCODE:
	sv = (SV *)SvRV(sv);
	ibuf = SvPV(sv, isiz);
	obuf = lzma_decompress(ibuf, (int)isiz, &osiz);
	if(obuf){
	  XPUSHs(newRV_noinc(newSVpvn(obuf, osiz)));
	  lzma_free(obuf);
	} else {
	  XPUSHs((SV *)&PL_sv_undef);
	}
	XSRETURN(1);
