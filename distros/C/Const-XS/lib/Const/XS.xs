#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

void make_readonly (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			int i = 0;
			AV * arr = (AV*)SvRV(val);
			int len = av_len(arr);
			for (i = 0; i <= len; i++) {
				SV * value = newSVsv(*av_fetch(arr, i, 0));
				make_readonly(value);
				av_store(arr, i, value);
			}
			make_readonly((SV*)arr);
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			HE * entry;
			(void)hv_iterinit(hash);
			while ((entry = hv_iternext(hash)))  {
				char * key =  SvPV_nolen(hv_iterkeysv(entry));
				SV * value = newSVsv(*hv_fetch(hash, key, strlen(key), 0));	
				make_readonly(value);
				hv_store(hash, key, strlen(key), value, 0);
			}
			make_readonly((SV*)hash);
		}
	}

	SvREADONLY_on(val);
}

MODULE = Const::XS  PACKAGE = Const::XS
PROTOTYPES: ENABLE

void
const(...)
	PROTOTYPE: \[$@%]@
	CODE:
		int i = 1;

		if (items < 2) {
			croak("No value for readonly variable");
		}

		if (SvTYPE(SvRV(ST(0))) == SVt_PVAV) {
			AV * ret = (AV*)SvRV(ST(0));
			for (i = 1; i < items; i++) {
				SV * val = newSVsv(ST(i));
				av_push(ret, val);
			}
			make_readonly(ST(0));
		} else if ( SvTYPE(SvRV(ST(0))) == SVt_PVHV) {
			HV * ret = (HV*)SvRV(ST(0));
			for (i = 1; i < items; i += 2) {
				char * key = SvPV_nolen(ST(i));
				SV * value = newSVsv(ST(i + 1));
				hv_store(ret, key, strlen(key), value, 0);
			}
			make_readonly(ST(0));
		} else {
			SV * ret = SvRV(ST(0));
			sv_setsv( ret, newSVsv(ST(1)) );
			make_readonly(ret);
		}
		XSRETURN(1);
