/*
@(#)File:           $RCSfile: decsetexp.c,v $
@(#)Version:        $Revision: 2.5 $
@(#)Last changed:   $Date: 2008/01/28 05:25:26 $
@(#)Purpose:        Format the exponent of a DECIMAL
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2001,2005,2007-08
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

/*TABSTOP=4*/

#include "decsci.h"

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_decsetexp_c[] = "@(#)$Id: decsetexp.c,v 2.5 2008/01/28 05:25:26 jleffler Exp $";
#endif /* lint */

/* Format an exponent */
char    *dec_setexp(char  *dst, int dp)
{
    *dst++ = 'E';
    if (dp >= 0)
        *dst++ = '+';
    else
    {
        *dst++ = '-';
        dp = -dp;
    }
    if (dp / 100 != 0)
        *dst++ = dp / 100 + '0';
    *dst++ = (dp / 10) % 10 + '0';
    *dst++ = (dp % 10) + '0';
    if (dp / 100 == 0)
        *dst++ = ' ';
    *dst = '\0';
    return(dst);
}

#ifdef TEST

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "phasedtest.h"

typedef struct Test
{
    int     val;
    char    *res;
}   Test;

static Test p1_test[] =
{
    {   0,      "E+00 " },
    {   -1,     "E-01 " },
    {   -2,     "E-02 " },
    {   -3,     "E-03 " },
    {   -10,    "E-10 " },
    {   -20,    "E-20 " },
    {   -99,    "E-99 " },
    {   -100,   "E-100" },
    {   -120,   "E-120" },
    {   +1,     "E+01 " },
    {   +2,     "E+02 " },
    {   +3,     "E+03 " },
    {   +10,    "E+10 " },
    {   +20,    "E+20 " },
    {   +99,    "E+99 " },
    {   +100,   "E+100" },
    {   +120,   "E+120" },
};

static void p1_tester(const void *data)
{
    const Test *test = (const Test *)data;
    char buffer[10];

    dec_setexp(buffer, test->val);
    if (strcmp(test->res, buffer) != 0)
        pt_fail("in = %4d, got <%s>, wanted <%s>\n", test->val,
                buffer, test->res);
    else
        pt_pass("in = %4d, got <%s> as expected\n", test->val, test->res);
}

static pt_auto_phase phases[] =
{
    { p1_tester, PT_ARRAYINFO(p1_test), 0, "Test decsetexp()" },
};

int main(int argc, char **argv)
{
    return(pt_auto_harness(argc, argv, phases, DIM(phases)));
}

#endif /* TEST */
