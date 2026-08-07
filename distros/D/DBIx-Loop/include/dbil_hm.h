#ifndef DBIL_HM_H
#define DBIL_HM_H

/* DBIx::Loop::Loop::Hyperman - the pure-XS loop adapter, over Hyperman's
 * public C ABI (hm_abi.h, vendored at a pinned HM_ABI_VERSION). The table is
 * resolved lazily at runtime via Hyperman::_abi_ptr - no link-time coupling,
 * no build-time Hyperman dependency; when Hyperman is not loaded (or its ABI
 * is older than ours) the adapter croaks with a clear message and every other
 * backend/adapter keeps working.
 *
 * The adapter implements the Perl seam (add_reader/add_writer/remove/timer/
 * new_future/await, in xs/loop_hyperman.xs) so the conformance suite drives
 * it like any other adapter, and fills a dbil_vt (dbil_vt.h) so backends can
 * bypass the Perl seam entirely: worker-fd readiness runs C to C.
 *
 * Requires dbil_pool.h (dbil_closure) before this file. */

#include "hm_abi.h"

static const hm_abi *DBIL_HM = NULL;    /* resolved on first use */

static const hm_abi *dbil_hm(pTHX) {
    if (!DBIL_HM) {
        dSP;
        int count;
        ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
        count = call_pv("Hyperman::_abi_ptr", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) {
            IV p = POPi;
            if (p) {
                const hm_abi *a = INT2PTR(const hm_abi *, p);
                if (a->abi_version >= HM_ABI_VERSION) DBIL_HM = a;
            }
        } else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
    }
    return DBIL_HM;
}

/* per-adapter state; the embedded vtable's ctx points back at this struct */
typedef struct dbil_hm_ctx {
    const hm_abi *A;
    void         *loop;      /* opaque hm_loop handle */
    dbil_vt       vt;
} dbil_hm_ctx;

static dbil_hm_ctx *dbil_hm_ctx_of(pTHX_ SV *self) {
    SV **e;
    if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV
        && (e = hv_fetchs((HV *)SvRV(self), "_ctx", 0)) && *e && SvIOK(*e))
        return INT2PTR(dbil_hm_ctx *, SvIV(*e));
    croak("DBIx::Loop::Loop::Hyperman: not an initialised adapter");
    return NULL;   /* not reached */
}

/* ---- trampolines: ABI C callbacks -> stored Perl callbacks ---------------
 * ABI contract: callbacks must not croak, so Perl callbacks run under G_EVAL
 * and errors become warnings. */

static void dbil_hm_io_tramp(pTHX_ int fd, int mask, void *ud) {
    SV *cb = (SV *)ud;
    dSP;
    PERL_UNUSED_VAR(fd);
    PERL_UNUSED_VAR(mask);
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV))
        warn("DBIx::Loop::Loop::Hyperman: io callback died: %s",
             SvPV_nolen(ERRSV));
    FREETMPS; LEAVE;
}

typedef struct { SV *cb; hm_abi_timer *t; } dbil_hm_tmr;

static void dbil_hm_timer_tramp(pTHX_ void *ud) {
    dbil_hm_tmr *tm = (dbil_hm_tmr *)ud;
    SV *cb = tm->cb;
    dSP;
    Safefree(tm);                    /* handle is dead once we fire */
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV))
        warn("DBIx::Loop::Loop::Hyperman: timer callback died: %s",
             SvPV_nolen(ERRSV));
    FREETMPS; LEAVE;
    SvREFCNT_dec(cb);
}

/* ---- Perl-seam internals (called from xs/loop_hyperman.xs) --------------- */

/* Stored Perl io callbacks live in the adapter's _r/_w hashes keyed by fd;
 * the stored SV itself is the watcher's ud, so replace/remove and the loop
 * slot stay in lockstep. */
static HV *dbil_hm_cbh(pTHX_ SV *self, int mask, int create) {
    HV *h = (HV *)SvRV(self);
    const char *k = (mask & HM_ABI_WRITE) ? "_w" : "_r";
    SV **e = hv_fetch(h, k, 2, create);
    if (!e || !*e) return NULL;
    if (!SvROK(*e)) {
        if (!create) return NULL;
        sv_setsv(*e, sv_2mortal(newRV_noinc((SV *)newHV())));
    }
    return (HV *)SvRV(*e);
}

static void dbil_hm_add_io(pTHX_ SV *self, int fd, int mask, SV *cb) {
    dbil_hm_ctx *c = dbil_hm_ctx_of(aTHX_ self);
    HV *cbs = dbil_hm_cbh(aTHX_ self, mask, 1);
    SV *held = newSVsv(cb);
    char key[16];
    I32 klen = (I32)sprintf(key, "%d", fd);
    c->A->io_watch(aTHX_ c->loop, fd, mask, dbil_hm_io_tramp, held);
    (void)hv_store(cbs, key, klen, held, 0);   /* frees any replaced cb */
}

static void dbil_hm_remove(pTHX_ SV *self, int fd) {
    dbil_hm_ctx *c = dbil_hm_ctx_of(aTHX_ self);
    HV *cbs;
    char key[16];
    I32 klen = (I32)sprintf(key, "%d", fd);
    c->A->io_unwatch(aTHX_ c->loop, fd, HM_ABI_READ);
    c->A->io_unwatch(aTHX_ c->loop, fd, HM_ABI_WRITE);
    if ((cbs = dbil_hm_cbh(aTHX_ self, HM_ABI_READ, 0)))
        (void)hv_delete(cbs, key, klen, G_DISCARD);
    if ((cbs = dbil_hm_cbh(aTHX_ self, HM_ABI_WRITE, 0)))
        (void)hv_delete(cbs, key, klen, G_DISCARD);
}

/* await bridge for foreign futures (DBIx::Loop::Future, ...): on_ready
 * settles a native Hyperman future the loop can run_until. cap = [bridge] */
XS_INTERNAL(dbil_hm_bridge_cb);
XS_INTERNAL(dbil_hm_bridge_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    const hm_abi *A = dbil_hm(aTHX);
    PERL_UNUSED_VAR(items);
    if (cap && A) {
        SV **br = av_fetch(cap, 0, 0);
        if (br) A->future_done(aTHX_ *br, NULL, 0);
    }
    XSRETURN_EMPTY;
}

static void dbil_hm_await(pTHX_ dbil_hm_ctx *c, SV *f) {
    if (c->A->is_future(aTHX_ f)) {
        c->A->run_until(aTHX_ c->loop, f);
        return;
    }
    {   /* foreign future: bridge through its on_ready */
        SV *bridge = c->A->future_new(aTHX);
        AV *cap = newAV();
        SV *cb;
        av_push(cap, SvREFCNT_inc(bridge));
        cb = sv_2mortal(dbil_closure(aTHX_ dbil_hm_bridge_cb, cap));
        {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 2); PUSHs(f); PUSHs(cb); PUTBACK;
            call_method("on_ready", G_VOID | G_DISCARD);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        }
        c->A->run_until(aTHX_ c->loop, bridge);
        SvREFCNT_dec(bridge);
    }
}

/* ---- the dbil_vt implementation (pure C, no Perl frames) ----------------- */

static void dbil_hm_vt_add_reader(pTHX_ void *vctx, int fd, dbil_io_fn fn,
                                  void *ud) {
    dbil_hm_ctx *c = (dbil_hm_ctx *)vctx;
    c->A->io_watch(aTHX_ c->loop, fd, HM_ABI_READ, fn, ud);
}

static void dbil_hm_vt_add_writer(pTHX_ void *vctx, int fd, dbil_io_fn fn,
                                  void *ud) {
    dbil_hm_ctx *c = (dbil_hm_ctx *)vctx;
    c->A->io_watch(aTHX_ c->loop, fd, HM_ABI_WRITE, fn, ud);
}

static void dbil_hm_vt_remove(pTHX_ void *vctx, int fd) {
    dbil_hm_ctx *c = (dbil_hm_ctx *)vctx;
    c->A->io_unwatch(aTHX_ c->loop, fd, HM_ABI_READ);
    c->A->io_unwatch(aTHX_ c->loop, fd, HM_ABI_WRITE);
}

static void *dbil_hm_vt_timer(pTHX_ void *vctx, double secs, dbil_timer_fn fn,
                              void *ud) {
    dbil_hm_ctx *c = (dbil_hm_ctx *)vctx;
    return (void *)c->A->timer(aTHX_ c->loop, secs, fn, ud);
}

static void dbil_hm_vt_timer_cancel(pTHX_ void *vctx, void *timer) {
    dbil_hm_ctx *c = (dbil_hm_ctx *)vctx;
    c->A->timer_cancel(aTHX_ c->loop, (hm_abi_timer *)timer);
}

static SV *dbil_hm_vt_new_future(pTHX_ void *vctx) {
    dbil_hm_ctx *c = (dbil_hm_ctx *)vctx;
    return c->A->future_new(aTHX);
}

static void dbil_hm_vt_await(pTHX_ void *vctx, SV *f) {
    dbil_hm_await(aTHX_ (dbil_hm_ctx *)vctx, f);
}

static dbil_hm_ctx *dbil_hm_ctx_new(const hm_abi *A, void *loop) {
    dbil_hm_ctx *c;
    Newxz(c, 1, dbil_hm_ctx);
    c->A    = A;
    c->loop = loop;
    c->vt.ctx          = (void *)c;
    c->vt.add_reader   = dbil_hm_vt_add_reader;
    c->vt.add_writer   = dbil_hm_vt_add_writer;
    c->vt.remove       = dbil_hm_vt_remove;
    c->vt.timer        = dbil_hm_vt_timer;
    c->vt.timer_cancel = dbil_hm_vt_timer_cancel;
    c->vt.new_future   = dbil_hm_vt_new_future;
    c->vt.await        = dbil_hm_vt_await;
    return c;
}

#endif /* DBIL_HM_H */
