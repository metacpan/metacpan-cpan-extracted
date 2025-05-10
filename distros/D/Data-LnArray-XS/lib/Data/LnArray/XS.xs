#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

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
	int len = av_len(current);
	for (int i = 0; i <= len; i++) {
		av_unshift(array, 1);
		av_store(array, 0, newSVsv(*av_fetch(current, i, 0)));
	}
	return array;
}

static SV * reduce (AV * array, SV * red, SV * cb) {
	dTHX;
	int len = av_len(array);
	for (int i = 0; i <= len; i++) {
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
			array = (AV*)SvRV(from);
		}
	
		if (items > 2) {	
			SV * cb = ST(2);
			for (i = 0; i <= av_len(array); i++) {
				dSP;
				GvSV(PL_defgv) = *av_fetch(array, i, 0);
				PUSHMARK(SP);
				call_sv(cb, G_SCALAR);
				SPAGAIN;
				SV * ret = POPs;
				PUTBACK;
				av_store(array, i, newSVsv(ret));
			}
		}

		RETVAL = newSVsv(new(self, array));
	OUTPUT:
		RETVAL

void
retrieve(self)
	SV * self
	CODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		for (i = 0; i <= len; i++) {
			ST(i) = newSVsv(*av_fetch(array, i, 0));
		}
	        XSRETURN(i);

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
    		int len = av_len(array), i = 0;
		GV * aa = gv_fetchpv("a", GV_ADD, SVt_PV);
		GV * bb = gv_fetchpv("b", GV_ADD, SVt_PV);
		SAVESPTR(GvSV(aa));
		SAVESPTR(GvSV(bb));
		for (i = 0; i <= len; i++) {
			av_push(new_array, newSVsv(*av_fetch(array, i, 0)));
		}
		for (i = 0; i <= len; i++) {
			for (int j=0; j < len; j++) {
				dSP;
				SV * a = GvSV(aa) = newSVsv(*av_fetch(new_array, j, 0));
				SV * b = GvSV(bb) = newSVsv(*av_fetch(new_array, j + 1, 0));
				PUSHMARK(SP);
				call_sv(cb, 3);
				double ret = SvNV(ST(2));
				if (ret > 0) {
					av_store(new_array, j, newSVsv(b));
					av_store(new_array, j + 1, newSVsv(a));
				}
				PUTBACK;
			}
		}
		
		RETVAL = newSVsv(new(self, new_array));
	OUTPUT:
		RETVAL

SV *
unshift(self, ...)
	SV * self
	CODE:
		AV * array = (AV*)SvRV(self);
		for (int i = 1; i < items; i++) {
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
    		int len = av_len(array);
		for (int i = 0; i <= len; i++) {
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
                  	dSP;
			SV * val = *av_fetch(array, i, 0);
                        PUSHMARK(SP);
                        XPUSHs(val);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
			if (SvTRUEx(*PL_stack_sp)) {
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
		int len = av_len(array);
		STRLEN retlen;
		char * joiner = SvPV(join, retlen);
		RETVAL = newSVpv("", 0);
		for (int i = 0; i <= len; i++) {
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
	CODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		int st = 0;
		for (i = 0; i <= len; i++) {
			ST(st) = newSViv(i);
			st++;
			ST(st) = newSVsv(*av_fetch(array, i, 0));
			st++;
		}
	        XSRETURN(i);

SV *
every(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array), i = 0;
		RETVAL = newRV_inc((SV*)newSViv(1));	
		for (i = 0; i <= len; i++) {
                  	dSP;
			SV * val = *av_fetch(array, i, 0);
                        PUSHMARK(SP);
                        XPUSHs(val);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
			if (!SvTRUEx(*PL_stack_sp)) {
				PUTBACK;
				RETVAL = newRV_inc((SV*)newSViv(0));
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
		RETVAL = (SV*) 0;
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			PUSHMARK(SP);
                        XPUSHs(val);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
			if (SvTRUEx(*PL_stack_sp)) {
				RETVAL = newSVsv(val);
				break;
			}
		}
	OUTPUT:
		RETVAL

SV *
findIndex(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0;
		RETVAL = (SV*) 0;
		for (i = 0; i <= len; i++) {
			SV * val = *av_fetch(array, i, 0);
			PUSHMARK(SP);
                        XPUSHs(val);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
			if (SvTRUEx(*PL_stack_sp)) {
				RETVAL = newSViv(i);
				break;
			}
		}
	OUTPUT:
		RETVAL

SV *
forEach(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		int len = av_len(array), i = 0, j = 0;
		AV * into = newAV();
		for (i = 0; i <= len; i++) {
			dSP;
			GvSV(PL_defgv) = *av_fetch(array, i, 0);
			PUSHMARK(SP);
			int p = call_sv(cb, 3);
			SPAGAIN;
			if (SvTRUEx(*PL_stack_sp)) {
				AV * temp = newAV();
				for (j = 0; j < p; j++) {
					av_push(temp, newSVsv(POPs));
				}
				temp = reverse(temp);
				for (j = 0; j < p; j++) {
					av_push(into, *av_fetch(temp, j, 0));
				}	
			}
			PUTBACK;	
		}
		len = av_len(into);
		for (i = 0; i <= len; i++) {
			ST(i) = newSVsv(*av_fetch(into, i, 0));
		}
	        XSRETURN(i);

SV *
keys(self)
	SV * self
	CODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		for (i = 0; i <= len; i++) {
			ST(i) = newSViv(i);
		}
	        XSRETURN(i);
	OUTPUT:
		RETVAL

SV *
map(self, cb)
	SV * self
	SV * cb
	CODE:
		AV * array = (AV*)SvRV(self);
		AV * new_array = newAV();
    		int len = av_len(array), i = 0, j = 0;
		int offset = 0;
		for (i = 0; i <= len; i++) {
                  	dSP;
			SV * val = *av_fetch(array, i, 0);
                        PUSHMARK(SP);
                        XPUSHs(val);
                        PUTBACK;
			int p = call_sv(cb, 3);
			SPAGAIN;
			if (SvTRUEx(*PL_stack_sp)) {
				AV * temp = newAV();
				for (j = 0; j < p; j++) {
					av_push(temp, newSVsv(POPs));
				}
				temp = reverse(temp);
				for (j = 0; j < p; j++) {
					av_push(new_array, *av_fetch(temp, j, 0));
				}
			}
			PUTBACK;

		}
		RETVAL = newSVsv(new(self, new_array));
	OUTPUT:
		RETVAL

SV *
reduce(self, cb, ...)
	SV * self
	SV * cb
	CODE:
		SV * red = items > 2 ? ST(3) : newSV(0);
		AV * array = (AV*)SvRV(self);
    		RETVAL = newSVsv(reduce(array, red, cb));
	OUTPUT:
		RETVAL

SV *
reduceRight(self, cb, ...)
	SV * self
	SV * cb
	CODE:
		SV * red = items > 2 ? ST(3) : newSV(0);
		AV * array = reverse((AV*)SvRV(self));
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
		RETVAL = newRV_inc((SV*)newSViv(0));	
		for (i = 0; i <= len; i++) {
                  	dSP;
			SV * val = *av_fetch(array, i, 0);
                        PUSHMARK(SP);
                        XPUSHs(val);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
			if (SvTRUEx(*PL_stack_sp)) {
				PUTBACK;
				RETVAL = newRV_inc((SV*)newSViv(1));
				break;
			}
		}
	OUTPUT:
		RETVAL

void
values(self)
	SV * self
	CODE:
		int i = 0;
		AV * array = (AV*)SvRV(self);
    		int len = av_len(array);
		for (i = 0; i <= len; i++) {
			ST(i) = newSVsv(*av_fetch(array, i, 0));
		}
	        XSRETURN(i);
