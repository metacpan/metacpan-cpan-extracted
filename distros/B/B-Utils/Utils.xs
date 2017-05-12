#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "BUtils.h"
#include "ppport.h"

/* After 5.10, the CxLVAL macro was added. */
#ifndef CxLVAL
#  define CxLVAL(cx) cx->blk_sub.lval
#endif

#define MY_CXT_KEY "B::Utils::_guts" XS_VERSION

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
static char *BUtils_svclassnames[] = {
    "B::NULL",
    "B::IV",
    "B::NV",
    "B::RV",
    "B::PV",
    "B::PVIV",
    "B::PVNV",
    "B::PVMG",
    "B::BM",
#if PERL_VERSION >= 9
    "B::GV",
#endif
    "B::PVLV",
    "B::AV",
    "B::HV",
    "B::CV",
#if PERL_VERSION <= 8
    "B::GV",
#endif
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
    OPc_COP	/* 11 */
} BUtils_opclass;

static char *BUtils_opclassnames[] = {
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
    "B::COP"	
};

static BUtils_opclass
BUtils_cc_opclass(pTHX_ const OP *o)
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
BUtils_cc_opclassname(pTHX_ const OP *o)
{
    return BUtils_opclassnames[BUtils_cc_opclass(aTHX_ o)];
}

I32
BUtils_op_name_to_num(SV *name)
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
BUtils_make_sv_object(pTHX_ SV *arg, SV *sv)
{
    char *type = 0;
    IV iv;
    dMY_CXT;

    if (!type) {
	type = BUtils_svclassnames[SvTYPE(sv)];
	iv = PTR2IV(sv);
    }
    sv_setiv(newSVrv(arg, type), iv);
    return arg;
}

MODULE = B::Utils           PACKAGE = B::Utils
PROTOTYPES: DISABLE
