#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

void _make_readonly (SV * val) {
	dTHX;

	if (SvOK(val) && SvROK(val)) {
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

	if (SvOK(val) && SvROK(val)) {
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

	if (SvOK(val) && SvROK(val)) {
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

void export (XSUBADDR_t cb, char * pkg, int pkg_len, char * method, int method_len) {
	dTHX;
	int name_len = pkg_len + method_len + 3;
	char *name = (char *)malloc(name_len);
	snprintf(name, name_len, "%s::%s", pkg, method);
	newXS(name, cb, __FILE__);
	free(name);
}

void export_proto (XSUBADDR_t cb, char * pkg, int pkg_len, char * method, int method_len, char * proto) {
	dTHX;
	int name_len = pkg_len + method_len + 3;
	char *name = (char *)malloc(name_len);
	snprintf(name, name_len, "%s::%s", pkg, method);
	newXSproto(name, cb, __FILE__, proto);
	free(name);
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


void
import(...)
    CODE:
		char *pkg = HvNAME((HV*)CopSTASH(PL_curcop));
		int pkg_len = strlen(pkg);
		STRLEN retlen;
		int i = 1;
		for (i = 1; i < items; i++) {
			char * ex = SvPV(ST(i), retlen);
			if (strcmp(ex, "all") == 0) {
				export_proto(XS_Const__XS_const, pkg, pkg_len, "const", 5, "\\[$@%]@");
				export_proto(XS_Const__XS_make_readonly, pkg, pkg_len, "make_readonly", 13, "\\[$@%]@");
				export(XS_Const__XS_make_readonly_ref, pkg, pkg_len, "make_readonly_ref", 17);
				export_proto(XS_Const__XS_unmake_readonly, pkg, pkg_len, "unmake_readonly", 15, "\\[$@%]@");
				export_proto(XS_Const__XS_is_readonly, pkg, pkg_len, "is_readonly", 11, "\\[$@%]@");
			} else if (strcmp(ex, "const") == 0) {
				export_proto(XS_Const__XS_const, pkg, pkg_len, "const", 5, "\\[$@%]@");
			} else if (strcmp(ex, "make_readonly") == 0) {
				export_proto(XS_Const__XS_make_readonly, pkg, pkg_len, "make_readonly", 13, "\\[$@%]@");
			} else if (strcmp(ex, "make_readonly_ref") == 0) {
				export(XS_Const__XS_make_readonly_ref, pkg, pkg_len, "make_readonly_ref", 17);
			} else if (strcmp(ex, "unmake_readonly") == 0) {
				export_proto(XS_Const__XS_unmake_readonly, pkg, pkg_len, "unmake_readonly", 15, "\\[$@%]@");
			} else if (strcmp(ex, "is_readonly") == 0) {
				export_proto(XS_Const__XS_is_readonly, pkg, pkg_len, "is_readonly", 11, "\\[$@%]@");
			} else {
				croak("Unknown import: %s", ex);
			}
		}

