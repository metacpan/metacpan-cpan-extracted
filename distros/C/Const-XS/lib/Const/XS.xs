#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

void _make_readonly (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			int i = 0;
			AV * arr = (AV*)SvRV(val);
			int len = av_len(arr);
			SvREADONLY_off((SV*)arr);
			for (i = 0; i <= len; i++) {
				SV * value = newSVsv(*av_fetch(arr, i, 0));
				_make_readonly(value);
				av_store(arr, i, value);
			}
			_make_readonly((SV*)arr);
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			HE * entry;
			(void)hv_iterinit(hash);
			SvREADONLY_off((SV*)hash);
			while ((entry = hv_iternext(hash)))  {
				char * key =  SvPV_nolen(hv_iterkeysv(entry));
				SV * value = newSVsv(*hv_fetch(hash, key, strlen(key), 0));	
				_make_readonly(value);
				hv_store(hash, key, strlen(key), value, 0);
			}
			_make_readonly((SV*)hash);
		}
	}

	SvREADONLY_on(val);
}

void _make_readwrite (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			int i = 0;
			AV * arr = (AV*)SvRV(val);
			int len = av_len(arr);
			_make_readwrite((SV*)arr);
			for (i = 0; i <= len; i++) {
				SV * value = newSVsv(*av_fetch(arr, i, 0));
				_make_readwrite(value);
				av_store(arr, i, value);
			}
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			HE * entry;
			(void)hv_iterinit(hash);
			_make_readwrite((SV*)hash);
			while ((entry = hv_iternext(hash)))  {
				char * key =  SvPV_nolen(hv_iterkeysv(entry));
				SV * value = newSVsv(*hv_fetch(hash, key, strlen(key), 0));	
				_make_readwrite(value);
				hv_store(hash, key, strlen(key), value, 0);
			}
		}
	}

	SvREADONLY_off(val);
}

int _is_readonly (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			int i = 0;
			AV * arr = (AV*)SvRV(val);
			int len = av_len(arr);
			if (! _is_readonly((SV*)arr) ) {
				return 0;
			}
			for (i = 0; i <= len; i++) {
				SV * value = *av_fetch(arr, i, 0);
				if (! _is_readonly(value) ) {
					return 0;
				}
			}
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			HE * entry;
			if (! _is_readonly((SV*)hash) ) {
				return 0;
			}
			(void)hv_iterinit(hash);
			while ((entry = hv_iternext(hash)))  {
				char * key =  SvPV_nolen(hv_iterkeysv(entry));
				SV * value = *hv_fetch(hash, key, strlen(key), 0);	
				if (! _is_readonly(value) ) {
					return 0;
				}
			}
		}
	}

	return SvREADONLY(val) ? 1 : 0; 
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
			_make_readonly(ST(0));
		} else if ( SvTYPE(SvRV(ST(0))) == SVt_PVHV) {
			if ((items - 1) % 2 != 0) {
				croak("Odd number of elements in hash assignment");
			}
			HV * ret = (HV*)SvRV(ST(0));
			for (i = 1; i < items; i += 2) {
				char * key = SvPV_nolen(ST(i));
				SV * value = newSVsv(ST(i + 1));
				hv_store(ret, key, strlen(key), value, 0);
			}
			_make_readonly(ST(0));
		} else {
			SV * ret = SvRV(ST(0));
			sv_setsv( ret, newSVsv(ST(1)) );
			_make_readonly(ret);
		}
		XSRETURN(1);

SV *
make_readonly_ref(...);
	CODE:
		_make_readonly(ST(0));
		XSRETURN(1);

SV *
make_readonly(...)
	PROTOTYPE: \[$@%]@
	CODE:
		int type = SvTYPE(SvRV(ST(0)));
		if (type == SVt_PVAV || type == SVt_PVHV) {
			_make_readonly(ST(0));
		} else {
			_make_readonly(SvRV(ST(0)));
		}
		XSRETURN(1);

SV * 
unmake_readonly(...)
	PROTOTYPE: \[$@%]@
	CODE:
		int type = SvTYPE(SvRV(ST(0)));
		if (type == SVt_PVAV || type == SVt_PVHV) {
			_make_readwrite(ST(0));
		} else {
			_make_readwrite(SvRV(ST(0)));
		}
		XSRETURN(1);

SV *
is_readonly(...)
	PROTOTYPE: \[$@%]@
	CODE:
		ST(0) = newSViv(_is_readonly(SvRV(ST(0))));
		XSRETURN(1);

