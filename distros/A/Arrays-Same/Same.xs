#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int arrays_same_i (SV* x, SV* y) {
	AV* arrx = (AV*)SvRV(x);
	AV* arry = (AV*)SvRV(y);	
	if (arrx == arry) {
		return 2;
	}
	int len = av_len(arrx);
	if (len != av_len(arry)) {
		return 0;
	}
	int i;
	for (i=0; i<=len; i++) {
		SV** elemx = av_fetch(arrx, i, 0);
		SV** elemy = av_fetch(arry, i, 0);
		int ix = SvIV(*elemx);
		int iy = SvIV(*elemy);
		if (ix != iy) {
			return 0;
		}
	}
		return 1;
}

int arrays_same_s (SV* x, SV* y) {
	AV* arrx = (AV*)SvRV(x);
	AV* arry = (AV*)SvRV(y);
	if (arrx == arry) {
		return 2;
	}
	int len = av_len(arrx);
	if (len != av_len(arry)) {
		return 0;
	}
	int i;
	for (i=0; i<=len; i++) {
		SV** elemx = av_fetch(arrx, i, 0);
		SV** elemy = av_fetch(arry, i, 0);
		STRLEN dummy;
		char* strx = SvPV(*elemx, dummy);
		char* stry = SvPV(*elemy, dummy);
		if (strcmp(strx, stry) != 0) {
			return 0;
		}
	}
	return 1;
}

MODULE = Arrays::Same		PACKAGE = Arrays::Same

PROTOTYPES: DISABLE

int
arrays_same_i (x, y)
	SV *	x
	SV *	y

int
arrays_same_s (x, y)
	SV *	x
	SV *	y
