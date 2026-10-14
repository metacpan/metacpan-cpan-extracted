#ifndef CONTEXT_VARS_FAA_H
#define CONTEXT_VARS_FAA_H

/* async subs, under Future::AsyncAwait.
 *
 * An async sub that reaches `await` on a pending future suspends: it leaves
 * by an ordinary return, so its scope closes, and when the future is ready it
 * is resumed from a callback, in whatever context that callback runs in. Left
 * alone, everything it reads after the await comes from there, and every
 * assignment it makes lands there - in somebody else's context.
 *
 * So for each suspended sub this keeps a context of its own: what the sub
 * could see when it first suspended, and everything it assigns from then on.
 * That context is made current for each stretch the sub runs, and put back
 * when the stretch ends, by suspending again or by finishing.
 *
 * Future::AsyncAwait finds these through hooks it calls around every suspend
 * and resume. They are reached at run time, through keys it puts in
 * PL_modglobal, so this dist needs nothing from it to build and nothing from
 * it at all when it is not loaded. The one thing taken on trust is the
 * layout of its hook table, version 2 of its hook interface, which its header
 * marks experimental.
 *
 * Two things about how it treats the save stack shape the code:
 *
 *   - The restore is pushed BEFORE the sub's frames are rebuilt. Pushed
 *     after, it lands in whatever block the await is in, and closes at the
 *     end of that block.
 *   - At the next suspend Future::AsyncAwait lifts that entry off the save
 *     stack WITHOUT running it, and puts it back at the next resume. So the
 *     entry's data is a record that the suspend hook can close by hand, and
 *     that closing again does nothing. */

/* struct AsyncAwaitHookFuncs, from Future::AsyncAwait's AsyncAwait.h. */
struct context_vars_faa_hooks {
    U32 flags;
    void (*post_cv_copy)(pTHX_ CV *runcv, CV *cv, HV *modhookdata, void *hookdata);
    void (*pre_suspend) (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
    void (*post_suspend)(pTHX_ CV *cv, HV *modhookdata, void *hookdata);
    void (*pre_resume)  (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
    void (*post_resume) (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
    void (*free)        (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
};
#define CONTEXT_VARS_FAA_ABI 2

/* One suspended sub's context. It lives in Future::AsyncAwait's per-sub hash,
 * as the private data of magic on a plain scalar, so that it goes - and lets
 * go of its context - when that hash does. */
typedef struct {
    context_vars_ctx *ctx;      /* owned */
    context_vars_ctx *prev;     /* what to put back; borrowed */
    int               active;   /* ctx is current for this sub now */
    int               pushed;   /* a restore for it is on, or lifted off, the save stack */
} context_vars_susp;

#define CONTEXT_VARS_SUSP_KEY "Context::Vars/suspended"

static int context_vars_faa_registered = 0;

static int context_vars_susp_free(pTHX_ SV *sv, MAGIC *mg) {
    context_vars_susp *r = (context_vars_susp *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (r) {
        if (r->ctx) context_vars_release(aTHX_ r->ctx);
        Safefree(r);
        mg->mg_ptr = NULL;
    }
    return 0;
}

static MGVTBL context_vars_susp_vtbl = { 0, 0, 0, 0, context_vars_susp_free };

static context_vars_susp *context_vars_susp_of(SV *rsv) {
    MAGIC *mg;
    for (mg = SvMAGIC(rsv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &context_vars_susp_vtbl)
            return (context_vars_susp *)mg->mg_ptr;
    return NULL;
}

static SV *context_vars_susp_sv(pTHX_ HV *mhd) {
    SV **svp;
    if (!mhd) return NULL;
    svp = hv_fetchs(mhd, CONTEXT_VARS_SUSP_KEY, 0);
    return svp ? *svp : NULL;
}

/* The end of one stretch: put back what was current before it. Run by the
 * save stack, or by hand from the suspend hook when the entry was lifted. */
static void context_vars_susp_close(pTHX_ context_vars_susp *r) {
    if (r && r->active) {
        dMY_CXT;
        MY_CXT.cur = r->prev;
        r->active  = 0;
        MY_CXT.depth--;
    }
}

static void context_vars_susp_restore(pTHX_ void *p) {
    SV *rsv = (SV *)p;
    context_vars_susp *r = context_vars_susp_of(rsv);
    context_vars_susp_close(aTHX_ r);
    if (r) r->pushed = 0;
    SvREFCNT_dec(rsv);
}

static void context_vars_faa_pre_suspend(pTHX_ CV *cv, HV *mhd, void *hd) {
    dMY_CXT;
    context_vars_susp *r;
    SV *rsv;
    PERL_UNUSED_ARG(cv); PERL_UNUSED_ARG(hd);

    if (!mhd || context_vars_susp_sv(aTHX_ mhd)) return;

    /* The first suspend: keep what the sub can see now, as a context of its
     * own. Never the shared empty one, so that it can be assigned to. */
    Newxz(r, 1, context_vars_susp);
    r->ctx = context_vars_ctx_new(aTHX_
        (CONTEXT_VARS_HAMT->map_copy)(aTHX_ MY_CXT.cur->map));
    rsv = newSV(0);
    sv_magicext(rsv, NULL, PERL_MAGIC_ext, &context_vars_susp_vtbl, (const char *)r, 0);
    (void)hv_stores(mhd, CONTEXT_VARS_SUSP_KEY, rsv);
}

static void context_vars_faa_post_suspend(pTHX_ CV *cv, HV *mhd, void *hd) {
    SV *rsv = context_vars_susp_sv(aTHX_ mhd);
    PERL_UNUSED_ARG(cv); PERL_UNUSED_ARG(hd);
    if (rsv) context_vars_susp_close(aTHX_ context_vars_susp_of(rsv));
}

static void context_vars_faa_pre_resume(pTHX_ CV *cv, HV *mhd, void *hd) {
    dMY_CXT;
    SV *rsv = context_vars_susp_sv(aTHX_ mhd);
    context_vars_susp *r;
    PERL_UNUSED_ARG(cv); PERL_UNUSED_ARG(hd);

    if (!rsv || !(r = context_vars_susp_of(rsv))) return;
    if (!r->pushed) {
        SvREFCNT_inc_simple_void_NN(rsv);
        SAVEDESTRUCTOR_X(context_vars_susp_restore, (void *)rsv);
        r->pushed = 1;
    }
    r->prev    = MY_CXT.cur;
    MY_CXT.cur = r->ctx;
    r->active  = 1;
    MY_CXT.depth++;
}

static const struct context_vars_faa_hooks context_vars_faa_hookfuncs = {
    0,
    NULL,
    context_vars_faa_pre_suspend,
    context_vars_faa_post_suspend,
    context_vars_faa_pre_resume,
    NULL,
    NULL
};

/* Called once Future::AsyncAwait has loaded, at once if it already has. */
static void context_vars_faa_enable(pTHX_ void *data) {
    SV **min = hv_fetchs(PL_modglobal, "Future::AsyncAwait/ABIVERSION_MIN", 0);
    SV **max = hv_fetchs(PL_modglobal, "Future::AsyncAwait/ABIVERSION_MAX", 0);
    SV **reg = hv_fetchs(PL_modglobal, "Future::AsyncAwait/register()@2", 0);
    PERL_UNUSED_ARG(data);

    if (context_vars_faa_registered) return;
    if (!min || !max || !reg || SvIV(*min) > CONTEXT_VARS_FAA_ABI
        || SvIV(*max) < CONTEXT_VARS_FAA_ABI || !SvUV(*reg)) {
        warn("Context::Vars: this Future::AsyncAwait does not offer version %d of "
             "its hook interface, so an async sub will not keep its variables "
             "across await", CONTEXT_VARS_FAA_ABI);
        return;
    }
    {
        void (*registerf)(pTHX_ const struct context_vars_faa_hooks *, void *) =
            INT2PTR(void (*)(pTHX_ const struct context_vars_faa_hooks *, void *),
                    SvUV(*reg));
        (*registerf)(aTHX_ &context_vars_faa_hookfuncs, NULL);
        context_vars_faa_registered = 1;
    }
}

static void context_vars_faa_boot(pTHX) {
    SV **svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/loaded", 0);
    if (svp && SvOK(*svp)) {
        context_vars_faa_enable(aTHX_ NULL);
        return;
    }
    {
        AV *av;
        svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/on_loaded", 0);
        if (svp && SvROK(*svp) == 0 && SvTYPE(*svp) == SVt_PVAV)
            av = (AV *)*svp;
        else {
            av = newAV();
            (void)hv_stores(PL_modglobal, "Future::AsyncAwait/on_loaded", (SV *)av);
        }
        av_push(av, newSVuv(PTR2UV(context_vars_faa_enable)));
        av_push(av, newSVuv(PTR2UV((void *)NULL)));
    }
}

#endif
