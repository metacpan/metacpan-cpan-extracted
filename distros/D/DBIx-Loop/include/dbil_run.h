#ifndef DBIL_RUN_H
#define DBIL_RUN_H

/* Running a DBI statement from C.
 *
 * DBI's prepare/execute/fetch and attribute reads are its Perl API - they
 * cannot be bypassed - so we drive them with call_method under G_EVAL (so a
 * RaiseError croak becomes a clean failure, not a longjmp out of C). This same
 * executor is reused inside the forked pool worker in phase 02. */

/* When set (inside a pool worker process), statements go through DBI's
 * prepare_cached - statement reuse was the ~5x lever in the DBD::SQLite
 * bench, and a worker re-runs the same SQL constantly. */
static int DBIL_PREPARE_CACHED = 0;

/* $h->FETCH($attr): read a DBI handle attribute from C. Mortal SV, or NULL. */
static SV *dbil_h_fetch(pTHX_ SV *h, const char *attr) {
    dSP;
    int n;
    SV *ret = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(h);
    mPUSHp(attr, strlen(attr));
    PUTBACK;
    n = call_method("FETCH", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && n > 0) { SV *v = POPs; if (SvOK(v)) ret = newSVsv(v); }
    else if (n > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return ret ? sv_2mortal(ret) : NULL;
}

/* Run one statement. is_query!=0 -> SELECT-style (fetchall_arrayref).
 * Returns a mortal result hashref, or NULL with *err (mortal) set:
 *   query -> { rows => [ [..], .. ], columns => [ name, .. ] }
 *   do    -> { rows_affected => N } */
static SV *dbil_run_dbi(pTHX_ SV *dbh, int is_query, SV *sql, AV *bind, SV **err) {
    SSize_t nb = bind ? (av_len(bind) + 1) : 0, i;
    *err = NULL;

    if (!is_query) {
        dSP;
        int n;
        IV rows = 0;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 3 + nb);
        PUSHs(dbh); PUSHs(sql); PUSHs(&PL_sv_undef);   /* do($sql, \%attr, @bind) */
        for (i = 0; i < nb; i++) { SV **e = av_fetch(bind, i, 0); PUSHs(e && *e ? *e : &PL_sv_undef); }
        PUTBACK;
        n = call_method("do", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) { SV *e = newSVsv(ERRSV); if (n > 0) (void)POPs; PUTBACK; FREETMPS; LEAVE; *err = sv_2mortal(e); return NULL; }
        if (n > 0) { SV *r = POPs; rows = SvOK(r) ? SvIV(r) : 0; }
        PUTBACK; FREETMPS; LEAVE;
        {
            HV *h = newHV();
            (void)hv_stores(h, "rows_affected", newSViv(rows));
            {   /* best-effort insert id: $dbh->last_insert_id (drivers vary) */
                dSP; int n2; SV *lid = NULL;
                ENTER; SAVETMPS; PUSHMARK(SP);
                EXTEND(SP, 5);
                PUSHs(dbh);
                PUSHs(&PL_sv_undef); PUSHs(&PL_sv_undef);
                PUSHs(&PL_sv_undef); PUSHs(&PL_sv_undef);
                PUTBACK;
                n2 = call_method("last_insert_id", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (!SvTRUE(ERRSV) && n2 > 0) { SV *v = POPs; if (SvOK(v)) lid = newSVsv(v); }
                else if (n2 > 0) (void)POPs;
                PUTBACK; FREETMPS; LEAVE;
                if (lid) (void)hv_stores(h, "insert_id", lid);
            }
            return sv_2mortal(newRV_noinc((SV *)h));
        }
    }
    else {
        SV *sth = NULL;
        /* prepare */
        {
            dSP; int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 2); PUSHs(dbh); PUSHs(sql); PUTBACK;
            n = call_method(DBIL_PREPARE_CACHED ? "prepare_cached" : "prepare",
                            G_SCALAR | G_EVAL);
            SPAGAIN;
            if (SvTRUE(ERRSV)) { SV *e = newSVsv(ERRSV); if (n > 0) (void)POPs; PUTBACK; FREETMPS; LEAVE; *err = sv_2mortal(e); return NULL; }
            if (n > 0) { SV *s = POPs; if (SvROK(s)) sth = SvREFCNT_inc(s); }
            PUTBACK; FREETMPS; LEAVE;
        }
        if (!sth) { *err = sv_2mortal(newSVpvs("prepare returned no statement handle")); return NULL; }
        sv_2mortal(sth);
        /* execute */
        {
            dSP; int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1 + nb); PUSHs(sth);
            for (i = 0; i < nb; i++) { SV **e = av_fetch(bind, i, 0); PUSHs(e && *e ? *e : &PL_sv_undef); }
            PUTBACK;
            n = call_method("execute", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (SvTRUE(ERRSV)) { SV *e = newSVsv(ERRSV); if (n > 0) (void)POPs; PUTBACK; FREETMPS; LEAVE; *err = sv_2mortal(e); return NULL; }
            if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
        }
        {
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
                    if (SvTRUE(ERRSV)) {
                        SV *e = newSVsv(ERRSV);   /* copy before FREETMPS frees mortals */
                        if (n > 0) (void)POPs;
                        PUTBACK; FREETMPS; LEAVE;
                        SvREFCNT_dec((SV *)h);
                        *err = sv_2mortal(e);
                        return NULL;
                    }
                    if (n > 0) { SV *r = POPs; if (SvROK(r)) fa = SvREFCNT_inc(r); }
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
            }
            else {
                (void)hv_stores(h, "rows",    newRV_noinc((SV *)newAV()));
                (void)hv_stores(h, "columns", newRV_noinc((SV *)newAV()));
            }
            return sv_2mortal(newRV_noinc((SV *)h));
        }
    }
}

#endif /* DBIL_RUN_H */
