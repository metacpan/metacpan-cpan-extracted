#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"

/* id-key for ext magic (Hi, Eva, David) */
#define ALT_EXTMG_CORONA 2805 + 1811

/* basic access to an object's corona (may croak) */
HV *ALT_corona(SV *obj) {
    HV *corona;
    SV *self;
    MAGIC *mg;
    if (!SvROK(obj) )
        Perl_croak(aTHX_ "Alter: Can't use a non-reference");
    self = SvRV(obj);
    if (SvREADONLY(self))
        Perl_croak(aTHX_ "Alter: Can't modify a read-only value");
    if (SvTYPE(self) < SVt_PVMG)
        (void) SvUPGRADE(self, SVt_PVMG);
    for (mg = SvMAGIC(self); mg; mg = mg->mg_moremagic) {
        if ((mg->mg_type == PERL_MAGIC_ext) &&
            (mg->mg_private == ALT_EXTMG_CORONA)
       ) break;
    }
    if (!mg) {
        corona = newHV();
        mg = sv_magicext(self, (SV*)corona, PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_dec(corona); /* must compensate */
        mg->mg_private = ALT_EXTMG_CORONA;
    } else {
        corona = (HV*)mg->mg_obj;
    }
    return corona;
}

/* Access to the type table (program-wide, i.e. not thread-duplicated)
 * This hash holds an SvTYPE (as an integer SV) for every class that
 * wants to autovivify the ego
 */
HV *ALT_type_tab() {
    static HV *type_tab = NULL;
    if (!type_tab)
        type_tab = newHV();
    return type_tab;
}

/* return a ref to a new SV according to given class' entry in type_tab,
 * or NULL */
SV *ALT_vivify( char *class) {
    HV *type_tab = ALT_type_tab();
    SV **type_ptr = hv_fetch(type_tab, class, strlen(class), 0);
    if (type_ptr) {
        SV *sv = newSV(0);
        (void) SvUPGRADE(sv, SvIV(*type_ptr));
        return newRV_noinc(sv);
    } else {
        return NULL;
    }
}

/*
void is_xs()
PPCODE:
    ST(0) = newSViv(1);
    sv_2mortal(ST(0));
    XSRETURN(1);
*/

MODULE = Alter		PACKAGE = Alter		

SV *corona(SV *obj)
PROTOTYPE: $
PREINIT:
    HV *corona;
CODE:
    corona = ALT_corona(obj);
    if (!corona)
        XSRETURN_EMPTY;
    RETVAL = newRV_inc((SV*)corona);
OUTPUT:
    RETVAL

SV *alter(SV *obj, SV *val)
PROTOTYPE: $$
PREINIT:
    HV *corona;
    char *class;
CODE:
    corona = ALT_corona(obj);
    if (!corona)
        XSRETURN_EMPTY;
    class = CopSTASHPV(PL_curcop);
    hv_store(corona, class, strlen(class), SvREFCNT_inc(val), 0);
    RETVAL = SvREFCNT_inc(obj); /* method chaining */
OUTPUT:
    RETVAL

SV *ego(SV *obj, ...)
PROTOTYPE: $
CODE:
    HV *corona = ALT_corona(obj);
    char *class;
    SV **ego_ptr;
    SV *ego;
    if (!corona)
        XSRETURN_EMPTY;
    class = CopSTASHPV(PL_curcop);
    if ((ego_ptr = hv_fetch(corona, class, strlen(class), 0))) {
        ego = *ego_ptr;
    } else {
        if ( (ego = ALT_vivify(class)) ) {
            hv_store(corona, class, strlen(class), ego, 0);
        }
    }
    if (!ego)
        XSRETURN_UNDEF;
    RETVAL = SvREFCNT_inc(ego);
OUTPUT:
    RETVAL

void _set_class_type(char *class, SV *spec)
CODE:
    HV *type_tab = ALT_type_tab();
    if (SvROK(spec)) {
        SV *type = newSViv(SvTYPE(SvRV(spec)));
        hv_store(type_tab, class, strlen(class), type, 0);
    } else if (!SvOK(spec)) {
        hv_delete(type_tab, class, strlen(class), G_DISCARD);
    }
    XSRETURN_EMPTY;
