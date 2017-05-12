/* -*- mode: C; c-file-style: "bsd" -*- */

#ifndef __PORBIT_EXTTYPES_H__
#define __PORBIT_EXTTYPES_H__

#include "porbit-perl.h"

#define LL_VALUE(sv) (*(long long *) &SvNVX (sv))
#define SvLLV(sv) (sv_isa (sv, "CORBA::LongLong") ? \
		    LL_VALUE (SvRV (sv)) : \
		    longlong_from_string (SvPV (sv, PL_na)))
#define ULL_VALUE(sv) (*(unsigned long long *) &SvNVX (sv))
#define SvULLV(sv) (sv_isa (sv, "CORBA::ULongLong") ? \
		    ULL_VALUE (SvRV (sv)) : \
		    ulonglong_from_string (SvPV (sv, PL_na)))
#define LD_VALUE(sv) (*(long double *) SvPVX (sv))
#define SvLDV(sv) (sv_isa (sv, "CORBA::LongDouble") ? \
		    LD_VALUE (SvRV (sv)) : \
		    longdouble_from_string (SvPV (sv, PL_na)))

SV *ll_from_longlong (long long val);
long long longlong_from_string (const char *str);
char *longlong_to_string (long long val);

SV *ull_from_ulonglong (unsigned long long val);
unsigned long long ulonglong_from_string (const char *str);
char *ulonglong_to_string (unsigned long long val);

SV *ld_from_longdouble (long double val);
long double longdouble_from_string (const char *str);
char *longdouble_to_string (long double val);

#endif __PORBIT_EXTTYPES_H__
