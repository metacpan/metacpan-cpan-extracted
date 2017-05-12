#define PERL_POLLUTE

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>


static UV dim[14]
	= { 31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, 31, 28 };
static IV tweak[12]
	= { 1, 2, 4, 5, 7, 8, 9, 11, 12, 14, 15, 16 };
static IV cum_days[12]
	= { -1, 30, 58, 89, 119, 150, 180, 211, 242, 272, 303, 333 };

static bool
is_leap_year (IV y)
{
	return (y % 4 == 0) && ((y % 100 != 0) || (y % 400 == 0));
}

static IV
days_in_month (IV month, IV year)
{
	IV ret = dim [ month - 1 ];
	if (ret == 0)
		ret = is_leap_year (year) ? 29 : 28;
	return ret;
}

/* Compute the number of days since 1970.  */
static bool
ymd_to_days (IV y, IV m, IV d, IV* days)
{
	IV x;
	IV nonleap_days;
	IV leap_days_4;
	IV leap_holes_100;
	IV leap_days_400;

	if (m < 1 || m > 12 || d < 1 || (d > 28 && d > days_in_month (m, y)))
		return FALSE;

	x = (m <= 2 ? y - 1 : y);
	nonleap_days = d + cum_days [m - 1] + 365 * (y - 1970);

	leap_days_4 = (x - 1968) >> 2;
	if (x >= 1900)
		leap_holes_100 = (x - 1900) / 100;
	else
		leap_holes_100 = - (1999 - x) / 100;
	if (x >= 1600)
		leap_days_400 = (x - 1600) / 400;
	else
		leap_days_400 = - (1999 - x) / 400;

	*days = nonleap_days + leap_days_4 - leap_holes_100 + leap_days_400;
	return TRUE;
}

/* Compute year, month, and day given days_since_1970.  */
static void
days_to_ymd (IV days, IV ymd[3])
{
	IV year;
	IV month, day, quot;

	/* Shift frame of reference from 1 Jan 1970 to (the imaginary)
	   1 Mar 0AD.  */
	days += 719468;

	/* Do the math.  */

	quot = days / 146097;
	days -= 146097 * quot;
	year = 400 * quot;

	if (days == 146096)
	{
		/* Handle 29 Feb 2000, 2400, ...  */
		year += 400;
		month = 2;
		day = 29;
	}
	else
	{
		quot = days / 36524;
		days -= 36524 * quot;
		year += 100 * quot;

		quot = days / 1461;
		days -= 1461 * quot;
		year += 4 * quot;

		if (days == 1460)
		{
			year += 4;
			month = 2;
			day = 29;
		}
		else
		{
			quot = days / 365;
			days -= 365 * quot;
			year += quot;

			quot = days / 32;
			days -= 32 * quot;
			month = quot;

			day = days + tweak [month];
			days = dim [month + 2];

			if (day > days)
			{
				day -= days;
				month += 1;
			}
			if (month > 9)
			{
				month -= 9;
				year += 1;
			}
			else
				month += 3;
		}
	}
	ymd[0] = year;
	ymd[1] = month;
	ymd[2] = day;
}

static bool
d8_to_days (SV* d8, IV* days)
{
	char buf[5];
	STRLEN len;
	char* p;

	p = SvPV(d8, len);
	if (len == 8)
	{
		while (len > 0)
		{
			if (!isDIGIT(p[len - 1]))
				break;
			len--;
		}
		if (len != 0)
			return FALSE;
	}
	else
		return FALSE;

	return ymd_to_days(10*(10*(10*(p[0]-'0')+p[1]-'0')+p[2]-'0')+p[3]-'0',
			   10*(p[4]-'0')+p[5]-'0', 10*(p[6]-'0')+p[7]-'0',
			   days);
}

static SV*
days_to_date (IV days, SV* pkg)
{
        char* pack=0;
        if (SvROK (pkg)) {
            HV* stash;
            stash=SvSTASH(SvRV(pkg));
       	    return sv_bless( newRV_noinc (newSViv (days)), stash );
        } else if (SvTRUE(pkg)) {
            pack=SvPV_nolen(pkg);
        }
        return sv_bless( newRV_noinc (newSViv (days)),
			 gv_stashpv (pack == 0 ? "Date::Simple" : pack, 1));
}

static int
is_object (SV* sv)
{
	return (SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVMG);
}

static SV*
new_for_cmp (SV* left, SV* right, int croak_on_fail)
{
	dSP;
	SV* ret;

	/* Comparing date with non-date.
	   Try to convert the right side to a date.  */
	EXTEND (sp, 2);
	PUSHMARK(sp);
	PUSHs (left);
	PUSHs (right);
	PUTBACK;
	perl_call_method (croak_on_fail ? "new" : "_new", G_SCALAR);
	SPAGAIN;
	ret = POPs;
	if (croak_on_fail && ! is_object (ret))
	{
		PUSHMARK(sp);
		PUSHs (left);
		PUSHs (right);
		PUTBACK;
		perl_call_pv ("Date::Simple::_inval", G_VOID);
		SPAGAIN;
	}
	return ret;
}

MODULE = Date::Simple	PACKAGE = Date::Simple

SV*
_ymd(obj_or_class, y, m, d)
	SV* obj_or_class
	IV y
	IV m
	IV d
	CODE:
	{
		IV days;
		if (ymd_to_days (y, m, d, &days))
			RETVAL = days_to_date (days, obj_or_class);
		else
			XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

SV*
_d8(obj_or_class, d8)
	SV* obj_or_class
	SV* d8
	CODE:
	{
		IV days;
		if (d8_to_days (d8, &days))
			RETVAL = days_to_date (days, obj_or_class);
		else
			XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

bool
leap_year(y)
	IV y
	CODE:
	{
		RETVAL = is_leap_year (y);
	}
	OUTPUT:
	RETVAL

IV
days_in_month(y, m)
	IV y
	IV m
	CODE:
	{
		if (m < 1 || m > 12)
			croak ("days_in_month: month out of range (%d)",
			       (int) m);
		RETVAL = days_in_month (m, y);
	}
	OUTPUT:
	RETVAL

IV
validate(ysv, m, d)
	SV* ysv
	IV m
	IV d
	CODE:
	{
		IV y;
		y = SvIV (ysv);
		if ((IV) SvNV (ysv) != y)
			RETVAL = 0;
		else if (m < 1 || m > 12)
			RETVAL = 0;
		else if (d < 1 || d > days_in_month (m, y))
			RETVAL = 0;
		else
			RETVAL = 1;
	}
	OUTPUT:
	RETVAL

void
ymd_to_days(y, m, d)
	IV y
	IV m
	IV d
	CODE:
	{
		IV days;
		if (! ymd_to_days (y, m, d, &days))
			XSRETURN_UNDEF;
		else
			XSRETURN_IV (days);
	}

SV*
days_since_1970(date)
	SV* date
	CODE:
	{
		if (SvROK(date))
			RETVAL = SvREFCNT_inc (SvRV(date));
		else
			XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

void
days_to_ymd(days)
	IV days
	PPCODE:
	{
		IV ymd[3];
		days_to_ymd (days, ymd);
		EXTEND (sp, 3);
		PUSHs (sv_2mortal (newSViv (ymd[0])));
		PUSHs (sv_2mortal (newSViv (ymd[1])));
		PUSHs (sv_2mortal (newSViv (ymd[2])));
	}

IV
year(date)
	SV* date
	CODE:
	{
		IV ymd[3];
		if (! SvROK (date))
			XSRETURN_UNDEF;

		days_to_ymd (SvIV (SvRV (date)), ymd);
		RETVAL = ymd[0];
	}
	OUTPUT:
	RETVAL

IV
month(date)
	SV* date
	CODE:
	{
		IV ymd[3];
		if (! SvROK (date))
			XSRETURN_UNDEF;

		days_to_ymd (SvIV (SvRV (date)), ymd);
		RETVAL = ymd[1];
	}
	OUTPUT:
	RETVAL

IV
day(date)
	SV* date
	CODE:
	{
		IV ymd[3];
		if (! SvROK (date))
			XSRETURN_UNDEF;

		days_to_ymd (SvIV (SvRV (date)), ymd);
		RETVAL = ymd[2];
	}
	OUTPUT:
	RETVAL



SV*
as_iso(date, ...)
	SV* date
	CODE:
	{
		IV ymd[3];
		if (! SvROK (date))
			XSRETURN_UNDEF;

		days_to_ymd (SvIV (SvRV (date)), ymd);
		RETVAL = newSVpvf ("%04d-%02d-%02d", (int) ymd[0] % 10000,
				   (int) ymd[1], (int) ymd[2]);
	}
	OUTPUT:
	RETVAL


SV*
as_d8(date, ...)
	SV* date
	CODE:
	{
		IV ymd[3];
		if (! SvROK (date))
			XSRETURN_UNDEF;

		days_to_ymd (SvIV (SvRV (date)), ymd);
		RETVAL = newSVpvf ("%04d%02d%02d", (int)ymd[0] % 10000,
				   (int) ymd[1], (int) ymd[2]);
	}
	OUTPUT:
	RETVAL

void
as_ymd(date)
	SV* date
	PPCODE:
	{
		IV ymd[3];
		if (! SvROK (date))
			XSRETURN_EMPTY;

		days_to_ymd (SvIV (SvRV (date)), ymd);
		EXTEND (sp, 3);
		PUSHs (sv_2mortal (newSViv (ymd[0])));
		PUSHs (sv_2mortal (newSViv (ymd[1])));
		PUSHs (sv_2mortal (newSViv (ymd[2])));
	}

SV*
_add(date, diff, ...)
	SV* date
	IV diff
	CODE:
	{
	        dSP;

	        SV* new_date;
		SV* format;

		IV days;

		if (! is_object (date))
			XSRETURN_UNDEF;

		days = SvIV (SvRV (date)) + diff;

		new_date = sv_bless(newRV_noinc(newSViv(days)),
				    SvSTASH(SvRV(date)));

		PUSHMARK(SP);
		XPUSHs(date);
		PUTBACK;

		call_method("default_format", G_SCALAR);

		SPAGAIN;

		format = POPs;

		PUSHMARK(SP);
		XPUSHs(new_date);
		XPUSHs(format);
		PUTBACK;

		call_method("default_format", G_DISCARD);

		RETVAL = new_date;

	}
	OUTPUT:
                RETVAL

SV*
_subtract(left, right, reverse)
	SV* left
	SV* right
	SV* reverse
	CODE:
	{
		if (! is_object (left))
			XSRETURN_UNDEF;

		if (SvTRUE (reverse))
			croak ("Can't subtract a date from a non-date");

		if (SvROK (right))
		{
			IV diff = SvIV (SvRV (left)) - SvIV (SvRV (right));
			RETVAL = newSViv (diff);
		}
		else
		{
			IV days = SvIV (SvRV (left)) - SvIV (right);
			SV* new_date = sv_bless (newRV_noinc (newSViv (days)),
						 SvSTASH (SvRV (left)));
			SV* format;

			dSP;

			PUSHMARK(SP);
			XPUSHs(left);
			PUTBACK;

			call_method("default_format", G_SCALAR);

			SPAGAIN;

			format = POPs;

			PUSHMARK(SP);
			XPUSHs(new_date);
			XPUSHs(format);
			PUTBACK;

			call_method("default_format", G_DISCARD);

			RETVAL = new_date;
		}
	}
	OUTPUT:
	RETVAL

IV
_compare(left, right, reverse)
	SV* left
	SV* right
	bool reverse
	CODE:
	{
		IV diff;

		if (! is_object (left))
			XSRETURN_UNDEF;

		if (! is_object (right))
			right = new_for_cmp (left, right, 1);

		diff = SvIV (SvRV (left)) - SvIV (SvRV (right));
		RETVAL = diff > 0 ? 1 : (diff < 0 ? -1 : 0);

		if (reverse)
			RETVAL = -RETVAL;
	}
	OUTPUT:
	RETVAL

SV*
_eq(left, right, reverse)
	SV* left
	SV* right
	bool reverse
	CODE:
	{
		if (! is_object (left))
			XSRETURN_UNDEF;

		if (! is_object (right))
			right = new_for_cmp (left, right, 0);

		if (! is_object (right))
			XSRETURN_NO;

		if (SvIV (SvRV (left)) == SvIV (SvRV (right)))
			XSRETURN_YES;
		else
			XSRETURN_NO;
	}
	OUTPUT:
	RETVAL

SV*
_ne(left, right, reverse)
	SV* left
	SV* right
	bool reverse
	CODE:
	{
		if (! is_object (left))
			XSRETURN_UNDEF;

		if (! is_object (right))
			right = new_for_cmp (left, right, 0);

		if (! is_object (right))
			XSRETURN_YES;

		if (SvIV (SvRV (left)) == SvIV (SvRV (right)))
			XSRETURN_NO;
		else
			XSRETURN_YES;
	}
	OUTPUT:
	RETVAL

IV
day_of_week(date)
	SV* date
	CODE:
	{
		IV days;
		if (! SvROK (date))
			XSRETURN_UNDEF;

		RETVAL = (SvIV (SvRV (date)) + 4) % 7;
		if (RETVAL < 0)
			RETVAL += 7;
	}
	OUTPUT:
	RETVAL
