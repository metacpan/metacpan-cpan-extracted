/* dbil_obs.h - the statement observer registry (dbil_abi v2).
 *
 * DBIx::Loop had one choke point every statement passes through, dbil_exec,
 * and no way to watch it. That is the seam a slow-query log, a per-query
 * metric or a database span all need, and none of them could be built
 * without wrapping the Perl API and giving up the C path.
 *
 * Included after dbil_future.h (it attaches to a future) and before
 * dbil_loop.h (which fires it). dbil_abi_impl.h, compiled later, registers
 * into the same table.
 *
 * WHAT AN OBSERVER IS NOT GIVEN: the bind values. They are the literal data -
 * names, tokens, card numbers - and an observer wanting the query text gets
 * the prepared SQL, which has placeholders exactly where the sensitive parts
 * would be. That is the correct thing to record anyway, and making it the
 * only thing on offer means nobody has to remember the rule.
 */

#ifndef DBIL_OBS_H
#define DBIL_OBS_H

#include "dbil_abi.h"

static struct { dbil_obs_start_cb start; dbil_obs_done_cb done; void *ud; }
    DBIL_OBS[DBIL_ABI_MAX_OBSERVERS];
static int DBIL_OBS_N = 0;

typedef struct { void *tok[DBIL_ABI_MAX_OBSERVERS]; int n; } dbil_obs_tokens;

/* The future struct without the croak. dbil_abi_impl.h has the same thing
 * under its own name, but it is compiled after the site that fires this, so
 * this file carries its own rather than reordering the whole include chain
 * for an observer nobody may have registered. */
static dbil_future *dbil_obs_peek(pTHX_ SV *sv) {
    MAGIC *mg;
    if (!sv || !SvROK(sv)) return NULL;
    mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &dbil_future_vtbl);
    return mg ? (dbil_future *)mg->mg_ptr : NULL;
}

static int dbil_obs_add(pTHX_ dbil_obs_start_cb start, dbil_obs_done_cb done,
                        void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!start || DBIL_OBS_N >= DBIL_ABI_MAX_OBSERVERS) return 0;
    DBIL_OBS[DBIL_OBS_N].start = start;
    DBIL_OBS[DBIL_OBS_N].done  = done;
    DBIL_OBS[DBIL_OBS_N].ud    = ud;
    DBIL_OBS_N++;
    return 1;
}

/* Fire the start half. Returns the tokens, or NULL when nobody is listening -
 * which is the branch every uninstrumented statement takes. */
static dbil_obs_tokens *dbil_obs_start(pTHX_ int is_query, SV *sql,
                                       AV *bind) {
    dbil_obs_tokens *t;
    STRLEN sl = 0;
    const char *sp = (sql && SvOK(sql)) ? SvPV_const(sql, sl) : "";
    int nbind = (bind && av_len(bind) >= 0) ? (int)(av_len(bind) + 1) : 0;
    int i;
    if (!DBIL_OBS_N) return NULL;
    Newxz(t, 1, dbil_obs_tokens);
    t->n = DBIL_OBS_N;
    for (i = 0; i < DBIL_OBS_N; i++)
        t->tok[i] = DBIL_OBS[i].start(aTHX_ is_query, sp, sl, nbind,
                                      DBIL_OBS[i].ud);
    return t;
}

static void dbil_obs_fire_done(pTHX_ dbil_obs_tokens *t, SV *res, SV *err) {
    int i;
    if (!t) return;
    for (i = 0; i < t->n && i < DBIL_OBS_N; i++)
        if (DBIL_OBS[i].done) DBIL_OBS[i].done(aTHX_ t->tok[i], res, err,
                                               DBIL_OBS[i].ud);
    Safefree(t);
}

/* The settle half, as a future continuation. Attached to whatever dbil_exec
 * returns, so it runs for all three backends - the native fd path, the forked
 * pool and the plain synchronous handle - without any of them knowing. */
XS_INTERNAL(dbil_xs_obs_done);
XS_INTERNAL(dbil_xs_obs_done) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    SV **tp;
    dbil_obs_tokens *t;
    dbil_future *p;
    if (!cap || items < 1) XSRETURN_EMPTY;
    tp = av_fetch(cap, 0, 0);
    if (!(tp && *tp)) XSRETURN_EMPTY;
    t = INT2PTR(dbil_obs_tokens *, SvIV(*tp));
    p = dbil_obs_peek(aTHX_ ST(0));
    if (!p) { dbil_obs_fire_done(aTHX_ t, NULL, NULL); XSRETURN_EMPTY; }
    if (p->state == 1) {
        /* done: result is an arrayref of values, and the statement's own
         * result is the first of them */
        SV *v = NULL;
        if (p->result && SvROK(p->result)
            && SvTYPE(SvRV(p->result)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(p->result);
            SV **e = (av_len(av) >= 0) ? av_fetch(av, 0, 0) : NULL;
            v = (e && *e) ? *e : NULL;
        }
        dbil_obs_fire_done(aTHX_ t, v, NULL);
    }
    else dbil_obs_fire_done(aTHX_ t, NULL, p->error);
    XSRETURN_EMPTY;
}

/* Attach the settle half to a statement's future. Mirrors what
 * dbil_abi_future_on_ready does, open-coded because that lives in
 * dbil_abi_impl.h and is compiled after the site that fires this. */
static void dbil_obs_attach(pTHX_ SV *fut, dbil_obs_tokens *t) {
    dbil_future *p;
    AV *cap;
    SV *cv;
    if (!t) return;
    p = dbil_obs_peek(aTHX_ fut);
    if (!p) { dbil_obs_fire_done(aTHX_ t, NULL, NULL); return; }
    cap = newAV();
    av_push(cap, newSViv(PTR2IV(t)));
    cv = dbil_closure(aTHX_ dbil_xs_obs_done, cap);
    if (p->state) {           /* already settled - fire now, never queue */
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(fut); PUTBACK;
        call_sv(cv, G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        SvREFCNT_dec(cv);
    }
    else av_push(p->cbs, cv);  /* the queue owns it */
}

#endif /* DBIL_OBS_H */
