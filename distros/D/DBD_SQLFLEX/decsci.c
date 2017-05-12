/*
@(#)File:            $RCSfile: decsci.c,v $
@(#)Version:         $Revision: 1.11 $
@(#)Last changed:    $Date: 1997/07/08 19:47:10 $
@(#)Purpose:         Fixed, Exponential and Engineering formatting of DECIMALs
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1991-93,1996-97
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

#include "esqlc.h"
#include "decsci.h"
#include <isdecs.h>

#define SIGN(s, p)  ((s) ? '-' : ((p) ? '+' : ' '))
#define VALID(n)	(((n) <= 0) ? 6 : (((n) > 32) ? 32 : (n)))
#define VALID2(n)	(((n) <= 0) ? 0 : (((n) > 151) ? 151 : (n)))

#define CONST_CAST(t, v)	((t)v)

/* For 32 digits, 3-digit exponent, leading blanks, etc, 42 is enough */
/* With fixed format, could have -0.(130*0)(32 digits) + null for length 166 */
static char     buffer[166];

#ifndef lint
static const char rcs[] = "@(#)$Id: decsci.c,v 1.11 1997/07/08 19:47:10 johnl Exp $";
#endif

/*
**	Format a fixed-point number.  Unreliable for ndigit > 58 because of the
**	implementation of decfcvt in ${SOURCE}/infx/decconv.c
*/
char           *decfix(const dec_t *d, int ndigit, int plus)
{
	register char  *dst = buffer;
	register char  *src;
	int             i;
	int             sn;
	int             dp;

	if (risnull(CDECIMALTYPE, (char *)d))
	{
		*dst = '\0';
		return(buffer);
	}

	ndigit = VALID2(ndigit);

	src = decfcvt(CONST_CAST(dec_t *, d), ndigit, &dp, &sn);

	*dst++ = SIGN(sn, plus);	/* Sign */
	if (dp >= 1)
	{
		while (dp-- > 0)
			*dst++ = ((*src) ? *src++ : '0');
		if (ndigit > 0)
			*dst++ = '.';
		for (i = 0; i < ndigit; i++)
			*dst++ = ((*src) ? *src++ : '0');
	}
	else
	{
		*dst++ = '0';
		if (ndigit > 0)
			*dst++ = '.';
		i = 0;
		while (dp++ < 0 && i < ndigit)
		{
			*dst++ = '0';
			i++;
		}
		while (*src && i < ndigit)
		{
			*dst++ = *src++;
			i++;
		}
	}
	*dst = '\0';

	return(buffer);
}

/* Format an exponent */
static char    *decexp(register char  *dst, register int dp)
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

/*	Format a scientific notation number */
char           *decsci(const dec_t *d, int ndigit, int plus)
{
	register char  *dst = buffer;
	register char  *src;
	int             sn;
	int             dp;
	dec_t           z;

	if (risnull(CDECIMALTYPE, (char *)d))
	{
		*dst = '\0';
		return(buffer);
	}

	ndigit = VALID(ndigit);
	src = dececvt(CONST_CAST(dec_t *, d), ndigit, &dp, &sn);
	*dst++ = SIGN(sn, plus);	/* Sign */
	*dst++ = *src++;			/* Digit before decimal point */
	*dst++ = '.';				/* Decimal point */
	while (*src)				/* Digits after decimal point */
		*dst++ = *src++;
	deccvdbl(0.0, &z);
	dst = decexp(dst, dp - (deccmp(CONST_CAST(dec_t *, d), &z) != 0));	/* Exponent */
	return(buffer);
}

/*
**	Format an engineering notation number.
**	Exponent is always a power of three.  Exponent is omitted if it is zero.
**	For values 1.0E-1 <= ABS(x) < 1.0E0, the value is printed as 0.xxxx.
**	The field always aligns the decimal points, prefixing blanks if necessary.
**	The number of digits printed ND is such that if the power of ten is of
**	the form (n * 3 + m) (m = 0, 1, 2), ND = ndigit - 2 + m.  The exception
**	to this is when the value is treated as 0.xxxx and ND = ndigit - 2
**	including the leading zero!
**	The field can be made constant width by specifying a non-zero cw.
*/
char           *deceng(const dec_t *d, int ndigit, int plus, int cw)
{
	register char  *dst = buffer;
	register char  *src;
	int             sn;
	int             dp;
	int             lb;
	int             exp;

	if (risnull(CDECIMALTYPE, (char *)d))
	{
		*dst = '\0';
		return(buffer);
	}

	ndigit = VALID(ndigit);
	src = dececvt(CONST_CAST(dec_t *, d), ndigit, &dp, &sn);
	exp = dp - 1;
	/* Calculate leading blanks */
	lb = 2 - (exp % 3);
	if (lb >= 3)
		lb -= 3;
	if (exp == -1)
	{
		lb = 2;
		ndigit--;
	}
	/* Shorten digit string as necessary */
	src[ndigit - lb] = '\0';

	while (lb-- > 0)			/* Leading blanks */
		*dst++ = ' ';

	*dst++ = SIGN(sn, plus);	/* Sign */
	if (exp == -1)
	{							/* Leading 0 */
		*dst++ = '0';
		exp = 0;
	}
	else
	{							/* Leading digits */
		while (exp % 3 != 0)
		{
			*dst++ = ((*src) ? *src++ : '0');
			exp--;
		}
		*dst++ = *src++;
	}
	*dst++ = '.';				/* Decimal point */
	while (*src)				/* Digits after decimal point */
		*dst++ = *src++;
	if (exp != 0)				/* Exponent */
		dst = decexp(dst, exp);
	else if (cw)
	{
		for (lb = 0; lb < 5; lb++)
			*dst++ = ' ';
	}
	*dst = '\0';
	return(buffer);
}

#ifdef TEST

#define DIM(x)	(sizeof(x)/sizeof(*(x)))

static char    *values[] =
{
 "0",
 "+3.14159265358979323844e+00",
 "-3.14159265358979323844e+01",
 " 3.14159265358979323844e+02",
 "+3.14159265358979323844e+03",
 "-3.14159265358979323844e+34",
 " 3.14159265358979323844e+68",
 "+3.14159265358979323844e+99",
 "-3.14159265358979323844e+100",
 " 9.99999999999999999999e+125",
 "+1.00000000000000000000e+126",
 "-3.14159265358979323844e+00",
 " 3.14159265358979323844e-01",
 "+3.14159265358979323844e-02",
 "-3.14159265358979323844e-03",
 " 3.14159265358979323844e-34",
 "+3.14159265358979323844e-68",
 "-3.14159265358979323844e-99",
 " 3.14159265358979323844e-100",
 "+3.14159265358979323844e-126",
 "-3.14159265358979323844e-127",
 " 1.00000000000000000000e-128",
 "+1.00000000000000000000e-129",
 "-1.00000000000000000000e-130",
 " 9.99999999999999999999e-131",
};

main()
{
	char           *s;
	dec_t           d;
	int             i;
	int             err;

	printf("\nFixed-point notation\n");
	printf("%-30s %s\n", "Input value", "Formatted");
	for (i = 0; i < DIM(values); i++)
	{
		if ((err = deccvasc(values[i], strlen(values[i]), &d)) != 0)
			printf("deccvasc error %d on %s\n", err, values[i]);
		else
		{
			s = decfix(&d, 6 + 3 * i, i % 2);
			printf("%-30s :%s:\n", values[i], s);
		}
	}

	printf("\nScientific notation\n");
	printf("%-30s %s\n", "Input value", "Formatted");
	for (i = 0; i < DIM(values); i++)
	{
		if ((err = deccvasc(values[i], strlen(values[i]), &d)) != 0)
			printf("deccvasc error %d on %s\n", err, values[i]);
		else
		{
			s = decsci(&d, 6, i % 2);
			printf("%-30s :%s:\n", values[i], s);
		}
	}

	printf("\nEngineering notation (variable)\n");
	printf("%-30s %s\n", "Input value", "Formatted");
	for (i = 0; i < DIM(values); i++)
	{
		if ((err = deccvasc(values[i], strlen(values[i]), &d)) != 0)
			printf("deccvasc error %d on %s\n", err, values[i]);
		else
		{
			/*s = deceng(&d, 16 + (i / 3), i % 2, 0);*/
			s = deceng(&d, 16, i % 2, 0);
			printf("%-30s :%s:\n", values[i], s);
		}
	}

	printf("\nEngineering notation (constant)\n");
	printf("%-30s %s\n", "Input value", "Formatted");
	for (i = 0; i < DIM(values); i++)
	{
		if ((err = deccvasc(values[i], strlen(values[i]), &d)) != 0)
			printf("deccvasc error %d on %s\n", err, values[i]);
		else
		{
			s = deceng(&d, 32 - 3 * (i / 3), i % 2, 1);
			printf("%-30s :%s:\n", values[i], s);
		}
	}

	return(0);
}

#endif	/* TEST */
