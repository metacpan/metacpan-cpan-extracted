#ifndef CHANDRA_SOCKET_HUB_H
#define CHANDRA_SOCKET_HUB_H

/*
 * chandra_socket_hub.h — C helpers for Chandra::Socket::Hub
 *
 * Static functions for listener setup, polling, broadcasting, and cleanup.
 * Depends on chandra_socket_common.h for shared utilities.
 */

/* ---- Remove a connection by fileno ---- */

static void
_hub_remove_conn(pTHX_ SV *self, IV fileno, SV *fh_sv)
{
    HV *hv = (HV *)SvRV(self);
    SV **conns_svp    = hv_fetchs(hv, "_conns", 0);
    SV **clients_svp  = hv_fetchs(hv, "_clients", 0);
    SV **select_svp   = hv_fetchs(hv, "_select", 0);
    SV **on_disc_svp  = hv_fetchs(hv, "_on_disconnect", 0);
    char fn_str[32];
    int fn_len;
    SV *conn = NULL;

    fn_len = my_snprintf(fn_str, sizeof(fn_str), "%" IVdf, fileno);

    if (conns_svp && SvROK(*conns_svp)) {
        HV *conns_hv = (HV *)SvRV(*conns_svp);
        SV *deleted = hv_delete(conns_hv, fn_str, fn_len, 0);
        if (deleted && SvOK(deleted))
            conn = deleted;
    }

    if (select_svp && SvOK(*select_svp) && fh_sv)
        _sock_select_remove(aTHX_ *select_svp, fh_sv);

    if (conn) {
        SV *conn_name = NULL;

        /* $conn->name */
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(conn);
            PUTBACK;
            count = call_method("name", G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                SV *n = POPs;
                if (SvOK(n) && SvTRUE(n))
                    conn_name = newSVsv(n);
            }
            PUTBACK;
            FREETMPS; LEAVE;
        }

        if (conn_name) {
            if (clients_svp && SvROK(*clients_svp)) {
                HV *clients_hv = (HV *)SvRV(*clients_svp);
                STRLEN nlen;
                const char *nstr = SvPV(conn_name, nlen);
                (void)hv_delete(clients_hv, nstr, nlen, G_DISCARD);
            }

            if (on_disc_svp && SvOK(*on_disc_svp))
                _sock_dispatch_cb(aTHX_ *on_disc_svp, conn);

            SvREFCNT_dec(conn_name);
        }

        _sock_call_void(aTHX_ conn, "close");
    }
}

/* ---- Create a TCP listener (plain or TLS) ---- */

static SV *
_hub_create_tcp_listener(pTHX_ HV *hv)
{
    SV **tls_cert_svp = hv_fetchs(hv, "tls_cert", 0);
    SV **tls_key_svp  = hv_fetchs(hv, "tls_key", 0);
    SV **bind_svp     = hv_fetchs(hv, "bind_addr", 0);
    SV **port_svp     = hv_fetchs(hv, "port", 0);
    SV *host = bind_svp ? *bind_svp : sv_2mortal(newSVpvs("127.0.0.1"));
    SV *port = port_svp ? *port_svp : &PL_sv_undef;
    SV *listener = NULL;

    if (tls_cert_svp && SvOK(*tls_cert_svp) &&
        tls_key_svp  && SvOK(*tls_key_svp)) {
        listener = _sock_tls_listen(aTHX_ host, port,
            *tls_cert_svp, *tls_key_svp);
        if (!listener)
            croak("Hub: cannot listen on TLS TCP %s:%s: %s",
                bind_svp ? SvPV_nolen(*bind_svp) : "?",
                port_svp ? SvPV_nolen(*port_svp) : "?",
                SvPV_nolen(get_sv("!", 0)));
        _sock_set_nonblocking(aTHX_ listener);
    } else {
        listener = _sock_tcp_listen(aTHX_ host, port);
        if (!listener)
            croak("Hub: cannot listen on TCP %s:%s: %s",
                bind_svp ? SvPV_nolen(*bind_svp) : "?",
                port_svp ? SvPV_nolen(*port_svp) : "?",
                SvPV_nolen(get_sv("!", 0)));
    }
    return listener;
}

/* ---- Create a Unix domain listener ---- */

static SV *
_hub_create_unix_listener(pTHX_ HV *hv)
{
    SV **name_svp  = hv_fetchs(hv, "name", 0);
    SV **token_svp = hv_fetchs(hv, "_token", 0);
    const char *name_str = (name_svp && SvOK(*name_svp))
        ? SvPV_nolen(*name_svp) : "default";
    SV *path_sv, *listener;
    const char *path_str;
    STRLEN path_len;

    path_sv = _sock_build_path(aTHX_ name_str);
    path_str = SvPV(path_sv, path_len);
    (void)hv_stores(hv, "_socket_path", newSVsv(path_sv));

    (void)unlink(path_str);

    listener = _sock_unix_listen(aTHX_ path_sv);
    if (!listener) {
        SvREFCNT_dec(path_sv);
        croak("Hub: cannot listen on %s: %s",
            path_str, SvPV_nolen(get_sv("!", 0)));
    }

    (void)chmod(path_str, 0600);
    _sock_set_nonblocking(aTHX_ listener);

    /* Write token file */
    {
        SV *token_path_sv = newSVpvf("%s.token", path_str);
        (void)hv_stores(hv, "_token_path", newSVsv(token_path_sv));

        if (token_svp && SvOK(*token_svp)) {
            STRLEN tlen;
            const char *tstr = SvPV(*token_svp, tlen);
            _sock_write_token_file(SvPV_nolen(token_path_sv), tstr, tlen);
        }
        SvREFCNT_dec(token_path_sv);
    }

    SvREFCNT_dec(path_sv);
    return listener;
}

/* ---- Start the listener socket ---- */

static void
_hub_start_listener(pTHX_ SV *self)
{
    HV *hv = (HV *)SvRV(self);
    SV **transport_svp = hv_fetchs(hv, "transport", 0);
    SV **select_svp    = hv_fetchs(hv, "_select", 0);
    const char *transport;
    SV *listener;

    transport = (transport_svp && SvOK(*transport_svp))
        ? SvPV_nolen(*transport_svp) : "unix";

    if (strEQ(transport, "tcp"))
        listener = _hub_create_tcp_listener(aTHX_ hv);
    else
        listener = _hub_create_unix_listener(aTHX_ hv);

    (void)hv_stores(hv, "_listener", listener);

    if (select_svp && SvOK(*select_svp))
        _sock_select_add(aTHX_ *select_svp, listener);
}

/* ---- Accept a new client connection ---- */

static void
_hub_accept_client(pTHX_ SV *listener, SV *select, SV *conns_ref)
{
    SV *client_sock = _sock_accept(aTHX_ listener);
    SV *conn;
    IV client_fileno;
    char cfn[32];
    int cfn_len;
    HV *conns_hv;

    if (!client_sock) return;

    _sock_set_nonblocking(aTHX_ client_sock);

    conn = _sock_connection_new(aTHX_ client_sock, NULL);
    if (!conn) { SvREFCNT_dec(client_sock); return; }

    client_fileno = _sock_fileno(aTHX_ client_sock);

    cfn_len = my_snprintf(cfn, sizeof(cfn), "%" IVdf, client_fileno);
    conns_hv = (HV *)SvRV(conns_ref);
    (void)hv_store(conns_hv, cfn, cfn_len, conn, 0);

    _sock_select_add(aTHX_ select, client_sock);

    SvREFCNT_dec(client_sock);
}

/* ---- Evict old client with the same name ---- */

static void
_hub_evict_duplicate(pTHX_ SV *self, HV *clients_hv, HV *conns_hv,
                     const char *cname, STRLEN cname_len)
{
    SV **old_svp = hv_fetch(clients_hv, cname, cname_len, 0);
    SV *old_sock = NULL;
    IV old_fn;

    if (!old_svp || !SvOK(*old_svp)) return;

    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*old_svp);
        PUTBACK;
        count = call_method("socket", G_SCALAR);
        SPAGAIN;
        if (count > 0) { SV *s = POPs; if (SvOK(s)) old_sock = newSVsv(s); }
        PUTBACK;
        FREETMPS; LEAVE;
    }

    if (!old_sock) return;

    old_fn = _sock_fileno(aTHX_ old_sock);
    if (old_fn >= 0) {
        char ofn[32];
        int ofn_len = my_snprintf(ofn, sizeof(ofn), "%" IVdf, old_fn);
        if (hv_exists(conns_hv, ofn, ofn_len))
            _hub_remove_conn(aTHX_ self, old_fn, old_sock);
    }
    SvREFCNT_dec(old_sock);
}

/* ---- Process a __handshake message ---- */

static int
_hub_process_handshake(pTHX_ SV *self, HV *hv, SV *conn, IV fh_fileno,
                       SV *fh, SV *data_sv, SV *token_sv)
{
    HV *hdata_hv;
    SV **htok_svp, **hname_svp;

    if (!data_sv || !SvOK(data_sv) || !SvROK(data_sv))
        return 0;

    hdata_hv  = (HV *)SvRV(data_sv);
    htok_svp  = hv_fetchs(hdata_hv, "token", 0);
    hname_svp = hv_fetchs(hdata_hv, "name", 0);

    /* Verify token */
    if (!htok_svp || !SvOK(*htok_svp) ||
        !token_sv || !SvOK(token_sv) ||
        !sv_eq(*htok_svp, token_sv)) {
        warn("Hub: rejected unauthenticated connection\n");
        _hub_remove_conn(aTHX_ self, fh_fileno, fh);
        return -1; /* break */
    }

    if (hname_svp && SvOK(*hname_svp)) {
        STRLEN cname_len;
        const char *cname = SvPV(*hname_svp, cname_len);
        SV **clients_svp = hv_fetchs(hv, "_clients", 0);
        SV **conns_svp   = hv_fetchs(hv, "_conns", 0);

        /* Evict old client with same name */
        if (clients_svp && SvROK(*clients_svp) &&
            conns_svp && SvROK(*conns_svp)) {
            _hub_evict_duplicate(aTHX_ self,
                (HV *)SvRV(*clients_svp),
                (HV *)SvRV(*conns_svp),
                cname, cname_len);
        }

        /* $conn->set_name($name) */
        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(conn);
            XPUSHs(*hname_svp);
            PUTBACK;
            call_method("set_name", G_DISCARD);
            FREETMPS; LEAVE;
        }

        /* $self->{_clients}{$name} = $conn */
        if (clients_svp && SvROK(*clients_svp)) {
            HV *clients_hv = (HV *)SvRV(*clients_svp);
            (void)hv_store(clients_hv, cname, cname_len,
                SvREFCNT_inc(conn), 0);
        }

        /* Fire on_connect */
        {
            SV **on_svp = hv_fetchs(hv, "_on_connect", 0);
            if (on_svp && SvOK(*on_svp))
                _sock_dispatch_cb(aTHX_ *on_svp, conn);
        }
    }

    return 0;
}

/* ---- Process messages from an existing connection ---- */

static void
_hub_dispatch_conn(pTHX_ SV *self, HV *hv, SV *fh, IV fh_fileno,
                   SV *conns_ref, SV *token_sv, SV *handlers_ref)
{
    char fn_str[32];
    int fn_len;
    SV **conn_svp;
    HV *conns_hv;
    SV *conn;
    SV **msg_svs = NULL;
    int msg_count = 0;
    int mi;

    fn_len = my_snprintf(fn_str, sizeof(fn_str), "%" IVdf, fh_fileno);
    conns_hv = (HV *)SvRV(conns_ref);
    conn_svp = hv_fetch(conns_hv, fn_str, fn_len, 0);
    if (!conn_svp || !SvOK(*conn_svp)) return;
    conn = *conn_svp;

    _sock_recv_messages(aTHX_ conn, &msg_svs, &msg_count);

    if (msg_count == 0) {
        if (!_sock_is_connected(aTHX_ conn)) {
            _hub_remove_conn(aTHX_ self, fh_fileno, fh);
            return;
        }
    }

    for (mi = 0; mi < msg_count; mi++) {
        HV *msg_hv;
        SV **ch_svp, **data_svp;

        if (!SvOK(msg_svs[mi]) || !SvROK(msg_svs[mi])) continue;
        msg_hv   = (HV *)SvRV(msg_svs[mi]);
        ch_svp   = hv_fetchs(msg_hv, "channel", 0);
        data_svp = hv_fetchs(msg_hv, "data", 0);

        if (ch_svp && SvOK(*ch_svp) &&
            strEQ(SvPV_nolen(*ch_svp), "__handshake")) {
            int rc = _hub_process_handshake(aTHX_ self, hv, conn,
                fh_fileno, fh,
                data_svp ? *data_svp : NULL, token_sv);
            if (rc < 0) break;

        } else if (ch_svp && SvOK(*ch_svp) &&
                   handlers_ref && SvROK(handlers_ref)) {
            HV *hnd_hv = (HV *)SvRV(handlers_ref);
            STRLEN ch_len;
            const char *ch_str = SvPV(*ch_svp, ch_len);
            SV **hnd_svp = hv_fetch(hnd_hv, ch_str, ch_len, 0);
            if (hnd_svp && SvOK(*hnd_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(data_svp ? *data_svp : &PL_sv_undef);
                XPUSHs(conn);
                PUTBACK;
                call_sv(*hnd_svp, G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
    }

    _sock_free_sv_array(aTHX_ msg_svs, msg_count);
}

/* ---- Poll for new connections and incoming messages ---- */

static void
_hub_do_poll(pTHX_ SV *self)
{
    HV *hv = (HV *)SvRV(self);
    SV **select_svp   = hv_fetchs(hv, "_select", 0);
    SV **listener_svp = hv_fetchs(hv, "_listener", 0);
    SV **conns_svp    = hv_fetchs(hv, "_conns", 0);
    SV **token_svp    = hv_fetchs(hv, "_token", 0);
    SV **handlers_svp = hv_fetchs(hv, "_handlers", 0);
    IV listener_fileno;
    SV **ready_svs = NULL;
    int ready_count = 0;
    int ri;

    if (!select_svp   || !SvOK(*select_svp))   return;
    if (!listener_svp || !SvOK(*listener_svp))  return;
    if (!conns_svp    || !SvROK(*conns_svp))    return;

    listener_fileno = _sock_fileno(aTHX_ *listener_svp);

    _sock_can_read(aTHX_ *select_svp, &ready_svs, &ready_count);

    for (ri = 0; ri < ready_count; ri++) {
        SV *fh = ready_svs[ri];
        IV fh_fileno = _sock_fileno(aTHX_ fh);

        if (fh_fileno == listener_fileno) {
            _hub_accept_client(aTHX_ *listener_svp,
                *select_svp, *conns_svp);
        } else {
            _hub_dispatch_conn(aTHX_ self, hv, fh, fh_fileno,
                *conns_svp,
                (token_svp && SvOK(*token_svp)) ? *token_svp : NULL,
                handlers_svp ? *handlers_svp : NULL);
        }
    }

    _sock_free_sv_array(aTHX_ ready_svs, ready_count);
}

/* ---- Broadcast to all connections ---- */

static void
_hub_do_broadcast(pTHX_ SV *self, SV *channel, SV *data)
{
    HV *hv = (HV *)SvRV(self);
    SV **conns_svp = hv_fetchs(hv, "_conns", 0);
    HV *conns_hv;
    HE *entry;

    if (!conns_svp || !SvROK(*conns_svp)) return;
    conns_hv = (HV *)SvRV(*conns_svp);

    hv_iterinit(conns_hv);
    while ((entry = hv_iternext(conns_hv)) != NULL) {
        SV *conn = hv_iterval(conns_hv, entry);
        if (SvOK(conn))
            _sock_conn_send(aTHX_ conn, SvPV_nolen(channel), data);
    }
}

/* ---- Close hub: shutdown all connections, cleanup files ---- */

static void
_hub_do_close(pTHX_ SV *self)
{
    HV *hv = (HV *)SvRV(self);
    SV **conns_svp      = hv_fetchs(hv, "_conns", 0);
    SV **listener_svp   = hv_fetchs(hv, "_listener", 0);
    SV **select_svp     = hv_fetchs(hv, "_select", 0);
    SV **token_path_svp = hv_fetchs(hv, "_token_path", 0);
    SV **sock_path_svp  = hv_fetchs(hv, "_socket_path", 0);

    if (conns_svp && SvROK(*conns_svp)) {
        HV *conns_hv = (HV *)SvRV(*conns_svp);
        HE *entry;

        hv_iterinit(conns_hv);
        while ((entry = hv_iternext(conns_hv)) != NULL) {
            SV *conn = hv_iterval(conns_hv, entry);
            if (SvOK(conn)) {
                _sock_conn_send(aTHX_ conn, "__shutdown",
                    sv_2mortal(newRV_noinc((SV *)newHV())));
                _sock_call_void(aTHX_ conn, "close");
            }
        }
    }

    (void)hv_stores(hv, "_conns",   newRV_noinc((SV *)newHV()));
    (void)hv_stores(hv, "_clients", newRV_noinc((SV *)newHV()));

    if (listener_svp && SvOK(*listener_svp)) {
        if (select_svp && SvOK(*select_svp))
            _sock_select_remove(aTHX_ *select_svp, *listener_svp);
        _sock_call_void(aTHX_ *listener_svp, "close");
        (void)hv_stores(hv, "_listener", newSV(0));
    }

    if (token_path_svp && SvOK(*token_path_svp)) {
        const char *tp = SvPV_nolen(*token_path_svp);
        Stat_t st;
        if (PerlLIO_stat(tp, &st) == 0)
            (void)unlink(tp);
    }

    if (sock_path_svp && SvOK(*sock_path_svp)) {
        const char *sp = SvPV_nolen(*sock_path_svp);
        Stat_t st;
        if (PerlLIO_stat(sp, &st) == 0)
            (void)unlink(sp);
    }
}

#endif /* CHANDRA_SOCKET_HUB_H */
