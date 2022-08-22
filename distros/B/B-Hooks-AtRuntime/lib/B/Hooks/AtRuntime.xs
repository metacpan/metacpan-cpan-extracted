#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_caller_cx
#define NEED_PL_parser
#define DPPP_PL_parser_NO_DUMMY
#include "ppport.h"

void
call_after (pTHX_ void *p)
{
    dSP;
    SV  *cv = (SV*)p;

    PUSHSTACKi(PERLSI_DESTROY);
    PUSHMARK(SP);
    call_sv(cv, G_VOID|G_DISCARD);
    POPSTACK;

    SvREFCNT_dec(cv);
}

void show_cx (pTHX_ const char *name, const PERL_CONTEXT *cx)
{
    int is_sub = CxTYPE(cx) == CXt_SUB;
    CV *cxcv = is_sub ? cx->blk_sub.cv : NULL;
    int is_special = is_sub ? CvSPECIAL(cxcv) : 0;
    const char *cvname = is_sub ? GvNAME(CvGV(cxcv)) : "<none>";

    Perl_warn(aTHX_ "%s: sub %s, special %s, name %s\n",
        name,
        (is_sub ? "yes" : "no"),
        (is_special ? "yes" : "no"),
        cvname);
}

MODULE = B::Hooks::AtRuntime  PACKAGE = B::Hooks::AtRuntime

#ifdef lex_stuff_sv

void
lex_stuff (s)
        SV *s
    CODE:
        if (!PL_parser)
            Perl_croak(aTHX_ "Not currently compiling anything");
        lex_stuff_sv(s, 0);

#endif

UV
count_BEGINs ()
    PREINIT:
        I32 c = 0;
        const PERL_CONTEXT *cx;
        const PERL_CONTEXT *dbcx;
        const CV *cxcv;
    CODE:
        RETVAL = 0;

        while ((cx = caller_cx(c++, &dbcx))) {

            /*
            show_cx(aTHX_ "cx", cx);
            show_cx(aTHX_ "dbcx", dbcx);
            */

            if (CxTYPE(dbcx) == CXt_SUB   &&
                (cxcv = dbcx->blk_sub.cv) &&
                CvSPECIAL(cxcv)         &&
                strEQ(GvNAME(CvGV(cxcv)), "BEGIN")
            )
                RETVAL++;
        }

        /*
        Perl_warn(aTHX_ "count_BEGINS: frames %i, BEGINs %lu\n",
            c, RETVAL);
        */
    OUTPUT:
        RETVAL

bool
compiling_string_eval ()
    PREINIT:
        I32 c = 0;
        const PERL_CONTEXT *cx;
        const PERL_CONTEXT *dbcx;
        const CV *cxcv;
    CODE:
        RETVAL = 0;
        while ((cx = caller_cx(c++, &dbcx))) {
            if (CxTYPE(dbcx) == CXt_SUB   &&
                (cxcv = dbcx->blk_sub.cv) &&
                CvSPECIAL(cxcv)         &&
                strEQ(GvNAME(CvGV(cxcv)), "BEGIN")
            ) {
                cx = caller_cx(c + 1, &dbcx);
                if (cx && CxREALEVAL(dbcx))
                    RETVAL = 1;
                break;
            }
        }
    OUTPUT:
        RETVAL

SV *
remaining_text ()
    PREINIT:
        char *c;
    CODE:
        RETVAL = &PL_sv_undef;
        if (PL_parser) {
            for (c = PL_bufptr; c < PL_bufend; c++) {
                if (isSPACE(*c))    continue;
                if (*c == '#')      break;
                /* strictly it might be UTF8, but this is just an error so I
                 * don't care. */
                RETVAL = newSVpvn(c, PL_bufend - c);
                break;
            }
        }
    OUTPUT:
        RETVAL

void
run (...)
    PREINIT:
        dORIGMARK;
        SV      *sv;
        I32     i = 0;
    CODE:
        /* This is the magic step... This leaves the scope that
         * surrounds the call to run(), putting us back in the outer
         * scope we were called from. This is what makes after_runtime
         * subs run at the end of the inserted-into scope, rather than
         * when run() finishes. */
        LEAVE;

        while (i++ < items) {
            sv = *(MARK + i);

            if (!SvROK(sv))
                Perl_croak(aTHX_ "Not a reference");
            sv = SvRV(sv);

            /* We have a ref to a ref; this is after_runtime. */
            if (SvROK(sv)) {
                sv = SvRV(sv);
                SvREFCNT_inc(sv);
                SAVEDESTRUCTOR_X(call_after, sv);
            }
            /* This is at_runtime. */
            else {
                PUSHMARK(SP); PUTBACK;
                call_sv(sv, G_VOID|G_DISCARD);
                MSPAGAIN;

            }
        }

        /* Re-enter the scope level we were supposed to be in, or perl
         * will get confused. */
        ENTER;
