#ifndef DBIL_LOOP_H
#define DBIL_LOOP_H

/* The DBIx::Loop instance and its dispatch, in C.
 *
 * The object is a blessed HV { dbh, loop, capability } - not a hot struct (one
 * per connection), so a hash is fine; the hot object is the future. query/do
 * build a future, run the statement (dbil_run_dbi), and settle it. Phase 1 is
 * synchronous (the stub path); phases 02/03 branch here on capability to the
 * worker pool / native fd backends. */

/* driver name via $dbh->{Driver}{Name} (FETCH from C). Mortal SV or NULL. */
static SV *dbil_driver_name(pTHX_ SV *dbh) {
    SV *drv = dbil_h_fetch(aTHX_ dbh, "Driver");
    if (drv && SvROK(drv)) {
        SV *nm = dbil_h_fetch(aTHX_ drv, "Name");
        if (nm && SvOK(nm)) return nm;
    }
    return NULL;
}

/* 'native' for socket drivers with non-blocking execute, else 'pool'. */
static const char *dbil_capability(pTHX_ SV *driver_name) {
    if (driver_name && SvOK(driver_name)) {
        STRLEN l;
        const char *p = SvPV_const(driver_name, l);
        if ((l == 2 && memEQ(p, "Pg", 2))
         || (l == 5 && memEQ(p, "mysql", 5))
         || (l == 7 && memEQ(p, "MariaDB", 7)))
            return "native";
    }
    return "pool";
}

/* fetch a stored field of the blessed-HV object, or NULL */
static SV *dbil_field(pTHX_ SV *self, const char *k, STRLEN kl) {
    HV *h;
    SV **e;
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("DBIx::Loop: not a DBIx::Loop object");
    h = (HV *)SvRV(self);
    e = hv_fetch(h, k, (I32)kl, 0);
    return (e && *e) ? *e : NULL;
}

/* Build the object: the blessed HV behind both DBIx::Loop->new (xs/loop.xs,
 * which parses the option pairs) and the C ABI's connect (dbil_abi_impl.h), so
 * the capability probe and the connect-args retention have one home.
 *
 * `loop` and `dbh` are required; the dsn/user/pass/attr group is optional and
 * stored only when a dsn is given, since it is what lets the pool's forked
 * workers open their own handles - a live dbh cannot cross a fork. Croaks on a
 * missing loop or dbh; callers that must not croak check first. */
static SV *dbil_new(pTHX_ const char *cls, SV *dbh, SV *loop,
                    SV *dsn, SV *user, SV *pass, SV *attr,
                    int nworkers, int max_queue) {
    HV *self;
    if (!loop || !SvOK(loop))
        croak("DBIx::Loop->new: a 'loop' is required - DBIx::Loop is not "
              "an event loop, it runs on one. Pass loop => $adapter.");
    if (!dbh || !SvROK(dbh))
        croak("DBIx::Loop->new: a 'dbh' is required (or use connect)");
    self = newHV();
    (void)hv_stores(self, "dbh",  newSVsv(dbh));
    (void)hv_stores(self, "loop", newSVsv(loop));
    (void)hv_stores(self, "workers",   newSViv(nworkers  > 0 ? nworkers  : 4));
    (void)hv_stores(self, "max_queue", newSViv(max_queue > 0 ? max_queue : 0));
    {
        SV *dn = dbil_driver_name(aTHX_ dbh);
        const char *cap = dbil_capability(aTHX_ dn);
        /* 'native' only when the driver's async surface is actually loaded
         * (DBD::Pg's PG_ASYNC resolves); otherwise the pool backend serves it
         * like any other driver */
        if (strEQ(cap, "native")
            && !(dn && SvOK(dn) && dbil_native_available(aTHX_ SvPV_nolen(dn))))
            cap = "pool";
        (void)hv_stores(self, "capability", newSVpv(cap, 0));
    }
    if (dsn && SvOK(dsn)) {
        AV *ca = newAV();
        av_push(ca, newSVsv(dsn));
        av_push(ca, (user && SvOK(user)) ? newSVsv(user) : newSV(0));
        av_push(ca, (pass && SvOK(pass)) ? newSVsv(pass) : newSV(0));
        av_push(ca, (attr && SvROK(attr)) ? newSVsv(attr) : newSV(0));
        (void)hv_stores(self, "connect_args", newRV_noinc((SV *)ca));
    }
    return sv_bless(newRV_noinc((SV *)self),
                    gv_stashpv(cls && *cls ? cls : "DBIx::Loop", GV_ADD));
}

/* get-or-create the worker pool for this object (cached as _pool IV).
 *
 * Every path to the pool - exec and txn alike - comes through here, so this is
 * where fork is caught. A cached pool that belongs to another process was
 * inherited across a fork: using it would have two processes reading one
 * socketpair, so it is disowned (fds closed, workers left alone) and a fresh
 * pool is forked for this process. */
static dbil_pool *dbil_pool_of(pTHX_ SV *self, SV *cargs) {
    HV  *h  = (HV *)SvRV(self);
    SV **pp = hv_fetchs(h, "_pool", 0);
    dbil_pool *p;
    if (pp && *pp && SvIOK(*pp)) {
        p = INT2PTR(dbil_pool *, SvIV(*pp));
        if (dbil_pool_owned(p)) return p;
        dbil_pool_disown(aTHX_ p);
        (void)hv_delete(h, "_pool", 5, G_DISCARD);
    }
    {
        SV *loop = dbil_field(aTHX_ self, "loop", 4);
        SV *wv   = dbil_field(aTHX_ self, "workers", 7);
        SV *mq   = dbil_field(aTHX_ self, "max_queue", 9);
        int nw   = (wv && SvIOK(wv)) ? (int)SvIV(wv) : 4;
        p = dbil_pool_new(aTHX_ loop, cargs, nw);
        p->max_queue = (mq && SvIOK(mq)) ? (int)SvIV(mq) : 0;
        (void)hv_stores(h, "_pool", newSViv(PTR2IV(p)));
    }
    return p;
}

/* get-or-create the native connection state (cached as _native IV) */
static dbil_native *dbil_native_of(pTHX_ SV *self) {
    HV  *h  = (HV *)SvRV(self);
    SV **pp = hv_fetchs(h, "_native", 0);
    dbil_native *nc;
    if (pp && *pp && SvIOK(*pp)) {
        nc = INT2PTR(dbil_native *, SvIV(*pp));
        if (dbil_native_owned(nc)) return nc;
        /* inherited across a fork: the libpq socket is the parent's */
        dbil_native_disown(aTHX_ nc);
        (void)hv_delete(h, "_native", 7, G_DISCARD);
    }
    nc = dbil_native_new(aTHX_ dbil_field(aTHX_ self, "dbh", 3),
                               dbil_field(aTHX_ self, "loop", 4));
    (void)hv_stores(h, "_native", newSViv(PTR2IV(nc)));
    return nc;
}

/* build a future, run the statement, settle it; return the future (+1).
 * 'native' -> the fd-async backend (Pg); 'pool' with connect args -> the
 * forked worker pool; otherwise the synchronous path (a bare dbh). */
static SV *dbil_exec(pTHX_ SV *self, int is_query, SV *sql, AV *bind) {
    SV *cap   = dbil_field(aTHX_ self, "capability", 10);
    SV *cargs = dbil_field(aTHX_ self, "connect_args", 12);
    SV *dbh, *fut, *err = NULL, *res;
    /* v2 observers. Fired here, once, because this is the only place all
     * three backends have in common - and attached to whatever comes back, so
     * none of them has to know it is being watched. */
    dbil_obs_tokens *obs = dbil_obs_start(aTHX_ is_query, sql, bind);

    if (cap && SvPOK(cap) && strEQ(SvPVX(cap), "native")) {
        dbil_native *nc = dbil_native_of(aTHX_ self);
        fut = dbil_native_run(aTHX_ nc, is_query, sql, bind);
        dbil_obs_attach(aTHX_ fut, obs);
        return fut;
    }

    if (cap && SvPOK(cap) && strEQ(SvPVX(cap), "pool")
        && cargs && SvROK(cargs)) {
        dbil_pool *p = dbil_pool_of(aTHX_ self, cargs);
        fut = dbil_pool_run(aTHX_ p, is_query, sql, bind);
        dbil_obs_attach(aTHX_ fut, obs);
        return fut;
    }

    dbh = dbil_field(aTHX_ self, "dbh", 3);
    fut = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    if (!dbh || !SvROK(dbh)) {
        dbil_future_settle_fail(aTHX_ fut, sv_2mortal(newSVpvs("no database handle")));
        dbil_obs_attach(aTHX_ fut, obs);
        return fut;
    }
    res = dbil_run_dbi(aTHX_ dbh, is_query, sql, bind, &err);
    if (res) dbil_future_settle_done1(aTHX_ fut, res);
    else     dbil_future_settle_fail(aTHX_ fut,
                 err ? err : sv_2mortal(newSVpvs("query failed")));
    dbil_obs_attach(aTHX_ fut, obs);
    return fut;
}

#endif /* DBIL_LOOP_H */
