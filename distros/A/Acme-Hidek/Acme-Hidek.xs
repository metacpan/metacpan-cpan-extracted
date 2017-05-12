#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef USE_PPPORT
#include "ppport.h"
#endif

static IV
hidek_get_age(pTHX_ SV* const hidek) {
    dSP;
    IV retval;
    PUSHMARK(SP);
    XPUSHs(hidek);
    PUTBACK;
    call_method("age", G_SCALAR);
    SPAGAIN;
    retval = POPi;
    PUTBACK;
    return retval;
}

MODULE = Acme::Hidek	PACKAGE = Acme::Hidek

PROTOTYPES: DISABLE

void
we_love_hidek(SV* hidek)
CODE:
{
    IV i;
    IV age = hidek_get_age(aTHX_ hidek) * 100;
    for(i = 0; i < age; i++) {
        PerlIO_stdoutf("We love hidek!\n");
    }
}
