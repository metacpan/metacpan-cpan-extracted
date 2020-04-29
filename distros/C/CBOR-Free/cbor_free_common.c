#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV *cbf_call_scalar_with_arguments( pTHX_ SV* cb, const U8 count, SV** args ) {
    // --- Almost all copy-paste from “perlcall” … blegh!
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, count);

    U8 i;
    for (i=0; i<count; i++) PUSHs( sv_2mortal(args[i]) );

    PUTBACK;

    call_sv(cb, G_SCALAR);

    SV *ret = newSVsv(POPs);

    FREETMPS;
    LEAVE;

    return ret;
}

void cbf_die_with_arguments( pTHX_ U8 argslen, SV** args ) {
    SV* diename = newSVpvs("CBOR::Free::_die");
    sv_2mortal(diename);

    // NB: args should NOT be mortal because the call to Perl
    // will do that for us.

    cbf_call_scalar_with_arguments(
        aTHX_
        diename,
        argslen,
        args
    );

    assert(0);
}
