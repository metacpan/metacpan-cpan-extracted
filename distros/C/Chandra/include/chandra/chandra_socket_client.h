#ifndef CHANDRA_SOCKET_CLIENT_H
#define CHANDRA_SOCKET_CLIENT_H

/*
 * chandra_socket_client.h — C helpers for Chandra::Socket::Client
 *
 * Static functions for connect, poll, and reconnect.
 * Depends on chandra_socket_common.h for shared utilities.
 */

/* ---- Connect via TCP (plain or TLS) ---- */

static SV *
_client_connect_tcp(pTHX_ HV *hv)
{
    SV **tls_svp  = hv_fetchs(hv, "tls", 0);
    SV **host_svp = hv_fetchs(hv, "host", 0);
    SV **port_svp = hv_fetchs(hv, "port", 0);
    SV *host = host_svp ? *host_svp : sv_2mortal(newSVpvs("127.0.0.1"));
    SV *port = port_svp ? *port_svp : &PL_sv_undef;
    SV *sock;

    if (tls_svp && SvTRUE(*tls_svp)) {
        SV **tls_ca_svp = hv_fetchs(hv, "tls_ca", 0);
        sock = _sock_tls_connect(aTHX_ host, port,
            (tls_ca_svp && SvOK(*tls_ca_svp)) ? *tls_ca_svp : NULL);
    } else {
        sock = _sock_tcp_connect(aTHX_ host, port);
    }

    if (sock)
        _sock_set_nonblocking(aTHX_ sock);

    return sock;
}

/* ---- Connect via Unix domain socket ---- */

static SV *
_client_connect_unix(pTHX_ HV *hv)
{
    SV **hub_name_svp = hv_fetchs(hv, "hub_name", 0);
    SV **explicit_svp = hv_fetchs(hv, "_explicit_token", 0);
    const char *hub = (hub_name_svp && SvOK(*hub_name_svp))
        ? SvPV_nolen(*hub_name_svp) : "default";
    SV *path_sv, *sock;

    path_sv = _sock_build_path(aTHX_ hub);
    sock = _sock_unix_connect(aTHX_ path_sv);

    if (sock) {
        _sock_set_nonblocking(aTHX_ sock);

        /* Read token from file unless explicitly provided */
        if (!explicit_svp || !SvTRUE(*explicit_svp)) {
            SV *tok = _sock_read_token_file(aTHX_ SvPV_nolen(path_sv));
            if (tok)
                (void)hv_stores(hv, "_token", tok);
        }
    }

    SvREFCNT_dec(path_sv);
    return sock;
}

/* ---- Send handshake message on a connection ---- */

static void
_client_send_handshake(pTHX_ HV *hv)
{
    SV **conn_svp  = hv_fetchs(hv, "_conn", 0);
    SV **name_svp  = hv_fetchs(hv, "name", 0);
    SV **token_svp = hv_fetchs(hv, "_token", 0);
    HV *hs;

    if (!conn_svp || !SvOK(*conn_svp)) return;

    hs = newHV();
    if (name_svp && SvOK(*name_svp))
        (void)hv_stores(hs, "name", newSVsv(*name_svp));
    if (token_svp && SvOK(*token_svp))
        (void)hv_stores(hs, "token", newSVsv(*token_svp));

    _sock_conn_send(aTHX_ *conn_svp, "__handshake",
        sv_2mortal(newRV_noinc((SV *)hs)));
}

/* ---- Connect to a Hub ---- */

static int
_client_do_connect(pTHX_ SV *self)
{
    HV *hv = (HV *)SvRV(self);
    SV **transport_svp = hv_fetchs(hv, "transport", 0);
    const char *transport;
    SV *sock;
    SV *conn;
    SV **name_svp;

    transport = (transport_svp && SvOK(*transport_svp))
        ? SvPV_nolen(*transport_svp) : "unix";

#ifdef _WIN32
    /* Auto-upgrade to TCP on Windows */
    if (!strEQ(transport, "tcp")) {
        transport = "tcp";
        (void)hv_stores(hv, "transport", newSVpvs("tcp"));
    }

    /* If connecting by hub name (no explicit port), read discovery file */
    {
        SV **port_svp  = hv_fetchs(hv, "port", 0);
        SV **hub_svp   = hv_fetchs(hv, "hub_name", 0);
        if ((!port_svp || !SvOK(*port_svp)) && hub_svp && SvOK(*hub_svp)) {
            SV *disc_path = _sock_build_path(aTHX_ SvPV_nolen(*hub_svp));
            const char *dpath = SvPV_nolen(disc_path);
            FILE *dfh = fopen(dpath, "rb");
            if (dfh) {
                char line[256];
                /* Line 1: port */
                if (fgets(line, sizeof(line), dfh)) {
                    IV port = atoi(line);
                    if (port > 0)
                        (void)hv_stores(hv, "port", newSViv(port));
                }
                /* Line 2: token (if not explicitly provided) */
                {
                    SV **explicit_svp = hv_fetchs(hv, "_explicit_token", 0);
                    if ((!explicit_svp || !SvTRUE(*explicit_svp))
                        && fgets(line, sizeof(line), dfh)) {
                        /* Strip trailing newline */
                        size_t len = strlen(line);
                        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
                            line[--len] = '\0';
                        if (len > 0)
                            (void)hv_stores(hv, "_token", newSVpvn(line, len));
                    }
                }
                fclose(dfh);
            }
            SvREFCNT_dec(disc_path);
        }
    }
#endif
    if (strEQ(transport, "tcp"))
        sock = _client_connect_tcp(aTHX_ hv);
    else
        sock = _client_connect_unix(aTHX_ hv);

    if (!sock) return 0;

    name_svp = hv_fetchs(hv, "name", 0);
    conn = _sock_connection_new(aTHX_ sock,
        (name_svp && SvOK(*name_svp)) ? *name_svp : NULL);

    (void)hv_stores(hv, "_conn", conn ? conn : newSV(0));
    _client_send_handshake(aTHX_ hv);
    (void)hv_stores(hv, "_retry_delay", newSVnv(0.1));

    SvREFCNT_dec(sock);
    return 1;
}

/* ---- Reconnect with exponential back-off ---- */

static void
_client_do_reconnect(pTHX_ SV *self)
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);

    if (conn_svp && SvOK(*conn_svp) && SvROK(*conn_svp)) {
        _sock_call_void(aTHX_ *conn_svp, "close");
        (void)hv_stores(hv, "_conn", newSV(0));
    }

    if (!_client_do_connect(aTHX_ self)) {
        SV **delay_svp = hv_fetchs(hv, "_retry_delay", 0);
        SV **max_svp   = hv_fetchs(hv, "_max_retry", 0);
        NV delay     = (delay_svp && SvOK(*delay_svp))
            ? SvNV(*delay_svp) : 0.1;
        NV max_retry = (max_svp && SvOK(*max_svp))
            ? SvNV(*max_svp) : 5.0;
        if (delay < max_retry)
            (void)hv_stores(hv, "_retry_delay", newSVnv(delay * 2));
    }
}

/* ---- Dispatch a pending reply callback ---- */

static int
_client_dispatch_reply(pTHX_ HV *hv, SV *reply_sv, SV *data)
{
    SV **pending_svp;
    HV *pending_hv;
    STRLEN rlen;
    const char *rstr;
    SV **cb_svp;
    SV *cb;

    if (!reply_sv || !SvOK(reply_sv)) return 0;

    pending_svp = hv_fetchs(hv, "_pending", 0);
    if (!pending_svp || !SvROK(*pending_svp)) return 0;

    pending_hv = (HV *)SvRV(*pending_svp);
    rstr = SvPV(reply_sv, rlen);
    cb_svp = hv_fetch(pending_hv, rstr, rlen, 0);
    if (!cb_svp || !SvOK(*cb_svp)) return 0;

    cb = newSVsv(*cb_svp);
    (void)hv_delete(pending_hv, rstr, rlen, G_DISCARD);
    _sock_dispatch_cb(aTHX_ cb, data ? data : &PL_sv_undef);
    SvREFCNT_dec(cb);
    return 1;
}

/* ---- Dispatch a channel handler ---- */

static void
_client_dispatch_channel(pTHX_ HV *hv, SV *channel, SV *data)
{
    SV **handlers_svp;
    HV *hnd_hv;
    STRLEN ch_len;
    const char *ch_str;
    SV **hnd_svp;

    if (!channel || !SvOK(channel)) return;

    handlers_svp = hv_fetchs(hv, "_handlers", 0);
    if (!handlers_svp || !SvROK(*handlers_svp)) return;

    hnd_hv = (HV *)SvRV(*handlers_svp);
    ch_str = SvPV(channel, ch_len);
    hnd_svp = hv_fetch(hnd_hv, ch_str, ch_len, 0);
    if (!hnd_svp || !SvOK(*hnd_svp)) return;

    _sock_dispatch_cb(aTHX_ *hnd_svp, data ? data : &PL_sv_undef);
}

/* ---- Poll for incoming messages ---- */

static void
_client_do_poll(pTHX_ SV *self)
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_conn", 0);
    SV **msg_svs = NULL;
    int msg_count = 0;
    int mi;

    if (!conn_svp || !SvOK(*conn_svp) || !SvROK(*conn_svp) ||
        !_sock_is_connected(aTHX_ *conn_svp)) {
        _client_do_reconnect(aTHX_ self);
        return;
    }

    _sock_recv_messages(aTHX_ *conn_svp, &msg_svs, &msg_count);

    if (msg_count == 0) {
        conn_svp = hv_fetchs(hv, "_conn", 0);
        if (!conn_svp || !SvOK(*conn_svp) || !SvROK(*conn_svp) ||
            !_sock_is_connected(aTHX_ *conn_svp)) {
            _client_do_reconnect(aTHX_ self);
            return;
        }
    }

    for (mi = 0; mi < msg_count; mi++) {
        HV *msg_hv;
        SV **reply_svp, **ch_svp, **data_svp;

        if (!SvOK(msg_svs[mi]) || !SvROK(msg_svs[mi])) continue;
        msg_hv    = (HV *)SvRV(msg_svs[mi]);
        reply_svp = hv_fetchs(msg_hv, "_reply_to", 0);
        ch_svp    = hv_fetchs(msg_hv, "channel", 0);
        data_svp  = hv_fetchs(msg_hv, "data", 0);

        /* Handle __token_rotate from hub */
        if (ch_svp && SvOK(*ch_svp) &&
            strEQ(SvPV_nolen(*ch_svp), "__token_rotate")) {
            if (data_svp && SvOK(*data_svp) && SvROK(*data_svp)) {
                HV *td = (HV *)SvRV(*data_svp);
                SV **new_tok_svp = hv_fetchs(td, "token", 0);
                if (new_tok_svp && SvOK(*new_tok_svp)) {
                    (void)hv_stores(hv, "_token",
                        newSVsv(*new_tok_svp));
                    /* Fire on_token_refresh callback */
                    {
                        SV **cb_svp2 = hv_fetchs(hv,
                            "_on_token_refresh", 0);
                        if (cb_svp2 && SvOK(*cb_svp2)
                            && SvROK(*cb_svp2)) {
                            _sock_dispatch_cb(aTHX_ *cb_svp2,
                                *new_tok_svp);
                        }
                    }
                }
            }
            continue;
        }

        if (_client_dispatch_reply(aTHX_ hv,
                reply_svp ? *reply_svp : NULL,
                data_svp ? *data_svp : NULL))
            continue;

        _client_dispatch_channel(aTHX_ hv,
            ch_svp ? *ch_svp : NULL,
            data_svp ? *data_svp : NULL);
    }

    _sock_free_sv_array(aTHX_ msg_svs, msg_count);
}

#endif /* CHANDRA_SOCKET_CLIENT_H */
