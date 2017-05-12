/* $Id: Amb.xs,v 1.2 2008/07/02 09:54:04 dk Exp $ */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Amb           PACKAGE = Amb

SV*
context_cv(context)
SV* context;
  CODE:
    /* stolen from Devel::Caller */
    PERL_CONTEXT *cx = INT2PTR(PERL_CONTEXT *, SvIV(context));
    CV *cur_cv;

    if (cx->cx_type != CXt_SUB)
        croak("cx_type is %d not CXt_SUB\n", cx->cx_type);

    cur_cv = cx->blk_sub.cv;
    if (!cur_cv)
        croak("Context has no CV!\n");

    RETVAL = (SV*) newRV_inc( (SV*) cur_cv );
  OUTPUT:
    RETVAL


SV*
caller_op(context)
SV* context;
  CODE:
    /* stolen from Devel::Caller */
    PERL_CONTEXT *cx = INT2PTR(PERL_CONTEXT*, SvIV(context));
    OP *op = (OP*)cx->blk_oldcop;
    SV *rv = newSV(0);
    sv_setref_iv(rv, "B::COP", PTR2IV(op));
    RETVAL = rv;
  OUTPUT:
    RETVAL

