/* #define PERL_NO_GET_CONTEXT 1 */ /* KISS */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

void abc(SV * p, ...) {
  dXSARGS;

  if(items == 4) printf ("abc: ok\n");
  else croak("abc: %d items, first is: %s\n", (int)items, SvPV_nolen(ST(0))); 
  /*XSRETURN(0);*/ /* same test results if uncommented in */
}

void def(SV * p, ...) {
  dXSARGS;

  if(items == 4) printf ("def: ok\n");
  else croak("def: %d items, first is: %s\n", (int)items, SvPV_nolen(ST(0)));
  PL_markstack_ptr++; 
  /*XSRETURN(0);*/ /* same test results if uncommented in */
}

void ghi(SV * p, ...) {
  dXSARGS;

  if(items == 4) printf ("ghi: ok\n");
  else croak("ghi: %d items, first is: %s\n", (int)items, SvPV_nolen(ST(0))); 
  /*XSRETURN(0);*/ /* same test results if uncommented in */
}

MODULE = Acme::Stack  PACKAGE = Acme::Stack

PROTOTYPES: ENABLE

void
abc (p, ...)
	SV *	p
        CODE:
        PL_markstack_ptr++;
        abc(p);
        XSRETURN(0); /* same test results with XSRETURN_EMPTY */

void
def (p, ...)
	SV *	p
        CODE:
        def(p);
        XSRETURN(0);  /* same test results with XSRETURN_EMPTY */

void
ghi (p, ...)
	SV *	p
        CODE:
        ghi(p);
        XSRETURN(0);  /* same test results with XSRETURN_EMPTY */

