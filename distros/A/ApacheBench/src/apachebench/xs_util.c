#include "perl.h"
#include "xs_util.h"

static SV *
call_perl_function__one_arg(SV * function_name, SV * arg1) {

    dSP;
    int count;
    SV *res;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(arg1));
    PUTBACK;

    count = call_sv(function_name, G_SCALAR);

    SPAGAIN;

    if (count == 1)
        res = newSVsv(POPs);
    else
        res = &PL_sv_undef;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}
