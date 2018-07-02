#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "xshelper.h"

#define IsObject(sv)   (SvROK(sv) && SvOBJECT(SvRV(sv)))
#define IsArrayRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define IsHashRef(sv)  (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVHV)
#define IsCodeRef(sv)  (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVCV)

#define XSCON_xc_stash(a)       ( (HV*)XSCON_av_at((a), XSCON_XC_STASH) )

static HV*
xscon_buildargs(const char* klass, I32 ax, I32 items) {
    dTHX;
    HV* args;

    /* shift @_ */
    ax++;
    items--;

    if(items == 1){
        SV* const args_ref = ST(0);
        if(!IsHashRef(args_ref)){
            croak("Single parameters to new() must be a HASH ref");
        }
        args = newHVhv((HV*)SvRV(args_ref));
        sv_2mortal((SV*)args);
    }
    else{
        I32 i;

        if( (items % 2) != 0 ){
            croak("Odd number of parameters to new()");
        }

        args = newHV_mortal();
        for(i = 0; i < items; i += 2){
            (void)hv_store_ent(args, ST(i), newSVsv(ST(i+1)), 0U);
        }

    }
    return args;
}

static SV*
xscon_create_instance(const char* klass) {
    dTHX;
    SV* instance;
    instance = sv_bless( newRV_noinc((SV*)newHV()), gv_stashpv(klass, 1) );
    return sv_2mortal(instance);
}

static void
xscon_initialize_object(const char* klass, SV* const object, HV* const args, bool const is_cloning) {
    dTHX;

    assert(object);
    assert(args);

    if(mg_find((SV*)args, PERL_MAGIC_tied)){
        croak("You cannot use tied HASH reference as initializing arguments");
    }

    HV* const stash = gv_stashpv(klass, 1);
    assert(stash != NULL);

    I32 i;
    SV* attr;
    SV** tmp;
    char* keyname;
    STRLEN keylen;

    /* find out allowed attributes */
    SV** const HAS_globref = hv_fetch(stash, "__XSCON_HAS", 11, 0);
    AV* const HAS_attrs = GvAV(*HAS_globref);
    I32 const HAS_len = av_len(HAS_attrs) + 1;

    /* find out type constraints */
    SV** const ISA_globref = hv_fetch(stash, "__XSCON_ISA", 11, 0);
    HV* const ISA_attrs = GvHV(*ISA_globref);

    /* copy allowed attributes */
    for (i = 0; i < HAS_len; i++) {
        tmp = av_fetch(HAS_attrs, i, 0);
        assert(tmp);
        attr = *tmp;
        keyname = SvPV(attr, keylen);
        
        if (hv_exists(args, keyname, keylen)) {
            SV** val  = hv_fetch(args, keyname, keylen, 0);
            SV*  val2 = newSVsv(*val);

            /* optional isa check */
            if (hv_exists(ISA_attrs, keyname, keylen)) {
                SV*  val3 = newSVsv(*val);
                SV** const check = hv_fetch(ISA_attrs, keyname, keylen, 0);
                SV* result;

                dSP;
                int count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 1);
                PUSHs(sv_2mortal(val3));
                PUTBACK;
                count  = call_sv(*check, G_SCALAR);
                result = POPs;

                if (!SvTRUE(result)) {
                    croak("Value '%s' failed type constraint for '%s'", SvPV_nolen(val2), keyname);
                }
                
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            
            (void)hv_store((HV *)SvRV(object), keyname, keylen, val2, 0);
        }
    }

    /* find out required attributes */
    SV** const REQ_globref = hv_fetch(stash, "__XSCON_REQUIRED", 16, 0);
    AV* const REQ_attrs = GvAV(*REQ_globref);
    I32 const REQ_len = av_len(REQ_attrs) + 1;

    /* check required attributes */
    for (i = 0; i < REQ_len; i++) {
        tmp = av_fetch(REQ_attrs, i, 0);
        assert(tmp);
        attr = *tmp;
        keyname = SvPV(attr, keylen);
        
        if (!hv_exists((HV *)SvRV(object), keyname, keylen)) {
            croak("Attribute '%s' is required", keyname);
        }
    }
}

static void
xscon_buildall(SV* const object, SV* const args) {
    dTHX;
    
    assert(object);
    assert(args);

    const char* klass = sv_reftype(SvRV(object), 1);
    HV* const stash = gv_stashpv(klass, 1);
    assert(stash != NULL);
    
    /* get cached stuff */
    SV** const globref = hv_fetch(stash, "__XSCON_BUILD", 13, 0);
    SV* buildall = GvSV(*globref);
    
    /* undef in $__XSCON_BUILD means we need to populate it */
    if (!SvOK(buildall)) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(object);
        PUTBACK;
        count = call_pv("Class::XSConstructor::populate_build", G_VOID);
        PUTBACK;
        FREETMPS;
        LEAVE;
        
        buildall = GvSV(*globref);
    }
    
    if (!SvOK(buildall)) {
        croak("something should have happened!");
    }
    
    if (!SvROK(buildall)) {
        return;
    }

    if (hv_exists((HV *)SvRV(args), "__no_BUILD__", 12)) {
        SV** val = hv_fetch((HV *)SvRV(args), "__no_BUILD__", 12, 0);
        if (SvOK(*val) && SvTRUE(*val)) {
            return;
        }
    }

    AV* const builds = (AV*)SvRV(buildall);
    I32 const len = av_len(builds) + 1;
    SV** tmp;
    SV* build;
    I32 i;

    for (i = 0; i < len; i++) {
        tmp = av_fetch(builds, i, 0);
        assert(tmp);
        build = *tmp;
        
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(object);
        PUSHs(args);
        PUTBACK;
        count = call_sv(build, G_VOID);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

MODULE = Class::XSConstructor  PACKAGE = Class::XSConstructor

void
new_object(SV* klass, ...)
CODE:
{
    const char* klassname;
    SV* args;
    SV* object;

    klassname = SvROK(klass) ? sv_reftype(SvRV(klass), 1) : SvPV_nolen_const(klass);
    args = newRV_inc((SV*)xscon_buildargs(klassname, ax, items));
    sv_2mortal(args);
    object = xscon_create_instance(klassname);
    xscon_initialize_object(klassname, object, (HV*)SvRV(args), FALSE);
    xscon_buildall(object, args);
    ST(0) = object; /* because object is mortal, we should return it as is */
    XSRETURN(1);
}

void
install_constructor(char* name)
CODE:
{
    if (newXS(name, XS_Class__XSConstructor_new_object, (char*)__FILE__) == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");
}
