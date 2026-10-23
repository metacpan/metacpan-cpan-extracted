#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

#ifndef G_LIST
#define G_LIST G_ARRAY
#endif

#ifndef DEFSV_set
#define DEFSV_set(sv) (DEFSV = (sv))
#endif

static SV * call_one (pTHX_ SV * cb, SV * arg) {
	dSP;
	SV * ret;
	PUSHMARK(SP);
	XPUSHs(arg);
	PUTBACK;
	call_sv(cb, G_SCALAR);
	SPAGAIN;
	ret = POPs;
	PUTBACK;
	return ret;
}

static void copy_into (pTHX_ AV * into, int count) {
	SV ** sp = PL_stack_sp - count + 1;
	int j;
	for (j = 0; j < count; j++) {
		av_push(into, newSVsv(sp[j]));
	}
	PL_stack_sp -= count;
}

static SV * new (SV * class, AV * array) {
	dTHX;
	if (SvTYPE(class) != SVt_PV) {
		char * name = HvNAME(SvSTASH(SvRV(class)));
		class = newSVpv(name, strlen(name));
	}
	return sv_bless(newRV_noinc((SV*)array), gv_stashsv(class, 0));
}

static AV * reverse (AV * current) {
	dTHX;
	AV * array = newAV();
	int len = av_len(current), i = 0;
	for (i = 0; i <= len; i++) {
		av_unshift(array, 1);
		av_store(array, 0, newSVsv(*av_fetch(current, i, 0)));
	}
	return array;
}

static SV * reduce (AV * array, SV * red, SV * cb) {
	dTHX;
	int len = av_len(array), i = 0;
	for (i = 0; i <= len; i++) {
		dSP;
		SV * val = *av_fetch(array, i, 0);
		PUSHMARK(SP);
		XPUSHs(red);
		XPUSHs(val);
		PUTBACK;
		call_sv(cb, G_SCALAR);
		SPAGAIN;
		red = POPs;
		PUTBACK;
	}
	return red;
}

static int mmin (int first, int second) {
	if (first > second) {
		return second;
	}
	return first;
}

static int mmax (int first, int second) {
	if (first < second) {
		return second;
	}
	return first;
}

MODULE = Data::LnArray::XS  PACKAGE = Data::LnArray::XS
PROTOTYPES: ENABLE

void
import(...)
	PROTOTYPE: DISABLE
	CODE:
		HV * tags = get_hv("Data::LnArray::XS::EXPORT_TAGS", 0);
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
arr(...)
        CODE:
		AV * array = av_make(items, MARK+1);
		RETVAL = new(newSVpv("Data::LnArray::XS", 17), array);
        OUTPUT:
                RETVAL

SV *
new(...)
        CODE:
		AV * array = av_make(items, MARK+1);
		SV * class = av_shift(array);
		RETVAL = new(class, array);
        OUTPUT:
                RETVAL

SV *
get(self, index)
	SV * self
	SV * index
	CODE:
		RETVAL = newSVsv(*av_fetch((AV*)SvRV(self), SvIV(index), 0));		
	OUTPUT:
		RETVAL

SV *
set(self, index, value)
	SV * self
	SV * index
	SV * value
	CODE:
		av_store((AV*)SvRV(self), SvIV(index), newSVsv(value));	
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV *
length(self)
	SV * self
	CODE:
		RETVAL = newSViv(av_len((AV*)SvRV(self)) + 1);
	OUTPUT:
		RETVAL

SV *
from (...)
	CODE:
		int i = 0;
		SV * self = ST(0);
		SV * from = ST(1);
		AV * array = newAV();
		if (SvTYPE(SvRV(from)) == SVt_PVHV) {
			if (!hv_exists((HV*)SvRV(from), "length", 6)) {
				croak("currently cannot handle");
			}
			int len = SvIV(*hv_fetch((HV*)SvRV(from), "length", 6, 0));
			for (i = 0; i < len; i++) {
				av_push(array, newSViv(i));
			}
		} else if ( SvTYPE(SvRV(from)) != SVt_PVAV ) {
			STRLEN retlen;
			char * str = SvPV(from, retlen);
			for (i = 0; i < retlen; i++) {
				SV *sv = newSVpvn(str, 1);
				av_push(array, sv);
				str += 1;
			}
		} else {
			AV * src = (AV*)SvRV(from);
			int len = av_len(src);
			for (i = 0; i <= len; i++) {
				SV ** svp = av_fetch(src, i, 0);
				av_push(array, svp ? newSVsv(*svp) : newSV(0));
			}
		}

		if (items > 2) {
			SV * cb = ST(2);
			ENTER;
			SAVE_DEFSV;
			for (i = 0; i <= av_len(array); i++) {
				dSP;
				SV * ret;
				DEFSV_set(*av_fetch(array, i, 0));
				PUSHMARK(SP);
				PUTBACK;
				call_sv(cb, G_SCALAR);
				SPAGAIN;
				ret = POPs;
				PUTBACK;
				av_store(array, i, newSVsv(ret));
			}
			LEAVE;
		}

		RETVAL = newSVsv(new(self, array));
	OUTPUT:
		RETVAL

void
retrieve(self)
	SV * self
	PPCODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		EXTEND(SP, len + 1);
		for (i = 0; i <= len; i++) {
			mPUSHs(newSVsv(*av_fetch(array, i, 0)));
		}

SV *
isArray(self, ...)
	SV * self
	CODE:
		SV * array = ST(1);
		if ( !SvROK(array) || SvTYPE(SvRV(array)) != SVt_PVAV ) {
			RETVAL = newRV_inc((SV*)newSViv(0));
		} else {
			RETVAL = newRV_inc((SV*)newSViv(1));
		}
	OUTPUT:
		RETVAL

SV *
of(...)
        CODE:
		AV * array = av_make(items, MARK+1);
		SV * class = av_shift(array);
		RETVAL = new(class, array);
        OUTPUT:
                RETVAL

SV *
copyWithin(self, target, start, ...)
	SV * self
	SV * target
	SV * start
	CODE:
		int length = av_len((AV*)SvRV(self)) + 1;
	
		int itarget = SvIV(target);
		int to = itarget < 0 
			? mmax( length + itarget, 0)
			: mmin( itarget, length);

		int istart = SvIV(start);
		int from = istart < 0 
			? mmax( length + istart, 0)
			: mmin( istart, length);

		int iend = items == 4 ? SvIV(ST(3)) : length - 1;
		int final = iend < 0 
			? mmax( length + iend, 0)
			: mmin( iend, length);


		int count = mmin(final - from, length - to);

		int direction = 1;

		if ( from < to && to < ( from + count ) ) {
			direction = - 1;
			from += count - 1;
			to += count - 1;
		}

		AV * array = (AV*)SvRV(self);

		while ( count > 0 ) {
			av_store(array, to, newSVsv(*av_fetch(array, from, 0)));	
			from += direction;
			to += direction;
			count--;
        	}

		RETVAL = newSVsv(self);	
	OUTPUT:
		RETVAL

SV *
fill(self, target, start, ...)
	SV * self
	SV * target
	SV * start
	CODE:
		int length = av_len((AV*)SvRV(self)) + 1;
	
		int istart = SvIV(start);
		int from = istart < 0 
			? mmax( length + istart, 0)
			: mmin( istart, length);

		int iend = items == 4 ? SvIV(ST(3)) : length - 1;
		int final = iend < 0 
			? mmax( length + iend, 0)
			: mmin( iend, length);

		AV * array = (AV*)SvRV(self);
		
		while (from <= final) {
			av_store(array, from, newSVsv(target));
			from++;
		}

		RETVAL = newSVsv(self);	
	OUTPUT:
		RETVAL

SV *
pop(self)
	SV * self
	CODE:
		RETVAL = av_pop((AV*)SvRV(self));
	OUTPUT:
		RETVAL

SV *
push(self, value)
	SV * self
	SV * value
	CODE:
		av_push((AV*)SvRV(self), newSVsv(value));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV *
reverse(self)
	SV * self
	CODE:
		AV * current = (AV*)SvRV(self);
		AV * array = reverse(current);
		RETVAL = newSVsv(new(self, array));
	OUTPUT:
		RETVAL

SV *
shift(self)
	SV * self
	CODE:
		RETVAL = av_shift((AV*)SvRV(self));
	OUTPUT:
		RETVAL

SV *
sort(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		AV * new_array = newAV();
    		int len = av_len(array), i = 0, j = 0;
		HV * stash = (SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV && CvSTASH((CV*)SvRV(cb)))
			? CvSTASH((CV*)SvRV(cb)) : CopSTASH(PL_curcop);
		const char * pkg = stash && HvNAME(stash) ? HvNAME(stash) : "main";
		GV * aa = gv_fetchpv(Perl_form(aTHX_ "%s::a", pkg), GV_ADD, SVt_PV);
		GV * bb = gv_fetchpv(Perl_form(aTHX_ "%s::b", pkg), GV_ADD, SVt_PV);
		ENTER;
		SAVESPTR(GvSV(aa));
		SAVESPTR(GvSV(bb));
		for (i = 0; i <= len; i++) {
			av_push(new_array, newSVsv(*av_fetch(array, i, 0)));
		}
		for (i = 0; i <= len; i++) {
			for (j = 0; j < len; j++) {
				dSP;
				SV * a = GvSV(aa) = sv_mortalcopy(*av_fetch(new_array, j, 0));
				SV * b = GvSV(bb) = sv_mortalcopy(*av_fetch(new_array, j + 1, 0));
				NV ret;
				PUSHMARK(SP);
				PUTBACK;
				call_sv(cb, G_SCALAR);
				SPAGAIN;
				ret = POPn;
				PUTBACK;
				if (ret > 0) {
					av_store(new_array, j, newSVsv(b));
					av_store(new_array, j + 1, newSVsv(a));
				}
			}
		}
		LEAVE;

		RETVAL = newSVsv(new(self, new_array));
	OUTPUT:
		RETVAL

SV *
unshift(self, ...)
	SV * self
	CODE:
		AV * array = (AV*)SvRV(self);
		int i = 1;
		for (i = 1; i < items; i++) {
			av_unshift(array, 1);
			av_store(array, 0, newSVsv(ST(i)));
		}
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV *
concat(self, array)
	SV * self
	AV * array
	CODE:
    		int len = av_len(array), i = 0;
		for (i = 0; i <= len; i++) {
			av_push((AV*)SvRV(self), newSVsv(*av_fetch(array, i, 0)));
		}
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV *
filter(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		AV * new_array = newAV();
    		int len = av_len(array), i = 0;
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			if (SvTRUEx(call_one(aTHX_ cb, val))) {
				av_push(new_array, newSVsv(val));
			}
		}
		RETVAL = newSVsv(new(self, new_array));
	OUTPUT:
		RETVAL

SV *
includes(self, find)
	SV * self
	SV * find
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		RETVAL = newRV_inc((SV*)newSViv(0));
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			if ( SvTYPE(val) == SVt_PV ) {
				STRLEN r1, r2;
				char * v1 = SvPV(val, r1);
				char * v2 = SvPV(find, r2);
				if ( strcmp(v1, v2) == 0 ) {
					RETVAL = newRV_inc((SV*)newSViv(1));
					break;
				}
			}
		}
	OUTPUT:
		RETVAL

SV *
indexOf(self, find) 
	SV * self
	SV * find
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		RETVAL = (SV*)newSViv(-1);
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			if ( SvTYPE(val) == SVt_PV ) {
				STRLEN r1, r2;
				char * v1 = SvPV(val, r1);
				char * v2 = SvPV(find, r2);
				if ( strcmp(v1, v2) == 0 ) {
					RETVAL = (SV*)newSViv(i);
					break;
				}
			}
		}
	OUTPUT:
		RETVAL

SV *
join(self, join) 
	SV * self
	SV * join
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		STRLEN retlen;
		char * joiner = SvPV(join, retlen);
		RETVAL = newSVpv("", 0);
		for (i = 0; i <= len; i++) {
			if (i > 0) {
				sv_catpv(RETVAL, joiner);
			}
			sv_catpv(RETVAL, SvPV(*av_fetch(array, i, 0), retlen));
		}
	OUTPUT:
		RETVAL


SV *
lastIndexOf(self, find) 
	SV * self
	SV * find
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		RETVAL = (SV*)newSViv(-1);
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			if ( SvTYPE(val) == SVt_PV ) {
				STRLEN r1, r2;
				char * v1 = SvPV(val, r1);
				char * v2 = SvPV(find, r2);
				if ( strcmp(v1, v2) == 0 ) {
					RETVAL = (SV*)newSViv(i);
				}
			}
		}
	OUTPUT:
		RETVAL

SV *
slice(self, start, end)
	SV * self
	SV * start
	SV * end
	CODE:
		AV * array = (AV*)SvRV(self);
		AV * new_array = newAV();
		int from = SvIV(start);
		int to = mmin(SvIV(end), av_len(array));
		for (from = from; from <= to; from++) {
			av_push(new_array, newSVsv(*av_fetch(array, from, 0)));
		}
		RETVAL = newSVsv(new(self, new_array));
	OUTPUT:
		RETVAL

SV *
toString(self, join) 
	SV * self
	SV * join
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		STRLEN retlen;
		char * joiner = SvPV(join, retlen);
		RETVAL = newSVpv("", 0);
		for (i = 0; i <= len; i++) {
			if (i > 0) {
				sv_catpv(RETVAL, joiner);
			}
			sv_catpv(RETVAL, SvPV(*av_fetch(array, i, 0), retlen));
		}
	OUTPUT:
		RETVAL


void
entries(self)
	SV * self
	PPCODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		EXTEND(SP, 2 * (len + 1));
		for (i = 0; i <= len; i++) {
			mPUSHs(newSViv(i));
			mPUSHs(newSVsv(*av_fetch(array, i, 0)));
		}

SV *
every(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array), i = 0;
		RETVAL = newRV_noinc((SV*)newSViv(1));
		for (i = 0; i <= len; i++) {
			if (!SvTRUEx(call_one(aTHX_ cb, *av_fetch(array, i, 0)))) {
				SvREFCNT_dec(RETVAL);
				RETVAL = newRV_noinc((SV*)newSViv(0));
				break;
			}
		}
	OUTPUT:
		RETVAL

SV *
find(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		RETVAL = NULL;
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			if (SvTRUEx(call_one(aTHX_ cb, val))) {
				RETVAL = newSVsv(val);
				break;
			}
		}
		if (!RETVAL) RETVAL = newSV(0);
	OUTPUT:
		RETVAL

SV *
findIndex(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		RETVAL = NULL;
		for (i = 0; i <= len; i++) {
			if (SvTRUEx(call_one(aTHX_ cb, *av_fetch(array, i, 0)))) {
				RETVAL = newSViv(i);
				break;
			}
		}
		if (!RETVAL) RETVAL = newSV(0);
	OUTPUT:
		RETVAL

void
forEach(self, cb)
	SV * self
	SV * cb
	PPCODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		AV * into = (AV*)sv_2mortal((SV*)newAV());
		PUTBACK;
		ENTER;
		SAVE_DEFSV;
		for (i = 0; i <= len; i++) {
			dSP;
			int p;
			DEFSV_set(*av_fetch(array, i, 0));
			PUSHMARK(SP);
			PUTBACK;
			p = call_sv(cb, G_LIST);
			if (p > 0 && SvTRUEx(*PL_stack_sp))
				copy_into(aTHX_ into, p);
			else
				PL_stack_sp -= p;
		}
		LEAVE;
		SPAGAIN;
		len = av_len(into);
		EXTEND(SP, len + 1);
		for (i = 0; i <= len; i++) {
			PUSHs(*av_fetch(into, i, 0));
		}

void
keys(self)
	SV * self
	PPCODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		EXTEND(SP, len + 1);
		for (i = 0; i <= len; i++) {
			mPUSHs(newSViv(i));
		}

SV *
map(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		AV * new_array = newAV();
    		int len = av_len(array), i = 0;
		for (i = 0; i <= len; i++) {
                  	dSP;
			int p;
                        PUSHMARK(SP);
                        XPUSHs(*av_fetch(array, i, 0));
                        PUTBACK;
			p = call_sv(cb, G_LIST);
			if (p > 0 && SvTRUEx(*PL_stack_sp))
				copy_into(aTHX_ new_array, p);
			else
				PL_stack_sp -= p;
		}
		RETVAL = newSVsv(new(self, new_array));
	OUTPUT:
		RETVAL

SV *
reduce(self, cb, ...)
	SV * self
	SV * cb
	CODE:
		SV * red = items > 2 ? ST(2) : sv_newmortal();
		AV * array = (AV*)SvRV(self);
    		RETVAL = newSVsv(reduce(array, red, cb));
	OUTPUT:
		RETVAL

SV *
reduceRight(self, cb, ...)
	SV * self
	SV * cb
	CODE:
		SV * red = items > 2 ? ST(2) : sv_newmortal();
		AV * array = (AV*)sv_2mortal((SV*)reverse((AV*)SvRV(self)));
    		RETVAL = newSVsv(reduce(array, red, cb));
	OUTPUT:
		RETVAL

SV *
some(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array), i = 0;
		RETVAL = newRV_noinc((SV*)newSViv(0));
		for (i = 0; i <= len; i++) {
			if (SvTRUEx(call_one(aTHX_ cb, *av_fetch(array, i, 0)))) {
				SvREFCNT_dec(RETVAL);
				RETVAL = newRV_noinc((SV*)newSViv(1));
				break;
			}
		}
	OUTPUT:
		RETVAL

void
values(self)
	SV * self
	PPCODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		EXTEND(SP, len + 1);
		for (i = 0; i <= len; i++) {
			mPUSHs(newSVsv(*av_fetch(array, i, 0)));
		}
