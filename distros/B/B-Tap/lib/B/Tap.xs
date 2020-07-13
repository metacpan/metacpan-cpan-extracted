#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

static XOP my_xop_tap;
static XOP my_xop_push_sv;

static OP *XS_B_Tap_pp_push_sv(pTHX) {
    dXSARGS; dORIGMARK;

    SV* const sv = cSVOP_sv;
    /* I know what this temporary variable is ugly. Patches welcome. */
    SV * tmp = get_sv("B::Tap::_TMP", GV_ADD);
    sv_setsv(tmp, sv);

    /* Restore mark after work. */
    PUSHMARK(ORIGMARK);

    RETURN;
}

static OP *XS_B_Tap_pp_tap(pTHX) {
    dXSARGS; dORIGMARK;
    int i;
    SV *tmp;
    AV *ret = newAV();

    av_push(ret, newSViv(GIMME_V));
    if (GIMME_V == G_SCALAR) {
        SvREFCNT_inc(ST(0));
        av_push(ret, ST(0));
    } else if (GIMME_V == G_VOID) {
        /* do nothing */
    } else {
        AV * av = newAV();
        for (i=0; i<items; i++) {
            SvREFCNT_inc(ST(i));
            av_push(av, ST(i));
        }
        av_push(ret, newRV_noinc((SV*)av));
    }

    /* I know what this temporary variable is ugly. Patches welcome. */
    tmp = get_sv("B::Tap::_TMP", GV_ADD);
    if (SvROK(tmp) && SvTYPE(SvRV(tmp)) == SVt_PVAV) {
        av_push((AV*)SvRV(tmp), newRV_noinc((SV*)ret));
    } else {
        sv_dump(tmp);
        croak("ArrayRef is expected, but it's not ArrayRef.");
    }

    /* restore mark */
    PUSHMARK(ORIGMARK);

    RETURN;
}

/* characters, compatible with B::Concise */
static char tap_oa_char(int oa_class) {
    switch (oa_class) {
    /*
    case OA_OP:
        return '0'; */
    case OA_UNOP:
        return '1';
    case OA_BINOP:
        return '2';
    case OA_LOGOP:
        return '|';
    case OA_LISTOP:
        return '@';
    case OA_PMOP:
        return '/';
    case OA_SVOP:
        return '$';
        /*
    case OA_PVOP:
        return '"'; */
    case OA_LOOP:
        return '{';
    case OA_COP:
        return ';';
    case OA_PADOP:
        return '#';
    default:
        return '-'; /* unknown */
    }
}

#define OP_CLASS_EX(op) \
    ((op)->op_type == OP_NULL ? (PL_opargs[(op)->op_targ] & OA_CLASS_MASK) : OP_CLASS((op)))

static char OA_CHAR(pTHX_ OP *op) {
    return tap_oa_char(OP_CLASS_EX(op));
}

#define TAP_TRACE(op, depth) \
    { \
        int i; \
        for (i=0;i<depth; i++) { \
            PerlIO_printf(PerlIO_stderr(), " "); \
        } \
        PerlIO_printf(PerlIO_stderr(), " rewriting: <%c", OA_CHAR(aTHX_ op)); \
        PerlIO_printf(PerlIO_stderr(), "> "); \
        if (op->op_type == OP_NULL) { \
            PerlIO_printf(PerlIO_stderr(), "ex-%s", PL_op_name[op->op_targ]); \
        } else { \
            PerlIO_printf(PerlIO_stderr(), "%s", OP_NAME(op)); \
        } \
        PerlIO_printf(PerlIO_stderr(), "\n"); \
    }


#define RECURSE(next) rewrite_op(aTHX_ (OP*)next, orig, replacement, depth+1)
#define REPLACE(type, meth) \
    if (((type)target)->meth == orig) { \
        ((type)target)->meth = replacement; \
    } else {\
        RECURSE(((type)target)->meth); \
    }

static void rewrite_op(pTHX_ OP* target, OP* orig, OP* replacement, int depth) {
    /* TAP_TRACE(target, depth); */

    switch (OP_CLASS_EX(target)) {
    case OA_UNOP:
        REPLACE(UNOP*, op_first);
        break;
    case OA_BINOP:
        REPLACE(BINOP*, op_first);
        break;
    case OA_LOGOP:
        REPLACE(LOGOP*, op_first);
        REPLACE(LOGOP*, op_other);
        break;
    case OA_LISTOP:
        REPLACE(LOGOP*, op_first);
        break;
    }

    if (OpSIBLING(target)) {
        if (OpSIBLING(target) == orig) {
            OpMORESIB_set(target, replacement);
        } else {
            rewrite_op(aTHX_ (OP*)OpSIBLING(target), orig, replacement, depth);
        }
    }
}

#undef RECURSE

MODULE = B::Tap    PACKAGE = B::Tap

PROTOTYPES: DISABLE

BOOT:
    /* Register custom ops */
    XopENTRY_set(&my_xop_tap, xop_name, "b_tap_tap");
    XopENTRY_set(&my_xop_tap, xop_desc, "b_tap_tap");
    XopENTRY_set(&my_xop_tap, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ XS_B_Tap_pp_tap, &my_xop_tap);

    XopENTRY_set(&my_xop_push_sv, xop_name, "b_tap_push_sv");
    XopENTRY_set(&my_xop_push_sv, xop_desc, "b_Tap_push_sv");
    XopENTRY_set(&my_xop_push_sv, xop_class, OA_SVOP);
    Perl_custom_op_register(aTHX_ XS_B_Tap_pp_push_sv, &my_xop_push_sv);

    /* Register constats */
    HV* stash = gv_stashpvn("B::Tap", strlen("B::Tap"), TRUE);
    newCONSTSUB(stash, "G_SCALAR", newSViv(G_SCALAR));
    newCONSTSUB(stash, "G_ARRAY",  newSViv(G_ARRAY));
    newCONSTSUB(stash, "G_VOID",   newSViv(G_VOID));

void
_tap(opp, root_opp, buf)
    void* opp;
    void* root_opp;
    SV * buf;
CODE:
{
    /* Rewrite op tree. */
    OP * orig_op = (OP*)opp;
    OP * next_op = orig_op->op_next;
    OP * sibling_op = OpSIBLING(orig_op);

    /*
     * Before:
     *
     * (orig_op
     *     next:next_op
     *     sibling:sibling_op)
     *
     * After:
     *
     * (b_tap
     *     first:(orig_op next:(push_sv next:b_tap))
     *     last:(b_tap_push_sv next:b_tap)
     *     next:next_op
     *     sibling:sibling_op
     *     )
     */

    /* Create 'b_tap_push_sv' node */
    SVOP * push_sv = (SVOP*)newSVOP(OP_CONST, 0, buf);
    push_sv->op_type   = OP_CUSTOM;
    push_sv->op_ppaddr = XS_B_Tap_pp_push_sv;
    push_sv->op_flags  = OPf_WANT_LIST;
    push_sv->op_sv = buf;
    SvREFCNT_inc(buf);

    BINOP * b_tap = (BINOP*)newBINOP(OP_NULL, 0, orig_op, (OP*)push_sv);
    b_tap->op_type     = OP_CUSTOM;
    b_tap->op_ppaddr   = XS_B_Tap_pp_tap;
    b_tap->op_flags    = (orig_op->op_flags & OPf_WANT) | OPf_KIDS;
    b_tap->op_first    = orig_op;
    b_tap->op_last     = (OP*)push_sv;
    OpMORESIB_set(b_tap, sibling_op);

    orig_op->op_next   = (OP*)push_sv;
    push_sv->op_next   = (OP*)b_tap;
    b_tap->op_next     = next_op;

    rewrite_op(aTHX_ (OP*)root_opp, (OP*)orig_op, (OP*)b_tap, 0);
}

