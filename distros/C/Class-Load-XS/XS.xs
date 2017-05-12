#define PERL_NO_GET_CONTEXT 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* This code was originally written by Goro Fuji for Class::MOP, and later
   refined by Florian Ragwitz. */

static bool
check_version (pTHX_ SV *klass, SV *required_version) {
    bool ret = 0;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(klass);
    PUSHs(required_version);
    PUTBACK;

    call_method("VERSION", G_DISCARD|G_VOID|G_EVAL);

    SPAGAIN;

    if (!SvTRUE(ERRSV)) {
        ret = 1;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

static bool
has_a_sub (pTHX_ HV *stash) {
    HE *he;

    (void)hv_iterinit(stash);

    while ( (he = hv_iternext(stash)) ) {
        GV * const gv          = (GV*)HeVAL(he);
        STRLEN keylen;
        const char * const key = HePV(he, keylen);
        SV *sv = NULL;

        if(isGV(gv)){
            sv = (SV *)GvCVu(gv);
        }
        /* expand the gv into a real typeglob if it contains stub functions or
           constants. */
        else {
            gv_init(gv, stash, key, keylen, GV_ADDMULTI);
            sv = (SV *)GvCV(gv);
        }

        if (sv) {
            return TRUE;
        }
    }

    return FALSE;
}

static SV* KEY_FOR__version;
static SV* KEY_FOR_VERSION;
static SV* KEY_FOR_ISA;

static U32 HASH_FOR__version;
static U32 HASH_FOR_VERSION;
static U32 HASH_FOR_ISA;

void
prehash_keys (pTHX) {
    KEY_FOR__version = newSVpv("-version", 8);
    KEY_FOR_VERSION = newSVpv("VERSION", 7);
    KEY_FOR_ISA = newSVpv("ISA", 3);

    PERL_HASH(HASH_FOR__version, "-version", 8);
    PERL_HASH(HASH_FOR_VERSION, "VERSION", 7);
    PERL_HASH(HASH_FOR_ISA, "ISA", 3);
}

MODULE = Class::Load::XS   PACKAGE = Class::Load::XS

PROTOTYPES: DISABLE

BOOT:
    prehash_keys(aTHX);

void
is_class_loaded(klass, options=NULL)
    SV *klass
    HV *options
    PREINIT:
        HV *stash;
        bool found_method = FALSE;
    PPCODE:
        SvGETMAGIC(klass);
        if (!(SvPOKp(klass) && SvCUR(klass))) { /* XXX: SvPOK does not work with magical scalars */
            XSRETURN_NO;
        }

        stash = gv_stashsv(klass, 0);
        if (!stash) {
            XSRETURN_NO;
        }

        if (options && hv_exists_ent(options, KEY_FOR__version, HASH_FOR__version)) {
            HE *required_version = hv_fetch_ent(options, KEY_FOR__version, 0, HASH_FOR__version);
            if (check_version (aTHX_ klass, HeVAL(required_version))) {
                XSRETURN_YES;
            }

            XSRETURN_NO;
        }

        if (hv_exists_ent (stash, KEY_FOR_VERSION, HASH_FOR_VERSION)) {
            HE *version = hv_fetch_ent(stash, KEY_FOR_VERSION, 0, HASH_FOR_VERSION);
            if (version) {
                SV *value = HeVAL(version);
                SV *version_sv;
                if (value && isGV(value) && (version_sv = GvSV(value))) {
                    if (SvROK(version_sv)) {
                        /* Any object is good enough, though this is most
                           likely going to be a version object */
                        if (sv_isobject(version_sv)) {
                            XSRETURN_YES;
                        }
                        else {
                            SV *version_sv_ref = SvRV(version_sv);

                            if (SvOK(version_sv_ref)) {
                                XSRETURN_YES;
                            }
                        }
                    }
                    else if (SvOK(version_sv)) {
                        XSRETURN_YES;
                    }
                }
            }
        }

        if (hv_exists_ent (stash, KEY_FOR_ISA, HASH_FOR_ISA)) {
            HE *isa = hv_fetch_ent(stash, KEY_FOR_ISA, 0, HASH_FOR_ISA);
            if (isa) {
               SV *value = HeVAL(isa);
               if (value && isGV(value) && GvAV(value) && av_len(GvAV(value)) != -1) {
                   XSRETURN_YES;
               }
            }
        }

        if (has_a_sub(aTHX_ stash)) {
            XSRETURN_YES;
        }

        XSRETURN_NO;
