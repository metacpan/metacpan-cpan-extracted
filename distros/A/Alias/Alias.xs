#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION         5
#define PERL_VERSION          PATCHLEVEL
#define PERL_SUBVERSION       SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#define PL_stack_sp	stack_sp

#endif

static void process_flag _((char *varname, SV **svp, char **strp, STRLEN *lenp));

static void
process_flag(varname, svp, strp, lenp)
    char *varname;
    SV **svp;
    char **strp;
    STRLEN *lenp;
{
    GV *vargv = gv_fetchpv(varname, FALSE, SVt_PV);
    SV *sv = Nullsv;
    char *str = Nullch;
    STRLEN len = 0;

    if (vargv && (sv = GvSV(vargv))) {
	if (SvROK(sv)) {
	    if (SvTYPE(SvRV(sv)) != SVt_PVCV)
		croak("$%s not a subroutine reference", varname);
	}
	else if (SvOK(sv))
	    str = SvPV(sv, len);
    }
    *svp = sv;
    *strp = str;
    *lenp = len;
}
		

MODULE = Alias		PACKAGE = Alias		PREFIX = alias_

PROTOTYPES: ENABLE

BOOT:
{
    GV *gv = gv_fetchpv("Alias::attr", FALSE, SVt_PVCV);
    if (gv && GvCV(gv))
	CvNODEBUG_on(GvCV(gv));
}


void
alias_attr(hashref)
	SV *	hashref
	PROTOTYPE: $
     PPCODE:
	{
	    HV *hv;
	    int in_destroy = 0;
	    int deref_call;
	    
	    if (SvREFCNT(hashref) == 0)
		in_destroy = 1;
	    
	    ++SvREFCNT(hashref);	/* in case LEAVE wants to clobber us */

	    if (SvROK(hashref) &&
		(hv = (HV *)SvRV(hashref)) && (SvTYPE(hv) == SVt_PVHV))
	    {
		SV *val, *tmpsv;
		char *key;
		I32 klen;
		SV *keypfx, *attrpfx, *deref;
		char *keypfx_c, *attrpfx_c, *deref_c;
		STRLEN keypfx_l, attrpfx_l, deref_l;

		process_flag("Alias::KeyFilter", &keypfx, &keypfx_c, &keypfx_l);
		process_flag("Alias::AttrPrefix", &attrpfx, &attrpfx_c, &attrpfx_l);
		process_flag("Alias::Deref", &deref, &deref_c, &deref_l);
		deref_call = (deref && !deref_c);
		
		LEAVE;                      /* operate at a higher level */
		
		(void)hv_iterinit(hv);
		while ((val = hv_iternextsv(hv, &key, &klen))) {
		    GV *gv;
		    int stype = SvTYPE(val);
		    int deref_this = 1;
		    int deref_objects = 0;

		    /* check the key for validity by either looking at
		     * its prefix, or by calling &$Alias::KeyFilter */
		    if (keypfx) {
			if (keypfx_c) {
			    if (keypfx_l && klen > keypfx_l
				&& strncmp(key, keypfx_c, keypfx_l))
				continue;
			}
			else {
			    dSP;
			    SV *ret = Nullsv;
			    I32 i;
			    
			    ENTER; SAVETMPS; PUSHMARK(sp);
			    XPUSHs(sv_2mortal(newSVpv(key,klen)));
			    PUTBACK;
			    if (perl_call_sv(keypfx, G_SCALAR))
				ret = *PL_stack_sp--;
			    SPAGAIN;
			    i = SvTRUE(ret);
			    FREETMPS; LEAVE;
			    if (!i)
				continue;
			}
		    }

		    if (SvROK(val) && deref) {
			if (deref_c) {
			    if (deref_l && !(deref_l == 1 && *deref_c == '0'))
				deref_objects = 1;
			}
			else {
			    dSP;
			    SV *ret = Nullsv;
			    
			    ENTER; SAVETMPS; PUSHMARK(sp);
			    XPUSHs(sv_2mortal(newSVpv(key,klen)));
			    XPUSHs(sv_2mortal(newSVsv(val)));
			    PUTBACK;
			    if (perl_call_sv(deref, G_SCALAR))
				ret = *PL_stack_sp--;
			    SPAGAIN;
			    deref_this = SvTRUE(ret);
			    FREETMPS; LEAVE;
			}
		    }
		    
		    /* attributes may need to be prefixed/renamed */
		    if (attrpfx) {
			STRLEN len;
			if (attrpfx_c) {
			    if (attrpfx_l) {
				SV *keysv = sv_2mortal(newSVpv(attrpfx_c, attrpfx_l));
				sv_catpvn(keysv, key, klen);
				key = SvPV(keysv, len);
				klen = len;
			    }
			}
			else {
			    dSP;
			    SV *ret = Nullsv;
			    
			    ENTER; PUSHMARK(sp);
			    XPUSHs(sv_2mortal(newSVpv(key,klen)));
			    PUTBACK;
			    if (perl_call_sv(attrpfx, G_SCALAR))
				ret = *PL_stack_sp--;
			    SPAGAIN; LEAVE;
			    key = SvPV(ret, len);
			    klen = len;
			}
		    }

		    if (SvROK(val) && (tmpsv = SvRV(val))) {
			if (deref_call) {
			    if (!deref_this)
				goto no_deref;
			}
			else if (!deref_objects && SvOBJECT(tmpsv))
			    goto no_deref;

			stype = SvTYPE(tmpsv);
			if (stype == SVt_PVGV)
			    val = tmpsv;

		    }
		    else if (stype != SVt_PVGV) {
		    no_deref:
			val = sv_2mortal(newRV(val));
		    }
		    
		    /* add symbol, forgoing "used once" warnings */
		    gv = gv_fetchpv(key, GV_ADDMULTI, SVt_PVGV);
		    
		    switch (stype) {
		    case SVt_PVAV:
			save_ary(gv);
			break;
		    case SVt_PVHV:
			save_hash(gv);
			break;
		    case SVt_PVGV:
			save_gp(gv,TRUE);   /* hide previous entry in symtab */
			break;
		    case SVt_PVCV:
			SAVESPTR(GvCV(gv));
			GvCV(gv) = Null(CV*);
			break;
		    default:
			save_scalar(gv);
			break;
		    }
		    sv_setsv((SV*)gv, val); /* alias the SV */
		}
		ENTER;			    /* in lieu of the LEAVE far beyond */
	    }
	    if (in_destroy)
		--SvREFCNT(hashref);	    /* avoid calling DESTROY forever */
	    else
		SvREFCNT_dec(hashref);
	    
	    XPUSHs(hashref);                /* simply return what we got */
	}
