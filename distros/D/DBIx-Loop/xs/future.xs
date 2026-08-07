MODULE = DBIx::Loop        PACKAGE = DBIx::Loop::Future

PROTOTYPES: DISABLE

SV *
new(class)
        SV *class
    CODE:
        RETVAL = dbil_future_new(aTHX_
            SvROK(class) ? sv_reftype(SvRV(class), 1) : SvPV_nolen(class));
    OUTPUT:
        RETVAL

SV *
done(self, ...)
        SV *self
    CODE:
    {
        dbil_future *f = dbil_future_of(aTHX_ self);
        AV *res = newAV();
        int i;
        if (f->state)
            croak("DBIx::Loop::Future: already settled");
        for (i = 1; i < items; i++) av_push(res, newSVsv(ST(i)));
        f->result = newRV_noinc((SV *)res);
        f->state  = 1;
        dbil_future_fire(aTHX_ self, f);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
fail(self, error)
        SV *self
        SV *error
    CODE:
    {
        dbil_future *f = dbil_future_of(aTHX_ self);
        if (f->state)
            croak("DBIx::Loop::Future: already settled");
        f->error = newSVsv(error);
        f->state = 2;
        dbil_future_fire(aTHX_ self, f);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
on_ready(self, cb)
        SV *self
        SV *cb
    CODE:
    {
        dbil_future *f = dbil_future_of(aTHX_ self);
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
            croak("DBIx::Loop::Future->on_ready: need a coderef");
        if (f->state) {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1); PUSHs(self); PUTBACK;
            call_sv(cb, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("DBIx::Loop::Future: on_ready callback died: %s",
                     SvPV_nolen(ERRSV));
            FREETMPS; LEAVE;
        } else {
            av_push(f->cbs, newSVsv(cb));
        }
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# then($on_done [, $on_fail]) / else($on_fail) -> a new future.
#
# The continuation is an AV on the callback queue, not a closure, so a chain
# costs one array per link and settling it runs no Perl frame but the user's
# own callbacks. `else` is the same thing with only the failure half, which is
# why it is an ALIAS rather than a second body.
SV *
then(self, on_done = &PL_sv_undef, on_fail = &PL_sv_undef)
        SV *self
        SV *on_done
        SV *on_fail
    ALIAS:
        else = 1
    CODE:
    {
        SV *next;
        /* else($cb): the one argument is the failure handler */
        if (ix == 1) { on_fail = on_done; on_done = &PL_sv_undef; }
        (void)dbil_future_of(aTHX_ self);         /* croak early if not one */
        next = dbil_future_new(aTHX_ "DBIx::Loop::Future");
        dbil_then_attach(aTHX_ self, next, on_done, on_fail);
        RETVAL = next;
    }
    OUTPUT:
        RETVAL

int
is_ready(self)
        SV *self
    CODE:
        RETVAL = dbil_future_of(aTHX_ self)->state != 0;
    OUTPUT:
        RETVAL

int
is_done(self)
        SV *self
    CODE:
        RETVAL = dbil_future_of(aTHX_ self)->state == 1;
    OUTPUT:
        RETVAL

int
is_failed(self)
        SV *self
    CODE:
        RETVAL = dbil_future_of(aTHX_ self)->state == 2;
    OUTPUT:
        RETVAL

SV *
failure(self)
        SV *self
    CODE:
    {
        dbil_future *f = dbil_future_of(aTHX_ self);
        RETVAL = (f->state == 2 && f->error) ? newSVsv(f->error) : newSV(0);
    }
    OUTPUT:
        RETVAL

void
get(self)
        SV *self
    PPCODE:
    {
        dbil_future *f = dbil_future_of(aTHX_ self);
        if (f->state == 0)
            croak("DBIx::Loop::Future->get: future is not ready "
                  "(await it on your event loop first)");
        if (f->state == 2)
            croak_sv(f->error ? f->error : sv_2mortal(newSVpvs("failed")));
        {
            AV *res = (AV *)SvRV(f->result);
            SSize_t i, n = av_len(res) + 1;
            EXTEND(SP, n);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(res, i, 0);
                PUSHs(e && *e ? sv_2mortal(newSVsv(*e)) : &PL_sv_undef);
            }
        }
    }
