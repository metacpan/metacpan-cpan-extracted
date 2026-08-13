MODULE = DBIx::Loop        PACKAGE = DBIx::Loop::Loop::Hyperman

# The pure-XS Hyperman loop adapter (dbil_hm.h). Implements the Perl seam
# (add_reader / add_writer / remove / timer / new_future / await) over
# Hyperman's C ABI, plus cancel_timer, and carries the dbil_vt C vtable so
# backends dispatch readiness C-to-C with no Perl call frame.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        const hm_abi *A = dbil_hm(aTHX);
        SV *loop_sv = NULL;
        void *loop;
        dbil_hm_ctx *c;
        HV *self;
        int i;
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        if (!A)
            croak("DBIx::Loop::Loop::Hyperman: no Hyperman C ABI version %d - "
                  "either Hyperman is not loaded (use Hyperman first) or it "
                  "predates the ABI (needs Hyperman 0.10 or newer)",
                  HM_ABI_VERSION);
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if (kl == 4 && memEQ(k, "loop", 4) && SvOK(ST(i + 1)))
                loop_sv = ST(i + 1);
        }
        if (loop_sv) {
            loop    = A->loop_of_sv(aTHX_ loop_sv);   /* croaks if not one */
            loop_sv = newSVsv(loop_sv);
        } else if ((loop = A->cur_loop(aTHX))) {
            loop_sv = A->sv_of_loop(aTHX_ loop);      /* +1, we own it */
        } else {
            /* no loop given, none running: make one (IO::Async parity) */
            dSP; int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1); mPUSHp("Hyperman::Loop", 14); PUTBACK;
            n = call_method("new", G_SCALAR);
            SPAGAIN;
            if (n > 0) { SV *s = POPs; loop_sv = newSVsv(s); }
            PUTBACK; FREETMPS; LEAVE;
            if (!loop_sv)
                croak("DBIx::Loop::Loop::Hyperman: Hyperman::Loop->new "
                      "returned nothing");
            loop = A->loop_of_sv(aTHX_ loop_sv);
        }
        c = dbil_hm_ctx_new(A, loop);
        self = newHV();
        (void)hv_stores(self, "loop", loop_sv);
        (void)hv_stores(self, "_ctx", newSViv(PTR2IV(c)));
        (void)hv_stores(self, "_vt",  newSViv(PTR2IV(&c->vt)));
        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

# the underlying Hyperman::Loop object
SV *
loop(self)
        SV *self
    CODE:
    {
        SV **e;
        (void)dbil_hm_ctx_of(aTHX_ self);   /* validates */
        e = hv_fetchs((HV *)SvRV(self), "loop", 0);
        RETVAL = (e && *e) ? newSVsv(*e) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

void
add_reader(self, fd, cb)
        SV *self
        int fd
        SV *cb
    ALIAS:
        add_writer = 1
    CODE:
        dbil_hm_add_io(aTHX_ self, fd, ix ? HM_ABI_WRITE : HM_ABI_READ, cb);

void
remove(self, fd)
        SV *self
        int fd
    CODE:
        dbil_hm_remove(aTHX_ self, fd);

# One-shot timer; returns a handle for cancel_timer. The handle dies when the
# callback fires - only cancel a timer that has not fired.
SV *
timer(self, secs, cb)
        SV *self
        double secs
        SV *cb
    CODE:
    {
        dbil_hm_ctx *c = dbil_hm_ctx_of(aTHX_ self);
        dbil_hm_tmr *tm;
        Newxz(tm, 1, dbil_hm_tmr);
        tm->cb = newSVsv(cb);
        tm->t  = c->A->timer(aTHX_ c->loop, secs, dbil_hm_timer_tramp, tm);
        RETVAL = newSViv(PTR2IV(tm));
    }
    OUTPUT:
        RETVAL

void
cancel_timer(self, handle)
        SV *self
        SV *handle
    CODE:
    {
        dbil_hm_ctx *c = dbil_hm_ctx_of(aTHX_ self);
        dbil_hm_tmr *tm;
        if (!SvIOK(handle))
            croak("cancel_timer: not a timer handle");
        tm = INT2PTR(dbil_hm_tmr *, SvIV(handle));
        c->A->timer_cancel(aTHX_ c->loop, tm->t);
        SvREFCNT_dec(tm->cb);
        Safefree(tm);
    }

# a pending Hyperman::Future (the ecosystem-native future)
SV *
new_future(self)
        SV *self
    CODE:
        RETVAL = dbil_hm_ctx_of(aTHX_ self)->A->future_new(aTHX);
    OUTPUT:
        RETVAL

# run the loop until $future is ready; takes Hyperman::Future natively and
# anything with on_ready (DBIx::Loop::Future) through a C bridge
SV *
await(self, future)
        SV *self
        SV *future
    CODE:
        dbil_hm_await(aTHX_ dbil_hm_ctx_of(aTHX_ self), future);
        RETVAL = newSVsv(future);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
    {
        HV *h;
        SV **e;
        if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)) XSRETURN_EMPTY;
        h = (HV *)SvRV(self);
        e = hv_fetchs(h, "_ctx", 0);
        if (e && *e && SvIOK(*e)) {
            dbil_hm_ctx *c = INT2PTR(dbil_hm_ctx *, SvIV(*e));
            /* drop any still-registered Perl-seam watchers so the loop never
             * fires into freed callbacks; skip during global destruction */
            if (!PL_dirty) {
                int m;
                for (m = 0; m < 2; m++) {
                    HV *cbs = dbil_hm_cbh(aTHX_ self,
                                          m ? HM_ABI_WRITE : HM_ABI_READ, 0);
                    if (cbs) {
                        HE *he;
                        hv_iterinit(cbs);
                        while ((he = hv_iternext(cbs))) {
                            I32 kl;
                            const char *k = hv_iterkey(he, &kl);
                            c->A->io_unwatch(aTHX_ c->loop, atoi(k),
                                             m ? HM_ABI_WRITE : HM_ABI_READ);
                        }
                    }
                }
            }
            Safefree(c);
            (void)hv_delete(h, "_ctx", 4, G_DISCARD);
            (void)hv_delete(h, "_vt",  3, G_DISCARD);
        }
    }
