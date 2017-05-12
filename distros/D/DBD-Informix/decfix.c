/*
@(#)File:           $RCSfile: decfix.c,v $
@(#)Version:        $Revision: 3.17 $
@(#)Last changed:   $Date: 2008/08/31 11:54:43 $
@(#)Purpose:        Fixed formatting of DECIMALs
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1991-93,1996-97,1999,2001,2003,2005,2007-08
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

#include <assert.h>
#include <string.h>
#include <stdio.h>
#include "decsci.h"

/*
** JL - 2001-10-04
** NB: The functions here have not been internationalized at all: there
** is no provision for a decimal point other than period, and there is
** no provision for grouping either before or after the decimal point.
** There is no provision for for omitting the decimal point for 0
** decimal places.
*/

/*
** Suppose the value to be printed is 1E+130 yet the user wants to
** accommodate values down to 1.000000000000000000000000000001E-130.
** This requires a buffer with 130 digits before the point, and 162
** after, plus the decimal point, and the sign, and the null!  That
** is a grand total of 295 characters (call it 300).  If you were to
** put commas every three digits before the point, you'd add another
** 45 characters; for commas every three places after the point, yet
** another 55, requiring 400 characters or so!
** Ouch!!
** This is why exponential notation is used!
** It is also fair to note that you use fixed notation only when the
** range of values you will deal with is appropriately constrained,
** which is normally the case in practice.
*/

enum { MAX_FIXDECSTRLEN = 166 };

#define MAX(x,y)	(((x)>(y))?(x):(y))
#define MIN(x,y)	(((x)<(y))?(x):(y))
#define SIGN(s, p)  ((s) ? '-' : ((p) ? '+' : ' '))
#define VALID(n)	(((n) <= 0) ? 0 : (((n) > 162) ? 162 : (n)))

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_decfix_c[] = "@(#)$Id: decfix.c,v 3.17 2008/08/31 11:54:43 jleffler Exp $";
#endif /* lint */

/*
** Formatting fixed-point numbers:
** -- Eliminate null quickly.
** -- Round a copy of the value.
** -- Generate sign.
** -- Process zero because it is easy.
** -- Format digits before decimal point, if any.
** --     If (dec_exp > 0) then
** --         Add MIN(dec_exp, dec_ndgts) digit pairs, chopping (one) leading zero.
** --         Add pairs of zeroes if we aren't at dec_exp.
** --     Else add a single zero
** -- Format digits after decimal point, if any.
** --     Add any needed leading zeroes (dec_exp < 0).
** --     Add MIN(MAX(dec_ndgt - dec_exp, 0), (nfrac+1)/2) digit pairs.
** --     Add zeroes if we aren't at nfrac.
** --     Note that there might be some leading zeroes required...
** --     Must not drop zeroes after decimal point.
*/

/* dec_fix() - format a fixed-point DECIMAL number */
int dec_fix(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen)
{
	char     *dst = buffer;
	size_t    i;
	ifx_dec_t dv;
	size_t len;

	/* Deal with null values first */
	if (dec_eq_null(d))
	{
		*dst = '\0';
		return(0);
	}

	dv = *d;
	ndigit = VALID(ndigit);
	decround(&dv, ndigit);

	*dst++ = SIGN(!d->dec_pos, plus);	/* Sign */

	if (dec_eq_zero(&dv))
	{
		len = ndigit + sizeof("+0.");
		if (buflen < len + 1)
		{
			*buffer = '\0';
			return(-1);		/* Buffer too short */
		}
		else
		{
			*dst++ = '0';
            if (ndigit > 0)
            {
                *dst++ = '.';
                memset(dst, '0', ndigit);
            }
			dst[ndigit] = '\0';
			return(0);
		}
	}

	if (dv.dec_exp > 0) 
		len = 2 * dv.dec_exp - (dv.dec_dgts[0] < 10) + ndigit + sizeof("+.");
	else
		len = ndigit + sizeof("+0.");
	if (buflen < len)
	{
		*buffer = '\0';
		return(-1);		/* Buffer too short */
	}

	/* There is now known to be enough space */

	/* Process integral part of number */
	i = 0;
	if (dv.dec_exp <= 0)
		*dst++ = '0';
	else
	{
		size_t d1 = MIN(dv.dec_exp, dv.dec_ndgts);
		size_t j;
		if (dv.dec_dgts[0] >= 10)
			*dst++ = (dv.dec_dgts[0] / 10) + '0';
		*dst++ = (dv.dec_dgts[0] % 10) + '0';
		for (i = 1; i < d1; i++)
		{
			*dst++ = (dv.dec_dgts[i] / 10) + '0';
			*dst++ = (dv.dec_dgts[i] % 10) + '0';
		}
		/* Pad with zeroes to decimal point */
		for (j = i; j < dv.dec_exp; j++)
		{
			*dst++ = '0'; /* Tens */
			*dst++ = '0'; /* Units */
		}
	}

	if (ndigit > 0)
	{
		size_t n = 0;
		size_t j;
		/* Emit decimal point! */
		*dst++ = '.';
		if (dv.dec_exp < 0)
		{
			/* Add leading zeroes on fraction */
			for (j = -dv.dec_exp; j > 0; j--)
			{
				*dst++ = '0'; /* Tens */
				if (++n < ndigit)
				{
					*dst++ = '0'; /* Units */
					++n;
				}
			}
		}
		/* Add residual digits */
		while (i < dv.dec_ndgts)
		{
			*dst++ = (dv.dec_dgts[i] / 10) + '0';
			if (++n < ndigit)
			{
				*dst++ = (dv.dec_dgts[i] % 10) + '0';
				++n;
			}
			i++;
		}
		/* Add residual zeroes */
		while (n++ < ndigit)
			*dst++ = '0';
	}

	*dst = '\0';

	return(0);
}

#ifdef TEST

#include <stdio.h>
#include <stdlib.h>
#include "phasedtest.h"

typedef struct Test
{
	const char *val;
	ifx_dec_t   dv;
	int         dp;
	int         plus;
	const char *res;
} Test;

static const Test p1_test[] =
{
	{	"0", DECZERO_INITIALIZER, 3, 1, "+0.000" },
	{	"0", DECZERO_INITIALIZER, 6, 1, "+0.000000" },
	{	"0", DECZERO_INITIALIZER, 0, 0, " 0" },
	{	"-1", { 1, DECPOSNEG, 1, {  1 } }, 0, 0, "-1" },
	{	"91", { 1, DECPOSPOS, 1, { 91 } }, 0, 0, " 91" },
	{	"0.0011", { -1, DECPOSPOS, 1, { 11 } }, 6, 1, "+0.001100" },
	{	"0.000001122", { -2, DECPOSPOS, 3, {  1, 12, 20 } }, 15, 1, "+0.000001122000000" },
	{	"+3.14159265358979323844e+00", { 1, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 6, 0, " 3.141593" },
	{	"-3.14159265358979323844e+00", { 1, DECPOSNEG, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 5, 0, "-3.14159" },
	{	"+3.14159265358979323844e+00", { 1, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 4, 1, "+3.1416" },
	{	"+3.14159265358979323844e+00", { 1, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 3, 1, "+3.142" },
	{	"-3.14159265358979323844e+01", { 1, DECPOSNEG, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 5, 1, "-31.41593" },
	{	"-3.14159265358979323844e+01", { 1, DECPOSNEG, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 9, 0, "-31.415926536" },

	{	" 3.14159265358979323844e+02", { 2, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 12, 1,	"+314.159265358979" },
	{	"+3.14159265358979323844e+03", { 2, DECPOSPOS, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 0,  1,	"+3142" },
	{	"-3.14159265358979323844e+34", { 18, DECPOSNEG, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 0,  1,	"-31415926535897932384400000000000000" },
	{	" 3.14159265358979323844e+68", { 35, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 3, 0, " 314159265358979323844000000000000000000000000000000000000000000000000.000" },
	{	"+3.14159265358979323844e+99", { 50, DECPOSPOS, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 0, 0, " 3141592653589793238440000000000000000000000000000000000000000000000000000000000000000000000000000000" },
	{	"-3.14159265358979323844e+100", { 51, DECPOSNEG, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 0, 0, "-31415926535897932384400000000000000000000000000000000000000000000000000000000000000000000000000000000" },

	{	" 9.99999999999999999999e+124", { 63, DECPOSPOS, 11, {  9, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99 } }, 0, 0, " 99999999999999999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"  },
	{	"+1.00000000000000000000e+125", { 63, DECPOSPOS, 1, { 10 } }, 0, 0, " 100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" },
	{	" 9.99999999999999999999e+125", { 63, DECPOSPOS, 11, { 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 90 } }, 0, 0, " 999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"  },
	/* 1E+126 should have a conversion failure! */
	/*
	{	"+1.00000000000000000000e+126", { 64, DECPOSPOS, 1, {  1 } }, 0, 0, "" },
	*/

	{	" 3.14159265358979323844e-01",	{ 0, DECPOSPOS, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 3,	0,	" 0.314" },
	{	"+3.14159265358979323844e-02",	{ 0, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 6,	1,	"+0.031416" },

	{	"-3.14159265358979323844e-03",	{ -1, DECPOSNEG, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 6,	0,	"-0.003142" },
	{	" 3.14159265358979323844e-34",	{ -16, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 10,	0,	" 0.0000000000" },
	{	"+3.14159265358979323844e-66",	{ -32, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000031416" },
	{	"+3.14159265358979323844e-67",	{ -33, DECPOSPOS, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000003142" },
	{	"+3.14159265358979323844e-68",	{ -33, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000314" },
	{	"+3.14159265358979323844e-69",	{ -34, DECPOSPOS, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000031" },
	{	"+3.14159265358979323844e-70",	{ -34, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000003" },
	{	"+3.14159265358979323844e-71",	{ -35, DECPOSPOS, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000000" },

	{	" 1.000000000000000000000000000001E-108",	{ -53, DECPOSPOS, 16, {  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1 } }, 140,	1,	"+0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000100" },
	{	"+3.14159265358979323844e-126",	{ -62, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 20,	1,	"+0.00000000000000000000" },
	{	"-3.14159265358979323844e-127",	{ -63, DECPOSNEG, 11, { 31, 41, 59, 26, 53, 58, 97, 93, 23, 84, 40 } }, 135,	0,	"-0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000314159265" },
	{	"11.001001001001001001001001001001E-128",	{ -63, DECPOSPOS, 16, { 11,  0, 10,  1,  0, 10,  1,  0, 10,  1,  0, 10,  1,  0, 10,  1 } }, 161,	1,	"+0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011001001001001001001001001001001000" },

	/* more overflow values!
	{	"+1.00000000000000000000e-129",	{ 0, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 10,	1,	"+0.0000000000" },
	{	"-1.00000000000000000000e-130",	{ 0, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 10,	1,	"-0.0000000000" },
	{	" 9.99999999999999999999e-131",	{ 0, DECPOSPOS, 11, {  3, 14, 15, 92, 65, 35, 89, 79, 32, 38, 44 } }, 0,	0,	"" },
	*/

};

static void p1_tester(const void *data)
{
    const Test *test = (const Test *)data;
	int       rv;
	char      buffer[MAX_FIXDECSTRLEN];

    rv = dec_fix(&test->dv, test->dp, test->plus, buffer, sizeof(buffer));
    if (rv != 0 || strcmp(test->res, buffer) != 0)
    {
        pt_fail("input <<%s>> (%d dp)\n", test->val, test->dp);
        pt_info("got    <<%s>>\n", buffer);
        pt_info("wanted <<%s>>\n", test->res);
        pt_info("error = %d\n", rv);
    }
    else
        pt_pass("input <<%s>> (%d dp) = <<%s>>\n", test->val, test->dp, buffer);
}

static const pt_auto_phase phases[] =
{
    { p1_tester, PT_ARRAYINFO(p1_test), 0, "Testing dec_fix()" },
};

int main(int argc, char **argv)
{
    return(pt_auto_harness(argc, argv, phases, DIM(phases)));
}

#endif	/* TEST */
