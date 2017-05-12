#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* variable living on C side. */
static int ex2_debug_c = 42;

MODULE = CookBookA::Ex2		PACKAGE = CookBookA::Ex2

int
ex2_debug_c(...)
    CODE:
	if( items > 0 ){
		ex2_debug_c = SvIV( ST(0) );
	}
	RETVAL = ex2_debug_c;
	printf("# On the C side, ex2_debug_c = %d\n", RETVAL );
    OUTPUT:
	RETVAL

int
ex2_debug_p(...)
    PREINIT:
	SV *ex2_debug_p;
    CODE:
	/* The variable $CookBookA::Ex2::ex2_debug_p was defined
	 * in the Ex2.pm module.
	 */
	ex2_debug_p = perl_get_sv( "CookBookA::Ex2::ex2_debug_p", FALSE );
	if( items > 0 ){
		sv_setiv( ex2_debug_p, SvIV( ST(0) ) );
	}
	RETVAL = SvIV( ex2_debug_p );
	printf("# On the C side, ex2_debug_p = %d\n", RETVAL );
    OUTPUT:
	RETVAL
