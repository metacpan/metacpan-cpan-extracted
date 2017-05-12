/* -*- mode: C++; c-file-style: "bsd" -*- */

#ifdef _WINDOWS
#define CM_longlong	__int64
#else
#define CM_longlong	long long
#endif

#define LL_VALUE(sv) (*(CM_longlong *) &SvNVX (sv))
#define SvLLV(sv) (sv_isa (sv, "CORBA::LongLong") ? \
		    LL_VALUE (SvRV (sv)) : \
		    longlong_from_string (SvPV (sv, PL_na)))
#define ULL_VALUE(sv) (*(unsigned CM_longlong *) &SvNVX (sv))
#define SvULLV(sv) (sv_isa (sv, "CORBA::ULongLong") ? \
		    ULL_VALUE (SvRV (sv)) : \
		    ulonglong_from_string (SvPV (sv, PL_na)))
#define LD_VALUE(sv) (*(long double *) SvPVX (sv))
#define SvLDV(sv) (sv_isa (sv, "CORBA::LongDouble") ? \
		    LD_VALUE (SvRV (sv)) : \
		    longdouble_from_string (SvPV (sv, PL_na)))

SV *ll_from_longlong (pTHX_ CM_longlong val);
CM_longlong longlong_from_string (const char *str);
char *longlong_to_string (CM_longlong val);

SV *ull_from_ulonglong (pTHX_ unsigned CM_longlong val);
unsigned CM_longlong ulonglong_from_string (const char *str);
char *ulonglong_to_string (unsigned CM_longlong val);

SV *ld_from_longdouble (pTHX_ long double val);
long double longdouble_from_string (const char *str);
char *longdouble_to_string (long double val);
