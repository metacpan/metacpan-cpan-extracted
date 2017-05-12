/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pomni.h"
#include "exttypes.h"
#include <ctype.h>

SV *
ll_from_longlong (pTHX_ CM_longlong val)
{
    SV *rv;
    SV *result = newSV(0);
    SvUPGRADE (result, SVt_NV);
    
    LL_VALUE(result) = val;

    rv = newRV_noinc (result);
    sv_bless (rv, gv_stashpv ("CORBA::LongLong", TRUE));

    return rv;
}

SV *
ull_from_ulonglong (pTHX_ unsigned CM_longlong val)
{
    SV *rv;
    SV *result = newSV(0);
    SvUPGRADE (result, SVt_NV);
    
    ULL_VALUE(result) = val;

    rv = newRV_noinc (result);
    sv_bless (rv, gv_stashpv ("CORBA::ULongLong", TRUE));

    return rv;
}

SV *
ld_from_longdouble (pTHX_ long double val)
{
    SV *rv;
    SV *result = newSV(sizeof(long double));
    
    LD_VALUE(result) = val;

    rv = newRV_noinc (result);
    sv_bless (rv, gv_stashpv ("CORBA::LongDouble", TRUE));

    return rv;
}

/* Some rough-and-ready equivalents for library functions to convert
 * CM_longlongs and long doubles to and from strings The long double
 * stuff is in particular somewhat bad. It usually gets the last
 * bit wrong (glibc uses a multiple precision library for this, it may
 * be hard to do better sticking within the long double type)
 *
 * The goal here is portability without having to know the details
 * of the layout of the long double type.
 */

CM_longlong
longlong_from_string (const char *str)
{
    CM_longlong val = 0;
    int negate = 0;
      
    while (*str) {
	if (*str == '-') {
	    negate = 1;
	    str++;
	    break;
	} else if (*str == '+') {
	    str++;
	    break;
	} else if (isspace (*str)) {
	    str++;
	} else
	    break;
    }

    while (*str) {
	if (isdigit (*str)) {
	    val *= 10;
	    val += *str - '0';
	} else if (!isspace (*str))
	    break;
	str++;
    }

    if (negate)
	val = -val;
    
    return val;
}

char *
longlong_to_string (CM_longlong val)
{
    size_t length = 2;
    char *str;
    size_t n = 0;
    int negate = 0;
    size_t m;
    char tmp;

    New (7554, str, 3, char);

    if (val < 0) {
	negate = 1;
	str[n] = '-';
	n++;
	val = -val;
    }

    while (val || (n == 0)) {
	str[n] = (val % 10) + '0';
	val /= 10;
	n++;
	if (n >= length) {
	    length *= 2;
	    Renew (str, length+1, char);
	}
    }

    str[n] = '\0';

    m = negate ? 1 : 0;
    while (--n > m) {
	tmp = str[m];
	str[m] = str[n];
	str[n] = tmp;
	m++;
    }

    return str;
}

unsigned CM_longlong
ulonglong_from_string (const char *str)
{
    unsigned CM_longlong val = 0;
      
    while (*str) {
	if (*str == '+') {
	    str++;
	    break;
	} else if (isspace (*str)) {
	    str++;
	} else
	    break;
    }

    while (*str) {
	if (isdigit (*str)) {
	    val *= 10;
	    val += *str - '0';
	} else if (!isspace (*str))
	    break;
	str++;
    }

    return val;
}

char *
ulonglong_to_string (unsigned CM_longlong val)
{
    size_t length = 2;
    char *str;
    size_t n = 0;
    size_t m;
    char tmp;

    New (7554, str, 3, char);

    while (val || (n == 0)) {
	str[n] = (val % 10) + '0';
	val /= 10;
	n++;
	if (n >= length) {
	    length *= 2;
	    Renew (str, length+1, char);
	}
    }

    str[n] = '\0';

    m = 0;
    while (--n > m) {
	tmp = str[m];
	str[m] = str[n];
	str[n] = tmp;
	m++;
    }

    return str;
}

long double 
longdouble_from_string (const char *str)
{
    int decimal = 0x7FFFFFFF;
    int exponent = 0;
    int negate = 0;
    int enegate = 0;
    long double val = 0;
    long double divisor = 1.0;
    long double d;
    int i = 0;

    /* Skip leading white space */
    
    while (*str)
      {
	if (!isspace (*str))
	  break;
	str++;
      }

    /* read sign */

    if (*str == '-')
      {
	negate = 1;
	str++;
      }
    else if (*str == '+')
      str++;
    
    /* read decimal digits */
    while (*str)
      {
	if (isdigit (*str))
	  {
	    val *= 10;
	    val += (*str - '0');
	    i++;
	  }
	else if (*str == '.')
	  decimal = i;
	else
	  break;
	str++;
      }

    /* read exponent */

    if (*str == 'e' || (*str == 'E'))
      {
	enegate = 0;
	str++;

	if (*str == '-')
	  {
	    enegate = 1;
	    str++;
	  }
	while (*str)
	  {
	    if (isdigit (*str))
	      {
		exponent *= 10;
		exponent += *str - '0';
		str++;
	      }
	    else
	      break;
	  }
	if (enegate)
	  exponent = -exponent;
      }

    if (decimal <= i)
      exponent -= (i - decimal);

    if (exponent < 0)
      {
	exponent = -exponent;
	enegate = 1;
      }
    else
      enegate = 0;

    if (negate)
      val = - val;

    divisor = 1.0;
    d = 10.0;
    while (exponent)
      {
	if (exponent & 1)
	  divisor *= d;
	exponent >>= 1;
	d *= d;
      }

    if (enegate)
      val /= divisor;
    else
      val *= divisor;

    return val;
}

char *
longdouble_to_string (long double val)
{
    int count;
    int invert;
    long double a;
    long double divisor, oldd;
    long double limit;
    long double small;
    int e;
    int i;
    int exp, oldexp;
    size_t length = 6;
    char *str;
    size_t n = 0;

    New (7554, str, length, char);

    if (val < 0) {
        str[n] = '-';
	n++;
    }

    if (val == 0) {
        strcat (&str[n], "0.e0");
	return str;
    }

    if (val < 1.0) {
	limit = 1 / val;
	invert = 1;
    } else {
        if (val * 2 == val) {	/* infinity */
	  strcat (&str[n], "Inf");
	  return str;
	}
        limit = val;
        invert = 0;
    }
    
    divisor = oldd = 1.0;
    exp = oldexp = 0;

    /* Use a modified binary search to find the exponent.
     * we grow the exponent by powers of two, and when we
     * overshoot, start again from the next to last point.
     */
    if (limit > 1.0) {
	
	do {
	    divisor = oldd;
	    exp = oldexp;
	
	    a = 10.0;
	    e = 1;
	    
	    do {
		oldd = divisor;
		divisor *= a;
		a = a*a;
		oldexp = exp;
		exp += e;
		e *= 2;
	    } while (divisor < limit);
	    
	} while (e != 2);
    }

    /* Scale the result
     */

    if (invert) {
	exp = -exp;
	val *= divisor;
    } else {
        if (divisor == limit) {
	    val /= divisor;
	} else {
	  exp = oldexp;
	  val /= oldd;
	}
    }

    /* We now have val normalized to 1.0 <= val < 10.0 */

    /* Write out digits, until it almost certainly doesn't make
     * a difference. (We go a few digits over, so that we don't
     * have to worry about rounding). This could most likely
     * be done better.
     */
    small = 10.0;
    i = 0;
    count = 2;
    while (count != 0)
      {
	int digit = (int)val;
	if (1.0 + small == 1.0)
	  count--;

	str[n++] = '0' + digit;
	if (n+4 >= length) {	/* leave space for . and e - */
	    length *= 2;
	    Renew (str, length, char);
	}
	val -= digit;
	small /= 10.;
	val *= 10.;
	if (i++ == 0)
	  str[n++] = '.';
      }

    str[n++] = 'e';

    if (exp < 0)
      {
	str[n++] = '-';
	exp = -exp;
      }
    
    do {
      str[n++] = (exp % 10) + '0';
      exp /= 10;
      if (n + 1 >= length) {
	length *= 2;
	Renew (str, length, char);
      }
    } while (exp);

    str[n] = '\0';

    return str;
}
