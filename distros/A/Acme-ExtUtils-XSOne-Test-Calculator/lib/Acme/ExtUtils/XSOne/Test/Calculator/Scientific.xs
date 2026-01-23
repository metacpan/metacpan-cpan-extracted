/*
 * Acme::ExtUtils::XSOne::Test::Calculator::Scientific - Scientific/advanced operations
 */

#include <math.h>

/* C helper functions for Scientific package */
static double sci_safe_log(double a, int *error) {
    if (a <= 0.0) {
        *error = 1;
        return 0.0;
    }
    *error = 0;
    return log(a);
}

static double sci_safe_sqrt(double a, int *error) {
    if (a < 0.0) {
        *error = 1;
        return 0.0;
    }
    *error = 0;
    return sqrt(a);
}

static double sci_ipow(double base, int exp) {
    /* Integer power - faster than pow() for integer exponents */
    if (exp == 0) return 1.0;
    int neg = 0;
    if (exp < 0) {
        neg = 1;
        exp = -exp;
    }
    double result = 1.0;
    while (exp > 0) {
        if (exp & 1) result *= base;
        base *= base;
        exp >>= 1;
    }
    return neg ? 1.0 / result : result;
}

static double sci_combination(int n, int r) {
    if (r > n || r < 0) return 0.0;
    if (r == 0 || r == n) return 1.0;
    double result = 1.0;
    for (int i = 0; i < r; i++) {
        result = result * (n - i) / (i + 1);
    }
    return result;
}

MODULE = Acme::ExtUtils::XSOne::Test::Calculator    PACKAGE = Acme::ExtUtils::XSOne::Test::Calculator::Scientific

PROTOTYPES: DISABLE

double
power(base, exp)
    double base
    double exp
CODE:
    RETVAL = pow(base, exp);
    add_to_history('^', base, exp, RETVAL);
OUTPUT:
    RETVAL

double
sqrt_val(a)
    double a
CODE:
    if (a < 0.0) {
        croak("Cannot take square root of negative number");
    }
    RETVAL = sqrt(a);
    add_to_history('r', a, 0.5, RETVAL);
OUTPUT:
    RETVAL

double
cbrt_val(a)
    double a
CODE:
    RETVAL = cbrt(a);
    add_to_history('r', a, 1.0/3.0, RETVAL);
OUTPUT:
    RETVAL

double
nth_root(a, n)
    double a
    double n
CODE:
    if (n == 0.0) {
        croak("Cannot take 0th root");
    }
    if (a < 0.0 && fmod(n, 2.0) == 0.0) {
        croak("Cannot take even root of negative number");
    }
    RETVAL = pow(a, 1.0/n);
    add_to_history('r', a, n, RETVAL);
OUTPUT:
    RETVAL

double
log_natural(a)
    double a
CODE:
    if (a <= 0.0) {
        croak("Cannot take log of non-positive number");
    }
    RETVAL = log(a);
    add_to_history('l', a, M_E, RETVAL);
OUTPUT:
    RETVAL

double
log10_val(a)
    double a
CODE:
    if (a <= 0.0) {
        croak("Cannot take log of non-positive number");
    }
    RETVAL = log10(a);
    add_to_history('L', a, 10, RETVAL);
OUTPUT:
    RETVAL

double
log_base(a, base)
    double a
    double base
CODE:
    if (a <= 0.0 || base <= 0.0 || base == 1.0) {
        croak("Invalid logarithm arguments");
    }
    RETVAL = log(a) / log(base);
    add_to_history('L', a, base, RETVAL);
OUTPUT:
    RETVAL

double
exp_val(a)
    double a
CODE:
    RETVAL = exp(a);
    add_to_history('e', a, 0, RETVAL);
OUTPUT:
    RETVAL

double
factorial(n)
    int n
CODE:
    if (n < 0) {
        croak("Cannot take factorial of negative number");
    }
    if (n > 170) {
        croak("Factorial overflow (max 170)");
    }
    RETVAL = 1.0;
    for (int i = 2; i <= n; i++) {
        RETVAL *= i;
    }
    add_to_history('!', (double)n, 0, RETVAL);
OUTPUT:
    RETVAL

double
ipow(base, exp)
    double base
    int exp
CODE:
    RETVAL = sci_ipow(base, exp);
    add_to_history('^', base, (double)exp, RETVAL);
OUTPUT:
    RETVAL

double
safe_sqrt(a)
    double a
CODE:
    int error;
    RETVAL = sci_safe_sqrt(a, &error);
    if (!error) {
        add_to_history('r', a, 0.5, RETVAL);
    }
OUTPUT:
    RETVAL

double
safe_log(a)
    double a
CODE:
    int error;
    RETVAL = sci_safe_log(a, &error);
    if (!error) {
        add_to_history('l', a, M_E, RETVAL);
    }
OUTPUT:
    RETVAL

double
combination(n, r)
    int n
    int r
CODE:
    RETVAL = sci_combination(n, r);
    add_to_history('C', (double)n, (double)r, RETVAL);
OUTPUT:
    RETVAL

double
permutation(n, r)
    int n
    int r
CODE:
    if (r > n || r < 0 || n < 0) {
        RETVAL = 0.0;
    } else {
        RETVAL = sci_combination(n, r);
        for (int i = 2; i <= r; i++) {
            RETVAL *= i;
        }
    }
    add_to_history('P', (double)n, (double)r, RETVAL);
OUTPUT:
    RETVAL

void
import(...)
CODE:
{
    static const char *scientific_exports[] = {
        "power", "sqrt_val", "cbrt_val", "nth_root",
        "log_natural", "log10_val", "log_base", "exp_val",
        "factorial", "ipow", "safe_sqrt", "safe_log",
        "combination", "permutation"
    };
    do_import(aTHX_ "Acme::ExtUtils::XSOne::Test::Calculator::Scientific",
              scientific_exports, 14, items, ax);
}
