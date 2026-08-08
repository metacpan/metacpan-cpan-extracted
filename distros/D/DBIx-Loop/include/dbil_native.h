#ifndef DBIL_NATIVE_H
#define DBIL_NATIVE_H

/* Backend A - native fd async, for socket drivers with a non-blocking execute
 * (DBD::Pg first; mysql/MariaDB slot in beside later).
 *
 * True single-threaded async: fire the query with {pg_async => PG_ASYNC},
 * register the connection's socket ($dbh->{pg_socket}) with the loop, and on
 * readability poll $dbh->pg_ready; when ready, $dbh->pg_result collects, rows
 * are fetched from the async statement handle, and the future settles. No
 * workers, no serialization - but exactly ONE query in flight per connection
 * (a libpq limit), so further queries FIFO-queue on the connection until the
 * pool of native connections arrives in phase 04.
 *
 * Everything reaches DBD::Pg through call_method / attribute FETCH, so this
 * file compiles with no libpq or DBD::Pg present; capability sniffing keeps
 * the whole backend unreachable unless DBD::Pg's async surface really exists.
 *
 * Depends on dbil_run.h (dbil_h_fetch) and dbil_pool.h (closures, dbil_vt). */

/* ---- the async-constant / capability sniff --------------------------------- */

static IV  DBIL_PG_ASYNC       = 0;
static int DBIL_PG_ASYNC_KNOWN = 0;

/* resolve DBD::Pg::PG_ASYNC once; 0 (and known) when absent */
static IV dbil_pg_async_const(pTHX) {
    if (DBIL_PG_ASYNC_KNOWN) return DBIL_PG_ASYNC;
    DBIL_PG_ASYNC_KNOWN = 1;
    {
        CV *cv = get_cv("DBD::Pg::PG_ASYNC", 0);
        if (cv) {
            dSP; int n;
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            n = call_sv((SV *)cv, G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && n > 0) DBIL_PG_ASYNC = POPi;
            else if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
        }
    }
    return DBIL_PG_ASYNC;
}

/* is the driver's native-async surface actually loaded + usable? */
static int dbil_native_available(pTHX_ const char *drv) {
    if (strEQ(drv, "Pg"))
        return dbil_pg_async_const(aTHX) != 0;
    /* mysql/MariaDB: deferred until their surface is wired in */
    return 0;
}

/* ---- native connection state ------------------------------------------------ */

typedef struct dbil_native {
    pid_t pid;        /* the process that owns this libpq connection */
    SV  *dbh;         /* the (parent-held) connection (+1)         */
    SV  *loop;        /* loop adapter (+1)                         */
    dbil_vt *vt;      /* C seam when the adapter has one           */
    int  fd;          /* pg_socket, registered with the loop; -1 = not yet */
    int  dead;        /* connection-level failure: stop accepting  */
    SV  *inflight;    /* future of the running query (+1) or NULL  */
    SV  *sth;         /* its async statement handle (+1) or NULL   */
    int  is_query;    /* SELECT-style: fetch rows on completion    */
    AV  *queue;       /* pending [is_query, sql, bindref, future, ...] */
} dbil_native;

static void dbil_native_pump(pTHX_ dbil_native *nc);   /* fire next; below */

/* $dbh->errstr as a mortal SV (best effort) */
static SV *dbil_errstr(pTHX_ SV *h, const char *fallback) {
    dSP; int n; SV *r = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 1); PUSHs(h); PUTBACK;
    n = call_method("errstr", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && n > 0) { SV *s = POPs; if (SvOK(s) && SvCUR(s)) r = newSVsv(s); }
    else if (n > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return r ? sv_2mortal(r) : sv_2mortal(newSVpv(fallback, 0));
}

/* finish the in-flight query: collect pg_result, fetch rows, settle */
static void dbil_native_complete(pTHX_ dbil_native *nc) {
    SV *fut = nc->inflight;
    SV *sth = nc->sth;
    IV  rows = 0;
    int ok = 1;
    SV *err = NULL;

    nc->inflight = NULL;
    nc->sth      = NULL;

    {   /* $dbh->pg_result: rows-affected, false on error */
        dSP; int n;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(nc->dbh); PUTBACK;
        n = call_method("pg_result", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            SV *e = newSVsv(ERRSV);
            if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            ok = 0; err = sv_2mortal(e);
        } else {
            SV *r = (n > 0) ? POPs : NULL;
            if (!r || !SvOK(r) || (SvPOK(r) && !SvCUR(r)) || (!SvPOK(r) && !SvTRUE(r) && SvIV(r) == 0 && !SvNOK(r))) {
                /* a plain false return = error; grab errstr after LEAVE */
                ok = SvTRUE(r) ? 1 : 0;
            }
            if (r && SvOK(r)) rows = SvIV(r);
            PUTBACK; FREETMPS; LEAVE;
            if (!ok) err = dbil_errstr(aTHX_ nc->dbh, "pg_result failed");
        }
    }

    if (fut) {
        if (!ok) {
            dbil_future_settle_fail(aTHX_ fut, err);
        }
        else if (nc->is_query && sth) {
            SV *nfld = dbil_h_fetch(aTHX_ sth, "NUM_OF_FIELDS");
            IV  nf   = (nfld && SvOK(nfld)) ? SvIV(nfld) : 0;
            HV *h    = newHV();
            if (nf > 0) {
                SV *names = dbil_h_fetch(aTHX_ sth, "NAME");
                SV *fa    = NULL;
                {
                    dSP; int n;
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    EXTEND(SP, 1); PUSHs(sth); PUTBACK;
                    n = call_method("fetchall_arrayref", G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (!SvTRUE(ERRSV) && n > 0) { SV *r = POPs; if (SvROK(r)) fa = SvREFCNT_inc(r); }
                    else if (n > 0) (void)POPs;
                    PUTBACK; FREETMPS; LEAVE;
                }
                (void)hv_stores(h, "rows", fa ? fa : newRV_noinc((SV *)newAV()));
                {
                    AV *cols = newAV();
                    if (names && SvROK(names) && SvTYPE(SvRV(names)) == SVt_PVAV) {
                        AV *na = (AV *)SvRV(names);
                        SSize_t j, m = av_len(na) + 1;
                        for (j = 0; j < m; j++) {
                            SV **c = av_fetch(na, j, 0);
                            av_push(cols, (c && *c) ? newSVsv(*c) : newSV(0));
                        }
                    }
                    (void)hv_stores(h, "columns", newRV_noinc((SV *)cols));
                }
            } else {
                (void)hv_stores(h, "rows",    newRV_noinc((SV *)newAV()));
                (void)hv_stores(h, "columns", newRV_noinc((SV *)newAV()));
            }
            dbil_future_settle_done1(aTHX_ fut, sv_2mortal(newRV_noinc((SV *)h)));
        }
        else {
            HV *h = newHV();
            (void)hv_stores(h, "rows_affected", newSViv(rows > 0 ? rows : 0));
            dbil_future_settle_done1(aTHX_ fut, sv_2mortal(newRV_noinc((SV *)h)));
        }
        SvREFCNT_dec(fut);
    }
    if (sth) SvREFCNT_dec(sth);

    dbil_native_pump(aTHX_ nc);       /* fire the next queued query, if any */
}

/* readable on the pg socket: is the async result ready yet? */
static void dbil_native_on_readable(pTHX_ dbil_native *nc) {
    int ready = 0;
    if (!nc->inflight) return;        /* spurious wakeup */
    {
        dSP; int n;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(nc->dbh); PUTBACK;
        n = call_method("pg_ready", G_SCALAR | G_EVAL);
        SPAGAIN;
        /* SvTRUE is a multi-evaluating macro before 5.30, so SvTRUE(POPs)
         * pops once per expansion and walks SP below the stack base. Pop
         * into a variable and test that. */
        if (n > 0) {
            SV *r = POPs;
            if (!SvTRUE(ERRSV)) ready = SvTRUE(r) ? 1 : 0;
        }
        PUTBACK; FREETMPS; LEAVE;
    }
    if (ready) dbil_native_complete(aTHX_ nc);
}

/* the two seam callbacks */
static void dbil_native_reader_c(pTHX_ int fd, int mask, void *ud) {
    PERL_UNUSED_VAR(fd); PERL_UNUSED_VAR(mask);
    dbil_native_on_readable(aTHX_ (dbil_native *)ud);
}
XS_INTERNAL(dbil_native_reader_cb);
XS_INTERNAL(dbil_native_reader_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    PERL_UNUSED_VAR(items);
    if (cap)
        dbil_native_on_readable(aTHX_
            INT2PTR(dbil_native *, SvIV(*av_fetch(cap, 0, 0))));
    XSRETURN_EMPTY;
}

/* register the pg socket with the loop (once) */
static void dbil_native_watch(pTHX_ dbil_native *nc) {
    SV *sock;
    if (nc->fd >= 0) return;
    sock = dbil_h_fetch(aTHX_ nc->dbh, "pg_socket");
    if (!sock || !SvOK(sock)) { nc->fd = -1; return; }
    nc->fd = (int)SvIV(sock);
    if (nc->vt) {
        nc->vt->add_reader(aTHX_ nc->vt->ctx, nc->fd, dbil_native_reader_c, nc);
    } else {
        AV *cap = newAV();
        SV *cb;
        av_push(cap, newSViv(PTR2IV(nc)));
        cb = sv_2mortal(dbil_closure(aTHX_ dbil_native_reader_cb, cap));
        {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 3);
            PUSHs(nc->loop); mPUSHi(nc->fd); PUSHs(cb);
            PUTBACK;
            call_method("add_reader", G_VOID | G_DISCARD | G_EVAL);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        }
    }
}

/* fire one query asynchronously; on immediate failure settle the future */
static void dbil_native_fire(pTHX_ dbil_native *nc, int is_query, SV *sql,
                             SV *bindref, SV *future) {
    SV *sth = NULL;

    {   /* $sth = $dbh->prepare($sql, { pg_async => PG_ASYNC }) */
        HV *attr = newHV();
        SV *attr_rv;
        (void)hv_stores(attr, "pg_async", newSViv(dbil_pg_async_const(aTHX)));
        attr_rv = sv_2mortal(newRV_noinc((SV *)attr));
        {
            dSP; int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 3);
            PUSHs(nc->dbh); PUSHs(sql); PUSHs(attr_rv);
            PUTBACK;
            n = call_method("prepare", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (SvTRUE(ERRSV)) {
                SV *e = newSVsv(ERRSV);
                if (n > 0) (void)POPs;
                PUTBACK; FREETMPS; LEAVE;
                dbil_future_settle_fail(aTHX_ future, sv_2mortal(e));
                SvREFCNT_dec(future);
                return;
            }
            if (n > 0) { SV *s = POPs; if (SvROK(s)) sth = SvREFCNT_inc(s); }
            PUTBACK; FREETMPS; LEAVE;
        }
    }
    if (!sth) {
        dbil_future_settle_fail(aTHX_ future,
            dbil_errstr(aTHX_ nc->dbh, "async prepare failed"));
        SvREFCNT_dec(future);
        return;
    }

    {   /* $sth->execute(@bind) - returns immediately under pg_async */
        AV *bind = (bindref && SvROK(bindref)) ? (AV *)SvRV(bindref) : NULL;
        SSize_t nb = bind ? av_len(bind) + 1 : 0, i;
        dSP; int n;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1 + nb); PUSHs(sth);
        for (i = 0; i < nb; i++) { SV **e = av_fetch(bind, i, 0); PUSHs(e && *e ? *e : &PL_sv_undef); }
        PUTBACK;
        n = call_method("execute", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            SV *e = newSVsv(ERRSV);
            if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            SvREFCNT_dec(sth);
            dbil_future_settle_fail(aTHX_ future, sv_2mortal(e));
            SvREFCNT_dec(future);
            return;
        }
        if (n > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
    }

    nc->inflight = future;   /* takes the +1 we were given */
    nc->sth      = sth;
    nc->is_query = is_query;
    dbil_native_watch(aTHX_ nc);
    /* if the result raced us and is already ready, complete now rather than
     * waiting for a readability edge we may have missed */
    dbil_native_on_readable(aTHX_ nc);
}

/* fire the next queued request if the connection is idle */
static void dbil_native_pump(pTHX_ dbil_native *nc) {
    if (nc->inflight || nc->dead) return;
    if (av_len(nc->queue) >= 3) {
        SV *isq  = av_shift(nc->queue);
        SV *sql  = av_shift(nc->queue);
        SV *bref = av_shift(nc->queue);
        SV *fut  = av_shift(nc->queue);
        dbil_native_fire(aTHX_ nc, (int)SvIV(isq), sv_2mortal(sql),
                         sv_2mortal(bref), fut);   /* fire takes fut's +1 */
        SvREFCNT_dec(isq);
    }
}

/* run one statement on the native connection; returns the future (+1) */
static SV *dbil_native_run(pTHX_ dbil_native *nc, int is_query, SV *sql, AV *bind) {
    SV *future = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    if (nc->dead) {
        dbil_future_settle_fail(aTHX_ future,
            sv_2mortal(newSVpvs("native connection is closed")));
        return future;
    }
    if (nc->inflight) {
        /* one in-flight per connection (libpq): queue */
        av_push(nc->queue, newSViv(is_query));
        av_push(nc->queue, newSVsv(sql));
        av_push(nc->queue, dbil_bind_rv(aTHX_ bind));
        av_push(nc->queue, SvREFCNT_inc(future));
        return future;
    }
    dbil_native_fire(aTHX_ nc, is_query, sql,
                     sv_2mortal(dbil_bind_rv(aTHX_ bind)),
                     SvREFCNT_inc(future));
    return future;
}

/* ---- lifecycle --------------------------------------------------------------- */

/* A libpq connection cannot be shared across a fork: two processes writing the
 * same socket interleave protocol messages and neither can recover. So the
 * owning pid is recorded and an inherited state is dropped rather than used. */
static int dbil_native_owned(const dbil_native *nc) {
    return nc && nc->pid == getpid();
}

static dbil_native *dbil_native_new(pTHX_ SV *dbh, SV *loop) {
    dbil_native *nc;
    Newxz(nc, 1, dbil_native);
    nc->pid   = getpid();
    nc->dbh   = SvREFCNT_inc(dbh);
    nc->loop  = SvREFCNT_inc(loop);
    nc->vt    = dbil_vt_of(aTHX_ loop);
    nc->fd    = -1;
    nc->queue = newAV();
    return nc;
}

/* Release inherited native state: drop our references and free the struct,
 * touching neither the loop (the registration is the parent's) nor the socket
 * (closing it would tear down the parent's connection). */
static void dbil_native_disown(pTHX_ dbil_native *nc) {
    if (!nc) return;
    if (nc->inflight) SvREFCNT_dec(nc->inflight);
    if (nc->sth)      SvREFCNT_dec(nc->sth);
    if (nc->queue)    SvREFCNT_dec((SV *)nc->queue);
    if (nc->dbh)      SvREFCNT_dec(nc->dbh);
    if (nc->loop)     SvREFCNT_dec(nc->loop);
    Safefree(nc);
}

static void dbil_native_free(pTHX_ dbil_native *nc) {
    if (!nc) return;
    if (!dbil_native_owned(nc)) { dbil_native_disown(aTHX_ nc); return; }
    if (nc->fd >= 0 && !PL_dirty) {
        if (nc->vt) nc->vt->remove(aTHX_ nc->vt->ctx, nc->fd);
        else {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 2); PUSHs(nc->loop); mPUSHi(nc->fd); PUTBACK;
            call_method("remove", G_VOID | G_DISCARD | G_EVAL);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        }
    }
    if (nc->inflight) {
        dbil_future_settle_fail(aTHX_ nc->inflight,
            sv_2mortal(newSVpvs("connection closed with query in flight")));
        SvREFCNT_dec(nc->inflight);
    }
    if (nc->sth) SvREFCNT_dec(nc->sth);
    {   /* fail anything still queued */
        while (av_len(nc->queue) >= 3) {
            SV *isq = av_shift(nc->queue), *sql = av_shift(nc->queue);
            SV *br  = av_shift(nc->queue), *fut = av_shift(nc->queue);
            SvREFCNT_dec(isq); SvREFCNT_dec(sql); SvREFCNT_dec(br);
            dbil_future_settle_fail(aTHX_ fut,
                sv_2mortal(newSVpvs("connection closed")));
            SvREFCNT_dec(fut);
        }
    }
    SvREFCNT_dec((SV *)nc->queue);
    SvREFCNT_dec(nc->dbh);
    SvREFCNT_dec(nc->loop);
    Safefree(nc);
}

#endif /* DBIL_NATIVE_H */
