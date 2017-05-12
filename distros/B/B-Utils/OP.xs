#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "BUtils.h"

/* Stolen from pp_ctl.c (with modifications) */

static I32
BUtils_dopoptosub_at(pTHX_ PERL_CONTEXT *cxstk, I32 startingblock)
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
BUtils_dopoptosub(pTHX_ I32 startingblock)
{
    dTHR;
    return BUtils_dopoptosub_at(aTHX_ cxstack, startingblock);
}

/* This function is based on the code of pp_caller */
PERL_CONTEXT*
BUtils_op_upcontext(pTHX_ I32 count, COP **cop_p, PERL_CONTEXT **ccstack_p,
                    I32 *cxix_from_p, I32 *cxix_to_p)
{
    PERL_SI *top_si = PL_curstackinfo;
    I32 cxix = BUtils_dopoptosub(aTHX_ cxstack_ix);
    PERL_CONTEXT *ccstack = cxstack;

    if (cxix_from_p) *cxix_from_p = cxstack_ix+1;
    if (cxix_to_p)   *cxix_to_p   = cxix;
    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si  = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = BUtils_dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
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
        cxix = BUtils_dopoptosub_at(aTHX_ ccstack, cxix - 1);
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
BUtils_find_return_op(pTHX_ I32 uplevel)
{
    PERL_CONTEXT *cx = BUtils_op_upcontext(aTHX_ uplevel, 0, 0, 0, 0);
    if (!cx) TOO_FAR;
#if HAS_RETSTACK
    return PL_retstack[cx->blk_oldretsp - 1];
#else
    return cx->blk_sub.retop;
#endif
}

OP*
BUtils_find_oldcop(pTHX_ I32 uplevel)
{
    PERL_CONTEXT *cx = BUtils_op_upcontext(aTHX_ uplevel, 0, 0, 0, 0);
    if (!cx) TOO_FAR;
    return (OP*) cx->blk_oldcop;
}


MODULE = B::Utils::OP           PACKAGE = B::Utils::OP        PREFIX = BUtils_OP_
PROTOTYPES: DISABLE

B::OP
parent_op(I32 uplevel)
  CODE:
    RETVAL = BUtils_find_oldcop(aTHX_ uplevel);
  OUTPUT:
    RETVAL

B::OP
return_op(I32 uplevel)
  CODE:
    RETVAL = BUtils_find_return_op(aTHX_ uplevel);
  OUTPUT:
    RETVAL

