#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <math.h>

char * ALPHA[256];
int INDEX[256];
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

static char * _biject (int id) {
	dTHX;
	id = id + OFFSET;
	char * outs = (char*) calloc(100, sizeof(char*));;
	while (id > 0) {
		strncat(outs, ALPHA[id % COUNT], 1);
		id = floor(id / COUNT);
	}
	reverse(outs);
	return outs;
}

static int _inverse (char * id) {
	dTHX;
	int out = 0, i = 0;
	for (i = 0; i < strlen(id); i++) {
		out = out * COUNT + INDEX[(int)id[i]];
	}
	return out - OFFSET;
}


MODULE = Bijection::XS  PACKAGE = Bijection::XS
PROTOTYPES: ENABLE

void
import(...)
	PROTOTYPE: DISABLE
	CODE:
		HV * tags = get_hv("Bijection::XS::EXPORT_TAGS", 0);
		AV * args = (AV *)sv_2mortal((SV *)newAV());
		SSize_t i, top;
		for (i = 0; i < items; i++) {
			SV * arg = ST(i);
			STRLEN len;
			const char * name;
			if (i > 0 && tags && SvOK(arg) && !SvROK(arg)) {
				name = SvPV_const(arg, len);
				if (len && isIDFIRST(name[0]) && hv_exists(tags, name, len)) {
					arg = newSVpvs_flags(":", SVs_TEMP);
					sv_catpvn(arg, name, len);
				}
			}
			av_push(args, SvREFCNT_inc_simple_NN(arg));
		}
		top = av_len(args);
		SP = MARK;
		PUSHMARK(SP);
		EXTEND(SP, top + 1);
		for (i = 0; i <= top; i++)
			PUSHs(*av_fetch(args, i, 0));
		PUTBACK;
		call_pv("Ex::Op::import", G_VOID | G_DISCARD);
		XSRETURN_EMPTY;

SV *
bijection_set(...)
	CODE:
		AV * args = av_make(items, MARK+1);
		SV * first = *av_fetch(args, 0, 0);
		int i = 0;
		
		if (SvTYPE(first) == SVt_IV &&  SvIV(first) > 0) {
			OFFSET = SvIV(first);
			av_shift(args);
		} else {
			OFFSET = av_len(args) + 1;
		}

		COUNT = av_len(args) + 1;
		for (i = 0; i < COUNT; i++) {
			STRLEN retlen;
			char * key = SvPV(*av_fetch(args, i, 0), retlen);
			ALPHA[i] = key;
			INDEX[(int)key[0]] = i;
		}

		RETVAL = newSViv(OFFSET);
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
		char * str = _biject(SvIV(id));
		RETVAL = newSVpv(str, strlen(str));
	OUTPUT:
		RETVAL

SV *
inverse(str)
	SV * str
	CODE:
		STRLEN retlen;
		RETVAL = newSViv(_inverse(SvPV(str, retlen)));
	OUTPUT:
		RETVAL

