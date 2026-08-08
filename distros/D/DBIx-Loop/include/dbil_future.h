#ifndef DBIL_FUTURE_H
#define DBIL_FUTURE_H

/* DBIx::Loop::Future - the canonical future, in C.
 *
 * A pending future carries a queue of on_ready callbacks. It settles exactly
 * once: done() stores an arrayref of result values, fail() stores an error SV;
 * either fires and then clears the queue (one-shot). The struct hangs off a
 * blessed scalar via ext magic, freed in the magic-free hook - no DESTROY
 * needed.
 *
 * Chaining (then/else) is C too. A continuation is not a Perl closure: it is a
 * plain AV of [ next, on_done, on_fail ] pushed onto the same queue, and the
 * fire loop tells the two apart by type - on_ready only ever accepts a
 * coderef, so an AV in the queue is unambiguously ours. That means a `then`
 * costs one array rather than a compiled closure, and settling a chain runs no
 * Perl frame except the user's own callbacks. */

typedef struct dbil_future {
    int  state;      /* 0 pending, 1 done, 2 failed          */
    SV  *result;     /* done: an arrayref of values (+1)      */
    SV  *error;      /* failed: the error SV (+1)             */
    AV  *cbs;        /* pending on_ready coderefs (+1 each)   */
} dbil_future;

static int dbil_future_free(pTHX_ SV *sv, MAGIC *mg) {
    dbil_future *f = (dbil_future *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (f) {
        if (f->result) SvREFCNT_dec(f->result);
        if (f->error)  SvREFCNT_dec(f->error);
        if (f->cbs)    SvREFCNT_dec((SV *)f->cbs);
        Safefree(f);
    }
    return 0;
}
static MGVTBL dbil_future_vtbl =
    { NULL, NULL, NULL, NULL, dbil_future_free, NULL, NULL, NULL };

/* the struct behind a DBIx::Loop::Future object, or croak */
static dbil_future *dbil_future_of(pTHX_ SV *self) {
    MAGIC *mg;
    if (!SvROK(self)) croak("DBIx::Loop::Future: not an object");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &dbil_future_vtbl);
    if (!mg) croak("DBIx::Loop::Future: not a DBIx::Loop::Future");
    return (dbil_future *)mg->mg_ptr;
}

/* new pending future, blessed into `class` (RV +1) */
static SV *dbil_future_new(pTHX_ const char *class) {
    dbil_future *f;
    SV *inner, *rv;
    Newxz(f, 1, dbil_future);
    f->cbs = newAV();
    inner  = newSV(0);
    sv_magicext(inner, NULL, PERL_MAGIC_ext, &dbil_future_vtbl, (char *)f, 0);
    rv = newRV_noinc(inner);
    sv_bless(rv, gv_stashpv(class && *class ? class : "DBIx::Loop::Future",
                            GV_ADD));
    return rv;
}

/* settle a future from C (no XSUB round-trip): done with a single value, or
 * failed with an error SV. Both are no-ops if already settled. `fire` runs
 * the on_ready queue. */
static void dbil_future_fire(pTHX_ SV *self, dbil_future *f);   /* below */
static void dbil_then_run(pTHX_ SV *self, dbil_future *f, AV *k);

/* Builtin result transforms. The DBI select* family is a fixed set of reshapes
 * of one query result, so instead of each being a Perl closure the handler
 * slot may hold one of these integers and the reshape happens in C. A
 * continuation is [ next, on_done, on_fail, arg ]: a handler that is a
 * reference is a coderef, one that is a plain integer is a builtin, and `arg`
 * carries whatever that builtin needs (the key field, for ALL_HASHREF). */
#define DBIL_T_ALL_ARRAYREF 1
#define DBIL_T_ROW_ARRAYREF 2
#define DBIL_T_ROW_ARRAY    3
#define DBIL_T_ROW_HASHREF  4
#define DBIL_T_COL_ARRAYREF 5
#define DBIL_T_ALL_HASHREF  6
/* ALL_ROWHASH is DBI's selectall_arrayref($sql, { Slice => {} }): every row as
 * a hashref, in the order the server returned them. ALL_HASHREF cannot stand
 * in for it - keying by a column destroys the ordering, which breaks keyset
 * pagination - so this is a genuinely missing member of the select* family
 * rather than a convenience over one. */
#define DBIL_T_ALL_ROWHASH  7

/* settle done from a list of values (copied, so the caller keeps its own) */
static void dbil_future_settle_done_av(pTHX_ SV *self, AV *vals) {
    dbil_future *f = dbil_future_of(aTHX_ self);
    AV *res;
    SSize_t i, n;
    if (f->state) return;
    res = newAV();
    n = vals ? av_len(vals) + 1 : 0;
    for (i = 0; i < n; i++) {
        SV **v = av_fetch(vals, i, 0);
        av_push(res, newSVsv(v && *v ? *v : &PL_sv_undef));
    }
    f->result = newRV_noinc((SV *)res);
    f->state  = 1;
    dbil_future_fire(aTHX_ self, f);
}

static void dbil_future_settle_done1(pTHX_ SV *self, SV *val) {
    dbil_future *f = dbil_future_of(aTHX_ self);
    AV *res;
    if (f->state) return;
    res = newAV();
    av_push(res, newSVsv(val));
    f->result = newRV_noinc((SV *)res);
    f->state  = 1;
    dbil_future_fire(aTHX_ self, f);
}

static void dbil_future_settle_fail(pTHX_ SV *self, SV *err) {
    dbil_future *f = dbil_future_of(aTHX_ self);
    if (f->state) return;
    f->error = newSVsv(err);
    f->state = 2;
    dbil_future_fire(aTHX_ self, f);
}

/* Attach a continuation to `target`: when it settles, run $on_done or
 * $on_fail and settle `next` with the result. An already-settled target runs
 * it now rather than queueing it, exactly as on_ready does.
 *
 * With both callbacks undef this is adoption - done passes the values
 * through, fail passes the error through - which is how a callback that
 * returns a future is flattened, with no second code path. */
static void dbil_then_attach4(pTHX_ SV *target, SV *next,
                              SV *on_done, SV *on_fail, SV *arg) {
    dbil_future *tf = dbil_future_of(aTHX_ target);
    AV *k = newAV();
    av_push(k, newSVsv(next));
    av_push(k, (on_done && SvOK(on_done)) ? newSVsv(on_done) : newSV(0));
    av_push(k, (on_fail && SvOK(on_fail)) ? newSVsv(on_fail) : newSV(0));
    av_push(k, (arg     && SvOK(arg))     ? newSVsv(arg)     : newSV(0));
    if (tf->state) {
        dbil_then_run(aTHX_ target, tf, k);
        SvREFCNT_dec((SV *)k);
    }
    else av_push(tf->cbs, newRV_noinc((SV *)k));
}

static void dbil_then_attach(pTHX_ SV *target, SV *next,
                             SV *on_done, SV *on_fail) {
    dbil_then_attach4(aTHX_ target, next, on_done, on_fail, NULL);
}

/* One of the DBI select* reshapes, applied to a query result hashref. Pushes
 * the values to settle the next future with onto `out`.
 *
 * Returns an error SV (+1) instead of croaking: in the Perl these reshapes ran
 * inside then's eval, so a bad key field produced a FAILED FUTURE rather than
 * a die at settle time. Croaking from here would escape through whatever
 * settled the query future, which is a different thing entirely. */
/* one row (an AV of values) against the column names, as a fresh HV (+1) */
static HV *dbil_row_to_hv(pTHX_ AV *ra, AV *cols) {
    HV *h = newHV();
    SSize_t j, ncol = cols ? av_len(cols) + 1 : 0;
    for (j = 0; j < ncol; j++) {
        SV **c = av_fetch(cols, j, 0);
        SV **v = av_fetch(ra, j, 0);
        STRLEN cl;
        const char *cp;
        if (!(c && *c)) continue;
        cp = SvPV_const(*c, cl);
        (void)hv_store(h, cp, (I32)cl, newSVsv(v && *v ? *v : &PL_sv_undef), 0);
    }
    return h;
}

static SV *dbil_then_builtin(pTHX_ IV op, SV *res, SV *arg, AV *out) {
    HV  *r;
    SV **e;
    AV  *rows = NULL, *cols = NULL;

    if (!(res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVHV)) {
        av_push(out, newSV(0));
        return NULL;
    }
    r = (HV *)SvRV(res);
    if ((e = hv_fetchs(r, "rows", 0)) && *e && SvROK(*e)
        && SvTYPE(SvRV(*e)) == SVt_PVAV) rows = (AV *)SvRV(*e);
    if ((e = hv_fetchs(r, "columns", 0)) && *e && SvROK(*e)
        && SvTYPE(SvRV(*e)) == SVt_PVAV) cols = (AV *)SvRV(*e);

    switch (op) {
    case DBIL_T_ALL_ARRAYREF:
        av_push(out, rows ? newRV_inc((SV *)rows) : newSV(0));
        break;

    case DBIL_T_ROW_ARRAYREF: {
        SV **row = rows ? av_fetch(rows, 0, 0) : NULL;
        av_push(out, (row && *row) ? newSVsv(*row) : newSV(0));
        break;
    }

    case DBIL_T_ROW_ARRAY: {   /* the first row as a list, or the empty list */
        SV **row = rows ? av_fetch(rows, 0, 0) : NULL;
        if (row && *row && SvROK(*row) && SvTYPE(SvRV(*row)) == SVt_PVAV) {
            AV *ra = (AV *)SvRV(*row);
            SSize_t i, n = av_len(ra) + 1;
            for (i = 0; i < n; i++) {
                SV **v = av_fetch(ra, i, 0);
                av_push(out, newSVsv(v && *v ? *v : &PL_sv_undef));
            }
        }
        break;
    }

    case DBIL_T_ROW_HASHREF: {
        SV **row = rows ? av_fetch(rows, 0, 0) : NULL;
        if (!(row && *row && SvROK(*row) && cols)) { av_push(out, newSV(0)); break; }
        av_push(out, newRV_noinc(
            (SV *)dbil_row_to_hv(aTHX_ (AV *)SvRV(*row), cols)));
        break;
    }

    /* every row as a hashref, order preserved */
    case DBIL_T_ALL_ROWHASH: {
        AV *o = newAV();
        SSize_t i, n = rows ? av_len(rows) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **row = av_fetch(rows, i, 0);
            if (!(row && *row && SvROK(*row) && SvTYPE(SvRV(*row)) == SVt_PVAV))
                continue;
            av_push(o, newRV_noinc(
                (SV *)dbil_row_to_hv(aTHX_ (AV *)SvRV(*row), cols)));
        }
        av_push(out, newRV_noinc((SV *)o));
        break;
    }

    case DBIL_T_COL_ARRAYREF: {
        AV *o = newAV();
        SSize_t i, n = rows ? av_len(rows) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **row = av_fetch(rows, i, 0);
            SV **v   = (row && *row && SvROK(*row)
                        && SvTYPE(SvRV(*row)) == SVt_PVAV)
                     ? av_fetch((AV *)SvRV(*row), 0, 0) : NULL;
            av_push(o, newSVsv(v && *v ? *v : &PL_sv_undef));
        }
        av_push(out, newRV_noinc((SV *)o));
        break;
    }

    case DBIL_T_ALL_HASHREF: {
        HV *o = newHV();
        SSize_t i, n = rows ? av_len(rows) + 1 : 0;
        SSize_t ncol = cols ? av_len(cols) + 1 : 0;
        SSize_t ki = -1, j;
        STRLEN keylen;
        const char *key = (arg && SvOK(arg)) ? SvPV_const(arg, keylen) : NULL;
        if (!key) {
            SvREFCNT_dec((SV *)o);
            return newSVpvs("DBIx::Loop->selectall_hashref: "
                            "a key field is required");
        }
        for (j = 0; j < ncol; j++) {
            SV **c = av_fetch(cols, j, 0);
            STRLEN cl;
            const char *cp;
            if (!(c && *c)) continue;
            cp = SvPV_const(*c, cl);
            if (cl == keylen && memEQ(cp, key, cl)) { ki = j; break; }
        }
        if (ki < 0) {
            SV *err = newSVpvs("DBIx::Loop->selectall_hashref: no such column '");
            sv_catpvn(err, key, keylen);
            sv_catpvs(err, "'");
            SvREFCNT_dec((SV *)o);
            return err;
        }
        for (i = 0; i < n; i++) {
            SV **row = av_fetch(rows, i, 0);
            AV *ra;
            HV *h;
            SV **kv;
            if (!(row && *row && SvROK(*row) && SvTYPE(SvRV(*row)) == SVt_PVAV))
                continue;
            ra = (AV *)SvRV(*row);
            h  = dbil_row_to_hv(aTHX_ ra, cols);
            kv = av_fetch(ra, ki, 0);
            if (kv && *kv) {
                STRLEN kl2;
                const char *kp2 = SvPV_const(*kv, kl2);
                (void)hv_store(o, kp2, (I32)kl2, newRV_noinc((SV *)h), 0);
            }
            else SvREFCNT_dec((SV *)h);
        }
        av_push(out, newRV_noinc((SV *)o));
        break;
    }

    default:
        av_push(out, newSVsv(res));
        break;
    }
    return NULL;
}

/* One settled future's continuation: call the handler for the outcome, then
 * settle the next future from what it returned. */
static void dbil_then_run(pTHX_ SV *self, dbil_future *f, AV *k) {
    int   failed = (f->state == 2);
    SV  **e      = av_fetch(k, 0, 0);
    SV   *next   = (e && *e) ? *e : NULL;
    SV   *cb     = NULL;
    if (!next) return;
    e = av_fetch(k, failed ? 2 : 1, 0);
    if (e && *e && SvOK(*e)) cb = *e;

    /* a builtin reshape: no callback, no Perl frame */
    if (cb && !SvROK(cb) && SvIOK(cb)) {
        AV  *out = newAV();
        SV **v   = (!failed && f->result)
                 ? av_fetch((AV *)SvRV(f->result), 0, 0) : NULL;
        SV  *arg = NULL, *err;
        e = av_fetch(k, 3, 0);
        if (e && *e && SvOK(*e)) arg = *e;
        err = dbil_then_builtin(aTHX_ SvIV(cb), (v && *v) ? *v : NULL, arg, out);
        if (err) {
            dbil_future_settle_fail(aTHX_ next, err);
            SvREFCNT_dec(err);
        }
        else dbil_future_settle_done_av(aTHX_ next, out);
        SvREFCNT_dec((SV *)out);
        return;
    }

    /* no handler for this outcome: the result passes straight through */
    if (!cb) {
        if (failed)
            dbil_future_settle_fail(aTHX_ next,
                f->error ? f->error : sv_2mortal(newSVpvs("failed")));
        else
            dbil_future_settle_done_av(aTHX_ next,
                f->result ? (AV *)SvRV(f->result) : NULL);
        return;
    }

    {
        dSP;
        int     count;
        SSize_t i;
        AV     *out;

        ENTER; SAVETMPS; PUSHMARK(SP);
        if (failed) {
            EXTEND(SP, 1);
            PUSHs(f->error ? sv_2mortal(newSVsv(f->error)) : &PL_sv_undef);
        }
        else {
            AV *res = f->result ? (AV *)SvRV(f->result) : NULL;
            SSize_t n = res ? av_len(res) + 1 : 0;
            EXTEND(SP, n);
            for (i = 0; i < n; i++) {
                SV **v = av_fetch(res, i, 0);
                PUSHs(v && *v ? sv_2mortal(newSVsv(*v)) : &PL_sv_undef);
            }
        }
        PUTBACK;
        count = call_sv(cb, G_ARRAY | G_EVAL);
        SPAGAIN;

        if (SvTRUE(ERRSV)) {
            /* The error is stringified, as the Perl chaining did with "$@":
             * an exception object arrives at the next future as its string.
             * NOT mortal - the FREETMPS below would free it before it is
             * used, which is a freed-string panic rather than a wrong value. */
            SV *err = newSVpv(SvPV_nolen(ERRSV), 0);
            SP -= count;
            PUTBACK; FREETMPS; LEAVE;
            dbil_future_settle_fail(aTHX_ next, err);
            SvREFCNT_dec(err);
            return;
        }

        out = newAV();
        for (i = (SSize_t)count - 1; i >= 0; i--) {
            SV *v = POPs;
            (void)av_store(out, i, newSVsv(v));
        }
        PUTBACK; FREETMPS; LEAVE;

        /* a lone returned future is adopted rather than stored as a value */
        if (av_len(out) == 0) {
            SV **v = av_fetch(out, 0, 0);
            if (v && *v && SvROK(*v) && sv_isobject(*v)
                && sv_derived_from(*v, "DBIx::Loop::Future")) {
                dbil_then_attach(aTHX_ *v, next, NULL, NULL);
                SvREFCNT_dec((SV *)out);
                return;
            }
        }
        dbil_future_settle_done_av(aTHX_ next, out);
        SvREFCNT_dec((SV *)out);
    }
}

/* Run and clear the queue, passing $self to each callback. Entries are either
 * an on_ready coderef or a then/else continuation (an AV); on_ready refuses
 * anything but a coderef, so the type is the discriminator. */
static void dbil_future_fire(pTHX_ SV *self, dbil_future *f) {
    SSize_t i, n = av_len(f->cbs) + 1;
    for (i = 0; i < n; i++) {
        SV **cb = av_fetch(f->cbs, i, 0);
        if (!cb || !*cb || !SvROK(*cb)) continue;
        if (SvTYPE(SvRV(*cb)) == SVt_PVAV) {
            dbil_then_run(aTHX_ self, f, (AV *)SvRV(*cb));
            continue;
        }
        {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1); PUSHs(self);
            PUTBACK;
            call_sv(*cb, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("DBIx::Loop::Future: on_ready callback died: %s",
                     SvPV_nolen(ERRSV));
            FREETMPS; LEAVE;
        }
    }
    av_clear(f->cbs);
}

#endif /* DBIL_FUTURE_H */
