#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

#ifndef GvCV_set
# define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#endif /* !GvCV_set */

#ifndef CvGV_set
# define CvGV_set(cv, gv) (CvGV(cv) = (gv))
#endif /* !CvGV_set */

#ifndef CvISXSUB
# define CvISXSUB(cv) !!CvXSUB(cv)
#endif /* !CvISXSUB */

#ifndef CvISXSUB_on
# define CvISXSUB_on(cv) ((void) (cv))
#endif /* !CvISXSUB_on */

#ifndef sv_setpvs
# define sv_setpvs(SV, STR) sv_setpvn(SV, ""STR"", sizeof(STR)-1)
#endif /* !sv_setpvs */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn(""name"", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif /* !PERL_UNUSED_ARG */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#ifndef ptr_table_new

struct q_ptr_tbl_ent {
	struct q_ptr_tbl_ent *next;
	void *from, *to;
};

# undef PTR_TBL_t
# define PTR_TBL_t struct q_ptr_tbl_ent *

# define ptr_table_new() THX_ptr_table_new(aTHX)
static PTR_TBL_t *THX_ptr_table_new(pTHX)
{
	PTR_TBL_t *tbl;
	Newx(tbl, 1, PTR_TBL_t);
	*tbl = NULL;
	return tbl;
}

# define ptr_table_free(tbl) THX_ptr_table_free(aTHX_ tbl)
static void THX_ptr_table_free(pTHX_ PTR_TBL_t *tbl)
{
	struct q_ptr_tbl_ent *ent = *tbl;
	Safefree(tbl);
	while(ent) {
	        struct q_ptr_tbl_ent *nent = ent->next;
	        Safefree(ent);
	        ent = nent;
	}
}

# define ptr_table_store(tbl, from, to) THX_ptr_table_store(aTHX_ tbl, from, to)
static void THX_ptr_table_store(pTHX_ PTR_TBL_t *tbl, void *from, void *to)
{
	struct q_ptr_tbl_ent *ent;
	Newx(ent, 1, struct q_ptr_tbl_ent);
	ent->next = *tbl;
	ent->from = from;
	ent->to = to;
	*tbl = ent;
}

# define ptr_table_fetch(tbl, from) THX_ptr_table_fetch(aTHX_ tbl, from)
static void *THX_ptr_table_fetch(pTHX_ PTR_TBL_t *tbl, void *from)
{
	struct q_ptr_tbl_ent *ent;
	for(ent = *tbl; ent; ent = ent->next) {
	        if(ent->from == from) return ent->to;
	}
	return NULL;
}

#endif /* !ptr_table_new */

#ifndef DPTR2FPTR
# define DPTR2FPTR(t,x) ((t)(UV)(x))
#endif /* !DPTR2FPTR */

#ifndef FPTR2DPTR
# define FPTR2DPTR(t,x) ((t)(UV)(x))
#endif /* !FPTR2DPTR */

#ifndef newSV_type
# define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
#endif /* !newSV_type */

/*
 * representing op pointer as B::OP object reference
 */

static HV *stash_bop;

#define decode_bop(bopref) THX_decode_bop(aTHX_ bopref)
static OP *THX_decode_bop(pTHX_ SV *bopref)
{
	/*
	 * This logic comes from B's typemap entry for B::OP.  It does
	 * not check for the alleged B::OP object being blessed into a
	 * B::OP class.
	 */
	if(!SvROK(bopref)) croak("bad B::OP reference");
	return INT2PTR(OP*, SvIV(SvRV(bopref)));
}

#define encode_bop(op) THX_encode_bop(aTHX_ op)
static SV *THX_encode_bop(pTHX_ OP *op)
{
	/*
	 * All the logic for blessing into the right B::OP class
	 * is in internal functions in B.  We really want to call
	 * make_op_object() from B.xs.	This is a roundabout way of
	 * getting to it.
	 */
	OP stalkop;
	SV *stalkbop, *bop;
	stalkop.op_next = op;
	stalkbop = sv_2mortal(newRV_noinc(newSViv(INT2PTR(IV, &stalkop))));
	sv_bless(stalkbop, stash_bop);
	{
		dSP;
		PUSHMARK(SP);
		XPUSHs(stalkbop);
		PUTBACK;
		call_method("next", G_SCALAR);
		SPAGAIN;
		bop = POPs;
		PUTBACK;
	}
	return bop;
}

/*
 * representing C call-checker function as Perl sub
 */

static void xsfunc_c_ckfun(pTHX_ CV *);

static PTR_TBL_t *ckfun_cap_map;

#define ckfun_encode_c_as_perl(cckfun) THX_ckfun_encode_c_as_perl(aTHX_ cckfun)
static CV *THX_ckfun_encode_c_as_perl(pTHX_ Perl_call_checker cckfun)
{
	void *vcckfun = FPTR2DPTR(void *, cckfun);
	CV *ckfun;
	if((ckfun = ptr_table_fetch(ckfun_cap_map, vcckfun)))
		return ckfun;
	ckfun = (CV*)newSV_type(SVt_PVCV);
	sv_setpvs((SV*)ckfun, "$$$");
	CvXSUBANY(ckfun).any_ptr = vcckfun;
	CvXSUB(ckfun) = xsfunc_c_ckfun;
	CvISXSUB_on(ckfun);
	ptr_table_store(ckfun_cap_map, vcckfun, (void*)ckfun);
	return ckfun;
}

#define ckfun_perl_is_encoded_c(ckfun) THX_ckfun_perl_is_encoded_c(aTHX_ ckfun)
static bool THX_ckfun_perl_is_encoded_c(pTHX_ CV *ckfun)
{
	return CvISXSUB(ckfun) && CvXSUB(ckfun) == xsfunc_c_ckfun;
}

#define ckfun_decode_c_as_perl(ckfun) THX_ckfun_decode_c_as_perl(aTHX_ ckfun)
static Perl_call_checker THX_ckfun_decode_c_as_perl(pTHX_ CV *ckfun)
{
	return DPTR2FPTR(Perl_call_checker, CvXSUBANY(ckfun).any_ptr);
}

static void xsfunc_c_ckfun(pTHX_ CV *ckfun)
{
	SV *ckobj_st, *namegv_st, *entersubop_st, *ckobj;
	GV *namegv;
	OP *entersubop;
	Perl_call_checker cckfun = ckfun_decode_c_as_perl(ckfun);
	dSP; dMARK;
	if(SP - MARK != 3) {
		bad_args:
		croak("non-Perl call checker called incorrectly");
	}
	ckobj_st = POPs;
	namegv_st = POPs;
	entersubop_st = TOPs;
	PUTBACK;
	if(!SvROK(ckobj_st)) goto bad_args;
	ckobj = SvRV(ckobj_st);
	if(!SvROK(namegv_st)) goto bad_args;
	namegv = (GV*)SvRV(namegv_st);
	if(SvTYPE((SV*)namegv) != SVt_PVGV) goto bad_args;
	entersubop = decode_bop(entersubop_st);
	entersubop = cckfun(aTHX_ entersubop, namegv, ckobj);
	entersubop_st = encode_bop(entersubop);
	SPAGAIN;
	TOPs = entersubop_st;
}

/*
 * representing Perl call-checker sub as C function
 */

static OP *cckfun_perl_ckfun(pTHX_ OP *entersubop, GV *namegv, SV *cckobj);

#define ckfun_encode_perl_as_c(ckfun, ckobj, cckfun_p, cckobj_p) \
	THX_ckfun_encode_perl_as_c(aTHX_ ckfun, ckobj, cckfun_p, cckobj_p)
static void THX_ckfun_encode_perl_as_c(pTHX_
	CV *ckfun, SV *ckobj, Perl_call_checker *cckfun_p, SV **cckobj_p)
{
	SV *cckobj = sv_2mortal((SV*)newAV());
	av_extend((AV*)cckobj, 1);
	av_store((AV*)cckobj, 0, SvREFCNT_inc((SV*)ckfun));
	av_store((AV*)cckobj, 1, SvREFCNT_inc(ckobj));
	*cckfun_p = cckfun_perl_ckfun;
	*cckobj_p = cckobj;
}

#define ckfun_c_is_encoded_perl(cckfun) \
	THX_ckfun_c_is_encoded_perl(aTHX_ cckfun)
static bool THX_ckfun_c_is_encoded_perl(pTHX_ Perl_call_checker cckfun)
{
	return cckfun == cckfun_perl_ckfun;
}

#define ckfun_decode_perl_as_c(cckfun, cckobj, ckfun_p, ckobj_p) \
	THX_ckfun_decode_perl_as_c(aTHX_ cckfun, cckobj, ckfun_p, ckobj_p)
static void THX_ckfun_decode_perl_as_c(pTHX_
	Perl_call_checker cckfun, SV *cckobj, CV **ckfun_p, SV **ckobj_p)
{
	SV **valp;
	PERL_UNUSED_ARG(cckfun);
	if(SvTYPE(cckobj) != SVt_PVAV || av_len((AV*)cckobj) != 1) {
		bad_args:
		croak("call checker shim called incorrectly");
	}
	*ckfun_p = (CV*)*av_fetch((AV*)cckobj, 0, 0);
	if(SvTYPE((SV*)*ckfun_p) != SVt_PVCV) goto bad_args;
	valp = av_fetch((AV*)cckobj, 1, 0);
	*ckobj_p = valp ? *valp : &PL_sv_undef;
}

static OP *cckfun_perl_ckfun(pTHX_ OP *entersubop, GV *namegv, SV *cckobj)
{
	SV *ckobj_st, *namegv_st, *entersubop_st, *ckobj;
	CV *ckfun;
	ckfun_decode_perl_as_c(0, cckobj, &ckfun, &ckobj);
	entersubop_st = encode_bop(entersubop);
	namegv_st = sv_2mortal(newRV_inc((SV*)namegv));
	ckobj_st = sv_2mortal(newRV_inc(ckobj));
	ENTER;
	{
		dSP;
		PUSHMARK(SP);
		EXTEND(SP, 3);
		PUSHs(entersubop_st);
		PUSHs(namegv_st);
		PUSHs(ckobj_st);
		PUTBACK;
		call_sv((SV*)ckfun, G_SCALAR);
		SPAGAIN;
		entersubop_st = POPs;
		PUTBACK;
	}
	LEAVE;
	return decode_bop(entersubop_st);
}

#define install_cv(cv, name) THX_install_cv(aTHX_ cv, name)
static void THX_install_cv(pTHX_ CV *cv, char const *name)
{
	GV *gv = gv_fetchpv(name, GV_ADDMULTI, SVt_PVCV);
	GvCV_set(gv, cv);
	GvCVGEN(gv) = 0;
	CvGV_set(cv, gv);
}

typedef SV *SVREF;

MODULE = B::CallChecker PACKAGE = B::CallChecker

PROTOTYPES: DISABLE

BOOT:
	ckfun_cap_map = ptr_table_new();
	stash_bop = gv_stashpvs("B::OP", 1);
	install_cv(ckfun_encode_c_as_perl(Perl_ck_entersub_args_proto),
		"B::CallChecker::ck_entersub_args_proto");
	install_cv(ckfun_encode_c_as_perl(Perl_ck_entersub_args_proto_or_list),
		"B::CallChecker::ck_entersub_args_proto_or_list");

void
cv_get_call_checker(CV *tgtcv)
PROTOTYPE: $
PREINIT:
	Perl_call_checker cckfun;
	SV *cckobj;
	CV *ckfun;
	SV *ckobj;
PPCODE:
	PUTBACK;
	cv_get_call_checker(tgtcv, &cckfun, &cckobj);
	if(ckfun_c_is_encoded_perl(cckfun)) {
		ckfun_decode_perl_as_c(cckfun, cckobj, &ckfun, &ckobj);
	} else {
		ckfun = ckfun_encode_c_as_perl(cckfun);
		ckobj = cckobj;
	}
	SPAGAIN;
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newRV_inc((SV*)ckfun)));
	PUSHs(sv_2mortal(newRV_inc(ckobj)));

void
cv_set_call_checker(CV *tgtcv, CV *ckfun, SVREF ckobj)
PROTOTYPE: $$$
PREINIT:
	Perl_call_checker cckfun;
	SV *cckobj;
CODE:
	PUTBACK;
	if(ckfun_perl_is_encoded_c(ckfun)) {
		cckfun = ckfun_decode_c_as_perl(ckfun);
		cckobj = ckobj;
	} else {
		ckfun_encode_perl_as_c(ckfun, ckobj, &cckfun, &cckobj);
	}
	cv_set_call_checker(tgtcv, cckfun, cckobj);
	SPAGAIN;

OP *
ck_entersub_args_list(OP *entersubop)
PROTOTYPE: $
CODE:
	PUTBACK;
	RETVAL = ck_entersub_args_list(entersubop);
	SPAGAIN;
OUTPUT:
	RETVAL
