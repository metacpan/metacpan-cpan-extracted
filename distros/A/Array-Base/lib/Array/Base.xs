#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#define QHAVE_OP_AEACH PERL_VERSION_GE(5,11,0)
#define QHAVE_OP_AKEYS PERL_VERSION_GE(5,11,0)
#define QHAVE_OP_KVASLICE PERL_VERSION_GE(5,19,4)

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef newSVpvs_share
# define newSVpvs_share(STR) newSVpvn_share(""STR"", sizeof(STR)-1, 0)
#endif /* !newSVpvs_share */

#ifndef SvSHARED_HASH
# define SvSHARED_HASH(SV) SvUVX(SV)
#endif /* !SvSHARED_HASH */

#ifndef OpMORESIB_set
# define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
#endif /* !OpMORESIB_set */
#ifndef OpSIBLING
# define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
# define OpSIBLING(o) (0 + (o)->op_sibling)
#endif /* !OpSIBLING */

#ifndef op_contextualize
# define scalar(op) Perl_scalar(aTHX_ op)
# define list(op) Perl_list(aTHX_ op)
# define scalarvoid(op) Perl_scalarvoid(aTHX_ op)
# define op_contextualize(op, c) THX_op_contextualize(aTHX_ op, c)
static OP *THX_op_contextualize(pTHX_ OP *o, I32 context)
{
	switch (context) {
		case G_SCALAR: return scalar(o);
		case G_ARRAY:  return list(o);
		case G_VOID:   return scalarvoid(o);
		default:
			croak("panic: op_contextualize bad context");
			return o;
	}
}
#endif /* !op_contextualize */

#if !PERL_VERSION_GE(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
#endif /* <5.9.3 */

#if !PERL_VERSION_GE(5,10,1)
typedef unsigned Optype;
#endif /* <5.10.1 */

#ifndef wrap_op_checker
# define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
static void THX_wrap_op_checker(pTHX_ Optype opcode,
	Perl_check_t new_checker, Perl_check_t *old_checker_p)
{
	if(*old_checker_p) return;
	OP_REFCNT_LOCK;
	if(!*old_checker_p) {
		*old_checker_p = PL_check[opcode];
		PL_check[opcode] = new_checker;
	}
	OP_REFCNT_UNLOCK;
}
#endif /* !wrap_op_checker */

static SV *base_hint_key_sv;
static U32 base_hint_key_hash;
static OP *(*THX_nxck_aelem)(pTHX_ OP *o);
static OP *(*THX_nxck_aslice)(pTHX_ OP *o);
#if QHAVE_OP_KVASLICE
static OP *(*THX_nxck_kvaslice)(pTHX_ OP *o);
#endif /* QHAVE_OP_KVASLICE */
static OP *(*THX_nxck_lslice)(pTHX_ OP *o);
static OP *(*THX_nxck_av2arylen)(pTHX_ OP *o);
static OP *(*THX_nxck_splice)(pTHX_ OP *o);
#if QHAVE_OP_AKEYS
static OP *(*THX_nxck_keys)(pTHX_ OP *o);
#endif /* QHAVE_OP_AKEYS */
#if QHAVE_OP_AEACH
static OP *(*THX_nxck_each)(pTHX_ OP *o);
#endif /* QHAVE_OP_AEACH */

#define current_base() THX_current_base(aTHX)
static IV THX_current_base(pTHX)
{
	HE *base_ent = hv_fetch_ent(GvHV(PL_hintgv), base_hint_key_sv, 0,
					base_hint_key_hash);
	return base_ent ? SvIV(HeVAL(base_ent)) : 0;
}

#define mapify_op(lop, base, type) THX_mapify_op(aTHX_ lop, base, type)
static OP *THX_mapify_op(pTHX_ OP *lop, IV base, U16 type)
{
	OP *mop = newLISTOP(OP_LIST, 0,
			newBINOP(type, 0,
				newGVOP(OP_GVSV, 0, PL_defgv),
				newSVOP(OP_CONST, 0, newSViv(base))),
			lop);
	mop->op_type = OP_MAPSTART;
	mop->op_ppaddr = PL_ppaddr[OP_MAPSTART];
	mop = PL_check[OP_MAPSTART](aTHX_ mop);
#ifdef OPpGREP_LEX
	if(mop->op_type == OP_MAPWHILE) {
		mop->op_private &= ~OPpGREP_LEX;
		if(cLISTOPx(mop)->op_first->op_type == OP_MAPSTART)
			cLISTOPx(mop)->op_first->op_private &=
				~OPpGREP_LEX;
	}
#endif /* OPpGREP_LEX */
	return mop;
}

static OP *THX_myck_aelem(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *aop, *iop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		aop = cBINOPx(op)->op_first;
		iop = OpSIBLING(aop);
		if(!iop || OpHAS_SIBLING(iop)) goto bad_ops;
		OpLASTSIB_set(aop, op);
		cBINOPx(op)->op_last = NULL;
		OpLASTSIB_set(iop, NULL);
		iop = op_contextualize(
				newBINOP(OP_I_SUBTRACT, 0, iop,
					newSVOP(OP_CONST, 0, newSViv(base))),
				G_SCALAR);
		OpMORESIB_set(aop, iop);
		OpLASTSIB_set(iop, op);
		cBINOPx(op)->op_last = iop;
	}
	return THX_nxck_aelem(aTHX_ op);
}

static OP *THX_myck_aslice(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *iop, *aop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		iop = cLISTOPx(op)->op_first;
		aop = OpSIBLING(iop);
		if(!aop || OpHAS_SIBLING(aop)) goto bad_ops;
		OpLASTSIB_set(iop, NULL);
		cLISTOPx(op)->op_first = aop;
		iop = op_contextualize(mapify_op(iop, base, OP_I_SUBTRACT),
			G_ARRAY);
		OpMORESIB_set(iop, aop);
		cLISTOPx(op)->op_first = iop;
	}
	return THX_nxck_aslice(aTHX_ op);
}

#if QHAVE_OP_KVASLICE

static OP *THX_pp_munge_kvaslice(pTHX)
{
	dSP; dMARK;
	if(SP != MARK) {
		SV **kp;
		IV base = POPi;
		PUTBACK;
		if(MARK+1 != SP) {
			for(kp = MARK; kp != SP; kp += 2) {
				SV *k = kp[1];
				if(SvOK(k))
					kp[1] = sv_2mortal(
						newSViv(SvIV(k) + base));
			}
		}
	}
	return PL_op->op_next;
}

#define newUNOP_munge_kvaslice(f, l) THX_newUNOP_munge_kvaslice(aTHX_ f, l)
static OP *THX_newUNOP_munge_kvaslice(pTHX_ OP *kvasliceop, OP *baseop)
{
	OP *mungeop, *pushop;
	pushop = newOP(OP_PUSHMARK, 0);
	NewOpSz(0, mungeop, sizeof(UNOP));
#ifdef XopENTRY_set
	mungeop->op_type = OP_CUSTOM;
#else /* !XopENTRY_set */
	mungeop->op_type = OP_DOFILE;
#endif /* !XopENTRY_set */
	mungeop->op_ppaddr = THX_pp_munge_kvaslice;
	mungeop->op_flags = OPf_KIDS;
	cUNOPx(mungeop)->op_first = pushop;
	OpMORESIB_set(pushop, kvasliceop);
	OpMORESIB_set(kvasliceop, baseop);
	OpLASTSIB_set(baseop, mungeop);
	return mungeop;
}

static OP *THX_myck_kvaslice(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *iop, *aop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		iop = cLISTOPx(op)->op_first;
		aop = OpSIBLING(iop);
		if(!aop || OpHAS_SIBLING(aop)) goto bad_ops;
		/*
		 * A kvaslice op is built in a nasty way that interferes
		 * with munging it through a checker.  It's first built
		 * containing the interesting operands, but missing a
		 * necessary pushmark op.  The checker gets invoked on
		 * this incomplete op.	Then the pushmark gets inserted,
		 * without invoking any checker, provided that the op is
		 * still of type kvaslice.  If the checker changed the op
		 * type, then instead a new kvaslice gets built containing
		 * the pushmark and whatever the checker returned,
		 * and the checker gets invoked a second time on that.
		 *
		 * The incomplete structure the first time round
		 * means we can't very well wrap the op at that point.
		 * We can munge the operands, but the wrapping needs to
		 * be postponed until after the pushmark gets inserted.
		 * But to get any control after the pushmark is inserted,
		 * we have to change the op type the first time round,
		 * so that we get invoked a second time.  We can detect
		 * which stage of op construction we're at by seeing
		 * whether the first child is a pushmark.
		 */
		if(iop->op_type == OP_PUSHMARK)
			return newUNOP_munge_kvaslice(
					THX_nxck_kvaslice(aTHX_ op),
					newSVOP(OP_CONST, 0, newSViv(base)));
		OpLASTSIB_set(iop, NULL);
		cLISTOPx(op)->op_first = aop;
		iop = op_contextualize(mapify_op(iop, base, OP_I_SUBTRACT),
			G_ARRAY);
		OpMORESIB_set(iop, aop);
		cLISTOPx(op)->op_first = iop;
		op_null(op);
		return op;
	} else {
		return THX_nxck_kvaslice(aTHX_ op);
	}
}

#endif /* QHAVE_OP_KVASLICE */

static OP *THX_myck_lslice(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *iop, *aop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		iop = cBINOPx(op)->op_first;
		aop = OpSIBLING(iop);
		if(!aop || OpHAS_SIBLING(aop)) goto bad_ops;
		OpLASTSIB_set(iop, NULL);
		cBINOPx(op)->op_first = aop;
		cBINOPx(op)->op_last = NULL;
		iop = op_contextualize(mapify_op(iop, base, OP_I_SUBTRACT),
			G_ARRAY);
		OpMORESIB_set(iop, aop);
		cBINOPx(op)->op_first = iop;
		cBINOPx(op)->op_last = aop;
	}
	return THX_nxck_lslice(aTHX_ op);
}

static OP *THX_myck_av2arylen(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		op = THX_nxck_av2arylen(aTHX_ op);
		return newBINOP(OP_I_ADD, 0, op_contextualize(op, G_SCALAR),
				newSVOP(OP_CONST, 0, newSViv(base)));
	} else {
		return THX_nxck_av2arylen(aTHX_ op);
	}
}

static OP *THX_myck_splice(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *pop, *aop, *iop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		pop = cLISTOPx(op)->op_first;
		if(pop->op_type != OP_PUSHMARK) goto bad_ops;
		aop = OpSIBLING(pop);
		if(!aop) goto bad_ops;
		iop = OpSIBLING(aop);
		if(iop) {
			OP *rest = OpSIBLING(iop);
			OpMAYBESIB_set(aop, rest, op);
			OpLASTSIB_set(iop, NULL);
			if(!rest) cLISTOPx(op)->op_last = aop;
			iop = newBINOP(OP_I_SUBTRACT, 0,
					op_contextualize(iop, G_SCALAR),
					newSVOP(OP_CONST, 0, newSViv(base)));
			OpMAYBESIB_set(iop, rest, op);
			OpMORESIB_set(aop, iop);
			if(!rest) cLISTOPx(op)->op_last = iop;
		}
	}
	return THX_nxck_splice(aTHX_ op);
}

#if QHAVE_OP_AKEYS
static OP *THX_myck_keys(pTHX_ OP *op)
{
	/*
	 * Annoyingly, keys(@array) ops don't go through the nominal
	 * checker for OP_AKEYS.  Instead they start out as OP_KEYS,
	 * and get mutated to OP_AKEYS by the OP_KEYS checker.  This
	 * is therefore what we have to hook.
	 */
	OP *aop;
	IV base;
	if((op->op_flags & OPf_KIDS) && (aop = cUNOPx(op)->op_first, 1) &&
			(aop->op_type == OP_PADAV ||
			 aop->op_type == OP_RV2AV) &&
			(base = current_base()) != 0) {
		return mapify_op(
			op_contextualize(THX_nxck_keys(aTHX_ op), G_ARRAY),
			base, OP_I_ADD);
	} else {
		return THX_nxck_keys(aTHX_ op);
	}
}
#endif /* QHAVE_OP_AKEYS */

#if QHAVE_OP_AEACH

static OP *THX_pp_munge_aeach(pTHX)
{
	dSP; dMARK;
	if(SP != MARK) {
		IV base = POPi;
		if(SP != MARK && SvOK(MARK[1]))
			MARK[1] = sv_2mortal(newSViv(SvIV(MARK[1]) + base));
		PUTBACK;
	}
	return PL_op->op_next;
}

#define newUNOP_munge_aeach(f, l) THX_newUNOP_munge_aeach(aTHX_ f, l)
static OP *THX_newUNOP_munge_aeach(pTHX_ OP *aeachop, OP *baseop)
{
	OP *mungeop, *pushop;
	pushop = newOP(OP_PUSHMARK, 0);
	NewOpSz(0, mungeop, sizeof(UNOP));
#ifdef XopENTRY_set
	mungeop->op_type = OP_CUSTOM;
#else /* !XopENTRY_set */
	mungeop->op_type = OP_DOFILE;
#endif /* !XopENTRY_set */
	mungeop->op_ppaddr = THX_pp_munge_aeach;
	mungeop->op_flags = OPf_KIDS;
	cUNOPx(mungeop)->op_first = pushop;
	OpMORESIB_set(pushop, aeachop);
	OpMORESIB_set(aeachop, baseop);
	OpLASTSIB_set(baseop, mungeop);
	return mungeop;
}

static OP *THX_myck_each(pTHX_ OP *op)
{
	/*
	 * Annoyingly, each(@array) ops don't go through the nominal
	 * checker for OP_AEACH.  Instead they start out as OP_EACH,
	 * and get mutated to OP_AEACH by the OP_EACH checker.  This
	 * is therefore what we have to hook.
	 */
	OP *aop;
	IV base;
	if((op->op_flags & OPf_KIDS) && (aop = cUNOPx(op)->op_first, 1) &&
			(aop->op_type == OP_PADAV ||
			 aop->op_type == OP_RV2AV) &&
			(base = current_base()) != 0) {
		return newUNOP_munge_aeach(THX_nxck_each(aTHX_ op),
					newSVOP(OP_CONST, 0, newSViv(base)));
	} else {
		return THX_nxck_each(aTHX_ op);
	}
}

#endif /* QHAVE_OP_AEACH */

MODULE = Array::Base PACKAGE = Array::Base

PROTOTYPES: DISABLE

BOOT:
{
#ifdef XopENTRY_set
	XOP *xop;
	Newxz(xop, 1, XOP);
	XopENTRY_set(xop, xop_name, "munge_aeach");
	XopENTRY_set(xop, xop_desc, "fixup following each on array");
	XopENTRY_set(xop, xop_class, OA_UNOP);
	Perl_custom_op_register(aTHX_ THX_pp_munge_aeach, xop);
# if QHAVE_OP_KVASLICE
	Newxz(xop, 1, XOP);
	XopENTRY_set(xop, xop_name, "munge_kvaslice");
	XopENTRY_set(xop, xop_desc, "fixup following pair slice on array");
	XopENTRY_set(xop, xop_class, OA_UNOP);
	Perl_custom_op_register(aTHX_ THX_pp_munge_kvaslice, xop);
# endif /* QHAVE_OP_KVASLICE */
#endif /* XopENTRY_set */
}

BOOT:
{
	base_hint_key_sv = newSVpvs_share("Array::Base/base");
	base_hint_key_hash = SvSHARED_HASH(base_hint_key_sv);
	wrap_op_checker(OP_AELEM, THX_myck_aelem, &THX_nxck_aelem);
	wrap_op_checker(OP_ASLICE, THX_myck_aslice, &THX_nxck_aslice);
#if QHAVE_OP_KVASLICE
	wrap_op_checker(OP_KVASLICE, THX_myck_kvaslice, &THX_nxck_kvaslice);
#endif /* QHAVE_OP_KVASLICE */
	wrap_op_checker(OP_LSLICE, THX_myck_lslice, &THX_nxck_lslice);
	wrap_op_checker(OP_AV2ARYLEN, THX_myck_av2arylen, &THX_nxck_av2arylen);
	wrap_op_checker(OP_SPLICE, THX_myck_splice, &THX_nxck_splice);
#if QHAVE_OP_AKEYS
	wrap_op_checker(OP_KEYS, THX_myck_keys, &THX_nxck_keys);
#endif /* QHAVE_OP_AKEYS */
#if QHAVE_OP_AEACH
	wrap_op_checker(OP_EACH, THX_myck_each, &THX_nxck_each);
#endif /* QHAVE_OP_AEACH */
}

void
import(SV *classname, IV base)
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	if(base == 0) {
		(void) hv_delete_ent(GvHV(PL_hintgv), base_hint_key_sv,
				G_DISCARD, base_hint_key_hash);
	} else {
		SV *base_sv = newSViv(base);
		HE *he = hv_store_ent(GvHV(PL_hintgv), base_hint_key_sv,
				base_sv, base_hint_key_hash);
		if(he) {
			SV *val = HeVAL(he);
			SvSETMAGIC(val);
		} else {
			SvREFCNT_dec(base_sv);
		}
	}

void
unimport(SV *classname)
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	(void) hv_delete_ent(GvHV(PL_hintgv), base_hint_key_sv,
			G_DISCARD, base_hint_key_hash);
