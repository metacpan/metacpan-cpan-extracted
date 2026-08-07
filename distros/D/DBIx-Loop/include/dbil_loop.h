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

/* get-or-create the worker pool for this object (cached as _pool IV) */
static dbil_pool *dbil_pool_of(pTHX_ SV *self, SV *cargs) {
    HV  *h  = (HV *)SvRV(self);
    SV **pp = hv_fetchs(h, "_pool", 0);
    dbil_pool *p;
    if (pp && *pp && SvIOK(*pp)) return INT2PTR(dbil_pool *, SvIV(*pp));
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
    if (pp && *pp && SvIOK(*pp)) return INT2PTR(dbil_native *, SvIV(*pp));
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

    if (cap && SvPOK(cap) && strEQ(SvPVX(cap), "native")) {
        dbil_native *nc = dbil_native_of(aTHX_ self);
        return dbil_native_run(aTHX_ nc, is_query, sql, bind);
    }

    if (cap && SvPOK(cap) && strEQ(SvPVX(cap), "pool")
        && cargs && SvROK(cargs)) {
        dbil_pool *p = dbil_pool_of(aTHX_ self, cargs);
        return dbil_pool_run(aTHX_ p, is_query, sql, bind);
    }

    dbh = dbil_field(aTHX_ self, "dbh", 3);
    fut = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    if (!dbh || !SvROK(dbh)) {
        dbil_future_settle_fail(aTHX_ fut, sv_2mortal(newSVpvs("no database handle")));
        return fut;
    }
    res = dbil_run_dbi(aTHX_ dbh, is_query, sql, bind, &err);
    if (res) dbil_future_settle_done1(aTHX_ fut, res);
    else     dbil_future_settle_fail(aTHX_ fut,
                 err ? err : sv_2mortal(newSVpvs("query failed")));
    return fut;
}

#endif /* DBIL_LOOP_H */
