#ifndef DBIL_ABI_IMPL_H
#define DBIL_ABI_IMPL_H

/* Provider side of the public C ABI (dbil_abi.h): thin wrappers translating
 * the stable table entries onto the dbil_* internals, plus the filled table
 * itself and a selftest that drives it end to end. Consumers reach it via
 * DBIx::Loop::_abi_ptr (xs/abi.xs).
 *
 * Include after dbil_future.h, dbil_pool.h (for the magic-CV closures) and
 * dbil_loop.h (for dbil_new / dbil_exec). */

/* The public shape numbers are the internal ones. Checked here rather than
 * trusted, because dbil_abi.h ships to consumers and the two sets are edited
 * in different files. */
#if DBIL_ABI_ALL_ARRAYREF != DBIL_T_ALL_ARRAYREF \
 || DBIL_ABI_ROW_ARRAYREF != DBIL_T_ROW_ARRAYREF \
 || DBIL_ABI_ROW_ARRAY    != DBIL_T_ROW_ARRAY    \
 || DBIL_ABI_ROW_HASHREF  != DBIL_T_ROW_HASHREF  \
 || DBIL_ABI_COL_ARRAYREF != DBIL_T_COL_ARRAYREF \
 || DBIL_ABI_ALL_HASHREF  != DBIL_T_ALL_HASHREF  \
 || DBIL_ABI_ALL_ROWHASH  != DBIL_T_ALL_ROWHASH
#  error "dbil_abi.h shape constants have drifted from dbil_future.h"
#endif

/* the future struct without the croak, so is_future can answer for any SV */
static dbil_future *dbil_future_peek(pTHX_ SV *sv) {
    MAGIC *mg;
    if (!sv || !SvROK(sv)) return NULL;
    mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &dbil_future_vtbl);
    return mg ? (dbil_future *)mg->mg_ptr : NULL;
}

static int dbil_abi_is_future(pTHX_ SV *sv) {
    return dbil_future_peek(aTHX_ sv) != NULL;
}

static IV dbil_abi_future_state(pTHX_ SV *f) {
    dbil_future *p = dbil_future_peek(aTHX_ f);
    return p ? (IV)p->state : (IV)DBIL_ABI_PENDING;
}

/* borrowed values of a done future, into the caller's array */
static SSize_t dbil_abi_future_values(pTHX_ SV *f, SV **out, SSize_t max) {
    dbil_future *p = dbil_future_peek(aTHX_ f);
    AV *res;
    SSize_t i, n;
    if (!p || p->state != 1 || !p->result || !SvROK(p->result)) return 0;
    res = (AV *)SvRV(p->result);
    n   = av_len(res) + 1;
    if (n > max) n = max;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(res, i, 0);
        out[i] = (e && *e) ? *e : &PL_sv_undef;
    }
    return n;
}

static SV *dbil_abi_future_error(pTHX_ SV *f) {
    dbil_future *p = dbil_future_peek(aTHX_ f);
    return (p && p->state == 2) ? p->error : NULL;
}

static SV *dbil_abi_future_new(pTHX) {
    return dbil_future_new(aTHX_ "DBIx::Loop::Future");
}

static void dbil_abi_future_done1(pTHX_ SV *f, SV *val) {
    dbil_future_settle_done1(aTHX_ f, val);
}

static void dbil_abi_future_fail(pTHX_ SV *f, SV *err) {
    dbil_future_settle_fail(aTHX_ f, err);
}

/* on_ready continuation body: unbox the C fn + ud from the closure captures
 * and call it with the future (ST(0), pushed by the fire loop). */
XS_INTERNAL(dbil_xs_abi_ready_cb);
XS_INTERNAL(dbil_xs_abi_ready_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    SV **fn, **ud;
    if (!cap || items < 1) XSRETURN_EMPTY;
    fn = av_fetch(cap, 0, 0);
    ud = av_fetch(cap, 1, 0);
    if (!(fn && *fn)) XSRETURN_EMPTY;
    ((dbil_abi_ready_cb)INT2PTR(void *, SvIV(*fn)))
        (aTHX_ ST(0), (ud && *ud) ? INT2PTR(void *, SvIV(*ud)) : NULL);
    XSRETURN_EMPTY;
}

static void dbil_abi_future_on_ready(pTHX_ SV *f, dbil_abi_ready_cb cb,
                                     void *ud) {
    dbil_future *p = dbil_future_peek(aTHX_ f);
    if (!p || !cb) return;
    /* already settled: fire now, as on_ready does, and never queue */
    if (p->state) { cb(aTHX_ f, ud); return; }
    {
        AV *cap = newAV();
        SV *cv;
        av_push(cap, newSViv(PTR2IV(cb)));
        av_push(cap, newSViv(PTR2IV(ud)));
        cv = dbil_closure(aTHX_ dbil_xs_abi_ready_cb, cap);
        av_push(p->cbs, cv);      /* the queue owns it */
    }
}

static SV *dbil_abi_reshape(pTHX_ int shape, SV *result, SV *arg, AV *out) {
    return dbil_then_builtin(aTHX_ (IV)shape, result, arg, out);
}

static SV *dbil_abi_exec(pTHX_ SV *db, int is_query, SV *sql, AV *bind) {
    return dbil_exec(aTHX_ db, is_query, sql, bind);
}

/* query + one builtin reshape as a single call: the intermediate future is
 * still built (the reshape has to run when the rows land, not now), but no
 * Perl closure is compiled and no Perl frame runs on the settle path. */
static SV *dbil_abi_exec_shaped(pTHX_ SV *db, SV *sql, AV *bind,
                                int shape, SV *arg) {
    SV *qf   = sv_2mortal(dbil_exec(aTHX_ db, 1, sql, bind));
    SV *next = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    dbil_then_attach4(aTHX_ qf, next, sv_2mortal(newSViv((IV)shape)),
                      NULL, arg);
    return next;
}

/* Call a class method with `n` already-mortal args, under eval. Returns the
 * result (+1) or NULL with *err set (+1). The boot paths (connect, adapter)
 * use this so a consumer gets an error SV to fall back on rather than a
 * croak through its own boot code. */
static SV *dbil_abi_try_method(pTHX_ const char *cls, const char *meth,
                               SV **args, int n, SV **err) {
    dSP;
    int count;
    SV *out = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, n + 1);
    mPUSHp(cls, strlen(cls));
    { int i; for (i = 0; i < n; i++) PUSHs(args[i]); }
    PUTBACK;
    count = call_method(meth, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        /* NOT mortal: FREETMPS below would free it before the caller reads it */
        if (err) *err = newSVpv(SvPV_nolen(ERRSV), 0);
        if (count > 0) (void)POPs;
    }
    else if (count > 0) {
        SV *r = POPs;
        if (SvOK(r)) out = newSVsv(r);
        else if (err) *err = newSVpvf("DBIx::Loop: %s->%s returned undef",
                                      cls, meth);
    }
    else if (err) *err = newSVpvf("DBIx::Loop: %s->%s returned nothing",
                                  cls, meth);
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

/* DBI->connect + dbil_new, without croaking. The DBI connect is irreducibly
 * DBI's Perl API; everything after it is C. */
static SV *dbil_abi_connect(pTHX_ SV *dsn, SV *user, SV *pass, SV *attr,
                            SV *adapter, int workers, int max_queue,
                            SV **err) {
    SV *args[4], *dbh, *self = NULL;
    if (err) *err = NULL;
    if (!adapter || !SvOK(adapter)) {
        if (err) *err = newSVpvs("DBIx::Loop: connect needs a loop adapter - "
                                 "DBIx::Loop is not an event loop, it runs "
                                 "on one");
        return NULL;
    }
    args[0] = dsn  ? dsn  : &PL_sv_undef;
    args[1] = user ? user : &PL_sv_undef;
    args[2] = pass ? pass : &PL_sv_undef;
    args[3] = attr ? attr : &PL_sv_undef;
    dbh = dbil_abi_try_method(aTHX_ "DBI", "connect", args, 4, err);
    if (!dbh) return NULL;

    /* dbil_new croaks on a handle that is not a reference. Check that here
     * rather than trapping the croak, so this entry keeps its no-croak
     * contract by never reaching the croak at all - a driver that returns
     * something odd becomes an error SV like any other failure. */
    if (!SvROK(dbh)) {
        if (err) *err = newSVpvs("DBIx::Loop: DBI->connect returned a "
                                 "non-reference");
        SvREFCNT_dec(dbh);
        return NULL;
    }
    self = dbil_new(aTHX_ "DBIx::Loop", dbh, adapter,
                    dsn, user, pass, attr, workers, max_queue);
    SvREFCNT_dec(dbh);
    return self;
}

/* The Hyperman adapter on a loop the caller names. Requiring the module here
 * rather than at boot keeps DBIx::Loop loadable without Hyperman. */
static SV *dbil_abi_hyperman_adapter(pTHX_ SV *loop_sv, SV **err) {
    SV *args[2];
    int n = 0;
    if (err) *err = NULL;
    if (!gv_stashpvs("DBIx::Loop::Loop::Hyperman", 0)) {
        eval_pv("require DBIx::Loop::Loop::Hyperman;", FALSE);
        if (SvTRUE(ERRSV)) {
            if (err) *err = newSVpv(SvPV_nolen(ERRSV), 0);
            return NULL;
        }
    }
    if (loop_sv && SvOK(loop_sv)) {
        args[0] = sv_2mortal(newSVpvs("loop"));
        args[1] = loop_sv;
        n = 2;
    }
    return dbil_abi_try_method(aTHX_ "DBIx::Loop::Loop::Hyperman", "new",
                               args, n, err);
}

static const dbil_abi dbil_abi_table = {
    DBIL_ABI_VERSION,
    dbil_abi_connect,
    dbil_abi_hyperman_adapter,
    dbil_abi_exec,
    dbil_abi_exec_shaped,
    dbil_abi_is_future,
    dbil_abi_future_state,
    dbil_abi_future_values,
    dbil_abi_future_error,
    dbil_abi_future_on_ready,
    dbil_abi_future_new,
    dbil_abi_future_done1,
    dbil_abi_future_fail,
    dbil_abi_reshape,
    dbil_obs_add,                /* v2 */
};

/* ---- the v2 observer, driven from C (t/13-observer.t) ------------------- *
 * A Perl test cannot register a C callback, so the observable half lives
 * here: the counters and the last statement seen. */
static IV  DBIL_OBS_ST_STARTS = 0;
static IV  DBIL_OBS_ST_DONES  = 0;
static IV  DBIL_OBS_ST_OK     = 0;
static IV  DBIL_OBS_ST_ERR    = 0;
static IV  DBIL_OBS_ST_BIND   = -1;
static IV  DBIL_OBS_ST_QUERY  = -1;
static char DBIL_OBS_ST_SQL[512];

static void *dbil_obs_st_start(pTHX_ int is_query, const char *sql,
                               STRLEN sql_len, int nbind, void *ud) {
    PERL_UNUSED_ARG(ud);
    PERL_UNUSED_CONTEXT;
    DBIL_OBS_ST_STARTS++;
    DBIL_OBS_ST_BIND  = nbind;
    DBIL_OBS_ST_QUERY = is_query;
    if (sql_len >= sizeof(DBIL_OBS_ST_SQL)) sql_len = sizeof(DBIL_OBS_ST_SQL) - 1;
    memcpy(DBIL_OBS_ST_SQL, sql, sql_len);
    DBIL_OBS_ST_SQL[sql_len] = '\0';
    return INT2PTR(void *, DBIL_OBS_ST_STARTS);
}

static void dbil_obs_st_done(pTHX_ void *token, SV *res, SV *err, void *ud) {
    PERL_UNUSED_ARG(ud);
    PERL_UNUSED_CONTEXT;
    DBIL_OBS_ST_DONES++;
    if (res) DBIL_OBS_ST_OK++;
    if (err) DBIL_OBS_ST_ERR++;
    if (PTR2IV(token) < 1 || PTR2IV(token) > DBIL_OBS_ST_STARTS)
        DBIL_OBS_ST_ERR = -1;      /* correlation broke */
}

static int dbil_obs_selftest_install(pTHX) {
    const dbil_abi *A = INT2PTR(const dbil_abi *, PTR2IV(&dbil_abi_table));
    if (!A || A->abi_version != DBIL_ABI_VERSION) return 0;
    return A->on_exec(aTHX_ dbil_obs_st_start, dbil_obs_st_done, NULL);
}

/* ---- _abi_selftest: drive the table from C (t/16-abi.t) ------------------ */

static void dbil_abi_st_ready(pTHX_ SV *f, void *ud) {
    PERL_UNUSED_VAR(f);
    *(int *)ud += 1;
}

/* a query result as the backends produce it: { rows => [[..]], columns => [] } */
static SV *dbil_abi_st_result(pTHX) {
    HV *h    = newHV();
    AV *rows = newAV();
    AV *cols = newAV();
    AV *r1   = newAV();
    AV *r2   = newAV();
    av_push(cols, newSVpvs("id"));
    av_push(cols, newSVpvs("v"));
    av_push(r1, newSViv(1)); av_push(r1, newSVpvs("one"));
    av_push(r2, newSViv(2)); av_push(r2, newSVpvs("two"));
    av_push(rows, newRV_noinc((SV *)r1));
    av_push(rows, newRV_noinc((SV *)r2));
    (void)hv_stores(h, "rows",    newRV_noinc((SV *)rows));
    (void)hv_stores(h, "columns", newRV_noinc((SV *)cols));
    return newRV_noinc((SV *)h);
}

static int dbil_abi_selftest(pTHX) {
    const dbil_abi *A = &dbil_abi_table;
    int ok = 1;
    if (A->abi_version != DBIL_ABI_VERSION) return 0;

    /* future lifecycle: new -> pending -> on_ready (C) -> done -> fired once */
    {
        SV *f = A->future_new(aTHX);
        int fired = 0;
        SV *val = sv_2mortal(newSViv(42));
        SV *vals[4];
        if (!A->is_future(aTHX_ f))                       ok = 0;
        if (A->future_state(aTHX_ f) != DBIL_ABI_PENDING) ok = 0;
        A->future_on_ready(aTHX_ f, dbil_abi_st_ready, &fired);
        A->future_done1(aTHX_ f, val);
        A->future_done1(aTHX_ f, val);      /* second settle: no-op */
        if (fired != 1)                                   ok = 0;
        if (A->future_state(aTHX_ f) != DBIL_ABI_DONE)    ok = 0;
        if (A->future_values(aTHX_ f, vals, 4) != 1)      ok = 0;
        else if (SvIV(vals[0]) != 42)                     ok = 0;
        if (A->future_error(aTHX_ f) != NULL)             ok = 0;

        /* on_ready on an ALREADY settled future fires immediately */
        A->future_on_ready(aTHX_ f, dbil_abi_st_ready, &fired);
        if (fired != 2)                                   ok = 0;
        SvREFCNT_dec(f);
    }

    /* failure path */
    {
        SV *f = A->future_new(aTHX);
        SV *err = sv_2mortal(newSVpvs("nope"));
        SV *vals[2];
        A->future_fail(aTHX_ f, err);
        if (A->future_state(aTHX_ f) != DBIL_ABI_FAILED)  ok = 0;
        if (A->future_values(aTHX_ f, vals, 2) != 0)      ok = 0;
        if (!A->future_error(aTHX_ f))                    ok = 0;
        else if (strNE(SvPV_nolen(A->future_error(aTHX_ f)), "nope")) ok = 0;
        SvREFCNT_dec(f);
    }

    /* is_future never dereferences what it was handed */
    {
        if (A->is_future(aTHX_ &PL_sv_undef))             ok = 0;
        if (A->is_future(aTHX_ sv_2mortal(newSViv(7))))   ok = 0;
        if (A->is_future(aTHX_ sv_2mortal(newRV_noinc((SV *)newHV())))) ok = 0;
    }

    /* every reshape, against one synthetic result */
    {
        SV *res = sv_2mortal(dbil_abi_st_result(aTHX));
        AV *out = (AV *)sv_2mortal((SV *)newAV());
        SV *e;

        /* ALL_ARRAYREF: two rows */
        e = A->reshape(aTHX_ DBIL_ABI_ALL_ARRAYREF, res, NULL, out);
        if (e) { ok = 0; SvREFCNT_dec(e); }
        else {
            SV **v = av_fetch(out, 0, 0);
            if (!(v && *v && SvROK(*v) && av_len((AV *)SvRV(*v)) == 1)) ok = 0;
        }
        av_clear(out);

        /* ROW_HASHREF: the first row by name */
        e = A->reshape(aTHX_ DBIL_ABI_ROW_HASHREF, res, NULL, out);
        if (e) { ok = 0; SvREFCNT_dec(e); }
        else {
            SV **v = av_fetch(out, 0, 0);
            SV **c = (v && *v && SvROK(*v))
                   ? hv_fetchs((HV *)SvRV(*v), "v", 0) : NULL;
            if (!(c && *c && strEQ(SvPV_nolen(*c), "one"))) ok = 0;
        }
        av_clear(out);

        /* ROW_ARRAY: the first row as a list of two */
        e = A->reshape(aTHX_ DBIL_ABI_ROW_ARRAY, res, NULL, out);
        if (e) { ok = 0; SvREFCNT_dec(e); }
        else if (av_len(out) != 1) ok = 0;
        av_clear(out);

        /* COL_ARRAYREF: the first column of both rows */
        e = A->reshape(aTHX_ DBIL_ABI_COL_ARRAYREF, res, NULL, out);
        if (e) { ok = 0; SvREFCNT_dec(e); }
        else {
            SV **v = av_fetch(out, 0, 0);
            if (!(v && *v && SvROK(*v) && av_len((AV *)SvRV(*v)) == 1)) ok = 0;
        }
        av_clear(out);

        /* ALL_HASHREF without a key field fails rather than croaking */
        e = A->reshape(aTHX_ DBIL_ABI_ALL_HASHREF, res, NULL, out);
        if (!e) ok = 0; else SvREFCNT_dec(e);
        av_clear(out);

        /* ALL_HASHREF naming a column that is not there, likewise */
        e = A->reshape(aTHX_ DBIL_ABI_ALL_HASHREF, res,
                       sv_2mortal(newSVpvs("nope")), out);
        if (!e) ok = 0; else SvREFCNT_dec(e);
        av_clear(out);

        /* ALL_HASHREF keyed by id */
        e = A->reshape(aTHX_ DBIL_ABI_ALL_HASHREF, res,
                       sv_2mortal(newSVpvs("id")), out);
        if (e) { ok = 0; SvREFCNT_dec(e); }
        else {
            SV **v = av_fetch(out, 0, 0);
            if (!(v && *v && SvROK(*v)
                  && HvUSEDKEYS((HV *)SvRV(*v)) == 2)) ok = 0;
        }
        av_clear(out);

        /* ALL_ROWHASH: both rows as hashrefs, in order */
        e = A->reshape(aTHX_ DBIL_ABI_ALL_ROWHASH, res, NULL, out);
        if (e) { ok = 0; SvREFCNT_dec(e); }
        else {
            SV **v = av_fetch(out, 0, 0);
            if (!(v && *v && SvROK(*v) && av_len((AV *)SvRV(*v)) == 1)) ok = 0;
            else {
                AV  *a  = (AV *)SvRV(*v);
                SV **r0 = av_fetch(a, 0, 0);
                SV **r1 = av_fetch(a, 1, 0);
                SV **c0 = (r0 && *r0 && SvROK(*r0))
                        ? hv_fetchs((HV *)SvRV(*r0), "v", 0) : NULL;
                SV **c1 = (r1 && *r1 && SvROK(*r1))
                        ? hv_fetchs((HV *)SvRV(*r1), "v", 0) : NULL;
                if (!(c0 && *c0 && strEQ(SvPV_nolen(*c0), "one"))) ok = 0;
                if (!(c1 && *c1 && strEQ(SvPV_nolen(*c1), "two"))) ok = 0;
            }
        }
        av_clear(out);
    }

    /* connect refuses to croak: no adapter is an error SV, not a die */
    {
        SV *err = NULL;
        SV *db  = A->connect(aTHX_ sv_2mortal(newSVpvs("dbi:NoSuch:")),
                             NULL, NULL, NULL, NULL, 0, 0, &err);
        if (db) { ok = 0; SvREFCNT_dec(db); }
        if (!err) ok = 0; else SvREFCNT_dec(err);
    }

    /* and a dsn no driver can serve fails the same way */
    {
        SV *err = NULL;
        SV *db  = A->connect(aTHX_ sv_2mortal(newSVpvs("dbi:NoSuchDriver:x")),
                             NULL, NULL, NULL,
                             sv_2mortal(newSVpvs("not-an-adapter")),
                             0, 0, &err);
        if (db) { ok = 0; SvREFCNT_dec(db); }
        if (!err) ok = 0; else SvREFCNT_dec(err);
    }

    return ok;
}

/* ---- _abi_dbtest: the table against a real database ---------------------- *
 * The selftest above covers the table's own arithmetic; this drives it end to
 * end - connect, exec, exec_shaped, a C on_ready that fires when rows land,
 * and the failure path - against whatever dsn and loop adapter the test hands
 * in. Everything below the await is C: no Perl frame runs when a result
 * settles, which is the entire point of the table. */

static void dbil_abi_await(pTHX_ SV *adapter, SV *f) {
    dSP;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 2); PUSHs(adapter); PUSHs(f); PUTBACK;
    (void)call_method("await", G_VOID | G_DISCARD | G_EVAL);
    SPAGAIN; PUTBACK; FREETMPS; LEAVE;
}

/* run one statement to completion; 1 if it settled done */
static int dbil_abi_dbt_do(pTHX_ const dbil_abi *A, SV *adapter, SV *db,
                           const char *sql) {
    SV *f = A->exec(aTHX_ db, 0, sv_2mortal(newSVpv(sql, 0)), NULL);
    int ok;
    dbil_abi_await(aTHX_ adapter, f);
    ok = (A->future_state(aTHX_ f) == DBIL_ABI_DONE);
    SvREFCNT_dec(f);
    return ok;
}

static int dbil_abi_dbtest(pTHX_ SV *adapter, SV *dsn) {
    const dbil_abi *A = &dbil_abi_table;
    SV *err = NULL, *db, *attr;
    int ok = 1, fired = 0;

    {   /* RaiseError so a failure reaches the future, PrintError off so the
         * deliberate bad query below does not write to the test's stderr */
        HV *a = newHV();
        (void)hv_stores(a, "RaiseError", newSViv(1));
        (void)hv_stores(a, "PrintError", newSViv(0));
        attr = sv_2mortal(newRV_noinc((SV *)a));
    }
    db = A->connect(aTHX_ dsn, NULL, NULL,
                    attr, adapter, 2, 0, &err);
    if (!db) {
        if (err) SvREFCNT_dec(err);
        return 0;
    }

    if (!dbil_abi_dbt_do(aTHX_ A, adapter, db,
            "CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)")) ok = 0;
    if (!dbil_abi_dbt_do(aTHX_ A, adapter, db,
            "INSERT INTO t (id, v) VALUES (1, 'one')"))         ok = 0;
    if (!dbil_abi_dbt_do(aTHX_ A, adapter, db,
            "INSERT INTO t (id, v) VALUES (2, 'two')"))         ok = 0;

    /* exec_shaped + a C on_ready: rows arrive already reshaped */
    {
        SV *f = A->exec_shaped(aTHX_ db,
                    sv_2mortal(newSVpvs("SELECT id, v FROM t ORDER BY id")),
                    NULL, DBIL_ABI_ALL_ROWHASH, NULL);
        SV *vals[2];
        A->future_on_ready(aTHX_ f, dbil_abi_st_ready, &fired);
        dbil_abi_await(aTHX_ adapter, f);
        if (fired != 1)                                ok = 0;
        if (A->future_state(aTHX_ f) != DBIL_ABI_DONE) ok = 0;
        else if (A->future_values(aTHX_ f, vals, 2) != 1) ok = 0;
        else if (!(SvROK(vals[0]) && av_len((AV *)SvRV(vals[0])) == 1)) ok = 0;
        else {
            SV **r0 = av_fetch((AV *)SvRV(vals[0]), 0, 0);
            SV **c  = (r0 && *r0 && SvROK(*r0))
                    ? hv_fetchs((HV *)SvRV(*r0), "v", 0) : NULL;
            if (!(c && *c && strEQ(SvPV_nolen(*c), "one"))) ok = 0;
        }
        SvREFCNT_dec(f);
    }

    /* a bind value, and the single-row shape */
    {
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        SV *f, *vals[2];
        av_push(bind, newSViv(2));
        f = A->exec_shaped(aTHX_ db,
                sv_2mortal(newSVpvs("SELECT id, v FROM t WHERE id = ?")),
                bind, DBIL_ABI_ROW_HASHREF, NULL);
        dbil_abi_await(aTHX_ adapter, f);
        if (A->future_state(aTHX_ f) != DBIL_ABI_DONE)    ok = 0;
        else if (A->future_values(aTHX_ f, vals, 2) != 1) ok = 0;
        else {
            SV **c = SvROK(vals[0])
                   ? hv_fetchs((HV *)SvRV(vals[0]), "v", 0) : NULL;
            if (!(c && *c && strEQ(SvPV_nolen(*c), "two"))) ok = 0;
        }
        SvREFCNT_dec(f);
    }

    /* the failure path carries an error rather than croaking out of settle */
    {
        SV *f = A->exec(aTHX_ db, 1,
                    sv_2mortal(newSVpvs("SELECT * FROM no_such_table")), NULL);
        dbil_abi_await(aTHX_ adapter, f);
        if (A->future_state(aTHX_ f) != DBIL_ABI_FAILED) ok = 0;
        if (!A->future_error(aTHX_ f))                   ok = 0;
        SvREFCNT_dec(f);
    }

    {   /* tear the pool down deterministically rather than at destruction */
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(db); PUTBACK;
        (void)call_method("disconnect", G_VOID | G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    }
    SvREFCNT_dec(db);
    return ok;
}

#endif /* DBIL_ABI_IMPL_H */
