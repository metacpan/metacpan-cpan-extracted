/* Copyright (C) 2003, 2004, 2007, 2008  Matthijs van Duin <xmath@cpan.org>
 *
 * You may distribute under the same terms as perl itself, which is either 
 * the GNU General Public License or the Artistic License.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_MAGIC_backref
#define PERL_MAGIC_backref '<'
#endif

#ifndef packWARN
#define packWARN(w) (w)
#endif

#ifndef SVs_PADSTALE
#define SVs_PADSTALE 0
#endif
#ifndef SVs_PADBUSY
#define SVs_PADBUSY 0
#endif

#define CONTAINER_FLAGS ( SVs_TEMP | SVf_BREAK | \
		SVs_PADBUSY | SVs_PADTMP | SVs_PADMY | SVs_PADSTALE )

#ifdef PERL_OLD_COPY_ON_WRITE
#error "Data::Swap does not support PERL_OLD_COPY_ON_WRITE"
#endif

#ifndef PERL_COMBI_VERSION
#define PERL_COMBI_VERSION (PERL_REVISION * 1000000 + PERL_VERSION * 1000 + \
				PERL_SUBVERSION)
#endif

#if (PERL_COMBI_VERSION >= 5009003)
#define custom_warn_uninit(opdesc) \
	Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED), \
		PL_warn_uninit, "", " in ", opdesc)
#define BACKREFS_IN_HV 1
#else
#define custom_warn_uninit(opdesc) \
	Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED), \
		PL_warn_uninit, " in ", opdesc)
#define BACKREFS_IN_HV 0
#endif

#if (PERL_COMBI_VERSION < 5009004)
#define DA_SWAP_OVERLOAD_ERR \
	"Can't swap an overloaded object with a non-overloaded one"
#endif

#define DA_DEREF_ERR "Can't deref string (\"%.32s\")"

STATIC AV *extract_backrefs(pTHX_ SV *sv) {
	AV *av = NULL;

#if BACKREFS_IN_HV
	if (SvTYPE(sv) == SVt_PVHV && SvOOK(sv)) {
		AV **const avp = Perl_hv_backreferences_p(aTHX_ (HV *) sv);
		av = *avp;
		*avp = NULL;
	}
#endif

	if (!av && SvRMAGICAL(sv)) {
		MAGIC *const mg = mg_find(sv, PERL_MAGIC_backref);
		if (mg) {
			av = (AV *) mg->mg_obj;
			mg->mg_obj = NULL;
			mg->mg_virtual = NULL;
			sv_unmagic(sv, PERL_MAGIC_backref);
		}
	}

	return av;
}

STATIC void install_backrefs(pTHX_ SV *sv, AV *backrefs) {
	if (!backrefs)
		return;

#if BACKREFS_IN_HV
	if (SvTYPE(sv) == SVt_PVHV) {
		AV **const avp = Perl_hv_backreferences_p(aTHX_ (HV *) sv);
		*avp = backrefs;
		return;
	}
#endif

	sv_magic(sv, (SV *) backrefs, PERL_MAGIC_backref, NULL, 0);
}

STATIC AV *sv_move(pTHX_ SV *dst, SV *src, AV *br)
{
	AV *obr = extract_backrefs(aTHX_ src);

#if (PERL_COMBI_VERSION >= 5009003)
	dst->sv_u = src->sv_u;

	if (SvTYPE(src) == SVt_IV)
		SvANY(dst) = (XPVIV *) ((char *) &dst->sv_u.svu_iv
				- STRUCT_OFFSET(XPVIV, xiv_iv));
#if (PERL_COMBI_VERSION < 5011000)
	else if (SvTYPE(src) == SVt_RV)
		SvANY(dst) = &dst->sv_u.svu_rv;
#endif
	else
#endif
		SvANY(dst) = SvANY(src);

	SvFLAGS(dst) = (SvFLAGS(dst) & CONTAINER_FLAGS) |
			(SvFLAGS(src) & ~CONTAINER_FLAGS);

	install_backrefs(aTHX_ dst, br);

	return obr;
}


MODULE = Data::Swap  PACKAGE = Data::Swap

PROTOTYPES: DISABLE

BOOT:
	CvLVALUE_on(get_cv("Data::Swap::deref", TRUE));

void
deref(...)
    PREINIT:
	I32 i, n = 0;
	I32 sref;
	SV *sv;
    PPCODE:
	sref = (GIMME == G_SCALAR) && (PL_op->op_flags & OPf_REF);
	for (i = 0; i < items; i++) {
		if (!SvROK(ST(i))) {
			STRLEN z;
			if (SvOK(ST(i)))
				Perl_croak(aTHX_ DA_DEREF_ERR, SvPV(ST(i), z));
			if (ckWARN(WARN_UNINITIALIZED))
				custom_warn_uninit("deref");
			if (sref)
				return;
			continue;
		}
		sv = SvRV(ST(i));
		if (sref) {
			PUSHs(sv);
			PUTBACK;
			return;
		}
		switch (SvTYPE(sv)) {
			I32 x;
		case SVt_PVAV:
			if (!(x = av_len((AV *) sv) + 1))
				continue;
			SP += x;
			break;
		case SVt_PVHV:
			if (!(x = HvKEYS(sv)))
				continue;
			SP += x * 2;
			break;
		case SVt_PVCV:
			Perl_croak(aTHX_ "Can't deref subroutine reference");
		case SVt_PVFM:
			Perl_croak(aTHX_ "Can't deref format reference");
		case SVt_PVIO:
			Perl_croak(aTHX_ "Can't deref filehandle reference");
		default:
			SP++;
		}
		ST(n++) = ST(i);
	}
	EXTEND(SP, 0);
	for (i = 0; n--; ) {
		SV *sv = SvRV(ST(n));
		I32 x = SvTYPE(sv);
		if (x == SVt_PVAV) {
			i -= x = AvFILL((AV *) sv) + 1;
			Copy(AvARRAY((AV *) sv), SP + i + 1, x, SV *);
		} else if (x == SVt_PVHV) {
			HE *entry;
			HV *hv = (HV *) sv;
			i -= x = hv_iterinit(hv) * 2;
			PUTBACK;
			while ((entry = hv_iternext(hv))) {
				sv = hv_iterkeysv(entry);
				SPAGAIN;
				SvREADONLY_on(sv);
				SP[++i] = sv;
				sv = hv_iterval(hv, entry);
				SPAGAIN;
				SP[++i] = sv;
			}
			i -= x;
		} else {
			SP[i--] = sv;
		}
	}

void
swap(r1, r2)
	SV *r1
	SV *r2
    PREINIT:
	AV *br;
	SV t;
    CODE:
#ifdef DA_SWAP_OVERLOAD_ERR
	if (SvAMAGIC(r1) != SvAMAGIC(r2))
		Perl_croak(aTHX_ DA_SWAP_OVERLOAD_ERR);
#endif
	if (!SvROK(r1) || !(r1 = SvRV(r1)) || !SvROK(r2) || !(r2 = SvRV(r2)))
		Perl_croak(aTHX_ "Not a reference");
	if ((SvREADONLY(r1) && SvIMMORTAL(r1))
			|| (SvREADONLY(r2) && SvIMMORTAL(r2)))
		Perl_croak(aTHX_ PL_no_modify);
	br = NULL;
	br = sv_move(aTHX_ &t, r1, br);
	br = sv_move(aTHX_ r1, r2, br);
	br = sv_move(aTHX_ r2, &t, br);
