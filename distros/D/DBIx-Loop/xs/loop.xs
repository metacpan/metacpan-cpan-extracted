MODULE = DBIx::Loop        PACKAGE = DBIx::Loop

PROTOTYPES: DISABLE

# _capability($driver_name) -> 'native' | 'pool'  (the probe; internal)
SV *
_capability(driver_name)
        SV *driver_name
    CODE:
        RETVAL = newSVpv(dbil_capability(aTHX_ SvOK(driver_name) ? driver_name : NULL), 0);
    OUTPUT:
        RETVAL

# DBIx::Loop->new(dbh => $dbh, loop => $loop)
SV *
new(class, ...)
        SV *class
    CODE:
    {
        SV *dbh = NULL, *loop = NULL;
        SV *dsn = NULL, *user = NULL, *pass = NULL, *attr = NULL;
        int nworkers = 4;
        int max_queue = 0;
        HV *self;
        int i;
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if      (kl == 3 && memEQ(k, "dbh", 3))  dbh  = ST(i + 1);
            else if (kl == 4 && memEQ(k, "loop", 4)) loop = ST(i + 1);
            else if (kl == 3 && memEQ(k, "dsn", 3))  dsn  = ST(i + 1);
            else if (kl == 4 && memEQ(k, "user", 4)) user = ST(i + 1);
            else if (kl == 4 && memEQ(k, "pass", 4)) pass = ST(i + 1);
            else if (kl == 4 && memEQ(k, "attr", 4)) attr = ST(i + 1);
            else if (kl == 7 && memEQ(k, "workers", 7))
                nworkers = SvIV(ST(i + 1)) > 0 ? (int)SvIV(ST(i + 1)) : 1;
            else if (kl == 9 && memEQ(k, "max_queue", 9))
                max_queue = SvIV(ST(i + 1)) > 0 ? (int)SvIV(ST(i + 1)) : 0;
            /* other options (backend, ...) reserved for later phases */
        }
        if (!loop || !SvOK(loop))
            croak("DBIx::Loop->new: a 'loop' is required - DBIx::Loop is not "
                  "an event loop, it runs on one. Pass loop => $adapter.");
        if (!dbh || !SvROK(dbh))
            croak("DBIx::Loop->new: a 'dbh' is required (or use connect)");
        self = newHV();
        (void)hv_stores(self, "dbh",  newSVsv(dbh));
        (void)hv_stores(self, "loop", newSVsv(loop));
        (void)hv_stores(self, "workers", newSViv(nworkers));
        (void)hv_stores(self, "max_queue", newSViv(max_queue));
        {
            SV *dn = dbil_driver_name(aTHX_ dbh);
            const char *cap = dbil_capability(aTHX_ dn);
            /* 'native' only when the driver's async surface is actually
             * loaded (DBD::Pg's PG_ASYNC resolves); otherwise the pool
             * backend serves it like any other driver */
            if (strEQ(cap, "native")
                && !(dn && SvOK(dn) && dbil_native_available(aTHX_ SvPV_nolen(dn))))
                cap = "pool";
            (void)hv_stores(self, "capability", newSVpv(cap, 0));
        }
        /* connect args let the pool's forked workers open their own handles
         * (a live dbh cannot be shared across fork). Stored only when connect()
         * supplied a dsn; a bare new(dbh => ...) leaves the pool without them. */
        if (dsn && SvOK(dsn)) {
            AV *ca = newAV();
            av_push(ca, newSVsv(dsn));
            av_push(ca, user && SvOK(user) ? newSVsv(user) : newSV(0));
            av_push(ca, pass && SvOK(pass) ? newSVsv(pass) : newSV(0));
            av_push(ca, attr && SvROK(attr) ? newSVsv(attr) : newSV(0));
            (void)hv_stores(self, "connect_args", newRV_noinc((SV *)ca));
        }
        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

# $db->query($sql, @bind) -> future
SV *
query(self, sql, ...)
        SV *self
        SV *sql
    CODE:
    {
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        int i;
        for (i = 2; i < items; i++) av_push(bind, newSVsv(ST(i)));
        RETVAL = dbil_exec(aTHX_ self, 1, sql, bind);
    }
    OUTPUT:
        RETVAL

# $db->do($sql, @bind) -> future
SV *
do(self, sql, ...)
        SV *self
        SV *sql
    CODE:
    {
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        int i;
        for (i = 2; i < items; i++) av_push(bind, newSVsv(ST(i)));
        RETVAL = dbil_exec(aTHX_ self, 0, sql, bind);
    }
    OUTPUT:
        RETVAL

# The DBI select* family. Each is query() plus one fixed reshape of the result,
# so the reshape is a builtin continuation rather than a Perl closure: no
# closure is compiled per call and no Perl frame runs when the result lands.
# selectall_hashref takes its key field before the bind values, as DBI does.
SV *
selectall_arrayref(self, sql, ...)
        SV *self
        SV *sql
    ALIAS:
        selectall_arrayref = 1
        selectrow_arrayref = 2
        selectrow_array    = 3
        selectrow_hashref  = 4
        selectcol_arrayref = 5
        selectall_hashref  = 6
    CODE:
    {
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        SV *key  = NULL;
        SV *qf, *next;
        int i = 2;
        if (ix == DBIL_T_ALL_HASHREF) {
            if (items < 3)
                croak("DBIx::Loop->selectall_hashref: a key field is required");
            key = ST(2);
            i   = 3;
        }
        for (; i < items; i++) av_push(bind, newSVsv(ST(i)));
        qf   = sv_2mortal(dbil_exec(aTHX_ self, 1, sql, bind));
        next = dbil_future_new(aTHX_ "DBIx::Loop::Future");
        dbil_then_attach4(aTHX_ qf, next, sv_2mortal(newSViv((IV)ix)),
                          NULL, key);
        RETVAL = next;
    }
    OUTPUT:
        RETVAL

SV *
capability(self)
        SV *self
    CODE:
    {
        SV *v = dbil_field(aTHX_ self, "capability", 10);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

SV *
loop(self)
        SV *self
    CODE:
    {
        SV *v = dbil_field(aTHX_ self, "loop", 4);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

SV *
dbh(self)
        SV *self
    CODE:
    {
        SV *v = dbil_field(aTHX_ self, "dbh", 3);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

void
disconnect(self)
        SV *self
    CODE:
    {
        HV *h = (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)
              ? (HV *)SvRV(self) : NULL;
        SV *dbh = dbil_field(aTHX_ self, "dbh", 3);
        /* tear the pool down deterministically here (reap workers, drop fds)
         * rather than at global destruction */
        if (h) {
            SV **pp = hv_fetchs(h, "_pool", 0);
            SV **np = hv_fetchs(h, "_native", 0);
            if (pp && *pp && SvIOK(*pp)) {
                dbil_pool_free(aTHX_ INT2PTR(dbil_pool *, SvIV(*pp)));
                (void)hv_delete(h, "_pool", 5, G_DISCARD);
            }
            if (np && *np && SvIOK(*np)) {
                dbil_native_free(aTHX_ INT2PTR(dbil_native *, SvIV(*np)));
                (void)hv_delete(h, "_native", 7, G_DISCARD);
            }
        }
        if (dbh && SvROK(dbh)) {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1); PUSHs(dbh); PUTBACK;
            call_method("disconnect", G_VOID | G_DISCARD | G_EVAL);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        }
    }

# $db->txn(sub { my $tx = shift; ... }) -> future of the block's result.
# Acquires a slot (waits when saturated), BEGINs, runs the block with a pinned
# DBIx::Loop::Txn handle, COMMITs on success / ROLLBACKs on a die or failed
# block-future, releases the slot. Pool backend only for now: a native (Pg)
# transaction needs the native connection pool.
SV *
txn(self, block)
        SV *self
        SV *block
    CODE:
    {
        SV *cap   = dbil_field(aTHX_ self, "capability", 10);
        SV *cargs = dbil_field(aTHX_ self, "connect_args", 12);
        if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV)
            croak("DBIx::Loop->txn: need a coderef");
        if (!(cap && SvPOK(cap) && strEQ(SvPVX(cap), "pool")
              && cargs && SvROK(cargs)))
            croak("DBIx::Loop->txn: transactions need the pool backend "
                  "(connect() with a dsn); native-backend transactions arrive "
                  "with the native connection pool");
        RETVAL = dbil_txn_start(aTHX_ self, block,
                                dbil_pool_of(aTHX_ self, cargs));
    }
    OUTPUT:
        RETVAL

# worker pids of the live pool (test/introspection aid)
void
_worker_pids(self)
        SV *self
    PPCODE:
    {
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            SV **pp = hv_fetchs((HV *)SvRV(self), "_pool", 0);
            if (pp && *pp && SvIOK(*pp)) {
                dbil_pool *p = INT2PTR(dbil_pool *, SvIV(*pp));
                int i;
                EXTEND(SP, p->nw);
                for (i = 0; i < p->nw; i++)
                    mPUSHi((IV)p->w[i].pid);
            }
        }
    }

void
DESTROY(self)
        SV *self
    CODE:
    {
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            SV **pp = hv_fetchs((HV *)SvRV(self), "_pool", 0);
            SV **np = hv_fetchs((HV *)SvRV(self), "_native", 0);
            if (pp && *pp && SvIOK(*pp))
                dbil_pool_free(aTHX_ INT2PTR(dbil_pool *, SvIV(*pp)));
            if (np && *np && SvIOK(*np))
                dbil_native_free(aTHX_ INT2PTR(dbil_native *, SvIV(*np)));
        }
    }
