/*
 * Acme::ExtUtils::XSOne::Test::Calculator::Trig - Trigonometric functions
 */

#include <math.h>

/* C helper functions for Trig package */
static double trig_normalize_angle(double radians) {
    /* Normalize angle to [-PI, PI] */
    while (radians > M_PI) radians -= 2.0 * M_PI;
    while (radians < -M_PI) radians += 2.0 * M_PI;
    return radians;
}

static int trig_is_valid_asin_arg(double x) {
    return (x >= -1.0 && x <= 1.0);
}

static double trig_sec(double x) {
    return 1.0 / cos(x);
}

static double trig_csc(double x) {
    return 1.0 / sin(x);
}

static double trig_cot(double x) {
    return cos(x) / sin(x);
}

MODULE = Acme::ExtUtils::XSOne::Test::Calculator    PACKAGE = Acme::ExtUtils::XSOne::Test::Calculator::Trig

PROTOTYPES: DISABLE

double
sin_val(a)
    double a
CODE:
    RETVAL = sin(a);
    add_to_history('s', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
cos_val(a)
    double a
CODE:
    RETVAL = cos(a);
    add_to_history('c', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
tan_val(a)
    double a
CODE:
    RETVAL = tan(a);
    add_to_history('t', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
asin_val(a)
    double a
CODE:
    if (a < -1.0 || a > 1.0) {
        croak("asin argument must be in [-1, 1]");
    }
    RETVAL = asin(a);
    add_to_history('S', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
acos_val(a)
    double a
CODE:
    if (a < -1.0 || a > 1.0) {
        croak("acos argument must be in [-1, 1]");
    }
    RETVAL = acos(a);
    add_to_history('C', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
atan_val(a)
    double a
CODE:
    RETVAL = atan(a);
    add_to_history('T', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
atan2_val(y, x)
    double y
    double x
CODE:
    RETVAL = atan2(y, x);
    add_to_history('A', y, x, RETVAL);
OUTPUT:
    RETVAL

double
deg_to_rad(degrees)
    double degrees
CODE:
    RETVAL = degrees * M_PI / 180.0;
OUTPUT:
    RETVAL

double
rad_to_deg(radians)
    double radians
CODE:
    RETVAL = radians * 180.0 / M_PI;
OUTPUT:
    RETVAL

double
hypot_val(a, b)
    double a
    double b
CODE:
    RETVAL = hypot(a, b);
    add_to_history('h', a, b, RETVAL);
OUTPUT:
    RETVAL

double
normalize_angle(radians)
    double radians
CODE:
    RETVAL = trig_normalize_angle(radians);
OUTPUT:
    RETVAL

double
sec_val(a)
    double a
CODE:
    RETVAL = trig_sec(a);
    add_to_history('E', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
csc_val(a)
    double a
CODE:
    RETVAL = trig_csc(a);
    add_to_history('O', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
cot_val(a)
    double a
CODE:
    RETVAL = trig_cot(a);
    add_to_history('G', a, 0, RETVAL);
OUTPUT:
    RETVAL

int
is_valid_asin_arg(x)
    double x
CODE:
    RETVAL = trig_is_valid_asin_arg(x);
OUTPUT:
    RETVAL

void
import(...)
CODE:
{
    static const char *trig_exports[] = {
        "sin_val", "cos_val", "tan_val",
        "asin_val", "acos_val", "atan_val", "atan2_val",
        "deg_to_rad", "rad_to_deg", "hypot_val",
        "normalize_angle", "sec_val", "csc_val", "cot_val",
        "is_valid_asin_arg"
    };
    do_import(aTHX_ "Acme::ExtUtils::XSOne::Test::Calculator::Trig",
              trig_exports, 15, items, ax);
}
