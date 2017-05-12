#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = DBIx::DBO::Query            PACKAGE = DBIx::DBO::Query

void
_hv_store(hvref, key, val)
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

