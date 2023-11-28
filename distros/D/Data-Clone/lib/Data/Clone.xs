#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS /* for exceptions */
#include "xshelper.h"

#include "data_clone.h"

#ifndef SvRXOK
#define SvRXOK(sv) (SvROK(sv) && SvMAGICAL(SvRV(sv)) && mg_find(SvRV(sv), PERL_MAGIC_qr))
#endif

#define REINTERPRET_CAST(T, value) ((T)value)

#define PTR2STR(ptr) REINTERPRET_CAST(const char*, (&ptr))

#define MY_CXT_KEY "Data::Clone::_guts" XS_VERSION
typedef struct {
    U32 depth;
    HV* seen;
    CV* caller_cv;
    GV* my_clone;
    GV* object_callback;

    SV* clone_method;    /* "clone" */
    SV* tieclone_method; /* "TIECLONE" */
} my_cxt_t;
START_MY_CXT

static SV*
clone_rv(pTHX_ pMY_CXT_ SV* const cloning);

static SV*
clone_sv(pTHX_ pMY_CXT_ SV* const cloning) {
    assert(cloning);

    SvGETMAGIC(cloning);

    if(SvROK(cloning)){
        return clone_rv(aTHX_ aMY_CXT_ cloning);
    }
    else{
        SV* const cloned = newSV(0);
        /* no need to set SV_GMAGIC */
        sv_setsv_flags(cloned, cloning, SV_NOSTEAL);
        return cloned;
    }
}

static void
clone_hv_to(pTHX_ pMY_CXT_ HV* const cloning, HV* const cloned) {
    HE* iter;

    assert(cloning);
    assert(cloned);

    hv_iterinit(cloning);
    while((iter = hv_iternext(cloning))){
        SV* const key = hv_iterkeysv(iter);
        SV* const val = clone_sv(aTHX_ aMY_CXT_ hv_iterval(cloning, iter));
        (void)hv_store_ent(cloned, key, val, 0U);
    }
}

static void
clone_av_to(pTHX_ pMY_CXT_ AV* const cloning, AV* const cloned) {
    I32 last, i;

    assert(cloning);
    assert(cloned);

    last = av_len(cloning);
    av_extend(cloned, last);

    for(i = 0; i <= last; i++){
        SV** const svp = av_fetch(cloning, i, FALSE);
        if(svp){
            (void)av_store(cloned, i, clone_sv(aTHX_ aMY_CXT_ *svp));
        }
    }
}


static GV*
find_method_sv(pTHX_ HV* const stash, SV* const name) {
    HE* const he = hv_fetch_ent(stash, name, FALSE, 0U);

    if(he && isGV(HeVAL(he)) && GvCV((GV*)HeVAL(he))){ /* shortcut */
        return (GV*)HeVAL(he);
    }

    assert(SvPOKp(name));
    return gv_fetchmeth_autoload(stash, SvPVX(name), SvCUR(name), 0);
}

static int
sv_has_backrefs(pTHX_ SV* const sv) {
    if(SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_backref)) {
        return TRUE;
    }
#ifdef HvAUX
    else if(SvTYPE(sv) == SVt_PVHV){
        return SvOOK(sv) && HvAUX((HV*)sv)->xhv_backreferences != NULL;
    }
#endif
    return FALSE;
}

/* my_dopoptosub_at() and caller_cv() are stolen from pp_ctl.c */
static I32
my_dopoptosub_at(pTHX_ const PERL_CONTEXT* const cxstk, I32 const startingblock) {
    I32 i;

    assert(cxstk);

    for (i = startingblock; i >= 0; i--) {
        const PERL_CONTEXT* const cx = &cxstk[i];
        if(CxTYPE(cx) == CXt_SUB){
            break;
        }
    }
    return i;
}

static CV*
caller_cv(pTHX) {
    const PERL_CONTEXT* cx;
    const PERL_CONTEXT* ccstack = cxstack;
    const PERL_SI *si           = PL_curstackinfo;
    I32 cxix                    = my_dopoptosub_at(aTHX_ ccstack, cxstack_ix);
    I32 count                   = 0;

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && si->si_type != PERLSI_MAIN) {
            si      = si->si_prev;
            ccstack = si->si_cxstack;
            cxix = my_dopoptosub_at(aTHX_ ccstack, si->si_cxix);
        }
        if (cxix < 0) {
            return NULL;
        }
        /* skip &DB::sub */
        if (PL_DBsub && GvCV(PL_DBsub) &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;

        cxix = my_dopoptosub_at(aTHX_ ccstack, cxix - 1);
    }

    cx = &ccstack[cxix];
    return cx->blk_sub.cv;
}

static void
store_to_seen(pTHX_ pMY_CXT_ SV* const sv, SV* const proto) {
    (void)hv_store(MY_CXT.seen, PTR2STR(sv), sizeof(sv), proto, 0U);
    SvREFCNT_inc_simple_void_NN(proto);
}

static SV*
dc_call_sv1(pTHX_ SV* const proc, SV* const arg1) {
    dSP;
    SV* ret;

    assert(proc);
    assert(arg1);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(arg1);
    PUTBACK;

    call_sv(proc, G_SCALAR);

    SPAGAIN;
    ret = POPs;
    PUTBACK;

    SvREFCNT_inc_simple_void_NN(ret);

    FREETMPS;
    LEAVE;

    return sv_2mortal(ret);
}

static int
dc_need_to_call(pTHX_ pMY_CXT_ const CV* const method) {
    //warn("dc_need_co_call 0x%p 0x%p 0x%p", method, GvCV(MY_CXT.my_clone), MY_CXT.caller_cv);

    return method != GvCV(MY_CXT.my_clone) && method != MY_CXT.caller_cv;
}


static SV*
dc_clone_object(pTHX_ pMY_CXT_ SV* const cloning, SV* const method_sv) {
    SV* const sv     = SvRV(cloning);
    GV* const method = find_method_sv(aTHX_ SvSTASH(sv), method_sv);

    if(!method){ /* not a clonable object */
        SV* const object_callback = GvSVn(MY_CXT.object_callback);
        /* try to $Data::Clone::ObjectCallback->($cloning) */

        SvGETMAGIC(object_callback);

        if(SvOK(object_callback)){
            SV* const x = dc_call_sv1(aTHX_ object_callback, cloning);

            if(!SvROK(x)){
                croak("ObjectCallback function returned %s, but it must return a reference",
                    SvOK(x) ? SvPV_nolen_const(x) : "undef");
            }

            return x;
        }

        return sv_mortalcopy(cloning);
        croak("Non-clonable object %"SVf" found (missing a %"SVf" method)",
            cloning, method_sv);
    }

    /* has its own clone method */
    if(dc_need_to_call(aTHX_ aMY_CXT_ GvCV(method))){
        SV* const x = dc_call_sv1(aTHX_ (SV*)GvCV(method), cloning);

        if(!SvROK(x)){
            croak("Cloning method '%"SVf"' returned %s, but it must return a reference",
                method_sv, SvOK(x) ? SvPV_nolen_const(x) : "undef");
        }

        return x;
    }
    else { /* default clone() behavior: deep copy */
        return NULL;
    }
}


static SV*
clone_rv(pTHX_ pMY_CXT_ SV* const cloning) {
    int may_be_circular;
    SV*  sv;
    SV*  proto;
    SV*  cloned;
    MAGIC* mg;
    //CV* old_cv;

    assert(cloning);
    assert(SvROK(cloning));

    sv = SvRV(cloning);
    may_be_circular = (SvREFCNT(sv) > 1 || sv_has_backrefs(aTHX_ sv) );

    if(may_be_circular){
        SV** const svp = hv_fetch(MY_CXT.seen, PTR2STR(sv), sizeof(sv), FALSE);
        if(svp){
            proto = *svp;
            goto finish;
        }
    }

    if(SvOBJECT(sv) && !SvRXOK(cloning)){
        proto = dc_clone_object(aTHX_ aMY_CXT_ cloning, MY_CXT.clone_method);

        if(proto){
            proto = SvRV(proto);
            goto finish;
        }

        /* fall through to make a deep copy */
    }
    else if((mg = SvTIED_mg(sv, PERL_MAGIC_tied))){
        assert(SvTYPE(sv) == SVt_PVAV || SvTYPE(sv) == SVt_PVHV);
        proto = dc_clone_object(aTHX_ aMY_CXT_ SvTIED_obj(sv, mg), MY_CXT.tieclone_method);

        if(proto){
            SV* const varsv = (SvTYPE(sv) == SVt_PVHV
                ? (SV*)newHV()
                : (SV*)newAV()); // can we use newSV_type()?
            sv_magic(varsv,  proto, PERL_MAGIC_tied, NULL, 0);
            proto = varsv;
            goto finish;
        }

        /* fall through to make a deep copy */
    }

    /* XXX: need to save caller_cv, or not? */
    //old_cv           = MY_CXT.caller_cv;
    MY_CXT.caller_cv = NULL;

    if(SvTYPE(sv) == SVt_PVAV){
        proto = sv_2mortal((SV*)newAV());
        if(may_be_circular){
            store_to_seen(aTHX_ aMY_CXT_ sv, proto);
        }
        clone_av_to(aTHX_ aMY_CXT_ (AV*)sv, (AV*)proto);
    }
    else if(SvTYPE(sv) == SVt_PVHV){
        proto = sv_2mortal((SV*)newHV());
        if(may_be_circular){
            store_to_seen(aTHX_ aMY_CXT_ sv, proto);
        }
        clone_hv_to(aTHX_ aMY_CXT_ (HV*)sv, (HV*)proto);
    }
    else {
        proto = sv; /* do nothing */
    }

    //MY_CXT.caller_cv = old_cv;

    finish:
    cloned = newRV_inc(proto);

    if(SvOBJECT(sv)){
        sv_bless(cloned, SvSTASH(sv));
    }

    return SvWEAKREF(cloning) ? sv_rvweaken(cloned) : cloned;
}

/* as SV* sv_clone(SV* sv) */
SV*
Data_Clone_sv_clone(pTHX_ SV* const sv) {
    SV* VOL retval = NULL;
    CV* VOL old_cv;
    dMY_CXT;
    dXCPT;

    if(++MY_CXT.depth == U32_MAX){
        croak("Depth overflow on clone()");
    }

    old_cv = MY_CXT.caller_cv;
    MY_CXT.caller_cv = caller_cv(aTHX);

    XCPT_TRY_START {
        retval = sv_2mortal(clone_sv(aTHX_ aMY_CXT_ sv));
    } XCPT_TRY_END

    MY_CXT.caller_cv = old_cv;

    if(--MY_CXT.depth == 0){
        hv_undef(MY_CXT.seen);
    }

    XCPT_CATCH {
        XCPT_RETHROW;
    }
    return retval;
}

static void
my_cxt_initialize(pTHX_ pMY_CXT) {
    MY_CXT.depth    = 0;
    MY_CXT.seen     = newHV();
    MY_CXT.my_clone = CvGV(get_cvs("Data::Clone::clone", GV_ADD));

    MY_CXT.object_callback = gv_fetchpvs("Data::Clone::ObjectCallback", GV_ADDMULTI, SVt_PV);

    MY_CXT.clone_method    = newSVpvs_share("clone");
    MY_CXT.tieclone_method = newSVpvs_share("TIECLONE");
}

MODULE = Data::Clone        PACKAGE = Data::Clone

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    my_cxt_initialize(aTHX_ aMY_CXT);
}

#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    my_cxt_initialize(aTHX_ aMY_CXT);
    PERL_UNUSED_VAR(items);
}

#endif

void
clone(SV* sv)
CODE:
{
    sv = sv_clone(sv);
    ST(0) = sv;
    XSRETURN(1);
}

bool
is_cloning()
CODE:
{
    dMY_CXT;
    RETVAL = (MY_CXT.depth != 0);
}
OUTPUT:
    RETVAL
