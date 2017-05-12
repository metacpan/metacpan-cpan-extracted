/*
@(#)File:           $RCSfile: decsci.c,v $
@(#)Version:        $Revision: 4.12 $
@(#)Last changed:   $Date: 2008/09/23 05:37:31 $
@(#)Purpose:        Exponential formatting of DECIMALs
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1991-93,1996-97,1999,2001,2003,2005,2007-08
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

#ifdef TEST
#define USE_DEPRECATED_DECSCI_FUNCTIONS
#endif /* TEST */

#include <assert.h>
#include <string.h>
#include "decsci.h"

/* -1273: Output buffer is NULL or too small to hold the result. */
/* Explanation from finderr is not ideal, but will probably do.  */
enum { ERR_FMTBUFFERTOOSHORT = -1273 };

#define SIGN(s, p)  (((s) == DECPOSNEG) ? '-' : ((p) ? '+' : ' '))
#define VALID(n)    (((n) <= 0) ? 6 : (((n) > 32) ? 32 : (n)))

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_decsci_c[] = "@(#)$Id: decsci.c,v 4.12 2008/09/23 05:37:31 jleffler Exp $";
#endif /* lint */

#ifdef USE_DEPRECATED_DECSCI_FUNCTIONS
char *decsci(const ifx_dec_t *d, int ndigits, int plus)
{
    /* For 32 digits, 3-digit exponent, leading blanks, etc, 42 is enough */
    static char buffer[42];
    if (dec_sci(d, ndigits, plus, buffer, sizeof(buffer)) != 0)
        *buffer = '\0';
    return(buffer);
}
#endif /* USE_DEPRECATED_DECSCI_FUNCTIONS */

/* dec_sci_round - round at ndigits (rather than ndigits after decimal point) */
/*
** The function decround() rounds a decimal value to a given number of
** decimal places.  This code should round to a given number of digits
** instead.  It can exploit decround() by calculating the correct number
** of decimal places to specify.
** Given:
**  d = 3.141592E+00, rounding to n digits == decround(d, n-1).
**  d = 3.141592E+01, rounding to n digits == decround(d, n-2).
**  d = 3.141592E+02, rounding to n digits == decround(d, n-3).
**  d = 3.141592E-01, rounding to n digits == decround(d, n+0).
**  d = 3.141592E-02, rounding to n digits == decround(d, n+1).
**  d = 3.141592E-03, rounding to n digits == decround(d, n+2).
**  So for d with decimal exponent e,      => decround(d, n - (e + 1))
** Problem: given dec_exp, determining the exponent of 10 is not entirely trivial.
**  d = 3.141592E+00, dec_exp =  1, dec_dgts[0] =  3
**  d = 3.141592E+01, dec_exp =  1, dec_dgts[0] = 31
**  d = 3.141592E+02, dec_exp =  2, dec_dgts[0] =  3
**  d = 3.141592E-01, dec_exp =  0, dec_dgts[0] = 31
**  d = 3.141592E-02, dec_exp =  0, dec_dgts[0] =  3
**  d = 3.141592E-03, dec_exp = -1, dec_dgts[0] = 31
** Hence: e = 2 * (dec_exp - 1) + (dec_dgts[0] >= 10);
*/
static void dec_sci_round(ifx_dec_t *dp, int ndigits)
{
    int e;
    assert(!dec_eq_zero(dp) && !dec_eq_null(dp));
    e = 2 * (dp->dec_exp - 1) + (dp->dec_dgts[0] >= 10);
    decround(dp, ndigits - (e + 1));
}

/*  Format a scientific notation number */
int dec_sci(const ifx_dec_t *d, int ndigits, int plus, char *buffer, size_t buflen)
{
    char     *dst = buffer;
    int       digitpair;
    int       decexp = 0;
    size_t    i;
    ifx_dec_t dv;

    if (dec_eq_null(d))
    {
        *dst = '\0';
        return(0);
    }

    ndigits = VALID(ndigits);
    if (buflen < ndigits + sizeof("+.E+123"))
    {
        *dst = '\0';
        return(ERR_FMTBUFFERTOOSHORT);
    }

    /* Rounding to n digits total cannot generate zero from a non-zero number */
    if (dec_eq_zero(d))
    {
        *dst++ = SIGN(DECPOSPOS, plus);    /* Sign */
        *dst++ = '0';
        if (ndigits > 1)
            *dst++ = '.';
        memset(dst, '0', ndigits - 1);
        dst = dec_setexp(dst + ndigits - 1, 0); /* Exponent */
        return(0);
    }

    dv = *d;
    dec_sci_round(&dv, ndigits);

    *dst++ = SIGN(dv.dec_pos, plus);    /* Sign */
    decexp = 0;
    digitpair = dv.dec_dgts[0];
    if (digitpair >= 10)
    {
        decexp = 1;
        *dst++ = digitpair / 10 + '0';
        if (ndigits > 1)
        {
            *dst++ = '.';
            *dst++ = digitpair % 10 + '0';
        }
        ndigits -= 2;
    }
    else
    {
        decexp = 0;
        *dst++ = digitpair % 10 + '0';
        if (ndigits > 1)
            *dst++ = '.';
        ndigits--;
    }

    for (i = 1; i < dv.dec_ndgts && ndigits > 0; i++)
    {
        digitpair = dv.dec_dgts[i];
        *dst++ = digitpair / 10 + '0';
        ndigits--;
        if (ndigits > 0)
        {
            *dst++ = digitpair % 10 + '0';
            ndigits--;
        }
    }
    if (ndigits > 0)
    {
        memset(dst, '0', ndigits);
        dst += ndigits;
    }
    decexp = (2 * dv.dec_exp) + decexp - 2;
    dst = dec_setexp(dst, decexp);  /* Exponent */

    return(0);
}

#ifdef TEST

#include <stdio.h>
#include "phasedtest.h"

typedef struct p1_test
{
    const char *input;
    int         dp;
    int         plus;
    int         rc;
    const char *output;
}   p1_test;

static p1_test values[] =
{
    { "0",                             1, 0,     0, " 0E+00 "                      },
    { "0",                             2, 1,     0, "+0.0E+00 "                    },
    { "0",                             3, 0,     0, " 0.00E+00 "                   },
    { "0",                             4, 1,     0, "+0.000E+00 "                  },
    { "0",                             5, 0,     0, " 0.0000E+00 "                 },
    { "+3.14159265358979323844e+00",   1, 1,     0, "+3E+00 "                      },
    { "+3.14159265358979323844e+00",   2, 0,     0, " 3.1E+00 "                    },
    { "+3.14159265358979323844e+00",   3, 1,     0, "+3.14E+00 "                   },
    { "+3.14159265358979323844e+00",   4, 0,     0, " 3.142E+00 "                  },
    { "+3.14159265358979323844e+00",   5, 1,     0, "+3.1416E+00 "                 },
    { "+3.14159265358979323844e+00",   6, 1,     0, "+3.14159E+00 "                },
    { "-3.14159265358979323844e+01",   8, 0,     0, "-3.1415927E+01 "              },
    { " 3.14159265358979323844e+02",  10, 1,     0, "+3.141592654E+02 "            },
    { "+3.14159265358979323844e+03",  12, 0,     0, " 3.14159265359E+03 "          },
    { "-3.14159265358979323844e+34",  13, 1,     0, "-3.141592653590E+34 "         },
    { " 3.14159265358979323844e+68",  14, 0,     0, " 3.1415926535898E+68 "        },
    { "+3.14159265358979323844e+99",  15, 1,     0, "+3.14159265358979E+99 "       },
    { "-3.14159265358979323844e+100", 21, 0,     0, "-3.14159265358979323844E+100" },
    { " 9.99999999999999999999e+123", 20, 1,     0, "+1.0000000000000000000E+124"  },
    { " 9.99999999999999999999e+123", 21, 0,     0, " 9.99999999999999999999E+123" },
    { "+1.00000000000000000000e+124", 12, 1,     0, "+1.00000000000E+124"          },
    { " 9.99999999999999999999e+124", 21, 0,     0, " 9.99999999999999999999E+124" },
    { " 0.99999999999999999999e+125", 21, 0,     0, " 9.99999999999999999990E+124" },
    { " 0.09999999999999999999e+126", 21, 0,     0, " 9.99999999999999999900E+124" },
    { " 0.00999999999999999999e+127", 21, 0,     0, " 9.99999999999999999000E+124" },
    { " 0.00099999999999999999e+128", 21, 0,     0, " 9.99999999999999990000E+124" },
    { " 0.00009999999999999999e+129", 21, 0,     0, " 9.99999999999999900000E+124" },
    { "+1.00000000000000000000e+125", 14, 1, -1213, ""                             },
    { " 9.99999999999999999999e+125", 14, 0, -1213, ""                             },
    { "+1.00000000000000000000e+126", 14, 1, -1213, ""                             },
    { "-3.14159265358979323844e+00",  13, 0,     0, "-3.141592653590E+00 "         },
    { " 3.14159265358979323844e-01",  13, 1,     0, "+3.141592653590E-01 "         },
    { "+3.14159265358979323844e-02",  13, 0,     0, " 3.141592653590E-02 "         },
    { "-3.14159265358979323844e-03",  13, 1,     0, "-3.141592653590E-03 "         },
    { " 3.14159265358979323844e-34",  13, 0,     0, " 3.141592653590E-34 "         },
    { "+3.14159265358979323844e-68",  13, 1,     0, "+3.141592653590E-68 "         },
    { "-3.14159265358979323844e-99",  13, 0,     0, "-3.141592653590E-99 "         },
    { " 3.14159265358979323844e-100", 13, 1,     0, "+3.141592653590E-100"         },
    { "+3.14159265358979323844e-126", 13, 0,     0, " 3.141592653590E-126"         },
    { "-3.14159265358979323844e-127", 13, 1,     0, "-3.141592653590E-127"         },
    { " 1.00000000000000000000e-128", 13, 0,     0, " 1.000000000000E-128"         },
    { "+1.00000000000000000000e-129", 13, 1,     0, "+1.000000000000E-129"         },
    { "-1.00000000000100000000e-130", 13, 0,     0, "-1.000000000001E-130"         },
    { "+10.0000000000200000000e-131", 13, 0,     0, " 1.000000000002E-130"         },
    { "+100.000000000300000000e-132", 13, 0,     0, " 1.000000000003E-130"         },
    { "+1000.00000000400000000e-133", 13, 0,     0, " 1.000000000004E-130"         },
    { "+10000.0000000500000000e-134", 13, 0,     0, " 1.000000000005E-130"         },
    { " 9.99999999999999999999e-131", 13, 1, -1213, ""                             },
};

static void p1_tester(const void *data)
{
    const p1_test *test = (const p1_test *)data;
    char     *s;
    ifx_dec_t d;
    int       err;

    err = deccvasc(CONST_CAST(char *, test->input), strlen(test->input), &d);
    /*
    ** Relax condition to allow non-Informix deccvasc() to return
    ** different error code.  Check that an error is received when one
    ** is expected, and that none is received when none is expected.
    */
    if ((err == 0 && test->rc != 0) || (err != 0 && test->rc == 0))
        pt_fail("unexpected status %d (wanted %d) from deccvasc() for %s\n",
                err, test->rc, test->input);
    else if (err != 0)
        pt_pass("conversion failed %d as expected for %s\n", err, test->input);
    else
    {
        s = decsci(&d, test->dp, test->plus);
        if (strcmp(s, test->output) == 0)
            pt_pass("%-30s %2d/%d :%s:\n", test->input, test->dp, test->plus, s);
        else
        {
            pt_fail("%-30s got  :%s:\n", test->input, s);
            pt_info("%-21s expected %2d/%d :%s:\n", "", test->dp, test->plus, test->output);
        }
    }
}

static pt_auto_phase phases[] =
{
    { p1_tester, PT_ARRAYINFO(values), 0, "Basic testing of decsci" },
};

int main(int argc, char **argv)
{
    return(pt_auto_harness(argc, argv, phases, DIM(phases)));
}

#endif  /* TEST */

