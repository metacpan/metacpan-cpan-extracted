MODULE = Chandra    PACKAGE = Chandra::Socket::Hub

PROTOTYPES: DISABLE

SV *
_xs_generate_token()
CODE:
{
    unsigned char bytes[16];
    int fd;
    char hex[33];

    fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        ssize_t n = read(fd, bytes, 16);
        close(fd);
        if (n == 16) {
            int i;
            for (i = 0; i < 16; i++)
                sprintf(hex + i * 2, "%02x", bytes[i]);
            hex[32] = '\0';
            RETVAL = newSVpvn(hex, 32);
            goto done;
        }
    }
    /* Fallback: Perl random */
    {
        int i;
        for (i = 0; i < 4; i++)
            sprintf(hex + i * 8, "%08x",
                (unsigned int)(Drand01() * (double)0xFFFFFFFF));
        hex[32] = '\0';
        RETVAL = newSVpvn(hex, 32);
    }
    done:
    ;
}
OUTPUT:
    RETVAL

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
        } else if (strEQ(key, "transport")) {
            (void)hv_stores(self_hv, "transport", newSVsv(val));
        } else if (strEQ(key, "port")) {
            (void)hv_stores(self_hv, "port", newSVsv(val));
        } else if (strEQ(key, "bind")) {
            (void)hv_stores(self_hv, "bind_addr", newSVsv(val));
        } else if (strEQ(key, "tls_cert")) {
            (void)hv_stores(self_hv, "tls_cert", newSVsv(val));
        } else if (strEQ(key, "tls_key")) {
            (void)hv_stores(self_hv, "tls_key", newSVsv(val));
        }
    }

    /* Defaults */
    if (!hv_exists(self_hv, "transport", 9)) {
        (void)hv_stores(self_hv, "transport", newSVpvs("unix"));
    }
    if (!hv_exists(self_hv, "bind_addr", 9)) {
        (void)hv_stores(self_hv, "bind_addr", newSVpvs("127.0.0.1"));
    }

    (void)hv_stores(self_hv, "_conns", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_clients", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_handlers", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_select",
        newRV_noinc((SV *)newHV())); /* placeholder, replaced by helper */

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
        gv_stashpv(class, GV_ADD));

    /* Generate token */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = call_pv("Chandra::Socket::Hub::_xs_generate_token",
            G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            SV *token_sv = POPs;
            (void)hv_stores(self_hv, "_token", newSVsv(token_sv));
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    /* Create IO::Select and store it */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("IO::Select")));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            SV *sel = POPs;
            (void)hv_stores(self_hv, "_select", newSVsv(sel));
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    /* Start listener */
    _hub_start_listener(aTHX_ RETVAL);
}
OUTPUT:
    RETVAL

SV *
token(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_token", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
socket_path(class_or_self, ...)
    SV *class_or_self
CODE:
{
    /* Can be called as class method or instance method */
    if (items > 1) {
        /* Class method: socket_path($name) */
        const char *name = SvPV_nolen(ST(1));
        dSP;
        int count;
        SV *dir_sv;
        ENTER;
        SAVETMPS;

        /* Get $ENV{XDG_RUNTIME_DIR} || File::Spec->tmpdir */
        {
            SV **env_svp;
            HV *env_hv = get_hv("ENV", 0);
            if (env_hv && (env_svp = hv_fetchs(env_hv, "XDG_RUNTIME_DIR", 0)) && SvOK(*env_svp)) {
                dir_sv = newSVsv(*env_svp);
            } else {
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVpvs("File::Spec")));
                PUTBACK;
                count = call_method("tmpdir", G_SCALAR);
                SPAGAIN;
                dir_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("/tmp");
                PUTBACK;
            }
        }

        /* File::Spec->catfile($dir, "chandra-$name.sock") */
        {
            SV *filename = newSVpvf("chandra-%s.sock", name);
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvs("File::Spec")));
            XPUSHs(sv_2mortal(dir_sv));
            XPUSHs(sv_2mortal(filename));
            PUTBACK;
            count = call_method("catfile", G_SCALAR);
            SPAGAIN;
            RETVAL = (count > 0) ? newSVsv(POPs) : newSVpvs("");
            PUTBACK;
        }

        FREETMPS;
        LEAVE;
    } else {
        RETVAL = &PL_sv_undef;
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
on_connect(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_on_connect", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
on_disconnect(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_on_disconnect", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
broadcast(self, channel_sv, data_sv)
    SV *self
    SV *channel_sv
    SV *data_sv
CODE:
{
    _hub_do_broadcast(aTHX_ self, channel_sv, data_sv);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
send_to(self, name_sv, channel_sv, data_sv)
    SV *self
    SV *name_sv
    SV *channel_sv
    SV *data_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **clients_svp = hv_fetchs(hv, "_clients", 0);
    if (clients_svp && SvROK(*clients_svp)) {
        HV *clients = (HV *)SvRV(*clients_svp);
        const char *name;
        STRLEN name_len;
        SV **conn_svp;
        name = SvPV(name_sv, name_len);
        conn_svp = hv_fetch(clients, name, name_len, 0);
        if (conn_svp && SvOK(*conn_svp)) {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*conn_svp);
            XPUSHs(channel_sv);
            XPUSHs(data_sv);
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
    } else {
        RETVAL = newSViv(0);
    }
}
OUTPUT:
    RETVAL

void
clients(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **clients_svp = hv_fetchs(hv, "_clients", 0);
    if (clients_svp && SvROK(*clients_svp)) {
        HV *clients = (HV *)SvRV(*clients_svp);
        I32 num_keys = hv_iterinit(clients);
        if (GIMME_V == G_SCALAR) {
            mXPUSHi(num_keys);
            XSRETURN(1);
        } else {
            HE *entry;
            while ((entry = hv_iternext(clients)) != NULL) {
                XPUSHs(sv_2mortal(newSVhek(HeKEY_hek(entry))));
            }
        }
    } else {
        if (GIMME_V == G_SCALAR) {
            mXPUSHi(0);
            XSRETURN(1);
        }
    }
}

SV *
poll(self)
    SV *self
CODE:
{
    _hub_do_poll(aTHX_ self);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

void
run(self)
    SV *self
CODE:
{
    while (1) {
        _hub_do_poll(aTHX_ self);
        /* Small sleep to avoid CPU spin — 10ms */
        {
            struct timeval tv;
            tv.tv_sec = 0;
            tv.tv_usec = 10000;
            select(0, NULL, NULL, NULL, &tv);
        }
    }
}

void
close(self)
    SV *self
CODE:
{
    _hub_do_close(aTHX_ self);
}

void
DESTROY(self)
    SV *self
CODE:
{
    _hub_do_close(aTHX_ self);
}
