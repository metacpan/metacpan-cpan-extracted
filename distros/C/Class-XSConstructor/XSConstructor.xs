#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "xshelper.h"

#define IsObject(sv)    (SvROK(sv) && SvOBJECT(SvRV(sv)))
#define IsArrayRef(sv)  (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define IsHashRef(sv)   (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVHV)
#define IsCodeRef(sv)   (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVCV)
#define IsScalarRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) <= SVt_PVMG)

#define XSCON_xc_stash(a)       ( (HV*)XSCON_av_at((a), XSCON_XC_STASH) )

SV*
join_with_commas(AV *av) {
    SV *out = newSVpvs("");
    I32 len = av_len(av) + 1;

    for (I32 i = 0; i <= len; i++) {
        SV **svp = av_fetch(av, i, 0);
        if (!svp) continue;
        if (i > 0)
            sv_catpvs(out, ", ");
        sv_catsv(out, *svp);
    }

    return out;
}

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
xscon_initialize_object(const char* pkg, const char* klass, SV* const object, HV* const args, bool const is_cloning)
{
    dTHX;

    assert(object);
    assert(args);

    if(mg_find((SV*)args, PERL_MAGIC_tied)){
        croak("You cannot use tied HASH reference as initializing arguments");
    }

    HV* const stash = gv_stashpv(pkg, 1);
    assert(stash != NULL);

    I32 i;
    SV* attr;
    SV* fliggity;
    SV** tmp;
    SV** tmp2;
    char* keyname;
    STRLEN keylen;
    int flags;

    /* find out allowed attributes */
    SV** const HAS_globref = hv_fetch(stash, "__XSCON_HAS", 11, 0);
    AV* const HAS_array = GvAV(*HAS_globref);
    I32 const HAS_len = av_len(HAS_array) + 1;

    /* Flags for each attribute */
    SV** const FLAGS_globref = hv_fetch(stash, "__XSCON_FLAGS", 13, 0);
    HV* const FLAGS_hash = GvHV(*FLAGS_globref);
    
    /* Type constraints, coercions, and defaults */
    SV** const ISA_globref = hv_fetch(stash, "__XSCON_ISA", 11, 0);
    HV* const ISA_hash = GvHV(*ISA_globref);
    SV** const COERCIONS_globref = hv_fetch(stash, "__XSCON_COERCIONS", 17, 0);
    HV* const COERCIONS_hash = GvHV(*COERCIONS_globref);
    SV** const DEFAULTS_globref = hv_fetch(stash, "__XSCON_DEFAULTS", 16, 0);
    HV* const DEFAULTS_hash = GvHV(*DEFAULTS_globref);

    /* copy allowed attributes */
    for (i = 0; i < HAS_len; i++) {
        tmp = av_fetch(HAS_array, i, 0);
        assert(tmp);
        attr = *tmp;
        keyname = SvPV(attr, keylen);
        
        tmp2 = hv_fetch(FLAGS_hash, keyname, keylen, 0);
        assert(tmp2);
        fliggity = *tmp2;
        flags = (int)SvIV(fliggity);
        
        SV** valref;
        SV* val;
        bool has_value = false;
        
        if (hv_exists(args, keyname, keylen)) {
            // Value provided in args hash
            valref = hv_fetch(args, keyname, keylen, 0);
            val = newSVsv(*valref);
            has_value = true;
        }
        else if ( flags & 8 ) {
            // There is a default/builder
            has_value = true;
            // Some very common defaults are worth hardcoding into the flags
            // so we won't even need to do a hash lookup to find the default
            // value.
            I32 has_common_default = ( flags >> 4 ) & 15;
            switch ( has_common_default ) {
                // Undef
                case 1:
                    val = newSV(0);
                    break;
                // Number 0
                case 2:
                    val = newSViv(0);
                    break;
                // We're number 1
                case 3:
                    val = newSViv(1);
                    break;
                // False
                case 4:
                    val = &PL_sv_no;
                    break;
                // True
                case 5:
                    val = &PL_sv_yes;
                    break;
                // Empty string
                case 6:
                    val = newSVpvs("");
                    break;
                // Empty arrayref
                case 7:
                    AV *av = newAV();
                    val = newRV_noinc((SV*)av);
                    break;
                // Empty hashref
                case 8:
                    HV *hv = newHV();
                    val = newRV_noinc((SV*)hv);
                    break;
                // For anything else, we need to consult the defaults hash.
                default:
                    if ( hv_exists(DEFAULTS_hash, keyname, keylen) ) {
                        SV** const def = hv_fetch(DEFAULTS_hash, keyname, keylen, 0);
                        // Coderef, call as method
                        if (IsCodeRef(*def)) {
                            dSP;
                            int count;
                            ENTER;
                            SAVETMPS;
                            PUSHMARK(SP);
                            EXTEND(SP, 1);
                            PUSHs(object);
                            PUTBACK;
                            count = call_sv(*def, G_SCALAR);
                            SV* got = POPs;
                            val = newSVsv(got);
                            PUTBACK;
                            FREETMPS;
                            LEAVE;
                        }
                        // Scalarref to the name of a builder, call as method
                        else if (IsScalarRef(*def)) {
                            STRLEN len;
                            SV *method_name_sv = SvRV(*def);
                            char *method_name = SvPV(method_name_sv, len);
                            dSP;
                            int count;
                            ENTER;
                            SAVETMPS;
                            PUSHMARK(SP);
                            EXTEND(SP, 1);
                            PUSHs(object);
                            PUTBACK;
                            count = call_method(method_name, G_SCALAR);
                            SV* got = POPs;
                            val = newSVsv(got);
                            PUTBACK;
                            FREETMPS;
                            LEAVE;
                        }
                        // It's just a literal value.
                        else {
                            val = newSVsv(*def);
                        }
                    }
                    else {
                        has_value = false;
                        if ( flags & 1 ) {
                            croak("Attribute '%s' is required", keyname);
                        }
                    }
            }
        }
        else if ( flags & 1 ) {
            croak("Attribute '%s' is required", keyname);
        }
        
        if ( has_value ) {
            /* there exists an isa check */
            if ( flags & 2 && hv_exists(ISA_hash, keyname, keylen) ) {
                SV* val3 = newSVsv(val);
                SV** const check = hv_fetch(ISA_hash, keyname, keylen, 0);
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

                /* we failed type check */
                if ( !SvTRUE(result) ) {
                    if ( flags & 4 && hv_exists(COERCIONS_hash, keyname, keylen) ) {
                        SV** const coercion = hv_fetch(COERCIONS_hash, keyname, keylen, 0);
                        SV* newval;
                        
                        int count;
                        ENTER;
                        SAVETMPS;
                        PUSHMARK(SP);
                        EXTEND(SP, 1);
                        PUSHs(val3);
                        PUTBACK;
                        count  = call_sv(*coercion, G_SCALAR);
                        SV* tmpval = POPs;
                        newval = newSVsv(tmpval);
                        PUTBACK;
                        FREETMPS;
                        LEAVE;
                        
                        {
                            int count;
                            ENTER;
                            SAVETMPS;
                            PUSHMARK(SP);
                            EXTEND(SP, 1);
                            PUSHs(sv_2mortal(newval));
                            PUTBACK;
                            count  = call_sv(*check, G_SCALAR);
                            SV* result = POPs;
                            if ( SvTRUE(result) ) {
                                val = newSVsv(newval);
                            }
                            else {
                                croak("Coercion result '%s' failed type constraint for '%s'", SvPV_nolen(val), keyname);
                            }
                            PUTBACK;
                            FREETMPS;
                            LEAVE;
                        }
                    }
                    else {
                        croak("Value '%s' failed type constraint for '%s'", SvPV_nolen(val), keyname);
                    }
                }
                
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            
            (void)hv_store((HV *)SvRV(object), keyname, keylen, val, 0);
        }
    }
}

static void
xscon_buildall(const char* pkg, SV* const object, SV* const args) {
    dTHX;

    assert(object);
    assert(args);

    HV* const stash = gv_stashpv(pkg, 1);
    assert(stash != NULL);
    
    SV *pkgsv = newSVpv(pkg, 0);
    
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
        PUSHs(pkgsv);
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

static void
xscon_strictcon(const char* pkg, SV* const object, SV* const args) {
    dTHX;

    assert(object);
    assert(args);

    HV* const stash = gv_stashpv(pkg, 1);
    assert(stash != NULL);

    SV** const STRICT_globref = hv_fetch(stash, "__XSCON_STRICT", 14, 0);
    SV* const STRICT_flag = GvSV(*STRICT_globref);

    if (!SvTRUE(STRICT_flag)) {
        return;
    }

    SV** const HAS_globref = hv_fetch(stash, "__XSCON_HAS", 11, 0);
    AV* const HAS_array = GvAV(*HAS_globref);
    I32 const HAS_len = av_len(HAS_array) + 1;

    AV *badattrs = newAV();

    HV* argshv = (HV*)SvRV(args);
    HE* he;

    hv_iterinit(argshv);
    while ((he = hv_iternext(argshv))) {
        SV* const k = hv_iterkeysv(he);
        bool found = FALSE;

        I32 i;
        for (i = 0; i < HAS_len; i++) {
            SV* const attr = *av_fetch(HAS_array, i, TRUE);
            if (sv_eq(k, attr)) {
                found = TRUE;
                break;
            }
        }

        if (!found) {
            av_push(badattrs, k);
        }
    }

    I32 const badattrs_len = av_len(badattrs) + 1;
    if ( badattrs_len > 0 ) {
        SV* const badattrs_commas = join_with_commas(badattrs);
        if ( badattrs_len == 1 ) {
            croak("Found unknown attribute passed to the constructor: %s", SvPV_nolen(badattrs_commas));
        }
        else {
            croak("Found unknown attributes passed to the constructor: %s", SvPV_nolen(badattrs_commas));
        }
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

    char *constructor_package_name = (char *) CvXSUBANY(cv).any_ptr;

    klassname = SvROK(klass) ? sv_reftype(SvRV(klass), 1) : SvPV_nolen_const(klass);
    args = newRV_inc((SV*)xscon_buildargs(klassname, ax, items));
    sv_2mortal(args);
    object = xscon_create_instance(klassname);
    xscon_initialize_object(constructor_package_name, klassname, object, (HV*)SvRV(args), FALSE);
    xscon_buildall(constructor_package_name, object, args);
    xscon_strictcon(constructor_package_name, object, args);
    ST(0) = object; /* because object is mortal, we should return it as is */
    XSRETURN(1);
}

void
install_constructor(char* name)
CODE:
{
    CV *cv = newXS(name, XS_Class__XSConstructor_new_object, (char*)__FILE__);
    if (cv == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");
    
    char *full = savepv(name);
    const char *last = NULL;
    for (const char *p = full; (p = strstr(p, "::")); p += 2) {
        last = p;
    }
    char *pkg;
    if (last) {
        size_t len = (size_t)(last - full);
        pkg = (char *)malloc(len + 1);
        memcpy(pkg, full, len);
        pkg[len] = '\0';
    } else {
        pkg = strdup("");
    }
    
    CvXSUBANY(cv).any_ptr = pkg;
}
