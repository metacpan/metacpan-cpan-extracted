#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static SV * new_coerce (SV * type, CV * coerce) {
	dTHX;
	HV * hash = newHV();
	hv_store(hash, "name", 4, type, 0);
	hv_store(hash, "coerce", 6, (SV*)coerce, 0);
	return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(newSVpv("Basic::Coercion::XS", 19), 0));
}

char *get_caller(void) {
	dTHX;
	char *callr = HvNAME((HV*)CopSTASH(PL_curcop));
	return callr;
}

AV* split_by_regex(const char *input, const char *pattern) {
	dTHX;
	AV *result = newAV();
	STRLEN patlen = strlen(pattern);
	SV *pat_sv = newSVpvn(pattern, patlen);
	REGEXP *rx = pregcomp(pat_sv, 0);
	if (!rx) {
		SvREFCNT_dec(pat_sv);
		return result;
	}
	STRLEN input_len = strlen(input);
	STRLEN pos = 0;
	STRLEN last = 0;
	SV *input_sv = newSVpvn(input, input_len);
	while (pos <= input_len) {
		I32 nmatch;
		I32 ovector = 0;
		nmatch = pregexec(rx, input + pos, input + input_len, input, 0, input_sv, ovector);
		if (nmatch > 0) {
			STRLEN match_start = ((regexp *)SvANY(rx))->offs[0].start;
			STRLEN match_end = ((regexp *)SvANY(rx))->offs[0].end;
			SV *token = newSVpvn(input + last, match_start - last);
			av_push(result, token);
			if (match_end == match_start) {
				pos = match_end + 1;
			} else {
				pos = match_end;
			}
			last = pos;
			Safefree(ovector);
		} else {
			SV *token = newSVpvn(input + last, input_len - last);
			av_push(result, token);
			if (ovector) Safefree(ovector);
			break;
		}
	}
	SvREFCNT_dec(input_sv);
	SvREFCNT_dec(pat_sv);
	SvREFCNT_dec(rx);
	return result;
}

MODULE = Basic::Coercion::XS    PACKAGE = Basic::Coercion::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

SV *
_StrToArray(...)
	CODE:
		SV * self = CvXSUBANY(cv).any_ptr;
		if (!self || !SvOK(self)) {
			croak("StrToArray coerce constraint not initialized");
		}
		SV * param = ST(0);
		if (SvTYPE(param) != SVt_PV) {
			SvREFCNT_inc(param);
			RETVAL = param;
			XSRETURN(1);
		}
		STRLEN len;
		const char *input = SvPV(param, len);
		SV **pattern_sv = hv_fetch((HV*)SvRV(self), "by", 2, 0);
		const char *pattern = (pattern_sv && SvOK(*pattern_sv)) ? SvPV_nolen(*pattern_sv) : "\\s+";
		AV *result = split_by_regex(input, pattern);
		RETVAL = newRV_noinc((SV*)result);
	OUTPUT:
		RETVAL

SV *
StrToArray(...)
	CODE:
		CV *type = newXS(NULL, NULL, __FILE__);
		CvXSUB(type) = (XSUBADDR_t)(
			XS_Basic__Coercion__XS__StrToArray
		);
		SvREFCNT_inc(type);
		RETVAL = new_coerce(newSVpv("StrToArray", 10), type);
		SvREFCNT_inc(type);	
		CvXSUBANY(type).any_ptr = (void *)RETVAL;
		SvREFCNT_inc(RETVAL);
		HV * self = (HV*)SvRV(RETVAL);
		hv_store(self, "coerce", 6, newRV_noinc((SV*)type), 0);
		if (items % 2 != 0) {
			croak("StrToArray type constraint requires an even number of arguments");
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
coerce(...)
	OVERLOAD: &{}
	CODE:
		SV * self = ST(0);
		if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("first argument must be a Basic::Coercion::XS object");
		}
		SV * cb = *hv_fetch((HV*)SvRV(self), "coerce", 6, 0);
		RETVAL = (CV*)SvRV(cb);
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
			if (strcmp(ex, "StrToArray") == 0) {
				newXS(name, XS_Basic__Coercion__XS_StrToArray, __FILE__);
			}
		}
