/*---------------------------------------------------------------------------
 * dtl_posix.h - POSIX TZ footer parser for DateTime::Lite
 *
 * Derived from tzcode2026a/localtime.c and tzcode2026a/private.h,
 * which are in the public domain:
 *   "Unless specified below, all files in the tz code and data are in the
 *    public domain." (tzcode2026a/LICENSE)
 *
 * Adaptations for DateTime::Lite XS:
 *   - Extracted only the functions required to evaluate a POSIX TZ footer
 *     string for a single UTC timestamp: is_digit, getzname, getqzname,
 *     getnum, getsecs, getoffset, getrule, transtime.
 *   - All functions prefixed with dtl_ to avoid symbol collisions.
 *   - ATTRIBUTE_PURE_114833 and unreachable() replaced with portable
 *     equivalents safe under any C89/C99/C11 compiler.
 *   - Static linkage retained throughout; nothing is exported.
 *   - No dynamic allocation, no system calls, no global state.
 *   - Added dtl_posix_tz_lookup(): the single public entry point used by the
 *     XS layer. Given a UTC Unix timestamp and a POSIX TZ string, such as
 *     "EST5EDT,M3.2.0,M11.1.0", it returns the UTC offset in seconds, the
 *     DST flag, and the time-zone abbreviation.
 *
 * This file is included once, directly into DateTime-Lite.xs.
 *---------------------------------------------------------------------------*/

#ifndef DTL_POSIX_H
#define DTL_POSIX_H

#include <stdint.h>   /* int_fast32_t */
#include <string.h>   /* memcpy */
#include <stddef.h>  /* ptrdiff_t */
#include <limits.h>

/*---------------------------------------------------------------------------
 * Portability shims
 *---------------------------------------------------------------------------*/

/* Portable no-return hint for unreachable code paths.
 * The default is a no-op; the compiler may warn about missing returns
 * but the code is correct. */
#ifndef dtl_unreachable
#  if defined(__GNUC__) || defined(__clang__)
#    define dtl_unreachable() __builtin_unreachable()
#  else
#    define dtl_unreachable() ((void)0)
#  endif
#endif

/*---------------------------------------------------------------------------
 * Constants (from tzcode private.h, public domain)
 *---------------------------------------------------------------------------*/
enum
{
    DTL_SECSPERMIN    = 60,
    DTL_MINSPERHOUR   = 60,
    DTL_SECSPERHOUR   = DTL_SECSPERMIN * DTL_MINSPERHOUR,
    DTL_HOURSPERDAY   = 24,
    DTL_DAYSPERWEEK   = 7,
    DTL_DAYSPERNYEAR  = 365,
    DTL_DAYSPERLYEAR  = DTL_DAYSPERNYEAR + 1,
    DTL_MONSPERYEAR   = 12,
    DTL_EPOCH_YEAR    = 1970
};

#define DTL_SECSPERDAY  ((int_fast32_t) DTL_SECSPERHOUR * DTL_HOURSPERDAY)

/* Maximum length of a TZ abbreviation, per POSIX (we follow tzcode). */
#define DTL_TZNAME_MAXIMUM 254

/* Default DST rule used when footer has a DST name but no explicit rule.
 * This matches the tzcode default: US Eastern DST rules (spring forward
 * second Sunday in March, fall back first Sunday in November). */
#define DTL_TZDEFRULESTRING ",M3.2.0,M11.1.0"

/*---------------------------------------------------------------------------
 * isleap (from tzcode private.h, public domain)
 *---------------------------------------------------------------------------*/
#define dtl_isleap(y) \
    (((y) % 4) == 0 && (((y) % 100) != 0 || ((y) % 400) == 0))

/*---------------------------------------------------------------------------
 * Month and year length tables (from tzcode localtime.c, public domain)
 *---------------------------------------------------------------------------*/
static const int dtl_mon_lengths[2][DTL_MONSPERYEAR] =
{
    { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
    { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
};

static const int dtl_year_lengths[2] =
{
    DTL_DAYSPERNYEAR,
    DTL_DAYSPERLYEAR
};

/*---------------------------------------------------------------------------
 * struct dtl_rule (derived from tzcode localtime.c, public domain)
 *
 * Encodes one half of a DST transition rule (start or end).
 *---------------------------------------------------------------------------*/

enum dtl_r_type
{
    DTL_JULIAN_DAY,            /* Jn  = Julian day 1-365 (no leap day)     */
    DTL_DAY_OF_YEAR,           /* n   = day 0-365 (leap day counted)        */
    DTL_MONTH_NTH_DAY_OF_WEEK  /* Mm.w.d = month m, week w (1-5), day d    */
};

struct dtl_rule
{
    enum dtl_r_type r_type;    /* which form of rule                        */
    int             r_day;     /* day number                                */
    int             r_week;    /* week number (Mm.w.d only)                 */
    int             r_mon;     /* month number (Mm.w.d only)                */
    int_fast32_t    r_time;    /* transition wall-clock time in seconds     */
};

/*---------------------------------------------------------------------------
 * is_digit (from tzcode localtime.c, public domain)
 *---------------------------------------------------------------------------*/
static int
dtl_is_digit(char c)
{
    return '0' <= c && c <= '9';
}

/*---------------------------------------------------------------------------
 * getzname (from tzcode localtime.c, public domain)
 *
 * Advance past an unquoted TZ abbreviation (e.g. "EST") and return a
 * pointer to the first character that is not part of the name.
 *---------------------------------------------------------------------------*/
static const char *
dtl_getzname(register const char *strp)
{
    register char c;

    while( ( c = *strp ) != '\0' && !dtl_is_digit(c) &&
           c != ',' && c != '-' && c != '+' )
        ++strp;
    return strp;
}

/*---------------------------------------------------------------------------
 * getqzname (from tzcode localtime.c, public domain)
 *
 * Advance past a quoted TZ abbreviation enclosed by delim (e.g. '<+05:30>')
 * and return a pointer to the delimiter character.
 *---------------------------------------------------------------------------*/
static const char *
dtl_getqzname(register const char *strp, const int delim)
{
    register int c;

    while( ( c = *strp ) != '\0' && c != delim )
        ++strp;
    return strp;
}

/*---------------------------------------------------------------------------
 * getnum (from tzcode localtime.c, public domain)
 *
 * Extract a decimal integer in [min, max] from strp.
 * Returns a pointer to the first non-digit character, or NULL on error.
 *---------------------------------------------------------------------------*/
static const char *
dtl_getnum(register const char *strp, int *const nump,
           const int min, const int max)
{
    register char c;
    register int  num;

    if( strp == NULL || !dtl_is_digit( c = *strp ) )
        return NULL;
    num = 0;
    do
    {
        num = num * 10 + ( c - '0' );
        if( num > max )
            return NULL;    /* value out of range */
        c = *++strp;
    }
    while( dtl_is_digit(c) );
    if( num < min )
        return NULL;        /* value out of range */
    *nump = num;
    return strp;
}

/*---------------------------------------------------------------------------
 * getsecs (from tzcode localtime.c, public domain)
 *
 * Parse hh[:mm[:ss]] into *secsp. The hour is clamped to the range
 * [0, HOURSPERDAY * DAYSPERWEEK - 1] to allow quasi-POSIX rules like
 * "M10.4.6/26" (hour 26 = 02:00 two days later).
 * Returns a pointer past the parsed text, or NULL on error.
 *---------------------------------------------------------------------------*/
static const char *
dtl_getsecs(register const char *strp, int_fast32_t *const secsp)
{
    int num;

    strp = dtl_getnum( strp, &num, 0,
                       DTL_HOURSPERDAY * DTL_DAYSPERWEEK - 1 );
    if( strp == NULL )
        return NULL;
    *secsp = (int_fast32_t) num * DTL_SECSPERHOUR;
    if( *strp == ':' )
    {
        ++strp;
        strp = dtl_getnum( strp, &num, 0, DTL_MINSPERHOUR - 1 );
        if( strp == NULL )
            return NULL;
        *secsp += num * DTL_SECSPERMIN;
        if( *strp == ':' )
        {
            ++strp;
            /* DTL_SECSPERMIN + 1 allows for a leap second. */
            strp = dtl_getnum( strp, &num, 0, DTL_SECSPERMIN );
            if( strp == NULL )
                return NULL;
            *secsp += num;
        }
    }
    return strp;
}

/*---------------------------------------------------------------------------
 * getoffset (from tzcode localtime.c, public domain)
 *
 * Parse [+-]hh[:mm[:ss]] into *offsetp.
 * NOTE: POSIX convention - positive value means WEST of UTC.
 *       We preserve that convention here; callers negate as needed.
 * Returns a pointer past the parsed text, or NULL on error.
 *---------------------------------------------------------------------------*/
static const char *
dtl_getoffset(register const char *strp, int_fast32_t *const offsetp)
{
    register int neg = 0;

    if( *strp == '-' )
    {
        neg = 1;
        ++strp;
    }
    else if( *strp == '+' )
    {
        ++strp;
    }

    strp = dtl_getsecs( strp, offsetp );
    if( strp == NULL )
        return NULL;
    if( neg )
        *offsetp = -*offsetp;
    return strp;
}

/*---------------------------------------------------------------------------
 * getrule (from tzcode localtime.c, public domain)
 *
 * Parse a DST transition rule in one of three forms:
 *   Jn          Julian day (1-365, leap day not counted)
 *   n           Day of year (0-365, leap day counted)
 *   Mm.w.d      Month m (1-12), week w (1-5), day-of-week d (0=Sun)
 * Optionally followed by /time (default 02:00:00).
 *
 * Per RFC 9636 section 3.3.2, time may be negative or exceed 24 h
 * (TZif v3+ extension); dtl_getoffset() already handles the sign.
 *
 * Returns a pointer past the parsed rule, or NULL on error.
 *---------------------------------------------------------------------------*/
static const char *
dtl_getrule(const char *strp, register struct dtl_rule *const rulep)
{
    if( *strp == 'J' )
    {
        /* Julian day: 1-365, leap day not counted. */
        rulep->r_type = DTL_JULIAN_DAY;
        ++strp;
        strp = dtl_getnum( strp, &rulep->r_day, 1, DTL_DAYSPERNYEAR );
    }
    else if( *strp == 'M' )
    {
        /* Month, week, day of week. */
        rulep->r_type = DTL_MONTH_NTH_DAY_OF_WEEK;
        ++strp;
        strp = dtl_getnum( strp, &rulep->r_mon, 1, DTL_MONSPERYEAR );
        if( strp == NULL )
            return NULL;
        if( *strp++ != '.' )
            return NULL;
        strp = dtl_getnum( strp, &rulep->r_week, 1, 5 );
        if( strp == NULL )
            return NULL;
        if( *strp++ != '.' )
            return NULL;
        strp = dtl_getnum( strp, &rulep->r_day, 0, DTL_DAYSPERWEEK - 1 );
    }
    else if( dtl_is_digit(*strp) )
    {
        /* Day of year: 0-365. */
        rulep->r_type = DTL_DAY_OF_YEAR;
        strp = dtl_getnum( strp, &rulep->r_day, 0, DTL_DAYSPERLYEAR - 1 );
    }
    else
    {
        return NULL;  /* unrecognised rule format */
    }

    if( strp == NULL )
        return NULL;

    if( *strp == '/' )
    {
        /* Explicit transition time. */
        ++strp;
        strp = dtl_getoffset( strp, &rulep->r_time );
    }
    else
    {
        rulep->r_time = 2 * DTL_SECSPERHOUR;  /* default: 02:00:00 */
    }

    return strp;
}

/*---------------------------------------------------------------------------
 * transtime  (from tzcode localtime.c, public domain)
 *
 * Given a year, a parsed rule, and the UTC offset in effect when the
 * transition occurs (signed, seconds east of UTC), return the YEAR-RELATIVE
 * time (seconds since midnight Jan 1 of that year, UTC) at which the
 * transition occurs.
 *
 * Uses Zeller's Congruence for the Mm.w.d case; purely arithmetic, no
 * library calls.
 *---------------------------------------------------------------------------*/
static int_fast32_t
dtl_transtime(const int year,
              register const struct dtl_rule *const rulep,
              const int_fast32_t offset)
{
    register int        leapyear;
    register int_fast32_t value;
    register int        i;
    int                 d, m1, yy0, yy1, yy2, dow;

    leapyear = dtl_isleap(year);
    switch( rulep->r_type )
    {
        case DTL_JULIAN_DAY:
            /*
             * Jn: Julian day 1-365. Leap day is not counted; in a leap year,
             * day 60 and later are shifted by one extra day.
             */
            value = ( rulep->r_day - 1 ) * DTL_SECSPERDAY;
            if( leapyear && rulep->r_day >= 60 )
                value += DTL_SECSPERDAY;
            break;

        case DTL_DAY_OF_YEAR:
            /*
             * n: day of year 0-365. Simple multiplication.
             */
            value = rulep->r_day * DTL_SECSPERDAY;
            break;

        case DTL_MONTH_NTH_DAY_OF_WEEK:
            /*
             * Mm.w.d: nth occurrence of weekday d in month m.
             * Use Zeller's Congruence to find the day-of-week of the first
             * day of month m in year.
             */
            m1  = ( rulep->r_mon + 9 ) % 12 + 1;
            yy0 = ( rulep->r_mon <= 2 ) ? ( year - 1 ) : year;
            yy1 = yy0 / 100;
            yy2 = yy0 % 100;
            dow = ( ( 26 * m1 - 2 ) / 10 +
                    1 + yy2 + yy2 / 4 + yy1 / 4 - 2 * yy1 ) % 7;
            if( dow < 0 )
                dow += DTL_DAYSPERWEEK;

            /* d = zero-origin day-of-month of first occurrence of r_day in
             * this month. */
            d = rulep->r_day - dow;
            if( d < 0 )
                d += DTL_DAYSPERWEEK;

            /* Advance by (r_week - 1) weeks, clamping to month end. */
            for( i = 1; i < rulep->r_week; ++i )
            {
                if( d + DTL_DAYSPERWEEK >=
                    dtl_mon_lengths[leapyear][rulep->r_mon - 1] )
                    break;
                d += DTL_DAYSPERWEEK;
            }

            /* d is zero-origin day-of-month. Accumulate month offsets. */
            value = d * DTL_SECSPERDAY;
            for( i = 0; i < rulep->r_mon - 1; ++i )
                value += dtl_mon_lengths[leapyear][i] * DTL_SECSPERDAY;
            break;

        default:
            dtl_unreachable();
            value = 0;
            break;
    }

    /*
     * value is seconds since Jan 1 00:00:00 UTC of this year on the transition
     * day. Add the wall-clock time and subtract the UTC offset to convert to
     * UTC seconds-since-Jan-1.
     */
    return value + rulep->r_time - offset;
}

/*---------------------------------------------------------------------------
 * dtl_year_to_jan1  (new, not from tzcode)
 *
 * Return the Unix timestamp of midnight UTC on January 1 of year.
 * Valid for years >= 1970. Uses pure arithmetic; no library calls.
 *---------------------------------------------------------------------------*/
static int_fast64_t
dtl_year_to_jan1(int year)
{
    int_fast64_t days;
    int          y;

    /* Count days from 1970-01-01 to year-01-01. */
    y    = year - 1;
    days = (int_fast64_t)(year - DTL_EPOCH_YEAR) * DTL_DAYSPERNYEAR
           + ( y / 4   - (DTL_EPOCH_YEAR - 1) / 4   )
           - ( y / 100 - (DTL_EPOCH_YEAR - 1) / 100 )
           + ( y / 400 - (DTL_EPOCH_YEAR - 1) / 400 );

    return days * DTL_SECSPERDAY;
}

/*---------------------------------------------------------------------------
 * dtl_posix_tz_result  (new, not from tzcode)
 *
 * Convenience struct for the result of dtl_posix_tz_lookup().
 *---------------------------------------------------------------------------*/
#define DTL_POSIX_ABBR_MAX 32

typedef struct
{
    int_fast32_t offset;                    /* seconds east of UTC  */
    int          is_dst;                    /* 1 if DST, 0 if std   */
    char         abbr[DTL_POSIX_ABBR_MAX];  /* NUL-terminated abbr  */
    int          valid;                     /* 1 if result is valid */
} dtl_posix_tz_result;

/*---------------------------------------------------------------------------
 * dtl_posix_tz_lookup  (new, not from tzcode)
 *
 * Given a UTC Unix timestamp and a POSIX TZ footer string, compute the UTC
 * offset, DST status, and time-zone abbreviation in effect at that timestamp.
 *
 * Algorithm:
 *   1. Parse the standard name and offset from the footer string.
 *   2. If no DST suffix is present, return the standard offset.
 *   3. Parse the DST name, optional DST offset (default std - 1 h in POSIX
 *      convention, i.e. std_offset - 3600 in UTC terms).
 *   4. Parse the start and end DST rules.
 *   5. Use dtl_transtime() to find the transition timestamps for the year
 *      containing unix_secs.
 *   6. Compare unix_secs with the two transition times to decide which half
 *      of the year it falls in. Handle both northern-hemisphere (start < end)
 *      and southern-hemisphere (start > end) cases.
 *
 * The result is written into *res. On parse error, res->valid = 0.
 *---------------------------------------------------------------------------*/
static void
dtl_posix_tz_lookup(int_fast64_t unix_secs,
                    const char  *tz_str,
                    dtl_posix_tz_result *res)
{
    const char       *p = tz_str;
    const char       *stdname, *dstname;
    ptrdiff_t         stdlen,   dstlen;
    int_fast32_t      stdoffset, dstoffset;
    struct dtl_rule   start_rule, end_rule;
    int               have_dst_rule;
    int_fast64_t      jan1;
    int_fast32_t      start_trans, end_trans;
    int               year;
    int               is_dst;

    res->valid = 0;

    /*-----------------------------------------------------------------------
     * Parse the standard abbreviation.
     *-----------------------------------------------------------------------*/
    if( *p == '<' )
    {
        ++p;
        stdname = p;
        p = dtl_getqzname( p, '>' );
        if( *p != '>' )
            return;
        stdlen = p - stdname;
        ++p;
    }
    else
    {
        stdname = p;
        p = dtl_getzname( p );
        stdlen = p - stdname;
    }
    if( stdlen <= 0 || stdlen >= DTL_TZNAME_MAXIMUM )
        return;

    /*-----------------------------------------------------------------------
     * Parse the standard UTC offset (mandatory).
     * POSIX convention: positive = WEST. We negate to get UTC east.
     *-----------------------------------------------------------------------*/
    p = dtl_getoffset( p, &stdoffset );
    if( p == NULL )
        return;
    /* stdoffset is now seconds WEST of UTC; negate for east convention. */
    stdoffset = -stdoffset;

    /*-----------------------------------------------------------------------
     * If no DST suffix, return standard time unconditionally.
     *-----------------------------------------------------------------------*/
    if( *p == '\0' )
    {
        res->valid   = 1;
        res->is_dst  = 0;
        res->offset  = stdoffset;
        {
            int n = (int)( stdlen < DTL_POSIX_ABBR_MAX - 1
                           ? stdlen : DTL_POSIX_ABBR_MAX - 1 );
            memcpy( res->abbr, stdname, (size_t)n );
            res->abbr[n] = '\0';
        }
        return;
    }

    /*-----------------------------------------------------------------------
     * Parse the DST abbreviation.
     *-----------------------------------------------------------------------*/
    if( *p == '<' )
    {
        ++p;
        dstname = p;
        p = dtl_getqzname( p, '>' );
        if( *p != '>' )
            return;
        dstlen = p - dstname;
        ++p;
    }
    else
    {
        dstname = p;
        p = dtl_getzname( p );
        dstlen = p - dstname;
    }
    if( dstlen <= 0 || dstlen >= DTL_TZNAME_MAXIMUM )
        return;

    /*-----------------------------------------------------------------------
     * Optional DST offset (default: std + 1 h in UTC east convention,
     * which corresponds to stdoffset_POSIX - 1 h, i.e. one hour closer
     * to UTC than the standard offset in POSIX terms).
     *-----------------------------------------------------------------------*/
    if( *p != '\0' && *p != ',' && *p != ';' )
    {
        int_fast32_t raw_dst;
        p = dtl_getoffset( p, &raw_dst );
        if( p == NULL )
            return;
        dstoffset = -raw_dst;  /* negate POSIX to UTC east */
    }
    else
    {
        /* Default: DST = standard + 1 h. */
        dstoffset = stdoffset + DTL_SECSPERHOUR;
    }

    /*-----------------------------------------------------------------------
     * If no rule follows, use the POSIX default rule.
     *-----------------------------------------------------------------------*/
    if( *p == '\0' )
        p = DTL_TZDEFRULESTRING;

    if( *p != ',' && *p != ';' )
        return;

    /*-----------------------------------------------------------------------
     * Parse the DST start rule.
     *-----------------------------------------------------------------------*/
    p = dtl_getrule( p + 1, &start_rule );
    if( p == NULL || *p != ',' )
        return;

    /*-----------------------------------------------------------------------
     * Parse the DST end rule.
     *-----------------------------------------------------------------------*/
    p = dtl_getrule( p + 1, &end_rule );
    if( p == NULL || *p != '\0' )
        return;

    have_dst_rule = 1;
    (void)have_dst_rule;

    /*-----------------------------------------------------------------------
     * Determine the year and compute Jan 1 UTC for that year.
     *-----------------------------------------------------------------------*/
    {
        /* Approximate year from unix timestamp (good enough for +-9999). */
        int_fast64_t days_since_epoch = unix_secs / DTL_SECSPERDAY;
        year = DTL_EPOCH_YEAR + (int)( days_since_epoch / DTL_DAYSPERNYEAR );
        /* Adjust: make sure jan1 <= unix_secs. */
        jan1 = dtl_year_to_jan1( year );
        while( jan1 > unix_secs )
        {
            --year;
            jan1 = dtl_year_to_jan1( year );
        }
        while( dtl_year_to_jan1( year + 1 ) <= unix_secs )
        {
            ++year;
            jan1 = dtl_year_to_jan1( year );
        }
    }

    /*-----------------------------------------------------------------------
     * Compute the UTC timestamps of the DST start and end transitions.
     *
     * dtl_transtime() returns year-relative seconds (from Jan 1 00:00 UTC)
     * with offset already factored in; add jan1 to get Unix timestamp.
     *
     * For the start (std -> DST):  offset in effect = stdoffset
     * For the end   (DST -> std):  offset in effect = dstoffset
     *-----------------------------------------------------------------------*/
    start_trans = (int_fast32_t)( jan1 +
                  dtl_transtime( year, &start_rule, stdoffset ) );
    end_trans   = (int_fast32_t)( jan1 +
                  dtl_transtime( year, &end_rule,   dstoffset ) );

    /*-----------------------------------------------------------------------
     * Determine DST vs standard.
     *
     * Northern hemisphere: DST active when start_trans <= t < end_trans.
     * Southern hemisphere: DST active when t >= start_trans OR t < end_trans.
     *-----------------------------------------------------------------------*/
    if( start_trans < end_trans )
        is_dst = ( unix_secs >= start_trans && unix_secs < end_trans ) ? 1 : 0;
    else
        is_dst = ( unix_secs >= start_trans || unix_secs < end_trans ) ? 1 : 0;

    /*-----------------------------------------------------------------------
     * Fill in result.
     *-----------------------------------------------------------------------*/
    res->valid  = 1;
    res->is_dst = is_dst;
    res->offset = is_dst ? dstoffset : stdoffset;
    {
        const char *name   = is_dst ? dstname : stdname;
        ptrdiff_t   namelen = is_dst ? dstlen  : stdlen;
        int n = (int)( namelen < DTL_POSIX_ABBR_MAX - 1
                       ? namelen : DTL_POSIX_ABBR_MAX - 1 );
        memcpy( res->abbr, name, (size_t)n );
        res->abbr[n] = '\0';
    }
}

#endif /* DTL_POSIX_H */
