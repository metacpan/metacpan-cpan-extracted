#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

static SV * _new (SV * type, CV * cv) {
	dTHX;
	HV * hash = newHV();
	hv_store(hash, "name", 4, type, 0);
	hv_store(hash, "validate", 8, (SV*)cv, 0);
	return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(newSVpv("Basic::Types::XS", 16), 0));
}

int _sv_contains_numbers (SV * param, int dec) {
	dTHX;
	STRLEN retlen;
	char * str = SvPV(param, retlen);
	int i = 0;
	for (i = 0; i < retlen; i++) {
		if (!isdigit(str[i])) {
			if ( !dec && str[i] == '.' ) {
				dec = 1;
			} else {
				return 0;
			}
		}
	}
	return 1;
}

int _sv_isa_bool (SV * param) {
	dTHX;
	int type = SvTYPE(param);
	if (SvROK(param)) {
		param = SvRV(param);
		type = SvTYPE(param);
	}
	
	if (type >= SVt_PVAV) {
		return 0;
	}

	if (!SvOK(param)) {
		return 1;
	}

	if (type == SVt_IV) {
		int i = SvIV(param);
		if (i == 0 || i == 1) {
			return 1;
		}
	} else if (type == SVt_PV) {
		STRLEN retlen;
		char * i = SvPV(param, retlen);
		if (!retlen || i[0] == 0 || i[0] == 1) {
			return 1;
		}
	}

	return 0;
}

char *get_caller(void) {
	dTHX;
	char *callr = HvNAME((HV*)CopSTASH(PL_curcop));
	return callr;
}

static char * get_error_message (SV * self, const char * type) {
	dTHX;
	SV ** sv = hv_fetch((HV*)SvRV(self), "message", 7, 0);
	if (sv) {
		STRLEN retlen;
		char * msg = SvPV(*sv, retlen);
		if (retlen > 0) {
			return msg;
		}
	}
	size_t len = 40 + strlen(type);
	char *buffer = (char *)malloc(len);
	snprintf(buffer, len, "value did not pass type constraint \"%s\"", type);
	return buffer;
}

static SV * set_default (SV * self, SV * param) {
	dTHX;
	if (!SvOK(param) && hv_exists((HV*)SvRV(self), "default", 7)) {
		SV ** def = hv_fetch((HV*)SvRV(self), "default", 7, 0);
		if (SvOK(*def)) {
			dSP;
			PUSHMARK(SP);
			PUTBACK;
			call_sv(*def, G_SCALAR);
			SPAGAIN;
			param = POPs;
			PUTBACK;
		}
	}
	return param;
}

static SV * coerce (SV * self, SV * param) {
	dTHX;
	if (hv_exists((HV*)SvRV(self), "coerce", 6)) {
		SV ** coe = hv_fetch((HV*)SvRV(self), "coerce", 6, 0);
		if (SvOK(*coe)) {
			dSP;
			PUSHMARK(SP);
			XPUSHs(newSVsv(param));
			PUTBACK;
			call_sv(*coe, G_SCALAR);
			SPAGAIN;
			param = POPs;
			PUTBACK;
		}
	}
	return param;
}

MODULE = Basic::Types::XS  PACKAGE = Basic::Types::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

SV *
_Any(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Any type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (items < 1 ) {
			char * custom_error = get_error_message(self, "Any");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Any(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Any
		);
		RETVAL = _new(newSVpv("Any", 3), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Any type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_Defined(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Defined type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvOK(param)) {
			char * custom_error = get_error_message(self, "Defined");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Defined(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Defined
		);
		RETVAL = _new(newSVpv("Defined", 7), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Defined type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_Ref(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Ref type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param)) {
			char * custom_error = get_error_message(self, "Ref");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Ref(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Ref
		);
		RETVAL = _new(newSVpv("Ref", 3), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Ref type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_ScalarRef(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("ScalarRef type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) >= SVt_PVAV)) {
			char * custom_error = get_error_message(self, "ScalarRef");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
ScalarRef(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__ScalarRef
		);
		RETVAL = _new(newSVpv("ScalarRef", 9), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("ScalarRef type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_ArrayRef(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("ArrayRef type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVAV)) {
			char * custom_error = get_error_message(self, "ArrayRef");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
ArrayRef(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__ArrayRef
		);
		RETVAL = _new(newSVpv("ArrayRef", 8), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("ArrayRef type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_HashRef(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("HashRef type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVHV)) {
			char * custom_error = get_error_message(self, "HashRef");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
HashRef(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__HashRef
		);
		RETVAL = _new(newSVpv("HashRef", 7), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("HashRef type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_CodeRef(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("CodeRef type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVCV)) {
			char * custom_error = get_error_message(self, "CodeRef");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
CodeRef(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__CodeRef
		);
		RETVAL = _new(newSVpv("CodeRef", 7), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("CodeRef type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_RegexpRef(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("RegexpRef type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_REGEXP)) {
			char * custom_error = get_error_message(self, "RegexpRef");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
RegexpRef(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__RegexpRef
		);
		RETVAL = _new(newSVpv("RegexpRef", 9), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("RegexpRef type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_GlobRef(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("GlobRef type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVGV)) {
			char * custom_error = get_error_message(self, "GlobRef");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
GlobRef(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__GlobRef
		);
		RETVAL = _new(newSVpv("GlobRef", 7), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("GlobRef type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_Str(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Str type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		int type = SvTYPE(param);
		if (SvROK(param) || !SvOK(param) || (type > SVt_PV)) {
			char * custom_error = get_error_message(self, "Str");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Str(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Str
		);
		RETVAL = _new(newSVpv("Str", 3), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Str type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}		
	OUTPUT:
		RETVAL
		
SV *
_Num(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Num type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		int type = SvTYPE(param);
		if (SvROK(param) || !SvOK(param) || (type != SVt_IV && type != SVt_NV)) {
			if ( type != SVt_PV || ! _sv_contains_numbers(param, 0) ) {
				char * custom_error = get_error_message(self, "Num");
				croak("%s", custom_error);
			}
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Num(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Num
		);
		RETVAL = _new(newSVpv("Num", 3), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Num type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_Int(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Int type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		int type = SvTYPE(param);
		if (SvROK(param) || !SvOK(param) || (type != SVt_IV)) {
			if ( type != SVt_PV || ! _sv_contains_numbers(param, 1) ) {
				char * custom_error = get_error_message(self, "Int");
				croak("%s", custom_error);
			}
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Int(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Int
		);
		RETVAL = _new(newSVpv("Int", 3), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Int type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_Bool(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Bool type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!_sv_isa_bool(param)) {
			char * custom_error = get_error_message(self, "Bool");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Bool(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Bool
		);
		RETVAL = _new(newSVpv("Bool", 4), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Bool type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV * 
_Object(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("Object type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvROK(param) || !SvOK(param) || !SvSTASH(SvRV(param))) {
			char * custom_error = get_error_message(self, "Object");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Object(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__Object
		);
		RETVAL = _new(newSVpv("Object", 6), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("Object type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

SV *
_ClassName(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("ClassName type constraint not initialized");
		}

		SV * param = ST(0);
		param = set_default(self, param);
		param = coerce(self, param);

		if (!SvOK(param) || SvROK(param) || SvTYPE(param) != SVt_PV) {
			// Not a defined, non-reference string
			char * custom_error = get_error_message(self, "ClassName");
			croak("%s", custom_error);
		}
		STRLEN len;
		const char *pkg = SvPV(param, len);
		HV *stash = gv_stashpvn(pkg, len, 0);
		if (!stash) {
			char * custom_error = get_error_message(self, "ClassName");
			croak("%s", custom_error);
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
ClassName(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Types__XS__ClassName
		);
		RETVAL = _new(newSVpv("ClassName", 9), type);
		SvREFCNT_inc(type);
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "validate", 8, (SV*)type, 0);
		if (items % 2 != 0) {
			croak("ClassName type constraint requires an even number of arguments");
		}
		for (int i = 0; i < items; i += 2) {
			SV * key = ST(i);
			SV * value = ST(i + 1);
			if (!SvOK(key) || SvTYPE(key) != SVt_PV) {
				croak("key must be a string");
			}
			if (!SvOK(value)) {
				croak("value must be defined");
			}
			STRLEN keylen;
			char * keystr = SvPV(key, keylen);
			hv_store(self, keystr, keylen, newSVsv(value), 0);
		}
	OUTPUT:
		RETVAL

CV *
validate(...)
	OVERLOAD: &{}
	CODE:
		SV * self = ST(0);
		if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("first argument must be a Basic::Types::XS object");
		}
		SV * cb = *hv_fetch((HV*)SvRV(self), "validate", 8, 0);
		RETVAL = (CV*)cb;
	OUTPUT:
		RETVAL

void
import( ...)
	CODE:
		char *pkg = get_caller();
		STRLEN retlen;
		int i = 1;
		for (i = 1; i < items; i++) {
			char * ex = SvPV(ST(i), retlen);
			char name [strlen(pkg) + 2 + retlen];
			sprintf(name, "%s::%s", pkg, ex);
			if (strcmp(ex, "Any") == 0) {
				newXS(name, XS_Basic__Types__XS_Any, __FILE__);
			} else if (strcmp(ex, "Defined") == 0) {
				newXS(name, XS_Basic__Types__XS_Defined, __FILE__);
			} else if (strcmp(ex, "Str") == 0)  {
				newXS(name, XS_Basic__Types__XS_Str, __FILE__);
			} else if (strcmp(ex, "Num") == 0) {
				newXS(name, XS_Basic__Types__XS_Num, __FILE__);
			} else if (strcmp(ex, "Int") == 0) {
				newXS(name, XS_Basic__Types__XS_Int, __FILE__);
			} else if (strcmp(ex, "Ref") == 0) {
				newXS(name, XS_Basic__Types__XS_Ref, __FILE__);
			} else if (strcmp(ex, "ScalarRef") == 0) {
				newXS(name, XS_Basic__Types__XS_ScalarRef, __FILE__);
			} else if (strcmp(ex, "ArrayRef") == 0) {
				newXS(name, XS_Basic__Types__XS_ArrayRef, __FILE__);
			} else if (strcmp(ex, "HashRef") == 0) {
				newXS(name, XS_Basic__Types__XS_HashRef, __FILE__);
			} else if (strcmp(ex, "CodeRef") == 0) {
				newXS(name, XS_Basic__Types__XS_CodeRef, __FILE__);
			} else if (strcmp(ex, "RegexpRef") == 0) {
				newXS(name, XS_Basic__Types__XS_RegexpRef, __FILE__);
			} else if (strcmp(ex, "GlobRef") == 0) {
				newXS(name, XS_Basic__Types__XS_GlobRef, __FILE__);		
			} else if (strcmp(ex, "Bool") == 0) {
				newXS(name, XS_Basic__Types__XS_Bool, __FILE__);
			} else if (strcmp(ex, "Object") == 0) {
				newXS(name, XS_Basic__Types__XS_Object, __FILE__);
			} else if (strcmp(ex, "ClassName") == 0) {
				newXS(name, XS_Basic__Types__XS_ClassName, __FILE__);
			} else {
				croak("Unknown type constraint: %s", ex);
			}	
		}
