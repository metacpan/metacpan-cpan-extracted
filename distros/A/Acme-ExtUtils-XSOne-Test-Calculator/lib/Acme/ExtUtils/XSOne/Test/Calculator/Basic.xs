/*
 * Acme::ExtUtils::XSOne::Test::Calculator::Basic - Basic arithmetic operations
 */

#include <math.h>

/* C helper functions for Basic package */
static double basic_safe_divide(double a, double b, int *error) {
    if (b == 0.0) {
        *error = 1;
        return 0.0;
    }
    *error = 0;
    return a / b;
}

static double basic_clamp(double value, double min_val, double max_val) {
    if (value < min_val) return min_val;
    if (value > max_val) return max_val;
    return value;
}

static double basic_percent(double value, double percent) {
    return value * percent / 100.0;
}

MODULE = Acme::ExtUtils::XSOne::Test::Calculator    PACKAGE = Acme::ExtUtils::XSOne::Test::Calculator::Basic

PROTOTYPES: DISABLE

double
add(a, b)
    double a
    double b
CODE:
    RETVAL = a + b;
    add_to_history('+', a, b, RETVAL);
OUTPUT:
    RETVAL

double
subtract(a, b)
    double a
    double b
CODE:
    RETVAL = a - b;
    add_to_history('-', a, b, RETVAL);
OUTPUT:
    RETVAL

double
multiply(a, b)
    double a
    double b
CODE:
    RETVAL = a * b;
    add_to_history('*', a, b, RETVAL);
OUTPUT:
    RETVAL

double
divide(a, b)
    double a
    double b
CODE:
    if (b == 0.0) {
        croak("Division by zero");
    }
    RETVAL = a / b;
    add_to_history('/', a, b, RETVAL);
OUTPUT:
    RETVAL

double
modulo(a, b)
    double a
    double b
CODE:
    if (b == 0.0) {
        croak("Modulo by zero");
    }
    RETVAL = fmod(a, b);
    add_to_history('%', a, b, RETVAL);
OUTPUT:
    RETVAL

double
negate(a)
    double a
CODE:
    RETVAL = -a;
    add_to_history('n', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
absolute(a)
    double a
CODE:
    RETVAL = fabs(a);
    add_to_history('a', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
safe_divide(a, b)
    double a
    double b
CODE:
    int error;
    RETVAL = basic_safe_divide(a, b, &error);
    if (error) {
        RETVAL = 0.0;  /* Return 0 instead of croak */
    }
    add_to_history('/', a, b, RETVAL);
OUTPUT:
    RETVAL

double
clamp(value, min_val, max_val)
    double value
    double min_val
    double max_val
CODE:
    RETVAL = basic_clamp(value, min_val, max_val);
OUTPUT:
    RETVAL

double
percent(value, pct)
    double value
    double pct
CODE:
    RETVAL = basic_percent(value, pct);
    add_to_history('%', value, pct, RETVAL);
OUTPUT:
    RETVAL

void
import(...)
CODE:
{
    static const char *basic_exports[] = {
        "add", "subtract", "multiply", "divide", "modulo",
        "negate", "absolute", "safe_divide", "clamp", "percent"
    };
    do_import(aTHX_ "Acme::ExtUtils::XSOne::Test::Calculator::Basic",
              basic_exports, 10, items, ax);
}
