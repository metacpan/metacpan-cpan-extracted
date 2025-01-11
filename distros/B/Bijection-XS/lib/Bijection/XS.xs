#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <math.h>

AV * ALPHA;
HV * INDEX;
int OFFSET;
int COUNT;

void reverse(char *s) {
	size_t len = strlen(s);
	char *a = s;
	char *b = &s[(int)len - 1];
	char tmp;
	for (; a < b; ++a, --b) {
		tmp = *a;
		*a = *b;
		*b = tmp;
	}
}


static char * _biject (int id, char * out) {
	dTHX;
	id = id + OFFSET;
	while (id > 0) {
		sprintf(out, "%s%s", out, SvPV_nolen(*av_fetch(ALPHA, id % COUNT, 0))); 
		id = floor(id / COUNT);
	}
	reverse(out);
	return out;
}

static int _inverse (char * id) {
	dTHX;
	int out = 0;
	for (int i = 0; i < strlen(id); i++) {
		out = out * COUNT + SvIV(*hv_fetch(INDEX, &id[i], 1, 0));
	}
	return out - OFFSET;
}


MODULE = Bijection::XS  PACKAGE = Bijection::XS
PROTOTYPES: ENABLE

SV *
bijection_set(...)
	CODE:
		ALPHA = av_make(items, MARK+1);
		
		SV * first = *av_fetch(ALPHA, 0, 0);
	
		if (SvTYPE(first) == SVt_IV &&  SvIV(first) > 0) {
			OFFSET = SvIV(av_shift(ALPHA));
		} else {
			OFFSET = av_count(ALPHA);
		}

		COUNT = av_count(ALPHA);
		INDEX = newHV();
		for (int i = 0; i < COUNT; i++) {
			char * key = SvPV_nolen(*av_fetch(ALPHA, i, 0));
			hv_store(INDEX, key, strlen(key), newSViv(i), 0); 
		}

		RETVAL = newSViv(COUNT);
	OUTPUT:
		RETVAL

void
offset_set(offset)
	SV * offset
	CODE:
		OFFSET = SvIV(offset);


SV *
biject(id)
	SV * id
	CODE:
		if (SvIV(id) < 0) {
        		croak("id to encode must be an integer and non-negative");
		}

		char str[100] = "";
		_biject(SvIV(id), str);
		RETVAL = newSVpv(str, strlen(str));
	OUTPUT:
		RETVAL

SV *
inverse(str)
	SV * str
	CODE:
		RETVAL = newSViv(_inverse(SvPV_nolen(str)));
	OUTPUT:
		RETVAL

