#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static char private_data = '\0';

static MAGIC *
get_existing_magic(pTHX_ SV *sv)
{
    MAGIC *mg;

    for (mg = mg_find(sv, PERL_MAGIC_ext);  mg;  mg = mg->mg_moremagic)
        if (mg->mg_ptr == &private_data)
            return mg;

    return 0;
}

static MAGIC *
get_magic(pTHX_ SV *sv)
{
    MAGIC *mg;

    mg = get_existing_magic(aTHX_ sv);
    if (mg)
        return mg;

    /* didn't find any iterator magic, so create some */
    return sv_magicext(sv, sv_2mortal(newSViv(0)), PERL_MAGIC_ext, 0, &private_data, 0);
}

static int
advance_iterator(pTHX_ SV *sv)
{
    MAGIC *mg;
    int i;

    mg = get_magic(aTHX_ sv);
    i = SvIVX(mg->mg_obj);
    sv_setiv(mg->mg_obj, i + 1);
    return i;
}

static void
clear_iterator(pTHX_ SV *sv)
{
    MAGIC *mg;

    if ((mg = get_existing_magic(aTHX_ sv)))
        sv_setiv(mg->mg_obj, 0);
}

MODULE = Array::Each::Override      PACKAGE = Array::Each::Override

PROTOTYPES: ENABLE

void
array_each(sv)
    SV *sv
PROTOTYPE: \[@%]
PREINIT:
    int i;
    AV *av;
PPCODE:
    if (!SvROK(sv))
        croak("Argument to Array::Each::Override::array_each must be a reference");
    sv = SvRV(sv);
    if (SvTYPE(sv) == SVt_PVHV) {
        HV *hv = (HV *) sv;
        HE *entry;
        const I32 gimme = GIMME_V;

        /* PUTBACK; */
        entry = hv_iternext(hv);
        /* SPAGAIN; */

        if (entry) {
            SV *const key_sv = hv_iterkeysv(entry);
            EXTEND(SP, 2);
            PUSHs(key_sv);
            if (gimme != G_ARRAY)
               XSRETURN(1);
            else {
                SV *val;
                /* PUTBACK; */
                val = hv_iterval(hv, entry);
                /* SPAGAIN; */
                PUSHs(val);
                XSRETURN(2);
            }
        }
        else if (gimme == G_SCALAR) {
            XSRETURN_UNDEF;
        }
        else {
            XSRETURN_EMPTY;
        }
    }
    if (SvTYPE(sv) != SVt_PVAV) {
        Perl_croak(aTHX_ "Argument to Array::Each::Override::array_each must "
            "be a hash or array reference");
    }
    av = (AV *) sv;
    i = advance_iterator(aTHX_ sv);
    if (i > Perl_av_len(aTHX_ av)) {
        clear_iterator(aTHX_ sv);
        XSRETURN_EMPTY;
    }
    if (GIMME_V != G_VOID) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(i)));
        PUSHs(*Perl_av_fetch(aTHX_ av, i, 0));
        XSRETURN(2);
    }
    XSRETURN_EMPTY;

void
array_keys(sv)
    SV *sv
PROTOTYPE: \[@%]
PREINIT:
    int i;
    AV *av;
PPCODE:
    if (!SvROK(sv))
        croak("Argument to Array::Each::Override::array_keys must be a reference");
    sv = SvRV(sv);
    if (SvTYPE(sv) == SVt_PVHV) {
        HV *hv = (HV *) sv;
        HE *entry;
        const I32 gimme = GIMME_V;

        hv_iterinit(hv);

        if (gimme == G_VOID)
            XSRETURN_EMPTY;
        else if (gimme == G_SCALAR) {
            IV i;
            dTARGET;

            if (! SvTIED_mg((SV *) hv, PERL_MAGIC_tied))
                i = HvKEYS(hv);
            else {
                i = 0;
                while (hv_iternext(hv))
                    i++;
            }

            PUSHi(i);
            XSRETURN(1);
        }
        else {
            I32 n = HvKEYS(hv);
            EXTEND(SP, n);
            /* PUTBACK; */
            while ((entry = hv_iternext(hv))) {
                SV *key_sv;
                /* SPAGAIN; */
                key_sv = hv_iterkeysv(entry);
                PUSHs(key_sv);
                /* PUTBACK; */
            }
            /* SPAGAIN; */
            XSRETURN(n);
        }
    }
    if (SvTYPE(sv) != SVt_PVAV) {
        Perl_croak(aTHX_ "Argument to Array::Each::Override::array_keys must "
            "be a hash or array reference");
    }
    av = (AV *) sv;
    clear_iterator(aTHX_ sv);
    if (GIMME_V == G_SCALAR) {
        int n = Perl_av_len(aTHX_ av);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(n + 1)));
    }
    else if (GIMME_V == G_ARRAY) {
        int i;
        int n = Perl_av_len(aTHX_ av);
        EXTEND(SP, n + 1);
        for (i = 0;  i <= n;  i++) {
            PUSHs(sv_2mortal(newSViv(i)));
        }
   }

void
array_values(sv)
    SV *sv
PROTOTYPE: \[@%]
PREINIT:
    int i;
    AV *av;
PPCODE:
    if (!SvROK(sv))
        croak("Argument to Array::Each::Override::array_values must be a reference");
    sv = SvRV(sv);
    if (SvTYPE(sv) == SVt_PVHV) {
        HV *const hv = (HV *) sv;
        HV *keys;
        HE *entry;
        const I32 gimme = GIMME_V;

        keys = hv;
        hv_iterinit(keys);

        if (gimme == G_VOID)
            XSRETURN_EMPTY;
        else if (gimme == G_SCALAR) {
            IV i;
            dTARGET;

            if (! SvTIED_mg((SV *) keys, PERL_MAGIC_tied))
                i = HvKEYS(keys);
            else {
                i = 0;
                while (hv_iternext(keys))
                    i++;
            }

            PUSHi(i);
            XSRETURN(1);
        }
        else {
            I32 n = HvKEYS(keys);
            EXTEND(SP, n);
            /* PUTBACK; */
            while ((entry = hv_iternext(keys))) {
                SV *val;
                val = hv_iterval(hv, entry);
                /* SPAGAIN; */
                PUSHs(val);
            }
            /* PUTBACK; */
            XSRETURN(n);
        }
    }
    if (SvTYPE(sv) != SVt_PVAV) {
        Perl_croak(aTHX_ "Argument to Array::Each::Override::array_values must "
            "be a hash or array reference");
    }
    av = (AV *) sv;
    clear_iterator(aTHX_ sv);
    if (GIMME_V == G_SCALAR) {
        int n = Perl_av_len(aTHX_ av);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(n + 1)));
    }
    else if (GIMME_V == G_ARRAY) {
        int i;
        int n = Perl_av_len(aTHX_ av);
        EXTEND(SP, n + 1);
        for (i = 0;  i <= n;  i++) {
            SV **elem = Perl_av_fetch(aTHX_ av, i, 0);
            if (elem) {
                PUSHs(*elem);
            }
            else {
                PUSHs(&PL_sv_undef);
            }
        }
   }
