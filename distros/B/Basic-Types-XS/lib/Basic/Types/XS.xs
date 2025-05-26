#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

static SV * _new (SV * type) {
	dTHX;
	return sv_bless(newRV_noinc(type), gv_stashsv(newSVpv("Basic::Types::XS", 16), 0));
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

MODULE = Basic::Types::XS  PACKAGE = Basic::Types::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

SV *
Any()
	CODE:
		RETVAL = _new(newSVpv("Any", 3));
	OUTPUT:
		RETVAL

SV *
_Any(...)
	CODE:
		if (! items) {
			croak("value did not pass type constraint \"Any\"");
		}
		SvREFCNT_inc(ST(0));
		RETVAL = ST(0);
	OUTPUT:
		RETVAL

SV *
Defined()
	CODE:
		RETVAL = _new(newSVpv("Defined", 7));
	OUTPUT:
		RETVAL

SV *
_Defined(param)
	SV * param
	CODE:
		if (!SvOK(param)) {
			croak("value did not pass type constraint \"Defined\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Ref()
	CODE:
		RETVAL = _new(newSVpv("Ref", 3));
	OUTPUT:
		RETVAL

SV *
_Ref(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param)) {
			croak("value did not pass type constraint \"Ref\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
ScalarRef()
	CODE:
		RETVAL = _new(newSVpv("ScalarRef", 9));
	OUTPUT:
		RETVAL

SV *
_ScalarRef(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) >= SVt_PVAV)) {
			croak("value did not pass type constraint \"ScalarRef\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
ArrayRef()
	CODE:
		RETVAL = _new(newSVpv("ArrayRef", 8));
	OUTPUT:
		RETVAL

SV *
_ArrayRef(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVAV)) {
			croak("value did not pass type constraint \"ArrayRef\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
HashRef()
	CODE:
		RETVAL = _new(newSVpv("HashRef", 7));
	OUTPUT:
		RETVAL

SV *
_HashRef(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVHV)) {
			croak("value did not pass type constraint \"HashRef\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
CodeRef()
	CODE:
		RETVAL = _new(newSVpv("CodeRef", 7));
	OUTPUT:
		RETVAL

SV *
_CodeRef(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVCV)) {
			croak("value did not pass type constraint \"CodeRef\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
RegexpRef()
	CODE:
		RETVAL = _new(newSVpv("RegexpRef", 9));
	OUTPUT:
		RETVAL

SV *
_RegexpRef(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_REGEXP)) {
			croak("value did not pass type constraint \"RegexpRef\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
GlobRef()
	CODE:
		RETVAL = _new(newSVpv("GlobRef", 7));
	OUTPUT:
		RETVAL

SV *
_GlobRef(param)
	SV * param
	CODE:
		if (!SvROK(param) || !SvOK(param) || (SvTYPE(SvRV(param)) != SVt_PVGV)) {
			croak("value did not pass type constraint \"GlobRef\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL




SV *
Str()
	CODE:
		RETVAL = _new(newSVpv("Str", 3));
	OUTPUT:
		RETVAL

SV *
_Str(param)
	SV * param
	CODE:
		int type = SvTYPE(param);
		if (SvROK(param) || !SvOK(param) || (type > SVt_PV)) {
			croak("value did not pass type constraint \"Str\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Num()
	CODE:
		RETVAL = _new(newSVpv("Num", 3));
	OUTPUT:
		RETVAL

SV *
_Num(param)
	SV * param
	CODE:
		int type = SvTYPE(param);
		if (SvROK(param) || !SvOK(param) || (type != SVt_IV && type != SVt_NV)) {
			if ( type != SVt_PV || ! _sv_contains_numbers(param, 0) ) {
				croak("value did not pass type constraint \"Num\"");
			}
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Int()
	CODE:
		RETVAL = _new(newSVpv("Int", 3));
	OUTPUT:
		RETVAL

SV *
_Int(param)
	SV * param
	CODE:
		int type = SvTYPE(param);
		if (SvROK(param) || !SvOK(param) || (type != SVt_IV)) {
			if ( type != SVt_PV || ! _sv_contains_numbers(param, 1) ) {
				croak("value did not pass type constraint \"Int\"");
			}
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

SV *
Bool()
	CODE:
		RETVAL = _new(newSVpv("Bool", 4));
	OUTPUT:
		RETVAL

SV *
_Bool(param)
	SV * param
	CODE:
		int type = SvTYPE(param);
		if (!_sv_isa_bool(param)) {
			croak("value did not pass type constraint \"Bool\"");
		}
		SvREFCNT_inc(param);
		RETVAL = param;
	OUTPUT:
		RETVAL

CV *
validate(...)
	OVERLOAD: &{}
	CODE:
		STRLEN retlen;
		char * type = SvPV(SvRV(ST(0)), retlen);
		char class[16 + 3 + retlen];
		sprintf(class, "Basic::Types::XS::_%s", type);
		CV * cv = get_cv(class, 0);
		RETVAL = cv;
	OUTPUT:
		RETVAL

void
_install(pkg, ...)
	char * pkg
	CODE:
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
			}
		}
