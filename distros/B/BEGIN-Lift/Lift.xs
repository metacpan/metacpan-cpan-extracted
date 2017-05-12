#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

#ifndef cv_clone
#define cv_clone(a) Perl_cv_clone(aTHX_ a)
#endif

static SV *args_builder(U32 *flagsp) {
    I32 floor;
    CV *code;
    U8 errors;

    ENTER;

    PL_curcop = &PL_compiling;
    SAVEVPTR(PL_op);
    SAVEI8(PL_parser->error_count);
    PL_parser->error_count = 0;

    floor  = start_subparse(0, CVf_ANON);
    code   = newATTRSUB(floor, NULL, NULL, NULL, parse_args_list(flagsp));
    errors = PL_parser->error_count;

    LEAVE;

    if (errors) {
        ++PL_parser->error_count;
        code = NULL;
    }
    else {
        if ( CvROOT(code) == NULL ) {
            code = NULL;
        }
        else {
            if (CvCLONE(code)) {
                code = cv_clone(code);
            }
        }
    }

    return code ? newRV_inc((SV*) code) : NULL;
}

static OP *parser_callback(pTHX_ GV *namegv, SV *psobj, U32 *flagsp) {
    dSP;
    PUSHMARK(SP);
    mXPUSHs(args_builder(flagsp));
    PUTBACK;
    call_sv(psobj, G_VOID);
    SPAGAIN;
    PUTBACK;
    return newNULLLIST();
}

MODULE = BEGIN::Lift  PACKAGE = BEGIN::Lift::Util

PROTOTYPES: DISABLE

void
install_keyword_handler(keyword, handler)
        SV *keyword
        SV *handler
    CODE:
        if (SvTYPE(keyword) != SVt_RV && SvTYPE(SvRV(keyword)) != SVt_PVCV) {
            croak("'keyword' argument is not a CODE reference");
        }
        if (SvTYPE(handler) != SVt_RV && SvTYPE(SvRV(handler)) != SVt_PVCV) {
            croak("'handler' argument is not a CODE reference");
        }
        cv_set_call_parser( (CV*) SvRV( keyword ), parser_callback, handler );







