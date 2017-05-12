#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PM_GETRE
#define PM_GETRE(o) ((o)->op_pmregexp)
#endif

typedef SV    * B__PV;
typedef OP    * B__OP;
typedef PMOP  * B__PMOP;
typedef MAGIC * B__MAGIC;

#include "regcomp.h"

#include "b_sizeof.c"

static int B__Size_SV_size(SV *sv)
{
    dSP;
    int count, retval;

    ENTER;SAVETMPS;PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc(sv)));
    PUTBACK;

    count = perl_call_pv("B::Size::SV_size", G_SCALAR);

    SPAGAIN;

    retval = POPi;

    PUTBACK;FREETMPS;LEAVE;

    return retval;
}

#define sizeof_if(p) (p ? sizeof(*p) : 0);

static int REGEXP_size(PMOP *o)
{
    REGEXP *rx = PM_GETRE(o);
    int retval = 0;

    if (!rx) {
    	return retval;
    }

    retval = rx->prelen;

    retval += sizeof_if(rx->regstclass);
    retval += sizeof_if(rx->subbeg);
    retval += sizeof_if(rx->startp);
    retval += sizeof_if(rx->endp);

    if (rx->data) {
    	int n = rx->data->count;
    	retval += sizeof(*rx->data);
    	retval += sizeof(void *) * n;

    	while (--n >= 0) {
    	    switch (rx->data->what[n]) {
        	    case 's':
         	    case 'p':
        	        retval += B__Size_SV_size((SV*)rx->data->data[n]);
           	        break;
        	    case 'o':
        	        /*XXX: OP*/
        		break;
        	    case 'n':
        	        break;
   	        }
        }
    }

    if (rx->substrs) {
	    /* check_substr just points to anchor or float */
    	if (rx->anchored_substr) {
    	    retval += B__Size_SV_size(rx->anchored_substr);
    	}
    	if (rx->float_substr) {
    	    retval += B__Size_SV_size(rx->float_substr);
    	}

    	retval += sizeof(*rx->substrs);
    }

    return retval;
}

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
    	    sv = INT2PTR(B__PV, tmp);
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
    	    sv = INT2PTR(B__PV, tmp);
    	}
    	else
    	    croak("sv is not a reference");

    	RETVAL = SvCUR(sv);
    	ST(0) = sv_newmortal();
    	sv_setiv(ST(0), (IV)RETVAL);
    }
    
    XSRETURN(1);
}

#define MgLENGTH(mg) mg->mg_len

static XS(XS_B__MAGIC_LENGTH)
{
    dXSARGS;
    if (items != 1)
    	croak("Usage: B::MAGIC::LENGTH(mg)");
    {
    	B__MAGIC	mg;
    	I32	RETVAL;

    	if (SvROK(ST(0))) {
    	    IV tmp = SvIV((SV*)SvRV(ST(0)));
            mg = INT2PTR(B__MAGIC, tmp);
    	}
    	else
    	    croak("mg is not a reference");

    	RETVAL = MgLENGTH(mg);
    	ST(0) = sv_newmortal();
    	sv_setiv(ST(0), (IV)RETVAL);
    }
    
    XSRETURN(1);
}

static XS(XS_B__OP_name)
{
    dXSARGS;
    if (items != 1)
        croak("Usage: B::OP::name(o)");
    {
    	B__OP	o;
    	char *	RETVAL;

    	if (SvROK(ST(0))) {
    	    IV tmp = SvIV((SV*)SvRV(ST(0)));
    	    o = INT2PTR(B__OP, tmp);
    	}
    	else
    	    croak("o is not a reference");

    	ST(0) = sv_newmortal();
    	sv_setpv(ST(0), PL_op_name[o->op_type]);
    }

    XSRETURN(1);
}

static void boot_B_compat(void)
{
    HV *b_stash = gv_stashpvn("B", 1, TRUE);

    /* these were not present until 5.005_58ish */
    if (!perl_get_cv("B::PV::LEN", FALSE)) {
        (void)newXS("B::PV::LEN", XS_B__PV_LEN, __FILE__);
    }
    if (!perl_get_cv("B::PV::CUR", FALSE)) {
        (void)newXS("B::PV::CUR", XS_B__PV_CUR, __FILE__);
    }
    if (!perl_get_cv("B::MAGIC::LENGTH", FALSE)) {
        (void)newXS("B::MAGIC::LENGTH", XS_B__MAGIC_LENGTH, __FILE__);
    }
    if (!perl_get_cv("B::OP::name", FALSE)) {
        (void)newXS("B::OP::name", XS_B__OP_name, __FILE__);
    }
    if (!perl_get_cv("B::SVf_POK", FALSE)) {
    	(void)newCONSTSUB(b_stash, "SVf_POK", newSViv(SVf_POK));
    }
    if (!perl_get_cv("B::SVf_FAKE", FALSE)) {
    	(void)newCONSTSUB(b_stash, "SVf_FAKE", newSViv(SVf_FAKE));
    }
}

#define OP_op_name(i) PL_op_name[i]
#define OP_op_desc(i) PL_op_desc[i]

MODULE = B::Size   PACKAGE = B::Sizeof

PROTOTYPES: disable

BOOT:
    boot_B_Sizeof();
    boot_B_compat();

MODULE = B::Size	PACKAGE = B::PMOP

int
REGEXP_size(o)
    B::PMOP o

MODULE = B::Size	PACKAGE = B::OP		PREFIX = OP_

char *
OP_op_name(i)
    U16 i

char *
OP_op_desc(i)
    U16 i

