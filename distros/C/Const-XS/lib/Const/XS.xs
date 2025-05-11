#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

void _make_readonly (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			AV * arr = (AV*)SvRV(val);
			if (!SvREADONLY((SV*)arr)) {
				_make_readonly((SV*)arr);
				int i = 0;
				int len = av_len(arr);
				for (i = 0; i <= len; i++) {
					SV * value = *av_fetch(arr, i, 0);
					_make_readonly(value);
				}
			}
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			if (!SvREADONLY((SV*)hash)) {
				_make_readonly((SV*)hash);
				HE * entry;
				(void)hv_iterinit(hash);
				while ((entry = hv_iternext(hash)))  {
					STRLEN retlen;
					char * key =  SvPV(hv_iterkeysv(entry), retlen);
					SV * value = *hv_fetch(hash, key, retlen, 0);	
					_make_readonly(value);
				}
			}
		}
	}

	SvREADONLY_on(val);
}

void _make_readwrite (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			AV * arr = (AV*)SvRV(val);
			if (SvREADONLY(arr)) {
				int i = 0;
				int len = av_len(arr);
				_make_readwrite((SV*)arr);
				for (i = 0; i <= len; i++) {
					SV * value = *av_fetch(arr, i, 0);
					_make_readwrite(value);
				}
			}
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			if (SvREADONLY(hash)) {
				HE * entry;
				(void)hv_iterinit(hash);
				_make_readwrite((SV*)hash);
				while ((entry = hv_iternext(hash)))  {
					STRLEN retlen;
					char * key =  SvPV(hv_iterkeysv(entry), retlen);
					SV * value = *hv_fetch(hash, key, retlen, 0);	
					_make_readwrite(value);
				}
			}
		}
	}

	SvREADONLY_off(val);
}

int _is_readonly (SV * val) {
	dTHX;

	if (SvOK(val) && SvTYPE(val) == SVt_RV && SvROK(val)) {
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
			AV * arr = (AV*)SvRV(val);
			if (! _is_readonly((SV*)arr) ) {
				return 0;
			}
		} else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
			HV * hash = (HV*)SvRV(val);
			if (! _is_readonly((SV*)hash) ) {
				return 0;
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
				STRLEN retlen;
				char * key = SvPV(ST(i), retlen);
				SV * value = newSVsv(ST(i + 1));
				hv_store(ret, key, retlen, value, 0);
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

