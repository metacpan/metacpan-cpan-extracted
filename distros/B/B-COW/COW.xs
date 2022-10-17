/*
*
* Copyright (c) 2018, Nicolas R.
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

#if defined(SV_COW_REFCNT_MAX)
#   define B_CAN_COW 1
#else
#   define B_CAN_COW 0
#endif

/* CowREFCNT is incorrect on Perl < 5.32 */
#define myCowREFCNT(sv)   ((SvLEN(sv)>0) ? CowREFCNT(sv) : 0)

MODULE = B__COW       PACKAGE = B::COW

PROTOTYPES: DISABLE

SV*
can_cow()
CODE:
{
#if B_CAN_COW
    XSRETURN_YES;
#else
    XSRETURN_NO;
#endif
}
OUTPUT:
     RETVAL

SV*
is_cow(sv)
  SV *sv;
CODE:
{
/* not exactly accurate but let's start there  */
#if !B_CAN_COW
    XSRETURN_UNDEF;
#else
    if ( SvPOK(sv) && SvIsCOW(sv) ) XSRETURN_YES;
#endif
    XSRETURN_NO;
}
OUTPUT:
     RETVAL

SV*
cowrefcnt(sv)
  SV *sv;
CODE:
{
#if !B_CAN_COW
    XSRETURN_UNDEF;
#else
    if ( SvIsCOW(sv) ) XSRETURN_IV( myCowREFCNT(sv) );
#endif
    XSRETURN_UNDEF;
}
OUTPUT:
     RETVAL

SV*
cowrefcnt_max()
CODE:
{
#if !B_CAN_COW
    XSRETURN_UNDEF;
#else  
  XSRETURN_IV(SV_COW_REFCNT_MAX);
#endif
}
OUTPUT:
     RETVAL
