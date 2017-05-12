#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

MODULE = Array::RefElem		PACKAGE = Array::RefElem

void
av_store(avref, key, val)
	SV* avref
	I32 key
	SV* val
    PROTOTYPE: \@$$
    PREINIT:
	AV* av;
    CODE:
	if (!SvROK(avref) || SvTYPE(SvRV(avref)) != SVt_PVAV)
	   croak("First argument to av_store() must be an array reference");
	av = (AV*)SvRV(avref);
        SvREFCNT_inc(val);
	if (!av_store(av, key, val))
	    SvREFCNT_dec(val);

void
av_push(avref, val)
	SV* avref
	SV* val
    PROTOTYPE: \@$
    PREINIT:
	AV* av;
    CODE:
	if (!SvROK(avref) || SvTYPE(SvRV(avref)) != SVt_PVAV)
	   croak("First argument to av_push() must be an array reference");
	av = (AV*)SvRV(avref);
	SvREFCNT_inc(val);
	av_push(av, val);

void
hv_store(hvref, key, val)
	SV* hvref
	SV* key
	SV* val
    PROTOTYPE: \%$$
    PREINIT:
	HV* hv;
    CODE:
	if (!SvROK(hvref) || SvTYPE(SvRV(hvref)) != SVt_PVHV)
	   croak("First argument to hv_store() must be a hash reference");
	hv = (HV*)SvRV(hvref);
        SvREFCNT_inc(val);
	if (!hv_store_ent(hv, key, val, 0))
	    SvREFCNT_dec(val);

