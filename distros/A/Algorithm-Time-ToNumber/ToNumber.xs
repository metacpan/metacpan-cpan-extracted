#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

static void
parse_suricata_week(const char *timestamp, double *sin_out, double *cos_out)
{
    int year = 0, mon = 0, mday = 0, h = 0, m = 0;
    double s = 0.0;
    double week_seconds, angle;
    struct tm tm;

    memset(&tm, 0, sizeof(struct tm));
    sscanf(timestamp, "%4d-%2d-%2dT%d:%d:%lf",
           &year, &mon, &mday, &h, &m, &s);

    tm.tm_year = year - 1900;
    tm.tm_mon  = mon - 1;
    tm.tm_mday = mday;
    tm.tm_isdst = -1;
    mktime(&tm);

    week_seconds = tm.tm_wday * 86400.0 + h * 3600.0 + m * 60.0 + s;
    angle = 6.28318530717958647692528 * week_seconds / 604800.0;

    *sin_out = sin(angle);
    if (cos_out != NULL)
        *cos_out = cos(angle);
}

MODULE = Algorithm::Time::ToNumber    PACKAGE = Algorithm::Time::ToNumber

void
suricata_to_circle_both(class, timestamp)
    SV *class
    char *timestamp
PREINIT:
    double sin_val;
    double cos_val;
PPCODE:
    (void)class;
    parse_suricata_week(timestamp, &sin_val, &cos_val);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVnv(sin_val)));
    PUSHs(sv_2mortal(newSVnv(cos_val)));

double
suricata_to_angle_both(class, timestamp)
    SV *class
    char *timestamp
PREINIT:
    double sin_val;
CODE:
    (void)class;
    parse_suricata_week(timestamp, &sin_val, NULL);
    RETVAL = sin_val;
OUTPUT:
    RETVAL
