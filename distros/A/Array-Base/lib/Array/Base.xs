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

#ifndef newSVpvs_share
# define newSVpvs_share(STR) newSVpvn_share(""STR"", sizeof(STR)-1, 0)
#endif /* !newSVpvs_share */

#ifndef SvSHARED_HASH
# define SvSHARED_HASH(SV) SvUVX(SV)
#endif /* !SvSHARED_HASH */

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

static SV *base_hint_key_sv;
static U32 base_hint_key_hash;
static OP *(*nxck_aelem)(pTHX_ OP *o);
static OP *(*nxck_aslice)(pTHX_ OP *o);
static OP *(*nxck_lslice)(pTHX_ OP *o);
static OP *(*nxck_av2arylen)(pTHX_ OP *o);
static OP *(*nxck_splice)(pTHX_ OP *o);
#if QHAVE_OP_AKEYS
static OP *(*nxck_keys)(pTHX_ OP *o);
#endif /* QHAVE_OP_AKEYS */
#if QHAVE_OP_AEACH
static OP *(*nxck_each)(pTHX_ OP *o);
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

static OP *myck_aelem(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *aop, *iop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		aop = cBINOPx(op)->op_first;
		iop = aop->op_sibling;
		if(!iop || iop->op_sibling) goto bad_ops;
		aop->op_sibling =
			op_contextualize(
				newBINOP(OP_I_SUBTRACT, 0, iop,
					newSVOP(OP_CONST, 0, newSViv(base))),
				G_SCALAR);
	}
	return nxck_aelem(aTHX_ op);
}

#define base_myck_slice(op, nxck) THX_base_myck_slice(aTHX_ op, nxck)
static OP *THX_base_myck_slice(pTHX_ OP *op, OP *(*nxck)(pTHX_ OP *o))
{
	IV base;
	if((base = current_base()) != 0) {
		OP *lop, *aop, *mop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying array base");
		}
		lop = cLISTOPx(op)->op_first;
		aop = lop->op_sibling;
		if(!aop || aop->op_sibling) goto bad_ops;
		lop->op_sibling = NULL;
		mop = op_contextualize(mapify_op(lop, base, OP_I_SUBTRACT),
			G_ARRAY);
		mop->op_sibling = aop;
		cLISTOPx(op)->op_first = mop;
	}
	return nxck(aTHX_ op);
}

static OP *myck_aslice(pTHX_ OP *op) {
	return base_myck_slice(op, nxck_aslice);
}

static OP *myck_lslice(pTHX_ OP *op) {
	return base_myck_slice(op, nxck_lslice);
}

static OP *myck_av2arylen(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		op = nxck_av2arylen(aTHX_ op);
		return newBINOP(OP_I_ADD, 0, op_contextualize(op, G_SCALAR),
				newSVOP(OP_CONST, 0, newSViv(base)));
	} else {
		return nxck_av2arylen(aTHX_ op);
	}
}

static OP *myck_splice(pTHX_ OP *op)
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
		aop = pop->op_sibling;
		if(!aop) goto bad_ops;
		iop = aop->op_sibling;
		if(iop) {
			OP *rest = iop->op_sibling;
			iop->op_sibling = NULL;
			iop = newBINOP(OP_I_SUBTRACT, 0,
					op_contextualize(iop, G_SCALAR),
					newSVOP(OP_CONST, 0, newSViv(base)));
			iop->op_sibling = rest;
			aop->op_sibling = iop;
		}
	}
	return nxck_splice(aTHX_ op);
}

#if QHAVE_OP_AKEYS
static OP *myck_keys(pTHX_ OP *op)
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
		return mapify_op(op_contextualize(nxck_keys(aTHX_ op), G_ARRAY),
			base, OP_I_ADD);
	} else {
		return nxck_keys(aTHX_ op);
	}
}
#endif /* QHAVE_OP_AKEYS */

#if QHAVE_OP_AEACH

static OP *pp_munge_aeach(pTHX)
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

static OP *myck_each(pTHX_ OP *op)
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
		op = newLISTOP(OP_LIST, 0, nxck_each(aTHX_ op),
					newSVOP(OP_CONST, 0, newSViv(base)));
		op->op_type = OP_REVERSE;
		op->op_ppaddr = pp_munge_aeach;
		return op;
	} else {
		return nxck_each(aTHX_ op);
	}
}

#endif /* QHAVE_OP_AEACH */

MODULE = Array::Base PACKAGE = Array::Base

PROTOTYPES: DISABLE

BOOT:
	base_hint_key_sv = newSVpvs_share("Array::Base/base");
	base_hint_key_hash = SvSHARED_HASH(base_hint_key_sv);
	nxck_aelem = PL_check[OP_AELEM]; PL_check[OP_AELEM] = myck_aelem;
	nxck_aslice = PL_check[OP_ASLICE]; PL_check[OP_ASLICE] = myck_aslice;
	nxck_lslice = PL_check[OP_LSLICE]; PL_check[OP_LSLICE] = myck_lslice;
	nxck_av2arylen = PL_check[OP_AV2ARYLEN];
		PL_check[OP_AV2ARYLEN] = myck_av2arylen;
	nxck_splice = PL_check[OP_SPLICE]; PL_check[OP_SPLICE] = myck_splice;
#if QHAVE_OP_AKEYS
	nxck_keys = PL_check[OP_KEYS]; PL_check[OP_KEYS] = myck_keys;
#endif /* QHAVE_OP_AKEYS */
#if QHAVE_OP_AEACH
	nxck_each = PL_check[OP_EACH]; PL_check[OP_EACH] = myck_each;
#endif /* QHAVE_OP_AEACH */

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
