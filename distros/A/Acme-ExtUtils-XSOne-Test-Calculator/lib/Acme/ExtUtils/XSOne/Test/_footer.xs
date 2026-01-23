/*
 * Acme::ExtUtils::XSOne::Test::Calculator - Main module and BOOT section
 */

MODULE = Acme::ExtUtils::XSOne::Test::Calculator    PACKAGE = Acme::ExtUtils::XSOne::Test::Calculator

PROTOTYPES: DISABLE

double
pi()
CODE:
    RETVAL = M_PI;
OUTPUT:
    RETVAL

double
e()
CODE:
    RETVAL = M_E;
OUTPUT:
    RETVAL

const char *
version()
CODE:
    RETVAL = "0.01";
OUTPUT:
    RETVAL

BOOT:
    /* Initialize memory on module load */
    init_memory();
