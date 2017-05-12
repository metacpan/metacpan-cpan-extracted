#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef SV * B__PV;

static XS(XS_B__PV_LEN)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: B::PV::LEN(sv)");
    {
	B__PV	sv;
	STRLEN	RETVAL;

	if (SvROK(ST(0))) {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    sv = (B__PV) tmp;
	}
	else
	    croak("sv is not a reference");

	RETVAL = SvLEN(sv);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

static XS(XS_B__PV_CUR)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: B::PV::CUR(sv)");
    {
	B__PV	sv;
	STRLEN	RETVAL;

	if (SvROK(ST(0))) {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    sv = (B__PV) tmp;
	}
	else
	    croak("sv is not a reference");

	RETVAL = SvCUR(sv);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

static void boot_B_LexInfo(void)
{
    /* these were not present in 5.005_57 
     * make conditional in case they are added
     */
    if (!perl_get_cv("B::PV::LEN", FALSE)) {
        newXS("B::PV::LEN", XS_B__PV_LEN, __FILE__);
    }
    if (!perl_get_cv("B::PV::CUR", FALSE)) {
        newXS("B::PV::CUR", XS_B__PV_CUR, __FILE__);
    }
}

MODULE = B::LexInfo   PACKAGE = B::LexInfo

PROTOTYPES: disable

BOOT:
    boot_B_LexInfo();
