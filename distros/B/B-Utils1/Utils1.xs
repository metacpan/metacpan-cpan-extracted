#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "BUtils1.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

/* After 5.10, the CxLVAL macro was added. */
#ifndef CxLVAL
#  define CxLVAL(cx) cx->blk_sub.lval
#endif

#define MY_CXT_KEY "B::Utils1::_guts" XS_VERSION

typedef struct {
    int		x_walkoptree_debug;	/* Flag for walkoptree debug hook */
    SV *	x_specialsv_list[7];
} my_cxt_t;

START_MY_CXT

/* Stolen from B.xs */

/* XXX: This really need to be properly exported by the B module,
  possibly with custom .h retrieved by some extutil module for
  building, and we shall be able to simply reuse the public symbol
  from loaded module in run time.

  Beware of name clashes with CORE when loading the .so into the global namespace.
  It fails with strict linkers, HP-UX, OpenBSD and probably on darwin without -flat-namespace.
  "Can't make loaded symbols global on this platform while loading blib/arch/auto/B/Utils/Utils.sl
  at /opt/perl_32/lib/5.8.8/PA-RISC1.1-thread-multi/DynaLoader.pm line 230."
*/

#ifdef PERL_OBJECT
#undef PL_op_name
#undef PL_opargs 
#undef PL_op_desc
#define PL_op_name (get_op_names())
#define PL_opargs (get_opargs())
#define PL_op_desc (get_op_descs())
#endif

/* duplicated from B.xs. */
static char *BUtils1_svclassnames[] = {
    "B::NULL",
#if PERL_VERSION < 19
    "B::BIND",
#endif
    "B::IV",
    "B::NV",
#if PERL_VERSION <= 10
    "B::RV",
#endif
    "B::PV",
#if PERL_VERSION >= 19
    "B::INVLIST",
#endif
    "B::PVIV",
    "B::PVNV",
    "B::PVMG",
#if PERL_VERSION >= 11
    "B::REGEXP",
#endif
    "B::PVLV",
    "B::AV",
    "B::HV",
    "B::CV",
    "B::FM",
    "B::IO",
};

typedef enum {
    OPc_NULL,	/* 0 */
    OPc_BASEOP,	/* 1 */
    OPc_UNOP,	/* 2 */
    OPc_BINOP,	/* 3 */
    OPc_LOGOP,	/* 4 */
    OPc_LISTOP,	/* 5 */
    OPc_PMOP,	/* 6 */
    OPc_SVOP,	/* 7 */
    OPc_PADOP,	/* 8 */
    OPc_PVOP,	/* 9 */
    OPc_LOOP,	/* 10 */
    OPc_COP,	/* 11 */
    OPc_METHOP,	/* 12 */
    OPc_UNOP_AUX /* 13 */
} BUtils1_opclass;

static char *BUtils1_opclassnames[] = {
    "B::NULL",
    "B::OP",
    "B::UNOP",
    "B::BINOP",
    "B::LOGOP",
    "B::LISTOP",
    "B::PMOP",
    "B::SVOP",
    "B::PADOP",
    "B::PVOP",
    "B::LOOP",
    "B::COP",
    "B::METHOP",
    "B::UNOP_AUX"
};

static BUtils1_opclass
BUtils1_cc_opclass(pTHX_ const OP *o)
{
    if (!o)
	return OPc_NULL;

    if (o->op_type == 0)
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    if (o->op_type == OP_SASSIGN)
	return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);

#ifdef USE_ITHREADS
    if (o->op_type == OP_GV || o->op_type == OP_GVSV ||
	o->op_type == OP_AELEMFAST || o->op_type == OP_RCATLINE)
	return OPc_PADOP;
#endif

    switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
    case OA_BASEOP:
	return OPc_BASEOP;

    case OA_UNOP:
	return OPc_UNOP;

    case OA_BINOP:
	return OPc_BINOP;

    case OA_LOGOP:
	return OPc_LOGOP;

    case OA_LISTOP:
	return OPc_LISTOP;

    case OA_PMOP:
	return OPc_PMOP;

    case OA_SVOP:
	return OPc_SVOP;

    case OA_PADOP:
	return OPc_PADOP;

    case OA_PVOP_OR_SVOP:
        /*
         * Character translations (tr///) are usually a PVOP, keeping a 
         * pointer to a table of shorts used to look up translations.
         * Under utf8, however, a simple table isn't practical; instead,
         * the OP is an SVOP, and the SV is a reference to a swash
         * (i.e., an RV pointing to an HV).
         */
	return (o->op_private & (OPpTRANS_TO_UTF|OPpTRANS_FROM_UTF))
		? OPc_SVOP : OPc_PVOP;

    case OA_LOOP:
	return OPc_LOOP;

    case OA_COP:
	return OPc_COP;

    case OA_BASEOP_OR_UNOP:
	/*
	 * UNI(OP_foo) in toke.c returns token UNI or FUNC1 depending on
	 * whether parens were seen. perly.y uses OPf_SPECIAL to
	 * signal whether a BASEOP had empty parens or none.
	 * Some other UNOPs are created later, though, so the best
	 * test is OPf_KIDS, which is set in newUNOP.
	 */
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    case OA_FILESTATOP:
	/*
	 * The file stat OPs are created via UNI(OP_foo) in toke.c but use
	 * the OPf_REF flag to distinguish between OP types instead of the
	 * usual OPf_SPECIAL flag. As usual, if OPf_KIDS is set, then we
	 * return OPc_UNOP so that walkoptree can find our children. If
	 * OPf_KIDS is not set then we check OPf_REF. Without OPf_REF set
	 * (no argument to the operator) it's an OP; with OPf_REF set it's
	 * an SVOP (and op_sv is the GV for the filehandle argument).
	 */
	return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
#ifdef USE_ITHREADS
		(o->op_flags & OPf_REF) ? OPc_PADOP : OPc_BASEOP);
#else
		(o->op_flags & OPf_REF) ? OPc_SVOP : OPc_BASEOP);
#endif
    case OA_LOOPEXOP:
	/*
	 * next, last, redo, dump and goto use OPf_SPECIAL to indicate that a
	 * label was omitted (in which case it's a BASEOP) or else a term was
	 * seen. In this last case, all except goto are definitely PVOP but
	 * goto is either a PVOP (with an ordinary constant label), an UNOP
	 * with OPf_STACKED (with a non-constant non-sub) or an UNOP for
	 * OP_REFGEN (with goto &sub) in which case OPf_STACKED also seems to
	 * get set.
	 */
	if (o->op_flags & OPf_STACKED)
	    return OPc_UNOP;
	else if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
	    return OPc_PVOP;
    }
    warn("can't determine class of operator %s, assuming BASEOP\n",
	 PL_op_name[o->op_type]);
    return OPc_BASEOP;
}

char *
BUtils1_cc_opclassname(pTHX_ const OP *o)
{
    return BUtils1_opclassnames[BUtils1_cc_opclass(aTHX_ o)];
}

I32
BUtils1_op_name_to_num(SV *name)
{
    dTHX;
    char const *s;
    char *wanted = SvPV_nolen(name);
    int i =0;
    int topop = OP_max;

#ifdef PERL_CUSTOM_OPS
    topop--;
#endif

    if (SvIOK(name) && SvIV(name) >= 0 && SvIV(name) < topop)
        return SvIV(name);

    for (s = PL_op_name[i]; s; s = PL_op_name[++i]) {
        if (strEQ(s, wanted))
            return i;
    }
#ifdef PERL_CUSTOM_OPS
    if (PL_custom_op_names) {
        HE* ent;
        SV* value;
        /* This is sort of a hv_exists, backwards */
        (void)hv_iterinit(PL_custom_op_names);
        while ((ent = hv_iternext(PL_custom_op_names))) {
            if (strEQ(SvPV_nolen(hv_iterval(PL_custom_op_names,ent)),wanted))
                return OP_CUSTOM;
        }
    }
#endif

    croak("No such op \"%s\"", SvPV_nolen(name));

    return -1;
}

SV *
BUtils1_make_sv_object(pTHX_ SV *arg, SV *sv)
{
    char *type = 0;
    IV iv;
    dMY_CXT;

    if (!type) {
	type = BUtils1_svclassnames[SvTYPE(sv)];
	iv = PTR2IV(sv);
    }
    sv_setiv(newSVrv(arg, type), iv);
    return arg;
}

/* Stolen from pp_ctl.c (with modifications) */

static I32
BUtils1_dopoptosub_at(pTHX_ PERL_CONTEXT *cxstk, I32 startingblock)
{
    dTHR;
    I32 i;
    PERL_CONTEXT *cx;
    for (i = startingblock; i >= 0; i--) {
        cx = &cxstk[i];
        switch (CxTYPE(cx)) {
        default:
            continue;
        /*case CXt_EVAL:*/
        case CXt_SUB:
        /* In Perl 5.005, formats just used CXt_SUB */
#ifdef CXt_FORMAT
        case CXt_FORMAT:
#endif
            DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
            return i;
        }
    }
    return i;
}

static I32
BUtils1_dopoptosub(pTHX_ I32 startingblock)
{
    dTHR;
    return BUtils1_dopoptosub_at(aTHX_ cxstack, startingblock);
}

/* This function is based on the code of pp_caller */
PERL_CONTEXT*
BUtils1_op_upcontext(pTHX_ I32 count, COP **cop_p, PERL_CONTEXT **ccstack_p,
                    I32 *cxix_from_p, I32 *cxix_to_p)
{
    PERL_SI *top_si = PL_curstackinfo;
    I32 cxix = BUtils1_dopoptosub(aTHX_ cxstack_ix);
    PERL_CONTEXT *ccstack = cxstack;

    if (cxix_from_p) *cxix_from_p = cxstack_ix+1;
    if (cxix_to_p)   *cxix_to_p   = cxix;
    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si  = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = BUtils1_dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
                        if (cxix_to_p && cxix_from_p) *cxix_from_p = *cxix_to_p;
                        if (cxix_to_p) *cxix_to_p = cxix;
        }
        if (cxix < 0 && count == 0) {
                    if (ccstack_p) *ccstack_p = ccstack;
            return (PERL_CONTEXT *)0;
                }
        else if (cxix < 0)
            return (PERL_CONTEXT *)-1;
        if (PL_DBsub && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;

        if (cop_p) *cop_p = ccstack[cxix].blk_oldcop;
        cxix = BUtils1_dopoptosub_at(aTHX_ ccstack, cxix - 1);
                        if (cxix_to_p && cxix_from_p) *cxix_from_p = *cxix_to_p;
                        if (cxix_to_p) *cxix_to_p = cxix;
    }
    if (ccstack_p) *ccstack_p = ccstack;
    return &ccstack[cxix];
}

/* The most popular error message */
#define TOO_FAR \
  croak("want: Called from outside a subroutine")

/* Between 5.9.1 and 5.9.2 the retstack was removed, and the
   return op is now stored on the cxstack. */
#define HAS_RETSTACK (\
  PERL_REVISION < 5 || \
  (PERL_REVISION == 5 && PERL_VERSION < 9) || \
  (PERL_REVISION == 5 && PERL_VERSION == 9 && PERL_SUBVERSION < 2) \
)

OP*
BUtils1_find_return_op(pTHX_ I32 uplevel)
{
    PERL_CONTEXT *cx = BUtils1_op_upcontext(aTHX_ uplevel, 0, 0, 0, 0);
    if (!cx) TOO_FAR;
#if HAS_RETSTACK
    return PL_retstack[cx->blk_oldretsp - 1];
#else
    return cx->blk_sub.retop;
#endif
}

OP*
BUtils1_find_oldcop(pTHX_ I32 uplevel)
{
    PERL_CONTEXT *cx = BUtils1_op_upcontext(aTHX_ uplevel, 0, 0, 0, 0);
    if (!cx) TOO_FAR;
    return (OP*) cx->blk_oldcop;
}

MODULE = B::Utils1::OP           PACKAGE = B::Utils1::OP        PREFIX = BUtils1_OP_
PROTOTYPES: DISABLE

B::OP
parent_op(I32 uplevel)
  CODE:
    RETVAL = BUtils1_find_oldcop(aTHX_ uplevel);
  OUTPUT:
    RETVAL

B::OP
return_op(I32 uplevel)
  CODE:
    RETVAL = BUtils1_find_return_op(aTHX_ uplevel);
  OUTPUT:
    RETVAL

MODULE = B::Utils1           PACKAGE = B::Utils1
PROTOTYPES: DISABLE

