#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "xshelper.h"

#define IsObject(sv)    (SvROK(sv) && SvOBJECT(SvRV(sv)))
#define IsArrayRef(sv)  (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define IsHashRef(sv)   (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVHV)
#define IsCodeRef(sv)   (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVCV)
#define IsScalarRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) <= SVt_PVMG)

#define XSCON_xc_stash(a)       ( (HV*)XSCON_av_at((a), XSCON_XC_STASH) )

struct delete_ent_ctx {
    HV *hv;
    SV *key;
};

static void
delete_mutex(pTHX_ void *p)
{
    struct delete_ent_ctx *ctx = (struct delete_ent_ctx *)p;
    hv_delete_ent(ctx->hv, ctx->key, G_DISCARD, 0);
}

static void
dec_sv_refcnt(pTHX_ void *p)
{
    SV *sv = (SV *)p;
    SvREFCNT_dec(sv);
}

enum {
    XSCON_FLAG_REQUIRED             =    1,
    XSCON_FLAG_HAS_TYPE_CONSTRAINT  =    2,
    XSCON_FLAG_HAS_TYPE_COERCION    =    4,
    XSCON_FLAG_HAS_DEFAULT          =    8,
    XSCON_FLAG_NO_INIT_ARG          =   16,
    XSCON_FLAG_HAS_INIT_ARG         =   32,
    XSCON_FLAG_HAS_TRIGGER          =   64,
    XSCON_FLAG_WEAKEN               =  128,

    XSCON_BITSHIFT_DEFAULTS         =    8,
    XSCON_BITSHIFT_TYPES            =   16,
};

SV*
join_with_commas(AV *av) {
    dTHX;

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

static bool
_S_pv_is_integer (char* const pv) {
    dTHX;
    const char* p;
    p = &pv[0];

    /* -?[0-9]+ */
    if(*p == '-') p++;

    if (!*p) return FALSE;

    while(*p){
        if(!isDIGIT(*p)){
            return FALSE;
        }
        p++;
    }
    return TRUE;
}

static bool
_S_nv_is_integer (NV const nv) {
    dTHX;
    if(nv == (NV)(IV)nv){
        return TRUE;
    }
    else {
        char buf[64];  /* Must fit sprintf/Gconvert of longest NV */
        const char* p;
        (void)Gconvert(nv, NV_DIG, 0, buf);
        return _S_pv_is_integer(buf);
    }
}

bool
_is_class_loaded (SV* const klass ) {
    dTHX;
    HV *stash;
    GV** gvp;
    HE* he;

    if ( !SvPOKp(klass) || !SvCUR(klass) ) { /* XXX: SvPOK does not work with magical scalars */
        return FALSE;
    }

    stash = gv_stashsv( klass, FALSE );
    if ( !stash ) {
        return FALSE;
    }

    if (( gvp = (GV**)hv_fetchs(stash, "VERSION", FALSE) )) {
        if ( isGV(*gvp) && GvSV(*gvp) && SvOK(GvSV(*gvp)) ){
            return TRUE;
        }
    }

    if (( gvp = (GV**)hv_fetchs(stash, "ISA", FALSE) )) {
        if ( isGV(*gvp) && GvAV(*gvp) && av_len(GvAV(*gvp)) != -1 ) {
            return TRUE;
        }
    }

    hv_iterinit(stash);
    while (( he = hv_iternext(stash) )) {
        GV* const gv = (GV*)HeVAL(he);
        if ( isGV(gv) ) {
            if ( GvCVu(gv) ) { /* is GV and has CV */
                hv_iterinit(stash); /* reset */
                return TRUE;
            }
        }
        else if ( SvOK(gv) ) { /* is a stub or constant */
            hv_iterinit(stash); /* reset */
            return TRUE;
        }
    }
    return FALSE;
}

static bool
xscon_check_type(int flags, SV* const val, HV* const isa_hash, char* isa_hash_keyname, STRLEN isa_hash_keylen)
{
    dTHX;
    assert(value);

    // 15 indicates an unknown type constraint
    // We need to dive into the isa_hash to check it
    if ( flags & 15 == 15 ) {
        if ( ! hv_exists(isa_hash, isa_hash_keyname, isa_hash_keylen) ) {
            warn( "Type constraint check coderef gone AWOL for attribute '%s', so just assuming value passes", isa_hash_keyname );
            return 1;
        }
        
        SV** const check = hv_fetch(isa_hash, isa_hash_keyname, isa_hash_keylen, 0);
        SV* result;

        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(val));
        PUTBACK;
        count  = call_sv(*check, G_SCALAR);
        SPAGAIN;
        result = POPs;
        bool return_val = SvTRUE(result);
        FREETMPS;
        LEAVE;
        
        return return_val;
    }
    
    // ArrayRef-like types
    if ( flags & 16 ) {
        if ( !IsArrayRef(val) ) {
            return FALSE;
        }
        // ArrayRef[Any] or ArrayRef
        if ( flags == 16 ) {
            return TRUE;
        }
        int newflags = flags & 15;
        AV* const av = (AV*)SvRV(val);
        I32 const len = av_len(av) + 1;
        I32 i;
        for (i = 0; i < len; i++) {
            SV* const subval = *av_fetch(av, i, TRUE);
            if ( ! xscon_check_type(newflags, subval, NULL, NULL, 0) ) {
                return FALSE;
            }
        }
        return TRUE;
    }

    // HashRef-like types
    if ( flags & 32 ) {
        if ( !IsHashRef(val) ) {
            return FALSE;
        }
        // HashRef[Any] or HashRef
        if ( flags == 32 ) {
            return TRUE;
        }
        int newflags = flags & 31;
        HV* const hv = (HV*)SvRV(val);
        HE* he;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            SV* const subval = hv_iterval(hv, he);
            if ( ! xscon_check_type(newflags, subval, NULL, NULL, 0) ) {
                hv_iterinit(hv); /* reset */
                return FALSE;
            }
        }
        return TRUE;
    }
    
    switch ( flags ) {
        case 0: // Any or Item
            return TRUE;
        case 1: // Defined
            return SvOK(val);
        case 2: // Ref
            return SvOK(val) && SvROK(val);
        case 3: // Bool
            if ( SvROK(val) || isGV(val) ) {
                return FALSE;
            }
            else if ( sv_true( val ) ) {
                if ( SvPOKp(val) ) {
                    // String "1"
                    return SvCUR(val) == 1 && SvPVX(val)[0] == '1';
                }
                else if ( SvIOKp(val) ) {
                    // Integer 1
                    return SvIVX(val) == 1;
                }
                else if( SvNOKp(val) ) {
                    // Float 1.0
                    return SvNVX(val) == 1.0;
                }
                else {
                    // Another way to check for string "1"???
                    STRLEN len;
                    char* ptr = SvPV(val, len);
                    return len == 1 && ptr[0] == '1';
                }
            }
            else {
                // Any non-reference non-true value (0, undef, "", "0")
                // is a valid Bool.
                return TRUE;
            }
        case 4: // Int
            if ( SvOK(val) && !SvROK(val) && !isGV(val) ) {
                if ( SvPOK(val) ) {
                    return _S_pv_is_integer( SvPVX(val) );
                }
                else if ( SvIOK(val) ) {
                    return TRUE;
                }
                else if ( SvNOK(val) ) {
                    return _S_nv_is_integer( SvNVX(val) );
                }
            }
            return FALSE;
        case 5: // PositiveOrZeroInt
            // Discard non-integers
            if ( (!SvOK(val)) || SvROK(val) || isGV(val) ) {
                return FALSE;
            }
            if ( SvPOKp(val) ){
                if ( ! _S_pv_is_integer( SvPVX(val) ) ) {
                    return FALSE;
                }
            }
            else if ( SvIOKp(val) ) {
                /* ok */
            }
            else if ( SvNOKp(val) ) {
                if ( ! _S_nv_is_integer( SvNVX(val) ) ) {
                    return FALSE;
                }
            }

            // Check that the string representation is non-empty and
            // doesn't start with a minus sign. We already checked
            // for strings that don't look like integers at all.
            STRLEN len;
            char* i = SvPVx(val, len);
            return ( (len > 0 && i[0] != '-') ? TRUE : FALSE );
        case 6: // Num
            // In Perl We Trust
            return looks_like_number(val);
        case 7: // PositiveOrZeroNum
            if ( ! looks_like_number(val) ) {
                return FALSE;
            }
            NV numeric = SvNV(val);
            return numeric >= 0.0;
        case 8: // Str
            return SvOK(val) && !SvROK(val) && !isGV(val);
        case 9: // NonEmptyStr
            if ( SvOK(val) && !SvROK(val) && !isGV(val) ) {
                STRLEN l = sv_len(val);
                return ( (l==0) ? FALSE : TRUE );
            }
            return FALSE;
        case 10: // ClassName
            return _is_class_loaded(val);
        case 11: // might use later
            croak("PANIC!");
        case 12: // Object
            return IsObject(val);
        case 13: // ScalarRef
            return IsScalarRef(val);
        case 14: // CodeRef
            return IsCodeRef(val);
        case 15:
            // Should have already been checked by if block at start of function.
            croak("PANIC!");
        default:
            // Should never happen
            croak("PANIC!");
    } // switch ( flags )
}

void
xscon_run_trigger(SV *object,
                  const char *attr_name,
                  int attr_flags,
                  HV *trigger_hash)
{
    dTHX;
    dSP;

    STRLEN attr_len = strlen(attr_name);

    SV *mutexkey_sv;
    SV **svp;
    SV *trigger_sv;
    SV *value_sv;

    HV *object_hv = (HV *)SvRV(object);

    mutexkey_sv = newSV(attr_len + sizeof(":trigger_mutex") - 1);
    sv_setpvn(mutexkey_sv, attr_name, attr_len);
    sv_catpvs(mutexkey_sv, ":trigger_mutex");

    if (hv_exists_ent(object_hv, mutexkey_sv, 0)) {
        SvREFCNT_dec(mutexkey_sv);
        return;
    }

    hv_store_ent(object_hv, mutexkey_sv, newSViv(1), 0);

    ENTER;
    SAVETMPS;

    /* Ensure the key SV is released */
    SAVEDESTRUCTOR_X(dec_sv_refcnt, (void *)mutexkey_sv);

    /* Ensure the mutex is deleted on scope exit */
    struct delete_ent_ctx *ctx;
    Newxz(ctx, 1, struct delete_ent_ctx);
    ctx->hv  = object_hv;
    ctx->key = mutexkey_sv;
    SAVEDESTRUCTOR_X(delete_mutex, ctx);

    svp = hv_fetch(trigger_hash, attr_name, attr_len, 0);
    if (!svp || !SvOK(*svp)) {
        FREETMPS;
        LEAVE;
        return;
    }

    trigger_sv = *svp;

    svp = hv_fetch(object_hv, attr_name, attr_len, 0);
    value_sv = svp ? *svp : &PL_sv_undef;

    if (!SvROK(trigger_sv)) {

        /* ----------------------------------------------
         * Trigger is a method name (string)
         * Perl: $object->$trigger($object->{$attr_name})
         * ---------------------------------------------- */

        PUSHMARK(SP);
        XPUSHs((SV *)object);   /* invocant */
        XPUSHs(value_sv);
        PUTBACK;

        call_method(SvPV_nolen(trigger_sv), G_VOID);

    }
    else if (SvTYPE(SvRV(trigger_sv)) == SVt_PVCV) {

        /* ----------------------------------------------
         * Trigger is a coderef
         * Perl: $trigger->($object, $object->{$attr_name})
         * ---------------------------------------------- */

        PUSHMARK(SP);
        XPUSHs((SV *)object);
        XPUSHs(value_sv);
        PUTBACK;

        call_sv(trigger_sv, G_VOID);

    }
    else {
        croak("Unexpected trigger type");
    }

    FREETMPS;
    LEAVE;
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
    char* init_arg;
    STRLEN keylen;
    STRLEN init_arg_len;
    int flags;

    /* find out allowed attributes */
    SV** const HAS_globref = hv_fetch(stash, "__XSCON_HAS", 11, 0);
    AV* const HAS_array = GvAV(*HAS_globref);
    I32 const HAS_len = av_len(HAS_array) + 1;

    /* Fliggity flags for each attribute */
    SV** const FLAGS_globref = hv_fetch(stash, "__XSCON_FLAGS", 13, 0);
    HV* const FLAGS_hash = GvHV(*FLAGS_globref);
    
    /* Type constraints, coercions, and defaults */
    SV** const ISA_globref = hv_fetch(stash, "__XSCON_ISA", 11, 0);
    HV* const ISA_hash = GvHV(*ISA_globref);
    SV** const COERCIONS_globref = hv_fetch(stash, "__XSCON_COERCIONS", 17, 0);
    HV* const COERCIONS_hash = GvHV(*COERCIONS_globref);
    SV** const DEFAULTS_globref = hv_fetch(stash, "__XSCON_DEFAULTS", 16, 0);
    HV* const DEFAULTS_hash = GvHV(*DEFAULTS_globref);
    SV** const TRIGGERS_globref = hv_fetch(stash, "__XSCON_TRIGGERS", 16, 0);
    HV* const TRIGGERS_hash = GvHV(*TRIGGERS_globref);
    SV** const INIT_ARGS_globref = hv_fetch(stash, "__XSCON_INIT_ARGS", 17, 0);
    HV* const INIT_ARGS_hash = GvHV(*INIT_ARGS_globref);

    /* copy allowed attributes */
    for (i = 0; i < HAS_len; i++) {
        tmp = av_fetch(HAS_array, i, 0);
        assert(tmp);
        attr = *tmp;
        keyname = SvPV(attr, keylen);
        init_arg = SvPV(attr, init_arg_len);
        
        tmp2 = hv_fetch(FLAGS_hash, keyname, keylen, 0);
        assert(tmp2);
        fliggity = *tmp2;
        flags = (int)SvIV(fliggity);
        
        if ( flags & XSCON_FLAG_HAS_INIT_ARG && !( flags & XSCON_FLAG_NO_INIT_ARG ) ) {
            SV** tmp = hv_fetch(INIT_ARGS_hash, init_arg, init_arg_len, 0);
            SV* tmp2 = *tmp;
            init_arg = SvPV(tmp2, init_arg_len);
        }
        
        SV** valref;
        SV* val;
        bool has_value = FALSE;
        bool value_was_from_args = FALSE;
        
        if ( (!( flags & XSCON_FLAG_NO_INIT_ARG )) && hv_exists(args, init_arg, init_arg_len) ) {
            // Value provided in args hash
            valref = hv_fetch(args, init_arg, init_arg_len, 0);
            val = newSVsv(*valref);
            has_value = TRUE;
            value_was_from_args = TRUE;
        }
        else if ( flags & XSCON_FLAG_HAS_DEFAULT ) {
            // There is a default/builder
            has_value = TRUE;
            // Some very common defaults are worth hardcoding into the flags
            // so we won't even need to do a hash lookup to find the default
            // value.
            I32 has_common_default = ( flags >> XSCON_BITSHIFT_DEFAULTS ) & 255;
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
                            SPAGAIN;
                            SV* got = POPs;
                            val = newSVsv(got);
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
                            SPAGAIN;
                            SV* got = POPs;
                            val = newSVsv(got);
                            FREETMPS;
                            LEAVE;
                        }
                        // It's just a literal value.
                        else {
                            val = newSVsv(*def);
                        }
                    }
                    else {
                        has_value = FALSE;
                        if ( flags & XSCON_FLAG_REQUIRED ) {
                            if ( flags & XSCON_FLAG_HAS_INIT_ARG && strcmp(keyname, init_arg) != 0 ) {
                                croak("Attribute '%s' (init arg '%s') is required", keyname, init_arg);
                            }
                            else {
                                croak("Attribute '%s' is required", keyname);
                            }
                        }
                    }
            }
        }
        else if ( flags & XSCON_FLAG_REQUIRED ) {
            if ( flags & XSCON_FLAG_HAS_INIT_ARG && strcmp(keyname, init_arg) != 0 ) {
                croak("Attribute '%s' (init arg '%s') is required", keyname, init_arg);
            }
            else {
                croak("Attribute '%s' is required", keyname);
            }
        }
        
        if ( has_value ) {
            /* there exists an isa check */
            if ( flags & XSCON_FLAG_HAS_TYPE_CONSTRAINT ) {
                int type_flags = flags >> XSCON_BITSHIFT_TYPES;
                bool result = xscon_check_type(type_flags, newSVsv(val), ISA_hash, keyname, keylen);
            
                /* we failed type check */
                if ( !result ) {
                    if ( flags & XSCON_FLAG_HAS_TYPE_COERCION && hv_exists(COERCIONS_hash, keyname, keylen) ) {
                        SV** const coercion = hv_fetch(COERCIONS_hash, keyname, keylen, 0);
                        SV* newval;
                        
                        dSP;
                        int count;
                        ENTER;
                        SAVETMPS;
                        PUSHMARK(SP);
                        EXTEND(SP, 1);
                        PUSHs(val);
                        PUTBACK;
                        count  = call_sv(*coercion, G_SCALAR);
                        SPAGAIN;
                        SV* tmpval = POPs;
                        newval = newSVsv(tmpval);
                        FREETMPS;
                        LEAVE;
                        
                        bool result = xscon_check_type(type_flags, newSVsv(newval), ISA_hash, keyname, keylen);
                        if ( result ) {
                            val = newSVsv(newval);
                        }
                        else {
                            croak("Coercion result '%s' failed type constraint for '%s'", SvPV_nolen(newval), keyname);
                        }
                    }
                    else {
                        croak("Value '%s' failed type constraint for '%s'", SvPV_nolen(val), keyname);
                    }
                }
            }
            
            (void)hv_store((HV *)SvRV(object), keyname, keylen, val, 0);
            
            if ( value_was_from_args && flags & XSCON_FLAG_HAS_TRIGGER ) {
                xscon_run_trigger(object, keyname, flags, TRIGGERS_hash);
            }
            
            if ( SvROK(val) && flags & XSCON_FLAG_WEAKEN ) {
                sv_rvweaken(val);
            }
        }
    }
}

static void
xscon_buildall(const char* pkg, const char* klass, SV* const object, SV* const args) {
    dTHX;

    assert(object);
    assert(args);

    HV* const stash = gv_stashpv(pkg, 1);
    assert(stash != NULL);
    
    SV *pkgsv = newSVpv(pkg, 0);
    SV *klasssv = newSVpv(klass, 0);
    
    /* get cache stuff */
    SV** const globref = hv_fetch(stash, "__XSCON_BUILD", 13, 0);
    HV* buildall_hash = GvHV(*globref);
    
    STRLEN klass_len = strlen(klass);
    SV** buildall = hv_fetch(buildall_hash, klass, klass_len, 0);
    
    if ( !buildall || !SvOK(*buildall) ) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(pkgsv);
        PUSHs(klasssv);
        PUTBACK;
        count = call_pv("Class::XSConstructor::populate_build", G_VOID);
        PUTBACK;
        FREETMPS;
        LEAVE;
        
        buildall = hv_fetch(buildall_hash, klass, klass_len, 0);
    }
    
    if (!SvOK(*buildall)) {
        croak("something should have happened!");
    }
    
    if (!SvROK(*buildall)) {
        return;
    }

    if (hv_exists((HV *)SvRV(args), "__no_BUILD__", 12)) {
        SV** val = hv_fetch((HV *)SvRV(args), "__no_BUILD__", 12, 0);
        if (SvOK(*val) && SvTRUE(*val)) {
            return;
        }
    }

    AV* const builds = (AV*)SvRV(*buildall);
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
xscon_demolishall(const char* pkg, const char* klass, SV* const object, I32 in_global_destruction) {
    dTHX;

    assert(object);

    HV* const stash = gv_stashpv(pkg, 1);
    assert(stash != NULL);
    
    SV *pkgsv = newSVpv(pkg, 0);
    SV *klasssv = newSVpv(klass, 0);
    
    /* get cache stuff */
    SV** const globref = hv_fetch(stash, "__XSCON_DEMOLISH", 16, 0);
    HV* demolishall_hash = GvHV(*globref);
    
    STRLEN klass_len = strlen(klass);
    SV** demolishall = hv_fetch(demolishall_hash, klass, klass_len, 0);
    
    if ( !demolishall || !SvOK(*demolishall) ) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(pkgsv);
        PUSHs(klasssv);
        PUTBACK;
        count = call_pv("Class::XSConstructor::populate_demolish", G_VOID);
        PUTBACK;
        FREETMPS;
        LEAVE;
        
        demolishall = hv_fetch(demolishall_hash, klass, klass_len, 0);
    }
    
    if (!SvOK(*demolishall)) {
        croak("something should have happened!");
    }
    
    if (!SvROK(*demolishall)) {
        return;
    }

    AV* const demolishes = (AV*)SvRV(*demolishall);
    I32 const len = av_len(demolishes) + 1;
    SV** tmp;
    SV* demolish;
    I32 i;

    for (i = 0; i < len; i++) {
        tmp = av_fetch(demolishes, i, 0);
        assert(tmp);
        demolish = *tmp;
        
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(object);
        XPUSHs(sv_2mortal(newSViv((IV)in_global_destruction)));
        PUTBACK;
        count = call_sv(demolish, G_VOID);
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

BOOT:
{
    HV *stash = gv_stashpv("Class::XSConstructor", GV_ADD);

    newCONSTSUB(stash, "XSCON_FLAG_REQUIRED",             newSViv(XSCON_FLAG_REQUIRED));
    newCONSTSUB(stash, "XSCON_FLAG_HAS_TYPE_CONSTRAINT",  newSViv(XSCON_FLAG_HAS_TYPE_CONSTRAINT));
    newCONSTSUB(stash, "XSCON_FLAG_HAS_TYPE_COERCION",    newSViv(XSCON_FLAG_HAS_TYPE_COERCION));
    newCONSTSUB(stash, "XSCON_FLAG_HAS_DEFAULT",          newSViv(XSCON_FLAG_HAS_DEFAULT));
    newCONSTSUB(stash, "XSCON_FLAG_NO_INIT_ARG",          newSViv(XSCON_FLAG_NO_INIT_ARG));
    newCONSTSUB(stash, "XSCON_FLAG_HAS_INIT_ARG",         newSViv(XSCON_FLAG_HAS_INIT_ARG));
    newCONSTSUB(stash, "XSCON_FLAG_HAS_TRIGGER",          newSViv(XSCON_FLAG_HAS_TRIGGER));
    newCONSTSUB(stash, "XSCON_FLAG_WEAKEN",               newSViv(XSCON_FLAG_WEAKEN));
    newCONSTSUB(stash, "XSCON_BITSHIFT_DEFAULTS",         newSViv(XSCON_BITSHIFT_DEFAULTS));
    newCONSTSUB(stash, "XSCON_BITSHIFT_TYPES",            newSViv(XSCON_BITSHIFT_TYPES));
}

void
new_object(SV* klass, ...)
CODE:
{
    dTHX;
    const char* klassname;
    SV* args;
    SV* object;

    char *constructor_package_name = (char *) CvXSUBANY(cv).any_ptr;

    klassname = SvROK(klass) ? sv_reftype(SvRV(klass), 1) : SvPV_nolen_const(klass);
    args = newRV_inc((SV*)xscon_buildargs(klassname, ax, items));
    sv_2mortal(args);
    object = xscon_create_instance(klassname);
    xscon_initialize_object(constructor_package_name, klassname, object, (HV*)SvRV(args), FALSE);
    xscon_buildall(constructor_package_name, klassname, object, args);
    xscon_strictcon(constructor_package_name, object, args);
    ST(0) = object; /* because object is mortal, we should return it as is */
    XSRETURN(1);
}

void
destroy(SV* object, ...)
CODE:
{
    dTHX;
    char *destructor_package_name = (char *) CvXSUBANY(cv).any_ptr;
    const char* klassname = SvROK(object) ? sv_reftype(SvRV(object), 1) : SvPV_nolen_const(object);
    I32 in_global_destruction = PL_dirty;
    xscon_demolishall(destructor_package_name, klassname, object, in_global_destruction);
    XSRETURN(0);
}

void
install_constructor(char* name)
CODE:
{
    dTHX;
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

void
install_destructor(char* name)
CODE:
{
    dTHX;
    CV *cv = newXS(name, XS_Class__XSConstructor_destroy, (char*)__FILE__);
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
