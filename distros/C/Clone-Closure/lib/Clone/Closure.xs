#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newSV_type
#include "ppport.h"

/* stuff that should probably be in ppport.h, but isn't */

/* OK, so this is wrong, but it's what 5.6 did. */
#ifndef U_32
#define U_32(nv) ( (U32) I_32(nv) )
#endif

/* blead (5.9) stores these somewhere else, with access macros */
#ifndef COP_SEQ_RANGE_LOW
#define COP_SEQ_RANGE_LOW(sv)  (U_32(SvNVX(sv)))
#define COP_SEQ_RANGE_HIGH(sv) ((U32) SvIVX(sv))
#endif

#ifndef CvISXSUB
#define CvISXSUB(cv) CvXSUB(cv)
#endif

#ifndef CvWEAKOUTSIDE
#define CvWEAKOUTSIDE(cv) (0)
#endif

#ifndef CvCONST
#define CvCONST(cv) (0)
#endif

#ifndef AvREIFY_only
#define AvREIFY_only(av) (AvFLAGS(av) = AVf_REIFY)
#endif

#ifndef SvWEAKREF
#define SvWEAKREF(sv) (0)
#endif

#ifndef hv_iternext_flags
#define hv_iternext_flags(hv, fl) hv_iternext(hv)
#endif

#ifndef HV_ITERNEXT_WANTPLACEHOLDERS
#define HV_ITERNEXT_WANTPLACEHOLDERS 0
#endif

/* again, not correct but good enough for our purposes */
#ifndef sv_magicext
#define sv_magicext(sv, obj, how, vtbl, name, namelen) \
    sv_magic(sv, obj, how, name, namelen)
#endif

#ifndef isGV_with_GP
#define isGV_with_GP(sv) 1
#endif

#ifndef CvGV_set
#define CvGV_set(cv,gv) CvGV(cv) = (gv)
#endif

#ifndef CvSTASH_set
#define CvSTASH_set(cv,st) CvSTASH(cv) = (st)
#endif

#ifndef CVf_CVGV_RC
#define CVf_CVGV_RC 0
#endif

#if PERL_VERSION < 9 || (PERL_VERSION == 8 && PERL_SUBVERSION < 9)
#define SVt_LAST 16
#endif

static const char *svtypenames[SVt_LAST] = {
#if PERL_VERSION < 9
        "NULL",
        "IV",
        "NV",
        "RV",
        "PV",
        "PVIV",
        "PVNV",
        "MG",
        "BM",
        "LV",
        "AV",
        "HV",
        "CV",
        "GV",
        "FM",
        "IO"
#elif PERL_VERSION < 11
        "NULL",
        "BIND",
        "IV",
        "NV",
        "RV",
        "PV",
        "PVIV",
        "PVNV",
        "PVMG",
        "GV",
        "LV",
        "AV",
        "HV",
        "CV",
        "FM",
        "IO"
#else
        "NULL",
        "BIND",
        "IV",
        "NV",
        "PV",
        "PVIV",
        "PVNV",
        "MG",
        "REGEXP",
        "GV",
        "LV",
        "AV",
        "HV",
        "CV",
        "FM",
        "IO"
#endif
};

#ifdef DEBUG_CLONE
#define TRACEME(a) warn a;
#else
#define TRACEME(a)
#endif

#define TRACE_TYPE(type) TRACEME(("  %s\n", svtypenames[type]))

#define TRACE_SV(action, name, sv)                              \
    TRACEME(("%s (%s) = 0x%x(%d) [%x]%s%s%s%s%s\n", action, name, sv,    \
        SvREFCNT(sv), SvFLAGS(sv),                              \
        (SvPADMY(sv)   ? " PADMY"   : ""),                      \
        (SvPADTMP(sv)  ? " PADTMP"  : ""),                      \
        (SvTEMP(sv)    ? " TEMP"    : ""),                      \
        (SvFAKE(sv)    ? " FAKE"    : ""),                      \
        (SvMAGICAL(sv) ? " MAGIC"   : "")                       \
    ))

#define TRACE_SCOPE(cv) TRACEME(("scope 0x%x:%s\n", cv, \
    (cv && CvUNIQUE(cv)) ? " UNIQUE" : ""))

#define TRACE_MG(action, type, ptr, len, obj)       \
    TRACEME(("%s (%c magic) = 0x%x[%d], 0x%x\n",    \
        action, type, ptr, len, obj))

#define CLONE_KEY(x) ((char *) x) 

#define CLONE_STORE(x,y)						\
do {									\
    if (!hv_store(SEEN, CLONE_KEY(x), PTRSIZE, SvREFCNT_inc(y), 0)) {	\
        SvREFCNT_dec(y); /* Restore the refcount */                     \
	croak("Can't store clone in seen hash (HSEEN)");		\
    }									\
    else {	                                                        \
        TRACE_SV("ref", "SEEN", x);                                     \
        TRACE_SV("clone", "SEEN", y);                                   \
    }									\
} while (0)

#define CLONE_FETCH(x) (hv_fetch(SEEN, CLONE_KEY(x), PTRSIZE, 0))

static void hv_clone        (HV *SEEN, HV *ref, HV *clone);
static void av_clone        (HV *SEEN, AV *ref, AV *clone);
static SV  *sv_clone        (HV *SEEN, SV *ref);
static CV  *CC_cv_clone     (CV *ref);
static void pad_clone       (HV *SEEN, CV *ref, CV *clone);
static CV  *pad_findscope   (CV *start, SV *ref);

static void
hv_clone(HV *SEEN, HV *ref, HV *clone)
{
    HE *next = NULL;

    TRACE_SV("ref", "HV", ref);

    hv_iterinit(ref);
    while (next = hv_iternext_flags(ref, HV_ITERNEXT_WANTPLACEHOLDERS)) {
        SV *key = hv_iterkeysv(next);
        SV *val = hv_iterval(ref, next);
        SV *cln;
        HE *elm;

        SvGETMAGIC(val);
        TRACE_SV("ref", "HV elem", val);

        cln = sv_clone(SEEN, val);

        elm = hv_store_ent(clone, key, cln, 0);
        SvSETMAGIC(cln);

        if (elm) {
            TRACE_SV("clone", "HV elem", HeVAL(elm));
        }
        else {
            TRACE_SV("drop", "HV elem", cln);
            SvREFCNT_dec(cln);
        }
    }

    TRACE_SV("clone", "HV", clone);
}

static void
av_clone(HV *SEEN, AV *ref, AV *clone)
{
    I32 arrlen = 0;
    int i = 0;

    TRACE_SV("ref", "AV", ref);

    if (SvREFCNT(ref) > 1)
        CLONE_STORE(ref, (SV *)clone);

    arrlen = av_len(ref);
    av_extend(clone, arrlen);

    for (i = 0; i <= arrlen; i++) {
        SV **val = av_fetch(ref, i, 0);

        if (val) {
            SV *cln, **elm;

            SvGETMAGIC(*val);
            TRACE_SV("ref", "AV elem", *val);

            cln = sv_clone(SEEN, *val);

            elm = av_store(clone, i, cln);
            SvSETMAGIC(cln);

            if (elm) {
                TRACE_SV("clone", "AV elem", *elm);
            }
            else {
                TRACE_SV("drop", "AV elem", cln);
                SvREFCNT_dec(cln);
            }
        }
    }

    TRACE_SV("clone", "AV", clone);
}

/* largely taken from pad.c:cv_clone (in op.c in 5.6) */
static CV *
CC_cv_clone(CV *ref)
{
    AV *const rpadlist = CvPADLIST(ref);
    AV *const rname    = (AV *)*av_fetch(rpadlist, 0, FALSE);
    U32       rdepth   = CvDEPTH(ref) ? CvDEPTH(ref) : 1;
    AV *const rpad     = (AV *)*av_fetch(rpadlist, rdepth, FALSE);
    const I32 fname    = AvFILLp(rname);
    const I32 fpad     = AvFILLp(rpad);
    SV **     prname   = AvARRAY(rname);
    AV *      cpadlist;
    AV *      cname;
    AV *      cpad;
    AV *      a0;
    CV       *clone, *outside;
    I32       ix;

    TRACE_SV("ref", "CV", ref);

    /* CvCONST is only set if the sub is actually constant */
    if (CvCONST(ref)) {
        SvREFCNT_inc(ref);
        TRACE_SV("copy", "CV", ref);
        return ref;
    }

    /* BEGIN, eval &c. */
    assert(!CvUNIQUE(ref));
#if PERL_VERSION > 9
    /* closure prototype */
    assert(!CvCLONE(ref));
#endif
    /* named sub */
    assert(CvANON(ref));
    /* an instantiated closure shouldn't be WEAKOUTSIDE */
    assert(!(!CvCLONE(ref) && CvWEAKOUTSIDE(ref)));

    outside = CvOUTSIDE(ref);
    assert(CvPADLIST(outside));
    /* we should be cloning an instantiated closure, so CvOUTSIDE
     * shouldn't be a closure prototype */
    assert(!(outside && CvCLONE(outside)));

    clone = (CV *)newSV_type(SvTYPE(ref));
    CvFLAGS(clone) = CvFLAGS(ref) & ~CVf_CVGV_RC;

#ifdef USE_ITHREADS
    CvFILE(clone)           = CvISXSUB(ref) ? CvFILE(ref)
                                            : savepv(CvFILE(ref));
#else
    CvFILE(clone)           = CvFILE(ref);
#endif
    CvGV_set(clone,         CvGV(ref));
    CvSTASH_set(clone,      CvSTASH(ref));

    OP_REFCNT_LOCK;
    CvROOT(clone)           = OpREFCNT_inc(CvROOT(ref));
    OP_REFCNT_UNLOCK;

    CvSTART(clone)          = CvSTART(ref);

    CvOUTSIDE(clone)        = outside;
    if (!CvWEAKOUTSIDE(clone)) SvREFCNT_inc(outside);
#ifdef CvOUTSIDE_SEQ
    CvOUTSIDE_SEQ(clone)    = CvOUTSIDE_SEQ(ref);
#endif

    if (SvPOK(ref))
        sv_setpvn((SV *)clone, SvPVX_const(ref), SvCUR(ref));

    /* create a new padlist, and initial pad */

    cname = newAV();
    av_fill(cname, fname);

    /* fill in the names of the lexicals */
    for (ix = fname; ix >= 0; ix--) {
        av_store(cname, ix, SvREFCNT_inc(prname[ix]));
    }

    cpad = newAV();
    av_fill(cpad,  fpad);

    /* create @_ */
    a0 = newAV();
    av_extend(a0, 0);
    av_store(cpad, 0, (SV *)a0);
    AvREIFY_only(a0);

    /* the pad is filled in later, by pad_clone */

    cpadlist = newAV();
    AvREAL_off(cpadlist);
    av_store(cpadlist, 0, (SV *)cname);
    av_store(cpadlist, 1, (SV *)cpad);

    CvPADLIST(clone) = cpadlist;

    TRACE_SV("clone", "CV", clone);

    return clone;
}

/* mostly stolen from PadWalker */

static void
pad_clone(HV *SEEN, CV *ref, CV *clone)
{
    U32 vdepth = CvDEPTH(clone) ? CvDEPTH(clone) : 1;
    U32 rdepth = CvDEPTH(ref)   ? CvDEPTH(ref)   : 1;
    AV *padn   = (AV *) *av_fetch(CvPADLIST(clone), 0,      FALSE);
    AV *padv   = (AV *) *av_fetch(CvPADLIST(clone), vdepth, FALSE);
    AV *padr   = (AV *) *av_fetch(CvPADLIST(ref),   rdepth, FALSE);
    I32 i;

    TRACE_SV("ref", "pad", ref);

    for (i = av_len(padn); i >= 0; --i) {
        SV  **name_p, *name_sv, **val_p, *val_sv;
        SV  **old_p, *old_sv, *new_sv;
        const char *name;
        bool  can_copy;
        bool  is_proto;

        name_p  = av_fetch(padn, i, 0);
        name_sv = name_p ? *name_p : &PL_sv_undef;
        name    = (name_p && SvPOKp(name_sv))
                        ? SvPVX_const(name_sv)
                        : "???";

        val_p    = av_fetch(padr, i, 0);
        val_sv   = val_p ? *val_p : &PL_sv_undef;

        is_proto = 0;

        /* The following types of entries exist in pads... */

        /* @_ must be cloned */
        if (i == 0) {
            name = "@_";
            can_copy = 0;
        }

        /* 'our' entries have everything in the name, and need no pad
         * entry */
        else if (SvFLAGS(name_sv) & SVpad_OUR) {
            can_copy = 1;
        }

        /* PADTMP entries are targs/GVs/constants, and need copying.
         * PADGV/CONST are used by ithreads */
        else if (
            SvPADTMP(val_sv) || 
            IS_PADGV(val_sv) ||
            IS_PADCONST(val_sv)
        ) {
            name = "PADTMP";
            can_copy = 1;
        }

        /* entries with names are lexicals */
        else if (name_sv != &PL_sv_undef) {

            /* closure prototypes must be copied */
            if (*name == '&') {
#if PERL_VERSION < 9
                if (!SvFAKE(name_sv)) {
                    can_copy = 0;
                    is_proto = 1;
                }
                else
#endif
                can_copy = 1;
            }

            /* non-closures must clone all lexicals */
            else if (!CvCLONED(clone)) {
                can_copy = 0;
            }

            /* lexicals declared in this sub must be cloned */
            else if (!SvFAKE(name_sv)) {
                can_copy = 0;
            }

            /* closed-over lexicals need checking */
            else {
                CV *scope;

                /* start with the scope that declared the lexical... */
                scope = pad_findscope(clone, name_sv);

                /* even if this scope is unique, it may be inside one
                 * which isn't:
                 *     sub foo { eval q/my $x; sub { $x; }/; }
                 * eval STRING is always CvUNIQUE */
                while (scope && CvUNIQUE(scope)) {
                    scope = CvOUTSIDE(scope);
                    TRACE_SCOPE(scope);
                }

                /* XXX handle locating loops: see cop@269 */

                /* if this lexical was defined in a scope that can only
                 * run once it can be copied, otherwise it must be
                 * cloned */
                can_copy = (!scope || CvUNIQUE(scope));
            }
        }

        /* just in case :) */
        else {
            warn("Clone::Closure: unknown pad entry: please report a bug!");
#ifdef DEBUG_CLONE
            warn("name:\n");
            sv_dump(name_sv);
            warn("val:\n");
            sv_dump(val_sv);
#endif
            continue;
        }

        TRACE_SV("ref", name, val_sv);

        if (is_proto) {
            assert(PERL_VERSION < 9);
#ifdef CvWEAKOUTSIDE_on
            assert(CvWEAKOUTSIDE(val_sv));
#endif

            new_sv = (SV *)CC_cv_clone((CV *)val_sv);

            CvCLONE_on(new_sv);
            SvPADMY_on(new_sv);

#ifndef CvWEAKOUTSIDE_on
            {
                CV *old = CvOUTSIDE(new_sv);
                SvREFCNT_dec(old);
                TRACE_SV("ref", "outside", old);
            }
#endif
            CvOUTSIDE(new_sv) = clone;
#ifdef CvWEAKOUTSIDE_on
            TRACE_SV("weaken", name, new_sv);
            TRACE_SV("outside", name, clone);
            CvWEAKOUTSIDE_on(new_sv);
#else
            SvREFCNT_inc(clone);
            TRACE_SV("clone", "outside", clone);
#endif

            pad_clone(SEEN, (CV *)val_sv, (CV *)new_sv);
        }
        else if (can_copy) {
            new_sv = SvREFCNT_inc(val_sv);
            CLONE_STORE(val_sv, new_sv);
        }
        else {
            new_sv = sv_clone(SEEN, val_sv);
        }
         
        TRACE_SV("ref, again", name, val_sv);
        TRACE_SV(can_copy ? "copy" : "clone", name, new_sv);

        old_p    = av_fetch(padv, i, 0);
        old_sv   = old_p ? *old_p : &PL_sv_undef;

        /* can't use av_store as the refcounts get wrong:
         * pads are AvREAL even though they shouldn't be */
        (AvARRAY(padv))[i] = new_sv;

        /* XXX I don't like this: sometimes the refcnt gets too low */
        if ( SvREFCNT(old_sv) > 1 ) {
            SvREFCNT_dec(old_sv);
            TRACE_SV("drop", name, old_sv);
        }
        else
            TRACE_SV("NO DROP", name, old_sv);
    }

    TRACE_SV("clone", "pad", clone);
}

/* locate the scope in which a lexical was declared */
/* mostly stolen from pad.c:pad_findlex */

static CV *
pad_findscope(CV *scope, SV *name_sv)
{
    const char  *name = SvPVX_const(name_sv);
    U32          seq;
    CV          *last_fake = scope;

#ifdef CvOUTSIDE_SEQ
#define MOVE_OUT(scp, sq) sq = CvOUTSIDE_SEQ(scp), scp = CvOUTSIDE(scp)
#else
    seq = SvIVX(name_sv);
#define MOVE_OUT(scp, sq) scp = CvOUTSIDE(scp)
#endif

    TRACE_SCOPE(scope);

    for ( MOVE_OUT(scope, seq); scope; MOVE_OUT(scope, seq) ) {
        SV **svp, *sv;
        AV  *padlist, *padn;
        I32  off;

        TRACE_SCOPE(scope);

        padlist = CvPADLIST(scope);
        if (!padlist) /* an undef CV */
            continue;

        svp = av_fetch(padlist, 0, FALSE);
        if (!svp || *svp == &PL_sv_undef)
            continue;

        padn = (AV *)*svp;
        svp  = AvARRAY(padn);

        for (off = AvFILLp(padn); off > 0; off--) {

            sv = svp[off];
            if (
                !sv || sv == &PL_sv_undef
                || !strEQ(SvPVX_const(sv), name)
            ) {
                continue;
            }

            if (SvFAKE(sv)) {
                last_fake = scope;
                continue;
            }
        
            if (
                seq > COP_SEQ_RANGE_LOW(sv)
                && seq <= COP_SEQ_RANGE_HIGH(sv)
            )
            {
                return scope;
            }
            else {
                TRACEME(("found %s but %x not in [%x, %x]\n",
                    name, seq, COP_SEQ_RANGE_LOW(sv),
                    COP_SEQ_RANGE_HIGH(sv)));
            }
        }
    }

    TRACEME(("no scope found; returning last_fake = 0x%x\n",
        last_fake));
    return last_fake;
}

static SV *
sv_clone(HV *SEEN, SV *ref)
{
    dTHX;
    SV *clone = ref;
    SV **seen = NULL;
    int recurse = 1;

    TRACE_SV("ref", "SV", ref);

    if (SvIMMORTAL(ref)) {
        TRACE_SV("immortal", "SV", ref);
        return ref;
    }

    if ( seen = CLONE_FETCH(ref) ) {
        SvREFCNT_inc(*seen);
        TRACE_SV("fetch", "SV", *seen);
        return *seen;
    }

    TRACEME(("switch: (0x%x)\n", ref));
    switch (SvTYPE (ref)) {

        case SVt_NULL:
#if PERL_VERSION < 11
        case SVt_IV:
#endif
        case SVt_NV:
        case SVt_PV:
        case SVt_PVIV:
        case SVt_PVNV:
        case SVt_PVMG:
#if PERL_VERSION > 10
        case SVt_REGEXP:
#endif
        case SVt_PVLV:
        simple_clone:
            TRACE_TYPE(SvTYPE(ref))
            clone = newSVsv(ref);
            break;

        case SVt_PVFM:
        case SVt_PVIO:
        simple_copy:
            TRACE_TYPE(SvTYPE(ref))
            clone = SvREFCNT_inc(ref);  /* just return the ref */
            break;

        case SVt_RV:
            if (SvROK(ref)) {
                TRACEME(("  ROK (%s)\n", svtypenames[SvTYPE(ref)]));
                clone = NEWSV(1002, 0);
                sv_upgrade(clone, SVt_RV);
                break;
            }
            goto simple_clone;

        case SVt_PVAV:
            TRACE_TYPE(SVt_PVAV);
            clone = (SV *)newAV();
            break;

        case SVt_PVHV:
            TRACE_TYPE(SVt_PVHV);
            clone = (SV *)newHV();
            break;

        case SVt_PVCV:	/* 12 */
            {
                CV *cv = (CV *)ref;
                /* we shouldn't be cloning a closure prototype */
                /* (when nec. pad_clone calls CC_cv_clone directly) */
                assert(!CvCLONE(cv));

                if (CvCLONED(cv)) {
                    /* closures are cloned */
                    TRACEME(("  CV (closure)\n"));
                    clone = (SV *)CC_cv_clone(cv);
                }
                else {
                    /* named subs aren't cloned */
                    TRACEME(("  CV\n"));
                    clone = SvREFCNT_inc(ref);
                }
                break;
            }

        case SVt_PVGV:
            if (isGV_with_GP(ref))
                goto simple_copy;
            /* fall through */

#if PERL_VERSION < 9
        case SVt_PVBM:
#endif
            TRACEME(("  PVBM\n"));
            clone = newSVsv(ref);
            fbm_compile(clone, SvTAIL(ref) ? FBMcf_TAIL : 0);
            break;
    
        default:
            croak("unknown type of scalar: 0x%x", SvTYPE(ref));
    }

    /**
    * It is *vital* that this is performed *before* recursion,
    * to properly handle circular references. cb 2001-02-06
    */

    CLONE_STORE(ref,clone);

    if (SvMAGICAL(ref) && clone != ref) {
        MAGIC*  mg;
        int     shared = 0;

        for (mg = SvMAGIC(ref); mg; mg = mg->mg_moremagic) {
            SV      *obj = mg->mg_obj;
            char    *ptr = mg->mg_ptr;
            int     keepmg = 1, copymg = 0;

            TRACE_MG("ref", mg->mg_type, ptr, mg->mg_len, obj);

            switch (mg->mg_type) {
                case PERL_MAGIC_qr:
#if PERL_VERSION < 11
                /* 'r' magic with a SvPVX is for storing (??{})
                 * patterns. 'r' magic without is for qr//.
                 */
                if (SvPVX(ref) == NULL) {
                    regexp *const re = (regexp *)mg->mg_obj;
                    obj = (SV *)ReREFCNT_inc(re); 
                    break;
                }
#endif
                keepmg = 0;
                break;

                case PERL_MAGIC_utf8:
                {
                    void *tmp;

#ifdef PERL_MAGIC_UTF8_CACHESIZE
                    if (mg->mg_ptr) {
                        Newxz(tmp, PERL_MAGIC_UTF8_CACHESIZE * 2, STRLEN);
                        ptr = (char *)tmp;
                        Copy(
                            mg->mg_ptr, ptr,
                            PERL_MAGIC_UTF8_CACHESIZE * 2, STRLEN
                        );
                    }
#else
                    croak("can't handle 'w' magic under this version of perl");
#endif
                    break;
                }

                case PERL_MAGIC_tiedelem:
                    keepmg = 0;
                    shared = -1;
                    break;

#define SvSHRTIE(sv, mg) \
    sv_isa( SvTIED_obj(sv, mg), "threads::shared::tie" )

                case PERL_MAGIC_tied:
                    /* PL_vtbl_pack is normal tie magic */
                    if (mg->mg_virtual == &PL_vtbl_pack) {
                        recurse = 0;
                        copymg  = 1;
                    }
                    else {
                        if (SvSHRTIE(ref, mg)) {
                            shared  = 1;
                            keepmg  = 0;
                        }
                        else {
                            croak("tie magic with unknown vtable");
                        }
                    }
                    break;

                case PERL_MAGIC_tiedscalar:
                case PERL_MAGIC_taint:
                case PERL_MAGIC_uvar:
                case PERL_MAGIC_uvar_elem:
                case PERL_MAGIC_vstring:
                case PERL_MAGIC_glob:
                case PERL_MAGIC_ext:
                    copymg = 1;
                    break;

                case PERL_MAGIC_shared:
                    croak("don't know how to handle 'N' magic!");

                case PERL_MAGIC_shared_scalar:
                    if (!shared) shared = 1;
                    keepmg = 0;
                    break;

                /* bm & backref magics are handled separately */
                default:
                    keepmg = 0;
                    break;
            }

            if (copymg)
                obj = obj ? sv_clone(SEEN, mg->mg_obj) : NULL;

            if (keepmg) {
                TRACE_MG("clone", mg->mg_type, ptr, mg->mg_len, obj);
                sv_magicext(
                    clone, 
                    obj,
                    mg->mg_type, 
                    mg->mg_virtual,
                    ptr, 
                    mg->mg_len
                );
            }
            else {
                TRACE_MG("drop", mg->mg_type, mg->mg_ptr, mg->mg_len,
                mg->mg_obj);
            }
        }

        if (shared > 0) {
#ifdef SvSHARE
            TRACE_SV("share", "SV", clone);
            SvSHARE(clone);
#else
            croak("can't share values in this version of perl");
#endif
        }
    }

    if (!recurse) {
        TRACE_SV("skip", "SV", clone);
    }
    else if ( SvTYPE(ref) == SVt_PVHV ) {
        hv_clone(SEEN, (HV *)ref, (HV *)clone);
    }
    else if ( SvTYPE(ref) == SVt_PVAV ) {
        av_clone(SEEN, (AV *)ref, (AV *)clone);
    }
    else if ( SvTYPE(ref) == SVt_PVCV ) {
        if (CvCLONED((CV *)ref)) {
            pad_clone(SEEN, (CV *)ref, (CV *)clone);
        }
    }
    /* 3: REFERENCE (inlined for speed) */
    else if (SvROK(ref)) {
        TRACE_SV("ref", "RV", ref);

        SvROK_on(clone);
        SvRV(clone) = sv_clone(SEEN, SvRV(ref));

        if (sv_isobject(ref)) {
            sv_bless(clone, SvSTASH(SvRV(ref)));
        }

        if (SvWEAKREF(ref)) {
            TRACE_SV("weaken", "RV", clone);
            sv_rvweaken(clone);
        }

        TRACE_SV("clone", "RV", clone);
    }

    if (SvREADONLY(ref))
        SvREADONLY_on(clone);

    TRACE_SV("clone", "SV", clone);
    return clone;
}

MODULE = Clone::Closure		PACKAGE = Clone::Closure

PROTOTYPES: ENABLE

void
_breakpoint()
    PPCODE:
        XSRETURN_UNDEF;

void
clone(ref)
	SV *ref
    PREINIT:
	SV *clone;
        HV *SEEN;
    PPCODE:
        SEEN = newHV();

        TRACE_SV("ref", "clone", ref);
	clone = sv_clone(SEEN, ref);
        TRACE_SV("clone", "clone", clone);

        SvREFCNT_dec(SEEN);

	EXTEND(SP,1);
	PUSHs(sv_2mortal(clone));
