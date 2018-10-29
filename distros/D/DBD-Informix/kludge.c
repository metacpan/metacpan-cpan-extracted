/*
@(#)File:           $RCSfile: kludge.c,v $
@(#)Version:        $Revision: 1.13 $
@(#)Last changed:   $Date: 2018/04/29 00:40:56 $
@(#)Purpose:        Library support for KLUDGE macro
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1995-2018
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
*/

/*TABSTOP=4*/

#include "kludge.h"

#include <assert.h>
#ifdef KLUDGE_VERBOSE
#include <stdio.h>
#else
#include <string.h>
#endif /* KLUDGE_VERBOSE */

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
extern const char jlss_id_kludge_c[];
const char jlss_id_kludge_c[] = "@(#)$Id: kludge.c,v 1.13 2018/04/29 00:40:56 jleffler Exp $";
#endif /* lint */

#ifndef KLUDGE_DISABLE
/*
** The function should return 1 each time it is called, whether compiled
** with -DKLUDGE_VERBOSE or not.
**
** It is hard preventing modern compilers from optimizing away the
** recursive invocation implied by the FEATURE_FILE macro.  Using common
** built-ins like strlen() or strcmp() doesn't work, so for the time
** being, the code uses strxfrm() instead.  Since the result depends on
** the run-time locale, it can't easily be removed by the optimizer.
** The residual question is "what is its cost", which is hard to know.
** At worst, it gets called once per feature or kludge in the code per
** run, so the cost should be bearable.
*/

/* Possibly report on kludges used at run-time */
int kludge_use(const char *str)
{
    assert(str != 0 && *str != '\0');
#ifdef KLUDGE_VERBOSE
    FEATURE_FILE("KLUDGE Verbose");
    return fprintf(stderr, "%s\n", str) > 0;
#else
    FEATURE_FILE("KLUDGE Quiet");
    return strxfrm(0, str, 0) != 0;
#endif /* KLUDGE_VERBOSE */
}
#endif /* KLUDGE_DISABLE */
