MODULE = Chandra    PACKAGE = Chandra::Socket::Client

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "name")) {
            (void)hv_stores(self_hv, "name", newSVsv(val));
        } else if (strEQ(key, "hub")) {
            (void)hv_stores(self_hv, "hub_name", newSVsv(val));
        } else if (strEQ(key, "transport")) {
            (void)hv_stores(self_hv, "transport", newSVsv(val));
        } else if (strEQ(key, "host")) {
            (void)hv_stores(self_hv, "host", newSVsv(val));
        } else if (strEQ(key, "port")) {
            (void)hv_stores(self_hv, "port", newSVsv(val));
        } else if (strEQ(key, "token")) {
            (void)hv_stores(self_hv, "_token", newSVsv(val));
            (void)hv_stores(self_hv, "_explicit_token", newSViv(1));
        } else if (strEQ(key, "tls")) {
            (void)hv_stores(self_hv, "tls", newSVsv(val));
        } else if (strEQ(key, "tls_ca")) {
            (void)hv_stores(self_hv, "tls_ca", newSVsv(val));
        }
    }

    /* Defaults */
    if (!hv_exists(self_hv, "transport", 9)) {
        (void)hv_stores(self_hv, "transport", newSVpvs("unix"));
    }
    if (!hv_exists(self_hv, "host", 4)) {
        (void)hv_stores(self_hv, "host", newSVpvs("127.0.0.1"));
    }
    if (!hv_exists(self_hv, "_explicit_token", 15)) {
        (void)hv_stores(self_hv, "_explicit_token", newSViv(0));
    }

    (void)hv_stores(self_hv, "_conn", newSV(0));
    (void)hv_stores(self_hv, "_handlers", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_pending", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_next_id", newSViv(0));
    (void)hv_stores(self_hv, "_retry_delay", newSVnv(0.1));
    (void)hv_stores(self_hv, "_max_retry", newSViv(5));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
        gv_stashpv(class, GV_ADD));

    /* Connect to hub */
    (void)_client_do_connect(aTHX_ RETVAL);
}
OUTPUT:
    RETVAL

int
is_connected(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);
    if (conn_svp && SvOK(*conn_svp) && SvROK(*conn_svp)) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*conn_svp);
        PUTBACK;
        count = call_method("is_connected", G_SCALAR);
        SPAGAIN;
        if (count > 0) { SV *tmp = POPs; RETVAL = SvIV(tmp); }
        PUTBACK;
        FREETMPS;
        LEAVE;
    } else {
        RETVAL = 0;
    }
}
OUTPUT:
    RETVAL

SV *
on(self, channel_sv, callback)
    SV *self
    SV *channel_sv
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **handlers_svp = hv_fetchs(hv, "_handlers", 0);
    if (handlers_svp && SvROK(*handlers_svp)) {
        HV *handlers = (HV *)SvRV(*handlers_svp);
        const char *channel;
        STRLEN ch_len;
        channel = SvPV(channel_sv, ch_len);
        (void)hv_store(handlers, channel, ch_len, newSVsv(callback), 0);
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
send(self, channel_sv, data_sv, ...)
    SV *self
    SV *channel_sv
    SV *data_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);
    if (conn_svp && SvOK(*conn_svp) && SvROK(*conn_svp)) {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*conn_svp);
        XPUSHs(channel_sv);
        XPUSHs(data_sv);
        if (items > 3) {
            XPUSHs(ST(3));
        }
        PUTBACK;
        count = call_method("send", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? newSVsv(POPs) : newSViv(0);
        PUTBACK;
        FREETMPS;
        LEAVE;
    } else {
        RETVAL = newSViv(0);
    }
}
OUTPUT:
    RETVAL

SV *
request(self, channel_sv, data_sv, callback)
    SV *self
    SV *channel_sv
    SV *data_sv
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);
    if (conn_svp && SvOK(*conn_svp) && SvROK(*conn_svp)) {
        /* Increment _next_id */
        SV **id_svp = hv_fetchs(hv, "_next_id", 0);
        IV id = (id_svp && SvOK(*id_svp)) ? SvIV(*id_svp) + 1 : 1;
        (void)hv_stores(hv, "_next_id", newSViv(id));

        /* Store pending callback */
        {
            SV **pending_svp = hv_fetchs(hv, "_pending", 0);
            if (pending_svp && SvROK(*pending_svp)) {
                HV *pending = (HV *)SvRV(*pending_svp);
                char id_str[32];
                int id_len = my_snprintf(id_str, sizeof(id_str), "%" IVdf, id);
                (void)hv_store(pending, id_str, id_len, newSVsv(callback), 0);
            }
        }

        /* Build extra hash with _id */
        {
            HV *extra = newHV();
            (void)hv_stores(extra, "_id", newSViv(id));

            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*conn_svp);
            XPUSHs(channel_sv);
            XPUSHs(data_sv);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)extra)));
            PUTBACK;
            count = call_method("send", G_SCALAR);
            SPAGAIN;
            RETVAL = (count > 0) ? newSVsv(POPs) : newSViv(0);
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
    } else {
        RETVAL = newSViv(0);
    }
}
OUTPUT:
    RETVAL

SV *
poll(self)
    SV *self
CODE:
{
    _client_do_poll(aTHX_ self);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
reconnect(self)
    SV *self
CODE:
{
    _client_do_reconnect(aTHX_ self);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

void
close(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);
    if (conn_svp && SvOK(*conn_svp) && SvROK(*conn_svp)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*conn_svp);
        PUTBACK;
        call_method("close", G_DISCARD);
        FREETMPS;
        LEAVE;
        (void)hv_stores(hv, "_conn", newSV(0));
    }
}

void
DESTROY(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);
    if (conn_svp && SvOK(*conn_svp) && SvROK(*conn_svp)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*conn_svp);
        PUTBACK;
        call_method("close", G_DISCARD);
        FREETMPS;
        LEAVE;
        (void)hv_stores(hv, "_conn", newSV(0));
    }
}
