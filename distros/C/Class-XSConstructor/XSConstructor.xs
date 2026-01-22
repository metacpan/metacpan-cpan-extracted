#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#include "xshelper.h"
#include "Clone.xs"

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
    XSCON_FLAG_HAS_ALIASES          =  256,
    XSCON_FLAG_HAS_SLOT_INITIALIZER =  512,
    XSCON_FLAG_UNDEF_TOLERANT       = 1024,
    XSCON_FLAG_CLONE_ON_WRITE       = 2048,

    XSCON_BITSHIFT_DEFAULTS         =   16,
    XSCON_BITSHIFT_TYPES            =   24,
};

enum {
    XSCON_TYPE_BASE_ANY             =    0,
    XSCON_TYPE_BASE_DEFINED         =    1,
    XSCON_TYPE_BASE_REF             =    2,
    XSCON_TYPE_BASE_BOOL            =    3,
    XSCON_TYPE_BASE_INT             =    4,
    XSCON_TYPE_BASE_PZINT           =    5,
    XSCON_TYPE_BASE_NUM             =    6,
    XSCON_TYPE_BASE_PZNUM           =    7,
    XSCON_TYPE_BASE_STR             =    8,
    XSCON_TYPE_BASE_NESTR           =    9,
    XSCON_TYPE_BASE_CLASSNAME       =   10,
    XSCON_TYPE_BASE_OBJECT          =   12,
    XSCON_TYPE_BASE_SCALARREF       =   13,
    XSCON_TYPE_BASE_CODEREF         =   14,

    XSCON_TYPE_OTHER                =   15,

    XSCON_TYPE_ARRAYREF             =   16,
    XSCON_TYPE_HASHREF              =   32,
};

enum {
    XSCON_DEFAULT_UNDEF             = 1,
    XSCON_DEFAULT_ZERO              = 2,
    XSCON_DEFAULT_ONE               = 3,
    XSCON_DEFAULT_FALSE             = 4,
    XSCON_DEFAULT_TRUE              = 5,
    XSCON_DEFAULT_EMPTY_STR         = 6,
    XSCON_DEFAULT_EMPTY_ARRAY       = 7,
    XSCON_DEFAULT_EMPTY_HASH        = 8,
};

typedef struct {
    char   *name;
    I32     flags;
    char   *init_arg;

    char  **aliases;
    I32     num_aliases;

    SV     *default_sv;
    SV     *trigger_sv;
    CV     *check_cv;
    CV     *coercion_cv;
    CV     *slot_initializer_cv;
    CV     *cloner_cv;
} xscon_param_t;

typedef struct {
    char   *package;
    bool    is_placeholder;

    CV     *buildargs_cv;
    CV     *foreignbuildargs_cv;
    CV     *foreignconstructor_cv;
    bool    foreignbuildall;

    xscon_param_t *params;
    I32     num_params;

    CV    **build_methods;
    I32     num_build_methods;

    bool    strict_params;
    char  **allow;
    I32     num_allow;
} xscon_constructor_t;

typedef struct {
    char *package;
    bool is_placeholder;

    CV  **demolish_methods;
    I32   num_demolish_methods;
} xscon_destructor_t;

typedef struct {
    char   *slot;
    bool    has_default;
    I32     default_flags;
    SV     *default_sv;
    bool    has_check;
    I32     check_flags;
    CV     *check_cv;
    bool    has_coercion;
    CV     *coercion_cv;
    bool    should_clone;
    CV     *cloner_cv;
} xscon_reader_t;

typedef struct {
    char *slot;
    char *method_name;
    bool has_curried;
    AV *curried;
    bool is_accessor;
    bool is_try;
} xscon_delegation_t;

xscon_constructor_t*
xscon_constructor_get_metadata(SV *sig_sv, xscon_constructor_t* sig) {

    dTHX;
    dSP;

    if (!sig_sv) {
        if ( !sig ) {
            croak("Expected sig_sv or sig");
        }
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(sig->package, 0)));
        PUTBACK;
        I32 count = call_pv("Class::XSConstructor::get_metadata", G_SCALAR);
        SPAGAIN;
        SV *sv = POPs;
        sig_sv = newSVsv(sv);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    /* Validate and dereference the top-level hashref */
    if (!SvROK(sig_sv) || SvTYPE(SvRV(sig_sv)) != SVt_PVHV) {
        croak("signature must be a hashref");
    }
    HV *sig_hv = (HV *)SvRV(sig_sv);

    SV **svp;

    /* Allocate the signature struct */
    if ( sig == NULL ) {
        xscon_constructor_t *sig;
        Newxz(sig, 1, xscon_constructor_t);
    }
    else {
        if (sig->params) {
            for (I32 i = 0; i < sig->num_params; i++) {
                xscon_param_t *p = &sig->params[i];
                Safefree(p->name);
                Safefree(p->init_arg);
                for (I32 j = 0; j < p->num_aliases; j++)
                    Safefree(p->aliases[j]);
                Safefree(p->aliases);
                SvREFCNT_dec(p->default_sv);
                SvREFCNT_dec(p->trigger_sv);
                SvREFCNT_dec(p->check_cv);
                SvREFCNT_dec(p->coercion_cv);
                SvREFCNT_dec(p->cloner_cv);
                SvREFCNT_dec(p->slot_initializer_cv);
            }
            Safefree(sig->params);
        }
        if (sig->allow) {
            for (I32 j = 0; j < sig->num_allow; j++)
                Safefree(sig->allow[j]);
            Safefree(sig->allow);
        }
        if (sig->build_methods) {
            for (I32 i = 0; i < sig->num_build_methods; i++) {
                if (sig->build_methods[i]) {
                    SvREFCNT_dec(sig->build_methods[i]);
                }
            }
            Safefree(sig->build_methods);
        }
        if (sig->foreignbuildargs_cv)
            Safefree(sig->foreignbuildargs_cv);
        if (sig->foreignconstructor_cv)
            Safefree(sig->foreignconstructor_cv);
        if (sig->buildargs_cv)
            Safefree(sig->buildargs_cv);
    }

    /* This is not a placeholder. */
    sig->is_placeholder = FALSE;

    /* Extract package */
    svp = hv_fetchs(sig_hv, "package", 0);
    if (svp && *svp && SvOK(*svp)) {
        sig->package = savepv(SvPV_nolen(*svp));
    } else {
        sig->package = NULL;
    }

    /* buildargs_cv */
    svp = hv_fetchs(sig_hv, "buildargs", 0);
    if (svp && SvOK(*svp)) {
        sig->buildargs_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
    } else {
        sig->buildargs_cv = NULL;
    }

    /* foreignbuildargs_cv */
    svp = hv_fetchs(sig_hv, "foreignbuildargs", 0);
    if (svp && SvOK(*svp)) {
        sig->foreignbuildargs_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
    } else {
        sig->foreignbuildargs_cv = NULL;
    }

    /* foreignconstructor_cv */
    svp = hv_fetchs(sig_hv, "foreignconstructor", 0);
    if (svp && SvOK(*svp)) {
        sig->foreignconstructor_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
    } else {
        sig->foreignconstructor_cv = NULL;
    }

    /* foreignbuildall */
    svp = hv_fetchs(sig_hv, "foreignbuildall", 0);
    if (svp && SvOK(*svp)) {
        sig->foreignbuildall = TRUE;
    } else {
        sig->foreignbuildall = FALSE;
    }

    /* Get build methods */
    {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(sig->package, 0)));
        PUTBACK;
        I32 count = call_pv("Class::XSConstructor::get_build_methods", G_ARRAY);
        SPAGAIN;
        if (count > 0) {
            Newxz(sig->build_methods, count, CV *);
            sig->num_build_methods = count;
            for (I32 i = count - 1; i >= 0; i--) {
                SV *sv = POPs;
                if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV) {
                    croak("get_build_methods must return only coderefs");
                }
                sig->build_methods[i] = (CV *)SvREFCNT_inc(SvRV(sv));
            }
        }
        else {
            sig->num_build_methods = 0;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    /* Extract strict_params */
    svp = hv_fetchs(sig_hv, "strict_params", 0);
    sig->strict_params = (svp && *svp && SvTRUE(*svp));

    /* Extract aliases (arrayref of strings) */
    svp = hv_fetchs(sig_hv, "allow", 0);
    if (sig->strict_params && svp && *svp) {
        if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
            croak("allow must be an arrayref");
        }

        AV *aav = (AV *)SvRV(*svp);
        I32 na = av_len(aav) + 1;
        sig->num_allow = na;
        Newxz(sig->allow, na, char *);
        for (I32 j = 0; j < na; j++) {
            SV **asv = av_fetch(aav, j, 0);
            if (!asv || !*asv || !SvOK(*asv)) {
                croak("allow value must be a string");
            }
            sig->allow[j] = savepv(SvPV_nolen(*asv));
        }
    }

    /* Fetch and validate params arrayref */
    svp = hv_fetchs(sig_hv, "params", 0);
    if (!svp || !*svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
        croak("'params' must be an arrayref");
    }
    AV *params_av = (AV *)SvRV(*svp);

    /* Allocate the params array */
    I32 num_params = av_len(params_av) + 1;
    sig->num_params = num_params;
    Newxz(sig->params, num_params, xscon_param_t);

    /* Iterate over params array */
    for (I32 i = 0; i < num_params; i++) {

        /* Extract param hashref */
        SV **elem = av_fetch(params_av, i, 0);
        if (!elem || !*elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
            croak("params[%d] must be a hashref", i);
        }

        HV *phv = (HV *)SvRV(*elem);
        xscon_param_t *p = &sig->params[i];

        /* Extract simple scalar fields */

        /* name */
        svp = hv_fetchs(phv, "name", 0);
        if (!svp || !*svp || !SvOK(*svp)) {
            croak("params[%d]{name} is required", i);
        }
        p->name = savepv(SvPV_nolen(*svp));

        /* flags */
        svp = hv_fetchs(phv, "flags", 0);
        p->flags = (svp && *svp) ? SvIV(*svp) : 0;

        /* init_arg */
        svp = hv_fetchs(phv, "init_arg", 0);
        if (svp && *svp && SvOK(*svp)) {
            p->init_arg = savepv(SvPV_nolen(*svp));
        }
        else {
            p->init_arg = NULL;
        }

        /* Extract aliases (arrayref of strings) */
        svp = hv_fetchs(phv, "aliases", 0);
        if (svp && *svp) {
            if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
                croak("aliases must be an arrayref");
            }

            AV *aav = (AV *)SvRV(*svp);
            I32 na = av_len(aav) + 1;
            p->num_aliases = na;
            Newxz(p->aliases, na, char *);
            for (I32 j = 0; j < na; j++) {
                SV **asv = av_fetch(aav, j, 0);
                if (!asv || !*asv || !SvOK(*asv)) {
                    croak("alias must be a string");
                }
                p->aliases[j] = savepv(SvPV_nolen(*asv));
            }
        }

        svp = hv_fetchs(phv, "default", 0);
        if (svp && SvOK(*svp)) {
            p->default_sv = SvREFCNT_inc(*svp);
        } else {
            p->default_sv = NULL;
        }

        svp = hv_fetchs(phv, "trigger", 0);
        if (svp && SvOK(*svp)) {
            p->trigger_sv = SvREFCNT_inc(*svp);
        } else {
            p->trigger_sv = NULL;
        }

        svp = hv_fetchs(phv, "check", 0);
        if (svp && SvOK(*svp)) {
            if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
                croak("check must be a coderef");
            p->check_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
        }
        else {
            p->check_cv = NULL;
        }

        svp = hv_fetchs(phv, "coercion", 0);
        if (svp && SvOK(*svp)) {
            if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
                croak("coercion must be a coderef");
            p->coercion_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
        }
        else {
            p->coercion_cv = NULL;
        }

        svp = hv_fetchs(phv, "slot_initializer", 0);
        if (svp && SvOK(*svp)) {
            if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
                croak("slot_initializer must be a coderef");
            p->slot_initializer_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
        }
        else {
            p->slot_initializer_cv = NULL;
        }

        svp = hv_fetchs(phv, "clone_on_write", 0);
        if (svp && SvOK(*svp)) {
            if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
                p->cloner_cv = (CV *)SvREFCNT_inc(SvRV(*svp));
            }
            else {
                p->cloner_cv = NULL;
            }
        }
        else {
            p->cloner_cv = NULL;
        }
    }
    
    return sig;
}

xscon_destructor_t*
xscon_destructor_get_metadata(char *packagename, xscon_destructor_t* sig) {

    dTHX;
    dSP;

    /* Allocate the signature struct */
    if ( sig == NULL ) {
        xscon_destructor_t *sig;
        Newxz(sig, 1, xscon_destructor_t);
    }
    else {
        if (sig->demolish_methods) {
            for (I32 i = 0; i < sig->num_demolish_methods; i++) {
                if (sig->demolish_methods[i]) {
                    SvREFCNT_dec(sig->demolish_methods[i]);
                }
            }
            Safefree(sig->demolish_methods);
        }
    }

    /* This is not a placeholder. */
    sig->is_placeholder = FALSE;

    /* Extract package */
    sig->package = packagename;

    /* Get demolish methods */
    {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(sig->package, 0)));
        PUTBACK;
        I32 count = call_pv("Class::XSConstructor::get_demolish_methods", G_ARRAY);
        SPAGAIN;
        if (count > 0) {
            Newxz(sig->demolish_methods, count, CV *);
            sig->num_demolish_methods = count;
            for (I32 i = count - 1; i >= 0; i--) {
                SV *sv = POPs;
                if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV) {
                    croak("get_demolish_methods must return only coderefs");
                }
                sig->demolish_methods[i] = (CV *)SvREFCNT_inc(SvRV(sv));
            }
        }
        else {
            sig->num_demolish_methods = 0;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    return sig;
}

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
xscon_buildargs(const xscon_constructor_t* sig, const char* klass, I32 ax, I32 items) {
    dTHX;
    HV* args;

    if ( sig->buildargs_cv ) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        I32 i;
        for (i = 0; i < items; i++) {
            XPUSHs( newSVsv(ST(i)) );
        }
        PUTBACK;
        count = call_sv((SV *)sig->buildargs_cv, G_SCALAR);
        SPAGAIN;
        SV* got = POPs;
        SV* args_ref = newSVsv(got);
        FREETMPS;
        LEAVE;
        if (!IsHashRef(args_ref)) {
            croak("BUILDARGS did not return a hashref");
        }
        return (HV*)SvRV(args_ref);
    }

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

static AV*
xscon_foreignbuildargs(const xscon_constructor_t* sig, const char* klass, AV* args, I32 context) {

    dTHX;
    dSP;

    /* Case 1: no foreignbuildargs_cv → return @_, the class name shifted off */
    if (!sig->foreignbuildargs_cv) {
        SV *discarded = av_shift(args);
        return args;
    }

    /* Case 2: call foreignbuildargs CV */
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    I32 argslen = av_len(args);
    for (I32 i = 0; i <= argslen; i++) {
        SV **svp = av_fetch(args, i, 0);
        XPUSHs(svp ? *svp : &PL_sv_undef);
    }
    PUTBACK;

    I32 count = call_sv((SV *)sig->foreignbuildargs_cv, context);

    SPAGAIN;

    AV* av = newAV();
    /* copy return values into AV */
    av_extend(av, count);
    for (I32 i = 0; i < count; i++) {
        SV *sv = POPs;
        av_store(av, count - ( i + 1 ), newSVsv(sv));
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return av;
}

static SV*
xscon_foreignconstructor(const xscon_constructor_t* sig, const char* klass, AV* fbargs) {
    dTHX;
    dSP;

    SV *ret;

    /* Must have a constructor CV */
    if (!sig->foreignconstructor_cv) {
        croak("No foreign constructor defined for class %s", klass);
    }

    /* --- call constructor in scalar context --- */
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);

    /* push class name as first argument */
    XPUSHs(sv_2mortal(newSVpv(klass, 0)));

    /* push fbargs as list */
    I32 n = av_len(fbargs);
    for (I32 i = 0; i <= n; i++) {
        SV **svp = av_fetch(fbargs, i, 0);
        XPUSHs(svp ? *svp : &PL_sv_undef);
    }

    PUTBACK;

    I32 count = call_sv((SV *)sig->foreignconstructor_cv, G_SCALAR);

    SPAGAIN;
    
    if (count != 1) {
        FREETMPS;
        LEAVE;
        croak("Foreign constructor did not return a value");
    }

    ret = POPs;

    /* take ownership before temporaries are freed */
    SvREFCNT_inc(ret);
    
    PUTBACK;
    FREETMPS;
    LEAVE;

    /* --- validate return value --- */

    if (SvROK(ret) && sv_isobject(ret)) {
        
        /* same class? */
        if (sv_isa(ret, klass)) {
            return ret;
        }

        /* different class → re-bless */
        HV *newstash = gv_stashpv(klass, GV_ADD);
        if (!newstash) {
            SvREFCNT_dec(ret);
            croak("Cannot find stash for class %s", klass);
        }

        sv_bless(ret, newstash);
        return ret;
    }
    
    SvREFCNT_dec(ret);
    croak("Foreign constructor did not return an object");
}

static SV*
xscon_create_instance(const xscon_constructor_t* sig, const char* klass) {
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
xscon_check_type(char* keyname, SV* const val, int flags, CV* check_cv)
{
    dTHX;
    assert(val);

    // An unknown type constraint
    // We need to dive into the isa_hash to check it
    if ( flags & XSCON_TYPE_OTHER == XSCON_TYPE_OTHER ) {
        if ( !check_cv ) {
            warn( "Type constraint check coderef gone AWOL for attribute '%s', so just assuming value passes", keyname ? keyname : "unknown" );
            return 1;
        }
        
        SV* result;

        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(val));
        PUTBACK;
        count  = call_sv((SV *)check_cv, G_SCALAR);
        SPAGAIN;
        result = POPs;
        bool return_val = SvTRUE(result);
        FREETMPS;
        LEAVE;
        
        return return_val;
    }
    
    if ( flags & XSCON_TYPE_ARRAYREF ) {
        if ( !IsArrayRef(val) ) {
            return FALSE;
        }
        if ( flags == XSCON_TYPE_ARRAYREF ) {
            return TRUE;
        }
        int newflags = flags & ( XSCON_TYPE_ARRAYREF - 1 );
        AV* const av = (AV*)SvRV(val);
        I32 const len = av_len(av) + 1;
        I32 i;
        for (i = 0; i < len; i++) {
            SV* const subval = *av_fetch(av, i, TRUE);
            if ( ! xscon_check_type(NULL, subval, newflags, NULL) ) {
                return FALSE;
            }
        }
        return TRUE;
    }

    if ( flags & XSCON_TYPE_HASHREF ) {
        if ( !IsHashRef(val) ) {
            return FALSE;
        }
        // HashRef[Any] or HashRef
        if ( flags == XSCON_TYPE_HASHREF ) {
            return TRUE;
        }
        int newflags = flags & ( XSCON_TYPE_HASHREF - 1 );
        HV* const hv = (HV*)SvRV(val);
        HE* he;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            SV* const subval = hv_iterval(hv, he);
            if ( ! xscon_check_type(NULL, subval, newflags, NULL) ) {
                hv_iterinit(hv); /* reset */
                return FALSE;
            }
        }
        return TRUE;
    }
    
    switch ( flags ) {
        case XSCON_TYPE_BASE_ANY:
            return TRUE;
        case XSCON_TYPE_BASE_DEFINED:
            return SvOK(val);
        case XSCON_TYPE_BASE_REF:
            return SvOK(val) && SvROK(val);
        case XSCON_TYPE_BASE_BOOL:
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
        case XSCON_TYPE_BASE_INT:
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
        case XSCON_TYPE_BASE_PZINT:
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
        case XSCON_TYPE_BASE_NUM:
            // In Perl We Trust
            return looks_like_number(val);
        case XSCON_TYPE_BASE_PZNUM:
            if ( ! looks_like_number(val) ) {
                return FALSE;
            }
            NV numeric = SvNV(val);
            return numeric >= 0.0;
        case XSCON_TYPE_BASE_STR:
            return SvOK(val) && !SvROK(val) && !isGV(val);
        case XSCON_TYPE_BASE_NESTR:
            if ( SvOK(val) && !SvROK(val) && !isGV(val) ) {
                STRLEN l = sv_len(val);
                return ( (l==0) ? FALSE : TRUE );
            }
            return FALSE;
        case XSCON_TYPE_BASE_CLASSNAME:
            return _is_class_loaded(val);
        case 11:
            // might use later
            croak("PANIC!");
        case XSCON_TYPE_BASE_OBJECT:
            return IsObject(val);
        case XSCON_TYPE_BASE_SCALARREF:
            return IsScalarRef(val);
        case XSCON_TYPE_BASE_CODEREF:
            return IsCodeRef(val);
        case XSCON_TYPE_OTHER:
            // Should have already been checked by if block at start of function.
            croak("PANIC!");
        default:
            // Should never happen
            croak("PANIC!");
    } // switch ( flags )
}

SV*
xscon_run_default(SV *object, char* keyname, int has_common_default, SV *default_sv)
{
    dTHX;

    switch ( has_common_default ) {
        case XSCON_DEFAULT_UNDEF:
            return newSV(0);
        case XSCON_DEFAULT_ZERO:
            return newSViv(0);
        case XSCON_DEFAULT_ONE:
            return newSViv(1);
        case XSCON_DEFAULT_FALSE:
            return &PL_sv_no;
        case XSCON_DEFAULT_TRUE:
            return &PL_sv_yes;
        case XSCON_DEFAULT_EMPTY_STR:
            return newSVpvs("");
        case XSCON_DEFAULT_EMPTY_ARRAY:
            AV *av = newAV();
            return newRV_noinc((SV*)av);
        case XSCON_DEFAULT_EMPTY_HASH:
            HV *hv = newHV();
            return newRV_noinc((SV*)hv);
    }

    if ( !default_sv ) {
        croak("Attribute '%s' is required, but default is AWOL", keyname);
        return &PL_sv_no;
    }

    // Coderef, call as method
    if (IsCodeRef( default_sv )) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(object);
        PUTBACK;
        count = call_sv((SV*)default_sv, G_SCALAR);
        SPAGAIN;
        SV* got = POPs;
        SV* val = newSVsv(got);
        FREETMPS;
        LEAVE;
        return val;
    }

    // Scalarref to the name of a builder, call as method
    if (IsScalarRef(default_sv)) {
        STRLEN len;
        SV *method_name_sv = SvRV(default_sv);
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
        SV* val = newSVsv(got);
        FREETMPS;
        LEAVE;
        return val;
    }

    return newSVsv(default_sv);
}

void
xscon_run_trigger(SV *object,
                  xscon_param_t* param)
{
    dTHX;
    dSP;

    char* attr_name = param->name;
    STRLEN attr_len = strlen(attr_name);

    SV *mutexkey_sv;
    SV **svp;
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

    svp = hv_fetch(object_hv, attr_name, attr_len, 0);
    value_sv = svp ? *svp : &PL_sv_undef;

    SV* trigger_sv = param->trigger_sv;

    if (!SvROK(trigger_sv)) {
        PUSHMARK(SP);
        XPUSHs((SV *)object);
        XPUSHs(value_sv);
        PUTBACK;
        call_method(SvPV_nolen(trigger_sv), G_VOID);
    }
    else if (SvTYPE(SvRV(trigger_sv)) == SVt_PVCV) {
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

int
xscon_initialize_object(const xscon_constructor_t* sig, const char* klass, SV* const object, HV* const args, bool const is_cloning)
{
    dTHX;

    assert(sig);
    assert(object);
    assert(args);

    if (sig->is_placeholder) {
        croak("Called on a placeholder");
    }

    if(mg_find((SV*)args, PERL_MAGIC_tied)){
        croak("You cannot use tied HASH reference as initializing arguments");
    }

    I32 i;
    int used = 0;

    /* copy allowed attributes */
    for (i = 0; i < sig->num_params; i++) {
        xscon_param_t *param = &sig->params[i];
        int flags = param->flags;
        char *keyname = param->name;
        int keylen = strlen(param->name);
        char *init_arg = param->init_arg;
        int init_arg_len = -1;
        if ( param->init_arg ) {
            init_arg_len = strlen(param->init_arg);
        }

        SV** valref;
        SV* val;
        bool has_value = FALSE;
        bool value_was_from_args = FALSE;

        if ( (!( flags & XSCON_FLAG_NO_INIT_ARG )) && init_arg_len >= 0 && hv_exists(args, init_arg, init_arg_len) ) {
            // Value provided in args hash
            valref = hv_fetch(args, init_arg, init_arg_len, 0);
            val = newSVsv(*valref);
            has_value = TRUE;
            value_was_from_args = TRUE;
            used++;
        }

        if ( flags & XSCON_FLAG_HAS_ALIASES ) {
            for (I32 i = 0; i < param->num_aliases; i++) {
                char *alias = param->aliases[i];
                int alias_len = strlen(alias);
                if ( hv_exists(args, alias, alias_len) ) {
                    if ( has_value ) {
                        croak("Superfluous alias used for attribute '%s': %s", keyname, alias);
                    }
                    else {
                        valref = hv_fetch(args, alias, alias_len, 0);
                        val = newSVsv(*valref);
                        has_value = TRUE;
                        value_was_from_args = TRUE;
                        used++;
                    }
                }
            }
        }

        if ( value_was_from_args && ( flags & XSCON_FLAG_UNDEF_TOLERANT ) && !SvOK(val) ) {
            has_value = FALSE;
            val = NULL;
        }

        if ( !has_value && flags & XSCON_FLAG_HAS_DEFAULT ) {
            // There is a default/builder
            // Some very common defaults are worth hardcoding into the flags
            // so we won't even need to do a hash lookup to find the default
            // value.
            I32 has_common_default = ( flags >> XSCON_BITSHIFT_DEFAULTS ) & 255;
            val = xscon_run_default( object, keyname, has_common_default, param->default_sv );
            has_value = TRUE;
            value_was_from_args = FALSE;
        }

        /* Type checks and coercions */
        if ( has_value && ( flags & XSCON_FLAG_HAS_TYPE_CONSTRAINT ) ) {
            int type_flags = flags >> XSCON_BITSHIFT_TYPES;
            bool failed = !xscon_check_type(keyname, newSVsv(val), type_flags, param->check_cv);
        
            /* we failed type check */
            if ( failed ) {
                if ( flags & XSCON_FLAG_HAS_TYPE_COERCION && param->coercion_cv ) {
                    SV* newval;
                    dSP;
                    int count;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    EXTEND(SP, 1);
                    PUSHs(val);
                    PUTBACK;
                    count  = call_sv((SV *)param->coercion_cv, G_SCALAR);
                    SPAGAIN;
                    SV* tmpval = POPs;
                    newval = newSVsv(tmpval);
                    FREETMPS;
                    LEAVE;
                    
                    bool passed_this_time = xscon_check_type(keyname, newSVsv(newval), type_flags, param->check_cv);
                    if ( passed_this_time ) {
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
        
        if ( has_value ) {
            if ( value_was_from_args && ( flags & XSCON_FLAG_CLONE_ON_WRITE ) ) {
                if ( param->cloner_cv ) {
                    SV* newval;
                    dSP;
                    int count;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    EXTEND(SP, 3);
                    PUSHs(object);
                    PUSHs(newSVpv(keyname, keylen));
                    PUSHs(val);
                    PUTBACK;
                    count = call_sv((SV *)param->cloner_cv, G_SCALAR);
                    SPAGAIN;
                    SV* tmpval = POPs;
                    newval = newSVsv(tmpval);
                    FREETMPS;
                    LEAVE;
                    bool passed_this_time = xscon_check_type(keyname, newSVsv(newval), flags >> XSCON_BITSHIFT_TYPES, param->check_cv);
                    if ( passed_this_time ) {
                        val = newSVsv(newval);
                    }
                    else {
                        croak("Cloning result '%s' failed type constraint for '%s'", SvPV_nolen(newval), keyname);
                    }
                }
                else {
                    HV *hseen = newHV();
                    SV *newval = sv_clone(aTHX_ val, hseen, -1);
                    hv_clear(hseen);
                    SvREFCNT_dec((SV *)hseen);
                    val = newval;
                }
            }

            if ( ( flags & XSCON_FLAG_HAS_SLOT_INITIALIZER ) && param->slot_initializer_cv ) {
                int count;
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 2);
                PUSHs(object);
                PUSHs(val);
                PUTBACK;
                count = call_sv((SV *)param->slot_initializer_cv, G_VOID);
                SPAGAIN;
                FREETMPS;
                LEAVE;
            }
            else {
                (void)hv_store((HV*)SvRV(object), keyname, keylen, val, 0);
            }

            if ( value_was_from_args && ( flags & XSCON_FLAG_HAS_TRIGGER ) ) {
                xscon_run_trigger(object, param);
            }
            
            if ( SvROK(val) && flags & XSCON_FLAG_WEAKEN ) {
                sv_rvweaken(val);
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
    }
    
    return used;
}

static void
xscon_buildall(const xscon_constructor_t* sig, const char* klass, SV* const object, SV* const args) {
    dTHX;
    dSP;

    assert(object);
    assert(args);

    HV* args_hv = (HV *)SvRV(args);

    /* __no_BUILD__ support */
    if (hv_exists(args_hv, "__no_BUILD__", 12)) {
        SV *val = hv_delete(args_hv, "__no_BUILD__", 12, 0);
        if ( SvOK(val) && SvTRUE(val) ) {
            return;
        }
    }

    /* If we can take the fast route... */
    if ( strcmp(klass, sig->package) == 0 ) {
        if ( sig->num_build_methods <= 0 )
            return;
        for (I32 i = 0; i < sig->num_build_methods; i++) {
            CV *cv = sig->build_methods[i];
            if (!cv)
                continue;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(object);
            PUSHs(args);
            PUTBACK;
            call_sv((SV *)cv, G_VOID);
            FREETMPS;
            LEAVE;
        }
        return;
    }

    /* Fall back to slow route because BUILDALL called on a subclass */
    HV* const stash = gv_stashpv("Class::XSConstructor", 1);
    assert(stash != NULL);
    
    SV *pkgsv = newSVpv(sig->package, 0);
    SV *klasssv = newSVpv(klass, 0);
    
    /* get cache stuff */
    SV** const globref = hv_fetch(stash, "BUILD_CACHE", 11, 0);
    HV* buildall_hash = buildall_hash = GvHV(*globref);
    STRLEN klass_len = strlen(klass);
    SV** buildall = hv_fetch(buildall_hash, klass, klass_len, 0);
    
    if ( !buildall || !SvOK(*buildall) ) {
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
    
    if (!buildall || !SvOK(*buildall)) {
        croak("something should have happened!");
    }
    
    if (!SvROK(*buildall)) {
        return;
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
xscon_demolishall(const xscon_destructor_t* sig, const char* klass, SV* object, bool use_eval, AV* args) {
    dTHX;
    dSP;

    assert(object);

    /* If we can take the fast route... */
    if ( strcmp(klass, sig->package) == 0 ) {
        if ( sig->num_demolish_methods <= 0 )
            return;
        for (I32 i = 0; i < sig->num_demolish_methods; i++) {
            CV *cv = sig->demolish_methods[i];
            if (!cv)
                continue;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(object);
            I32 i;
            I32 n = av_len(args);
            for (i = 0; i <= n; i++) {
                SV **svp = av_fetch(args, i, 0);
                XPUSHs(svp ? *svp : &PL_sv_undef);
            }
            PUTBACK;
            call_sv((SV *)cv, use_eval ? ( G_VOID | G_EVAL ) : G_VOID);
            FREETMPS;
            LEAVE;
        }
        return;
    }

    /* Fall back to slow route because DEMOLISHALL called on a subclass */
    HV* const stash = gv_stashpv("Class::XSConstructor", 1);
    assert(stash != NULL);
    
    SV *pkgsv = newSVpv(sig->package, 0);
    SV *klasssv = newSVpv(klass, 0);
    
    /* get cache stuff */
    SV** const globref = hv_fetch(stash, "DEMOLISH_CACHE", 14, 0);
    HV* demolishall_hash = GvHV(*globref);
    
    STRLEN klass_len = strlen(klass);
    SV** demolishall = hv_fetch(demolishall_hash, klass, klass_len, 0);
    
    if ( !demolishall || !SvOK(*demolishall) ) {
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
        I32 i;
        I32 n = av_len(args);
        for (i = 0; i <= n; i++) {
            SV **svp = av_fetch(args, i, 0);
            XPUSHs(svp ? *svp : &PL_sv_undef);
        }
        PUTBACK;
        count = call_sv(demolish, use_eval ? ( G_VOID | G_EVAL ) : G_VOID);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

static void
xscon_strictcon(const xscon_constructor_t* sig, const char* klassname, SV* const object, SV* const args) {
    dTHX;

    assert(object);
    assert(args);

    if ( ! sig->strict_params ) {
        return;
    }

    AV *badattrs = newAV();

    HV* argshv = (HV*)SvRV(args);
    HE* he;

    hv_iterinit(argshv);
    while ((he = hv_iternext(argshv))) {
        SV* const k = hv_iterkeysv(he);
        STRLEN k_len;
        char *k_str = SvPV(k, k_len);
        bool found = FALSE;

        I32 i;
        for (i = 0; i < sig->num_allow; i++) {
            if (k_len == strlen(sig->allow[i]) && memcmp(k_str, sig->allow[i], k_len) == 0) {
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
    newCONSTSUB(stash, "XSCON_FLAG_HAS_ALIASES",          newSViv(XSCON_FLAG_HAS_ALIASES));
    newCONSTSUB(stash, "XSCON_FLAG_HAS_SLOT_INITIALIZER", newSViv(XSCON_FLAG_HAS_SLOT_INITIALIZER));
    newCONSTSUB(stash, "XSCON_FLAG_UNDEF_TOLERANT",       newSViv(XSCON_FLAG_UNDEF_TOLERANT));
    newCONSTSUB(stash, "XSCON_FLAG_CLONE_ON_WRITE",       newSViv(XSCON_FLAG_CLONE_ON_WRITE));

    newCONSTSUB(stash, "XSCON_BITSHIFT_DEFAULTS",         newSViv(XSCON_BITSHIFT_DEFAULTS));
    newCONSTSUB(stash, "XSCON_BITSHIFT_TYPES",            newSViv(XSCON_BITSHIFT_TYPES));

    newCONSTSUB(stash, "XSCON_DEFAULT_UNDEF",             newSViv(XSCON_DEFAULT_UNDEF));
    newCONSTSUB(stash, "XSCON_DEFAULT_ZERO",              newSViv(XSCON_DEFAULT_ZERO));
    newCONSTSUB(stash, "XSCON_DEFAULT_ONE",               newSViv(XSCON_DEFAULT_ONE));
    newCONSTSUB(stash, "XSCON_DEFAULT_FALSE",             newSViv(XSCON_DEFAULT_FALSE));
    newCONSTSUB(stash, "XSCON_DEFAULT_TRUE",              newSViv(XSCON_DEFAULT_TRUE));
    newCONSTSUB(stash, "XSCON_DEFAULT_EMPTY_STR",         newSViv(XSCON_DEFAULT_EMPTY_STR));
    newCONSTSUB(stash, "XSCON_DEFAULT_EMPTY_ARRAY",       newSViv(XSCON_DEFAULT_EMPTY_ARRAY));
    newCONSTSUB(stash, "XSCON_DEFAULT_EMPTY_HASH",        newSViv(XSCON_DEFAULT_EMPTY_HASH));

    newCONSTSUB(stash, "XSCON_TYPE_BASE_ANY",             newSViv(XSCON_TYPE_BASE_ANY));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_DEFINED",         newSViv(XSCON_TYPE_BASE_DEFINED));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_REF",             newSViv(XSCON_TYPE_BASE_REF));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_BOOL",            newSViv(XSCON_TYPE_BASE_BOOL));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_INT",             newSViv(XSCON_TYPE_BASE_INT));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_PZINT",           newSViv(XSCON_TYPE_BASE_PZINT));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_NUM",             newSViv(XSCON_TYPE_BASE_NUM));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_PZNUM",           newSViv(XSCON_TYPE_BASE_PZNUM));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_STR",             newSViv(XSCON_TYPE_BASE_STR));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_NESTR",           newSViv(XSCON_TYPE_BASE_NESTR));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_CLASSNAME",       newSViv(XSCON_TYPE_BASE_CLASSNAME));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_OBJECT",          newSViv(XSCON_TYPE_BASE_OBJECT));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_SCALARREF",       newSViv(XSCON_TYPE_BASE_SCALARREF));
    newCONSTSUB(stash, "XSCON_TYPE_BASE_CODEREF",         newSViv(XSCON_TYPE_BASE_CODEREF));

    newCONSTSUB(stash, "XSCON_TYPE_OTHER",                newSViv(XSCON_TYPE_OTHER));

    newCONSTSUB(stash, "XSCON_TYPE_ARRAYREF",             newSViv(XSCON_TYPE_ARRAYREF));
    newCONSTSUB(stash, "XSCON_TYPE_HASHREF",              newSViv(XSCON_TYPE_HASHREF));
}

void
new_object(SV* klass, ...)
CODE:
{
    dTHX;
    dSP;

    const char* klassname;
    SV* args;
    SV* object;

    xscon_constructor_t *sig = (xscon_constructor_t *) CvXSUBANY(cv).any_ptr;
    if (sig->is_placeholder) xscon_constructor_get_metadata(NULL, sig);

    /* $klassname = shift */
    klassname = SvROK(klass) ? sv_reftype(SvRV(klass), 1) : SvPV_nolen_const(klass);

    bool need_to_remove_no_build = FALSE;

    if ( sig->foreignbuildall ) {
        if ( sig->foreignbuildargs_cv ) {
            /* @fbargs = scalar $foreign->BUILDARGS( @_ ) */
            AV *av = newAV();
            for (I32 i = 0; i < items; i++) {
                av_push(av, newSVsv(ST(i)));
            }
            AV* fbargs = xscon_foreignbuildargs(sig, klassname, av, G_SCALAR);

            /* $args = $fbargs[0] */
            SV** svp = av_fetch(fbargs, 0, 0);
            args = newSVsv(*svp);

            if ( !args || !IsHashRef(args)) {
                croak("Parent BUILDARGS did not return a hashref");
            }
        }
        else {
            /* $args = ref($_[0]) eq 'HASH' ? %{+shift} : @_ */
            args = newRV_inc((SV*)xscon_buildargs(sig, klassname, ax, items));
            sv_2mortal(args);
        }

        if ( !hv_exists((HV*)SvRV(args), "__no_BUILD__", 12) ) {
            /* $args{__no_BUILD__} = !!1 */
            (void)hv_store((HV*)SvRV(args), "__no_BUILD__", 12, &PL_sv_yes, 0);
            need_to_remove_no_build = TRUE;
        }

        /* @args_but_list = ( $args ) */
        AV *args_but_list = newAV();
        av_push( args_but_list, newSVsv(args) );

        /* $object = $klassname->SUPER::new( @args_but_list ); */
        object = xscon_foreignconstructor(sig, klassname, args_but_list);

        if ( need_to_remove_no_build ) {
            (void)hv_delete((HV*)SvRV(args), "__no_BUILD__", 12, G_DISCARD);
            need_to_remove_no_build = FALSE;
        }
    }
    else if ( sig->foreignconstructor_cv ) {
        /* @fbargs = $klassname->can('FOREIGNBUILDARGS') ? $klassname->FOREIGNBUILDARGS( @_ ) : @_ */
        AV *av = newAV();
        for (I32 i = 0; i < items; i++) {
            av_push(av, newSVsv(ST(i)));
        }
        AV* fbargs = xscon_foreignbuildargs(sig, klassname, av, G_ARRAY);

        /* $object = $klassname->SUPER::new( @fbargs ); */
        object = xscon_foreignconstructor(sig, klassname, fbargs);

        /* $args = ref($_[0]) eq 'HASH' ? %{+shift} : @_ */
        args = newRV_inc((SV*)xscon_buildargs(sig, klassname, ax, items));
        sv_2mortal(args);
    }
    else {
        /* $args = ref($_[0]) eq 'HASH' ? %{+shift} : @_ */
        args = newRV_inc((SV*)xscon_buildargs(sig, klassname, ax, items));
        sv_2mortal(args);

        /* $object = bless( {}, $klassname ); */
        object = xscon_create_instance(sig, klassname);
    }

    /* Initialize parameters: returns the number of keys in args that were actually used */
    int used = xscon_initialize_object(sig, klassname, object, (HV*)SvRV(args), FALSE);

    /* Call BUILD methods */
    xscon_buildall(sig, klassname, object, args);

    /* Strict constructor */
    if ( sig->strict_params ) {
        if ( used < HvUSEDKEYS((HV*)SvRV(args)) ) {
            xscon_strictcon(sig, klassname, object, args);
        }
    }

    /* return $object */
    ST(0) = object; /* because object is mortal, we should return it as is */
    XSRETURN(1);
}

void
BUILDALL(SV* object, SV* args)
CODE:
{
    dTHX;

    xscon_constructor_t *sig = (xscon_constructor_t *) CvXSUBANY(cv).any_ptr;
    if (sig->is_placeholder) xscon_constructor_get_metadata(NULL, sig);

    const char *klassname = NULL;
    HV *stash = SvSTASH(SvRV(object));
    if (!stash) croak("Not a blessed object?");
    klassname = HvNAME(stash);

    /* Call BUILD methods */
    xscon_buildall(sig, klassname, object, args);

    /* return $object */
    ST(0) = object; /* because object is mortal, we should return it as is */
    XSRETURN(1);
}

void
XSCON_CLEAR_CONSTRUCTOR_CACHE(SV* proto)
CODE:
{
    dTHX;

    xscon_constructor_t *sig = (xscon_constructor_t *) CvXSUBANY(cv).any_ptr;
    sig->is_placeholder = TRUE;

    /* return $proto */
    ST(0) = proto;
    XSRETURN(1);
}

void
destroy(SV* object, ...)
CODE:
{
    dTHX;
    xscon_destructor_t *sig = (xscon_destructor_t *) CvXSUBANY(cv).any_ptr;
    if (sig->is_placeholder) xscon_destructor_get_metadata(sig->package, sig);
    
    const char* klassname = SvROK(object) ? sv_reftype(SvRV(object), 1) : SvPV_nolen_const(object);
    AV* args = newAV();
    av_push( args, newSViv(PL_dirty) );
    xscon_demolishall(sig, klassname, object, FALSE, args);
    XSRETURN(0);
}

void
DEMOLISHALL(SV* object, ...)
CODE:
{
    dTHX;
    xscon_destructor_t *sig = (xscon_destructor_t *) CvXSUBANY(cv).any_ptr;
    if (sig->is_placeholder) xscon_destructor_get_metadata(sig->package, sig);
    
    const char* klassname = SvROK(object) ? sv_reftype(SvRV(object), 1) : SvPV_nolen_const(object);
    AV* args = newAV();
    for (I32 i = 1; i < items; i++) {
        av_push(args, newSVsv(ST(i)));
    }
    xscon_demolishall(sig, klassname, object, FALSE, args);
    XSRETURN(0);
}

void
XSCON_CLEAR_DESTRUCTOR_CACHE(SV* proto)
CODE:
{
    dTHX;

    xscon_destructor_t *sig = (xscon_destructor_t *) CvXSUBANY(cv).any_ptr;
    sig->is_placeholder = TRUE;

    /* return $proto */
    ST(0) = proto;
    XSRETURN(1);
}

void
reader(SV* object, ...)
CODE:
{
    dTHX;
    dSP;
    
    xscon_reader_t *sig = (xscon_reader_t *) CvXSUBANY(cv).any_ptr;
    
    HV *object_hv = (HV *)SvRV(object);
    STRLEN slotlen = strlen(sig->slot);
    
    if ( sig->has_default && !hv_exists(object_hv, sig->slot, slotlen) ) {
        SV* val = xscon_run_default(object, sig->slot, sig->default_flags, sig->default_sv);
        if ( sig->has_check && !xscon_check_type(sig->slot, newSVsv(val), sig->check_flags, sig->check_cv) ) {
            if ( sig->has_coercion ) {
                SV* newval;
                int count;
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 1);
                PUSHs(val);
                PUTBACK;
                count  = call_sv((SV *)sig->coercion_cv, G_SCALAR);
                SPAGAIN;
                SV* tmpval = POPs;
                newval = newSVsv(tmpval);
                FREETMPS;
                LEAVE;
                
                if ( xscon_check_type(sig->slot, newSVsv(newval), sig->check_flags, sig->check_cv) ) {
                    val = newSVsv(newval);
                }
                else {
                    croak("Coercion result '%s' failed type constraint for '%s'", SvPV_nolen(newval), sig->slot);
                }
            }
            else {
                croak("Value '%s' failed type constraint for '%s'", SvPV_nolen(val), sig->slot);
            }
        }
        (void)hv_store(object_hv, sig->slot, slotlen, val, 0);
    }
    
    SV** svp = hv_fetch(object_hv, sig->slot, slotlen, 0);
    SV* val = svp ? newSVsv(*svp) : &PL_sv_undef;

    if ( sig->should_clone && sig->cloner_cv == NULL ) {
        HV *hseen = newHV();
        SV *newval = sv_clone(aTHX_ val, hseen, -1);
        hv_clear(hseen);
        SvREFCNT_dec((SV *)hseen);
        ST(0) = newval;
    }
    else if ( sig->should_clone ) {
        SV* newval;
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 3);
        PUSHs(object);
        PUSHs(newSVpv(sig->slot, 0));
        PUSHs(val);
        PUTBACK;
        count = call_sv((SV *)sig->cloner_cv, G_SCALAR);
        SPAGAIN;
        SV* tmpval = POPs;
        newval = newSVsv(tmpval);
        FREETMPS;
        LEAVE;
        
        bool passed_this_time = TRUE;
        if ( sig->has_check ) {
            passed_this_time = xscon_check_type(sig->slot, newSVsv(newval), sig->check_flags, sig->check_cv);
        }
        
        if ( passed_this_time ) {
            ST(0) = newval;
        }
        else {
            croak("Cloning result '%s' failed type constraint for '%s'", SvPV_nolen(newval), sig->slot);
        }
    }
    else {
        ST(0) = val;
    }

    XSRETURN(1);
}

void
delegation(SV* object, ...)
CODE:
{
    dTHX;
    dSP;
    
    I32 gimme = GIMME_V;
    bool inc = FALSE;
    
    I32 nargs = items - 1;
    AV *args = newAV();
    for ( I32 i = 0; i < nargs; i++ ) {
        SV *arg = ST( i + 1 );
        av_push( args, arg );
    }
    
    xscon_delegation_t *sig = (xscon_delegation_t *) CvXSUBANY(cv).any_ptr;
    
    /* Get handler object */
    SV* handler;
    if ( sig->is_accessor ) {
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(object);
        PUTBACK;
        
        I32 count = call_method(sig->slot, G_SCALAR | G_EVAL);
        if (SvTRUE(ERRSV)) croak(NULL);
        
        SPAGAIN;
        handler = POPs;
        if ( handler != &PL_sv_undef ) {
            SvREFCNT_inc(handler);
            inc = TRUE;
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    else {
        HV *object_hv = (HV *)SvRV(object);
        STRLEN slotlen = strlen(sig->slot);
        SV** svp = hv_fetch(object_hv, sig->slot, slotlen, 0);
        handler = svp ? *svp : &PL_sv_undef;
        if ( handler != &PL_sv_undef ) {
            SvREFCNT_inc(handler);
            inc = TRUE;
        }
    }
    
    if ( !IsObject(handler) ) {
        if ( sig->is_try ) {
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
            return;
        }
        croak(
            "Expected blessed object to delegate to; got %s",
            ( handler == &PL_sv_undef ) ? "undef" : SvPV_nolen(handler)
        );
    }
    
    SP = MARK;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(handler);
    
    /* add curried arguments */
    if ( sig->has_curried ) {
        I32 n = av_len(sig->curried) + 1;
        for (I32 i = 0; i < n; i++) {
            SV **svp = av_fetch(sig->curried, i, 0);
            XPUSHs( svp ? *svp : &PL_sv_undef );
        }
    }
    
    /* forward all arguments except $object */
    for (I32 i = 0; i < nargs; i++) {
        SV **svp = av_fetch(args, i, 0);
        XPUSHs( svp ? *svp : &PL_sv_undef );
    }
    
    PUTBACK;
    
    I32 count = call_method(sig->method_name, gimme);
    LEAVE;
    
    if (inc) SvREFCNT_dec(handler);
    
    /* Do not SPAGAIN or POPs: return values left on stack! */
    XSRETURN(count);
}

void
install_constructor(char* name, char* name2, char* name3)
CODE:
{
    dTHX;
    CV *cv = newXS(name, XS_Class__XSConstructor_new_object, (char*)__FILE__);
    if (cv == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");

     CV *cv2 = newXS(name2, XS_Class__XSConstructor_BUILDALL, (char*)__FILE__);
     if (cv2 == NULL)
         croak("ARG! Something went really wrong while installing a new XSUB!");

     CV *cv3 = newXS(name3, XS_Class__XSConstructor_XSCON_CLEAR_CONSTRUCTOR_CACHE, (char*)__FILE__);
     if (cv3 == NULL)
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
    
    xscon_constructor_t *sig;
    Newxz(sig, 1, xscon_constructor_t);
    sig->package = savepv(pkg);
    sig->is_placeholder = TRUE;
    
    CvXSUBANY(cv).any_ptr = sig;
    CvXSUBANY(cv2).any_ptr = sig;
    CvXSUBANY(cv3).any_ptr = sig;
}

void
install_destructor(char* name, char* name2, char* name3)
CODE:
{
    dTHX;
    CV *cv = newXS(name, XS_Class__XSConstructor_destroy, (char*)__FILE__);
    if (cv == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");
    
    CV *cv2 = newXS(name2, XS_Class__XSConstructor_DEMOLISHALL, (char*)__FILE__);
    if (cv2 == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");
    
    CV *cv3 = newXS(name3, XS_Class__XSConstructor_XSCON_CLEAR_DESTRUCTOR_CACHE, (char*)__FILE__);
    if (cv3 == NULL)
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
    
    xscon_destructor_t *sig;
    Newxz(sig, 1, xscon_destructor_t);
    sig->package = savepv(pkg);
    sig->is_placeholder = TRUE;
    CvXSUBANY(cv).any_ptr = sig;
    CvXSUBANY(cv2).any_ptr = sig;
    CvXSUBANY(cv3).any_ptr = sig;
}

void
install_delegation(char *name, char *slot, char *method_name, SV *curried, bool is_accessor, bool is_try)
CODE:
{
    dTHX;
    CV *cv = newXS(name, XS_Class__XSConstructor_delegation, (char*)__FILE__);
    if (cv == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");
    
    xscon_delegation_t *sig;
    Newxz(sig, 1, xscon_delegation_t);
    sig->slot = savepv(slot);
    sig->is_try = is_try;
    sig->is_accessor = is_accessor;
    sig->method_name = savepv(method_name);
    
    if (!curried || !SvROK(curried) || SvTYPE(SvRV(curried)) != SVt_PVAV) {
        sig->has_curried = FALSE;
        sig->curried = NULL;
    }
    else {
        AV *curried_av = (AV *)SvRV(curried);
        sig->has_curried = TRUE;
        sig->curried = (AV *)SvREFCNT_inc((SV *)curried_av);
    }
    
    CvXSUBANY(cv).any_ptr = sig;
}

void
install_reader(char *name, char *slot, bool has_default, int default_flags, SV* default_sv, int check_flags, SV* check, SV* coercion, ...)
CODE:
{
    dTHX;
    CV *cv = newXS(name, XS_Class__XSConstructor_reader, (char*)__FILE__);
    if (cv == NULL)
        croak("ARG! Something went really wrong while installing a new XSUB!");

    xscon_reader_t *sig;
    Newxz(sig, 1, xscon_reader_t);
    sig->slot           = savepv(slot);
    sig->has_default    = has_default;
    sig->default_flags  = default_flags;
    sig->default_sv     = SvREFCNT_inc(default_sv);
    sig->check_flags    = check_flags;
    
    if (check && IsCodeRef(check)) {
        sig->has_check = TRUE;
        sig->check_cv = (CV *)SvREFCNT_inc(SvRV(check));
    }
    else {
        sig->has_check = FALSE;
        sig->check_cv = NULL;
    }
    
    if (coercion && IsCodeRef(coercion)) {
        sig->has_coercion = TRUE;
        sig->coercion_cv = (CV *)SvREFCNT_inc(SvRV(coercion));
    }
    else {
        sig->has_coercion = FALSE;
        sig->coercion_cv = NULL;
    }

    SV *cloner = &PL_sv_undef;
    if (items >= 9) {
        cloner = ST(8);
    }

    if (cloner && IsCodeRef(cloner)) {
        sig->should_clone = TRUE;
        sig->cloner_cv = (CV *)SvREFCNT_inc(SvRV(cloner));
    }
    else if (cloner && SvTRUE(cloner)) {
        sig->should_clone = TRUE;
        sig->cloner_cv = NULL;
    }
    else {
        sig->has_coercion = FALSE;
        sig->coercion_cv = NULL;
    }

    CvXSUBANY(cv).any_ptr = sig;
}

void
clone(self, depth=-1)
    SV *self
    int depth
    PREINIT:
    SV *clone = &PL_sv_undef;
    HV *hseen = newHV();
    PPCODE:
    TRACEME(("ref = 0x%x\n", self));
    clone = sv_clone(aTHX_ self, hseen, depth);
    hv_clear(hseen);  /* Free HV */
    SvREFCNT_dec((SV *)hseen);
    EXTEND(SP,1);
    PUSHs(sv_2mortal(clone));
