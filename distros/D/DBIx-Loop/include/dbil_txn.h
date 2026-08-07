#ifndef DBIL_TXN_H
#define DBIL_TXN_H

/* Transactions, pinned to one pool slot, orchestrated in C.
 *
 *   $db->txn(sub { my $tx = shift; ...; return $value_or_future })
 *
 * acquire a slot (waits when the pool is saturated) -> BEGIN -> run the block
 * with a DBIx::Loop::Txn handle whose query/do are pinned to that slot ->
 * COMMIT on success / ROLLBACK on a die or a failed block-future -> release
 * the slot. Returns a future of the block's result. The whole chain is C
 * closures registered as on_ready callbacks; nothing blocks the loop.
 *
 * Two txns run concurrently on different slots. A txn() inside a block is an
 * INDEPENDENT transaction on another slot (document: do not await one while
 * the pool is exhausted by its parents). A worker death mid-txn fails the
 * transaction (generation check) - it is never silently resumed on the
 * respawned connection.
 *
 * Depends on dbil_pool.h (slot checkout) and dbil_future.h. */

/* capture AV layout shared by the stage closures */
enum {
    DBIL_TC_SELF = 0,   /* the DBIx::Loop object (+1)              */
    DBIL_TC_BLOCK,      /* the user block CV (+1)                  */
    DBIL_TC_OUTER,      /* the future txn() returned (+1)          */
    DBIL_TC_TX,         /* the DBIx::Loop::Txn handle (+1)         */
    DBIL_TC_POOL,       /* pool pointer IV                         */
    DBIL_TC_RESULT,     /* block result AV-ref once known          */
    DBIL_TC_ERROR       /* error SV once known                     */
};

/* register a C-closure coderef as on_ready of a DBIx::Loop::Future from C */
static void dbil_txn_on_ready(pTHX_ SV *future, XSUBADDR_t body, AV *cap) {
    dbil_future *f = dbil_future_of(aTHX_ future);
    SV *cb = dbil_closure(aTHX_ body, cap);
    if (f->state) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(future); PUTBACK;
        call_sv(cb, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV))
            warn("DBIx::Loop::txn: stage callback died: %s", SvPV_nolen(ERRSV));
        FREETMPS; LEAVE;
        SvREFCNT_dec(cb);
    } else {
        av_push(f->cbs, cb);
    }
}

/* freeze one request tuple for the wire (mortal bytes, or NULL) */
static SV *dbil_txn_freeze_req(pTHX_ int is_query, const char *sql, AV *bind) {
    AV *req = newAV();
    av_push(req, newSViv(is_query));
    av_push(req, newSVpv(sql, 0));
    av_push(req, bind ? newRV_inc((SV *)bind) : newRV_noinc((SV *)newAV()));
    return dbil_freeze(aTHX_ sv_2mortal(newRV_noinc((SV *)req)));
}

/* tx handle fields */
static IV dbil_tx_iv(pTHX_ SV *tx_rv, const char *k) {
    HV *h = (HV *)SvRV(tx_rv);
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e && SvIOK(*e)) ? SvIV(*e) : -1;
}
static void dbil_tx_set_iv(pTHX_ SV *tx_rv, const char *k, IV v) {
    (void)hv_store((HV *)SvRV(tx_rv), k, (I32)strlen(k), newSViv(v), 0);
}

/* release the slot and mark the handle finished */
static void dbil_txn_finish(pTHX_ AV *cap) {
    dbil_pool *p = INT2PTR(dbil_pool *, SvIV(*av_fetch(cap, DBIL_TC_POOL, 0)));
    SV *tx = *av_fetch(cap, DBIL_TC_TX, 0);
    IV  wi = dbil_tx_iv(aTHX_ tx, "wi");
    dbil_tx_set_iv(aTHX_ tx, "active", 0);
    if (wi >= 0) dbil_pool_release(aTHX_ p, (int)wi);
}

/* stage 4: COMMIT (or ROLLBACK) completed - settle the outer future */
XS_INTERNAL(dbil_txn_commit_cb);
XS_INTERNAL(dbil_txn_commit_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    SV *fut, *outer, *errv;
    if (!cap || items < 1) XSRETURN_EMPTY;
    fut   = ST(0);
    outer = *av_fetch(cap, DBIL_TC_OUTER, 0);
    errv  = *av_fetch(cap, DBIL_TC_ERROR, 0);
    dbil_txn_finish(aTHX_ cap);
    if (errv && SvOK(errv)) {
        /* this was the ROLLBACK completing: fail with the stored error */
        dbil_future_settle_fail(aTHX_ outer, errv);
    }
    else if (dbil_future_of(aTHX_ fut)->state == 2) {
        dbil_future_settle_fail(aTHX_ outer,
            dbil_future_of(aTHX_ fut)->error
                ? dbil_future_of(aTHX_ fut)->error
                : sv_2mortal(newSVpvs("commit failed")));
    }
    else {
        SV *res = *av_fetch(cap, DBIL_TC_RESULT, 0);
        if (res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVAV) {
            /* settle done with the block's (list) result */
            AV *ra = (AV *)SvRV(res);
            dbil_future *of = dbil_future_of(aTHX_ outer);
            if (!of->state) {
                of->result = newRV_inc((SV *)ra);
                of->state  = 1;
                dbil_future_fire(aTHX_ outer, of);
            }
        } else {
            dbil_future_settle_done1(aTHX_ outer, &PL_sv_undef);
        }
    }
    XSRETURN_EMPTY;
}

/* send COMMIT or ROLLBACK on the pinned slot, then finish via commit_cb */
static void dbil_txn_end(pTHX_ AV *cap, const char *sql, SV *errv) {
    dbil_pool *p = INT2PTR(dbil_pool *, SvIV(*av_fetch(cap, DBIL_TC_POOL, 0)));
    SV *tx  = *av_fetch(cap, DBIL_TC_TX, 0);
    IV  wi  = dbil_tx_iv(aTHX_ tx, "wi");
    IV  gen = dbil_tx_iv(aTHX_ tx, "gen");
    SV *bytes = dbil_txn_freeze_req(aTHX_ 0, sql, NULL);
    SV *ef  = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    if (errv && SvOK(errv))
        av_store(cap, DBIL_TC_ERROR, newSVsv(errv));
    if (!bytes) {
        dbil_txn_finish(aTHX_ cap);
        dbil_future_settle_fail(aTHX_ *av_fetch(cap, DBIL_TC_OUTER, 0),
            sv_2mortal(newSVpvs("could not serialise txn end")));
        SvREFCNT_dec(ef);
        return;
    }
    dbil_pool_send_tx(aTHX_ p, (int)wi, (int)gen, bytes, ef);
    SvREFCNT_inc((SV *)cap);
    dbil_txn_on_ready(aTHX_ ef, dbil_txn_commit_cb, cap);
    SvREFCNT_dec(ef);
}

/* stage 3: the block's future settled */
XS_INTERNAL(dbil_txn_block_cb);
XS_INTERNAL(dbil_txn_block_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    SV *fut;
    dbil_future *f;
    if (!cap || items < 1) XSRETURN_EMPTY;
    fut = ST(0);
    f   = dbil_future_of(aTHX_ fut);
    if (f->state == 1) {
        av_store(cap, DBIL_TC_RESULT,
                 f->result ? SvREFCNT_inc(f->result) : &PL_sv_undef);
        dbil_txn_end(aTHX_ cap, "COMMIT", NULL);
    } else {
        dbil_txn_end(aTHX_ cap, "ROLLBACK",
            f->error ? f->error : sv_2mortal(newSVpvs("transaction block failed")));
    }
    XSRETURN_EMPTY;
}

/* stage 2: BEGIN completed - run the user block */
XS_INTERNAL(dbil_txn_begin_cb);
XS_INTERNAL(dbil_txn_begin_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    SV *fut, *block, *tx;
    if (!cap || items < 1) XSRETURN_EMPTY;
    fut = ST(0);
    if (dbil_future_of(aTHX_ fut)->state == 2) {
        SV *outer = *av_fetch(cap, DBIL_TC_OUTER, 0);
        dbil_txn_finish(aTHX_ cap);
        dbil_future_settle_fail(aTHX_ outer,
            dbil_future_of(aTHX_ fut)->error
                ? dbil_future_of(aTHX_ fut)->error
                : sv_2mortal(newSVpvs("BEGIN failed")));
        XSRETURN_EMPTY;
    }
    block = *av_fetch(cap, DBIL_TC_BLOCK, 0);
    tx    = *av_fetch(cap, DBIL_TC_TX, 0);
    {
        dSP; int n; SV *res = NULL;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(tx); PUTBACK;
        n = call_sv(block, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            SV *e = newSVsv(ERRSV);
            if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            dbil_txn_end(aTHX_ cap, "ROLLBACK", sv_2mortal(e));
            XSRETURN_EMPTY;
        }
        res = (n > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;

        if (res && SvROK(res) && sv_derived_from(res, "DBIx::Loop::Future")) {
            SvREFCNT_inc((SV *)cap);
            dbil_txn_on_ready(aTHX_ res, dbil_txn_block_cb, cap);
            SvREFCNT_dec(res);
        } else {
            AV *ra = newAV();
            av_push(ra, res ? res : &PL_sv_undef);   /* takes the +1 */
            av_store(cap, DBIL_TC_RESULT, newRV_noinc((SV *)ra));
            dbil_txn_end(aTHX_ cap, "COMMIT", NULL);
        }
    }
    XSRETURN_EMPTY;
}

/* stage 1: slot acquired - pin the handle, send BEGIN */
XS_INTERNAL(dbil_txn_acq_cb);
XS_INTERNAL(dbil_txn_acq_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    dbil_pool *p;
    SV *fut, *tx;
    IV wi;
    if (!cap || items < 1) XSRETURN_EMPTY;
    fut = ST(0);
    p   = INT2PTR(dbil_pool *, SvIV(*av_fetch(cap, DBIL_TC_POOL, 0)));
    tx  = *av_fetch(cap, DBIL_TC_TX, 0);
    {
        dbil_future *f = dbil_future_of(aTHX_ fut);
        SV **r0;
        if (f->state != 1) {
            dbil_future_settle_fail(aTHX_ *av_fetch(cap, DBIL_TC_OUTER, 0),
                f->error ? f->error : sv_2mortal(newSVpvs("could not acquire a slot")));
            XSRETURN_EMPTY;
        }
        r0 = av_fetch((AV *)SvRV(f->result), 0, 0);
        wi = (r0 && *r0) ? SvIV(*r0) : -1;
    }
    dbil_tx_set_iv(aTHX_ tx, "wi",  wi);
    dbil_tx_set_iv(aTHX_ tx, "gen", (wi >= 0) ? p->w[wi].gen : -1);
    dbil_tx_set_iv(aTHX_ tx, "active", 1);
    {
        SV *bytes = dbil_txn_freeze_req(aTHX_ 0, "BEGIN", NULL);
        SV *bf    = dbil_future_new(aTHX_ "DBIx::Loop::Future");
        if (!bytes) {
            dbil_txn_finish(aTHX_ cap);
            dbil_future_settle_fail(aTHX_ *av_fetch(cap, DBIL_TC_OUTER, 0),
                sv_2mortal(newSVpvs("could not serialise BEGIN")));
            SvREFCNT_dec(bf);
            XSRETURN_EMPTY;
        }
        dbil_pool_send_tx(aTHX_ p, (int)wi, (int)dbil_tx_iv(aTHX_ tx, "gen"),
                          bytes, bf);
        SvREFCNT_inc((SV *)cap);
        dbil_txn_on_ready(aTHX_ bf, dbil_txn_begin_cb, cap);
        SvREFCNT_dec(bf);
    }
    XSRETURN_EMPTY;
}

/* entry: $db->txn($block) -> outer future (+1) */
static SV *dbil_txn_start(pTHX_ SV *self, SV *block, dbil_pool *p) {
    SV *outer = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    SV *tx;
    AV *cap;
    {   /* the Txn handle: { db, wi, gen, active, pool } */
        HV *h = newHV();
        (void)hv_stores(h, "db",     newSVsv(self));
        (void)hv_stores(h, "wi",     newSViv(-1));
        (void)hv_stores(h, "gen",    newSViv(-1));
        (void)hv_stores(h, "active", newSViv(0));
        (void)hv_stores(h, "_pool",  newSViv(PTR2IV(p)));
        tx = sv_bless(newRV_noinc((SV *)h),
                      gv_stashpv("DBIx::Loop::Txn", GV_ADD));
    }
    cap = newAV();
    av_extend(cap, DBIL_TC_ERROR);
    av_store(cap, DBIL_TC_SELF,   newSVsv(self));
    av_store(cap, DBIL_TC_BLOCK,  newSVsv(block));
    av_store(cap, DBIL_TC_OUTER,  SvREFCNT_inc(outer));
    av_store(cap, DBIL_TC_TX,     tx);                 /* takes the +1 */
    av_store(cap, DBIL_TC_POOL,   newSViv(PTR2IV(p)));
    av_store(cap, DBIL_TC_RESULT, newSV(0));
    av_store(cap, DBIL_TC_ERROR,  newSV(0));
    {
        SV *acq = dbil_pool_acquire(aTHX_ p);
        dbil_txn_on_ready(aTHX_ acq, dbil_txn_acq_cb, cap);   /* cap owned */
        SvREFCNT_dec(acq);
    }
    return outer;
}

/* a statement on the Txn handle, pinned to its slot (+1 future) */
static SV *dbil_txn_stmt(pTHX_ SV *tx_rv, int is_query, SV *sql, AV *bind) {
    SV *future = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    IV active = dbil_tx_iv(aTHX_ tx_rv, "active");
    IV wi     = dbil_tx_iv(aTHX_ tx_rv, "wi");
    IV gen    = dbil_tx_iv(aTHX_ tx_rv, "gen");
    dbil_pool *p = INT2PTR(dbil_pool *,
                           dbil_tx_iv(aTHX_ tx_rv, "_pool"));
    if (!active || wi < 0 || !p) {
        dbil_future_settle_fail(aTHX_ future,
            sv_2mortal(newSVpvs("transaction is not active")));
        return future;
    }
    {
        AV *req = newAV();
        SV *bytes;
        av_push(req, newSViv(is_query));
        av_push(req, newSVsv(sql));
        av_push(req, bind ? newRV_inc((SV *)bind) : newRV_noinc((SV *)newAV()));
        bytes = dbil_freeze(aTHX_ sv_2mortal(newRV_noinc((SV *)req)));
        if (!bytes) {
            dbil_future_settle_fail(aTHX_ future,
                sv_2mortal(newSVpvs("could not serialise request")));
            return future;
        }
        dbil_pool_send_tx(aTHX_ p, (int)wi, (int)gen, bytes, future);
    }
    return future;
}

#endif /* DBIL_TXN_H */
