MODULE = Chandra    PACKAGE = Chandra::Socket::Connection

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    SV *socket_sv = NULL;
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "socket")) {
            socket_sv = val;
            (void)hv_stores(self_hv, "socket", newSVsv(val));
        } else if (strEQ(key, "name")) {
            (void)hv_stores(self_hv, "name", newSVsv(val));
        }
    }

    (void)hv_stores(self_hv, "_buf", newSVpvs(""));
    (void)hv_stores(self_hv, "_connected",
        newSViv(socket_sv && SvOK(socket_sv) ? 1 : 0));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
        gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
socket(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "socket", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
name(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "name", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

void
set_name(self, name_sv)
    SV *self
    SV *name_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "name", newSVsv(name_sv));
}

int
is_connected(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **conn_svp = hv_fetchs(hv, "_connected", 0);
    SV **sock_svp = hv_fetchs(hv, "socket", 0);
    RETVAL = (conn_svp && SvTRUE(*conn_svp) &&
              sock_svp && SvOK(*sock_svp)) ? 1 : 0;
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
    SV **conn_svp = hv_fetchs(hv, "_connected", 0);
    SV **sock_svp = hv_fetchs(hv, "socket", 0);

    if (!conn_svp || !SvTRUE(*conn_svp) || !sock_svp || !SvOK(*sock_svp)) {
        RETVAL = newSViv(0);
    } else {
        HV *msg_hv = newHV();
        SV **name_svp;
        int success;

        (void)hv_stores(msg_hv, "channel", newSVsv(channel_sv));
        (void)hv_stores(msg_hv, "data", newSVsv(data_sv));

        /* Add 'from' if name is set and truthy */
        name_svp = hv_fetchs(hv, "name", 0);
        if (name_svp && SvOK(*name_svp) && SvTRUE(*name_svp)) {
            (void)hv_stores(msg_hv, "from", newSVsv(*name_svp));
        }

        /* Merge extra hash if provided */
        if (items > 3 && SvOK(ST(3)) && SvROK(ST(3)) &&
            SvTYPE(SvRV(ST(3))) == SVt_PVHV) {
            HV *extra = (HV *)SvRV(ST(3));
            HE *entry;
            hv_iterinit(extra);
            while ((entry = hv_iternext(extra)) != NULL) {
                I32 klen;
                const char *key = hv_iterkey(entry, &klen);
                SV *val = hv_iterval(extra, entry);
                (void)hv_store(msg_hv, key, klen, newSVsv(val), 0);
            }
        }

        /* Call _xs_do_send($socket, \%msg) */
        {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*sock_svp);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)msg_hv)));
            PUTBACK;
            count = call_pv("Chandra::Socket::Connection::_xs_do_send",
                G_SCALAR);
            SPAGAIN;
            if (count > 0) { SV *tmp = POPs; success = SvIV(tmp); }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }

        RETVAL = newSViv(success);
    }
}
OUTPUT:
    RETVAL

SV *
reply(self, orig_msg_sv, data_sv)
    SV *self
    SV *orig_msg_sv
    SV *data_sv
CODE:
{
    if (!SvOK(orig_msg_sv) || !SvROK(orig_msg_sv) ||
        SvTYPE(SvRV(orig_msg_sv)) != SVt_PVHV) {
        RETVAL = newSViv(0);
    } else {
        HV *orig_hv = (HV *)SvRV(orig_msg_sv);
        SV **id_svp = hv_fetchs(orig_hv, "_id", 0);

        if (!id_svp || !SvOK(*id_svp)) {
            RETVAL = newSViv(0);
        } else {
            SV **ch_svp = hv_fetchs(orig_hv, "channel", 0);
            HV *extra_hv = newHV();
            int count;

            (void)hv_stores(extra_hv, "_reply_to", newSVsv(*id_svp));

            {
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(self);
                XPUSHs(ch_svp && SvOK(*ch_svp) ? *ch_svp : &PL_sv_undef);
                XPUSHs(data_sv);
                XPUSHs(sv_2mortal(newRV_noinc((SV *)extra_hv)));
                PUTBACK;
                count = call_method("send", G_SCALAR);
                SPAGAIN;
                RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : newSViv(0);
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
    }
}
OUTPUT:
    RETVAL

void
recv(self)
    SV *self
PPCODE:
{
    /* Delegate entirely to Perl helper _xs_do_recv which handles
       sysread, buffering, frame decoding, and returns a list of msgs */
    int count, i;
    SV **results;

    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        count = call_pv("Chandra::Socket::Connection::_xs_do_recv", G_ARRAY);
        SPAGAIN;

        if (count > 0) {
            /* Allocate temp array to save results before FREETMPS */
            Newx(results, count, SV *);
            for (i = count - 1; i >= 0; i--) {
                results[i] = newSVsv(POPs);
            }
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    /* Now push saved results onto the PPCODE return stack */
    for (i = 0; i < count; i++) {
        XPUSHs(sv_2mortal(results[i]));
    }
    if (count > 0) Safefree(results);
}

void
close(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **sock_svp;

    (void)hv_stores(hv, "_connected", newSViv(0));

    sock_svp = hv_fetchs(hv, "socket", 0);
    if (sock_svp && SvOK(*sock_svp)) {
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*sock_svp);
            PUTBACK;
            call_method("close", G_DISCARD);
            FREETMPS;
            LEAVE;
        }
        (void)hv_stores(hv, "socket", newSVsv(&PL_sv_undef));
    }
}

SV *
encode_frame(class, msg_sv)
    SV *class
    SV *msg_sv
CODE:
{
    SV *json_sv;
    const char *json_str;
    STRLEN json_len;
    char header[4];

    /* JSON encode */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(msg_sv);
        PUTBACK;
        count = call_pv("Chandra::Socket::Connection::_xs_json_encode",
            G_SCALAR);
        SPAGAIN;
        json_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    json_str = SvPV(json_sv, json_len);

    /* Build frame: 4-byte big-endian length + JSON payload */
    header[0] = (json_len >> 24) & 0xFF;
    header[1] = (json_len >> 16) & 0xFF;
    header[2] = (json_len >> 8) & 0xFF;
    header[3] = json_len & 0xFF;

    RETVAL = newSV(4 + json_len);
    SvPOK_on(RETVAL);
    Copy(header, SvPVX(RETVAL), 4, char);
    Copy(json_str, SvPVX(RETVAL) + 4, json_len, char);
    SvCUR_set(RETVAL, 4 + json_len);

    SvREFCNT_dec(json_sv);
}
OUTPUT:
    RETVAL

void
decode_frames(class, data_sv)
    SV *class
    SV *data_sv
PPCODE:
{
    AV *result = newAV();
    I32 ri, result_count;

    if (SvOK(data_sv)) {
        const char *buf;
        STRLEN buf_len;
        STRLEN consumed = 0;

        buf = SvPV(data_sv, buf_len);

        while (buf_len - consumed >= 4) {
            const unsigned char *p =
                (const unsigned char *)(buf + consumed);
            UV frame_len = ((UV)p[0] << 24) | ((UV)p[1] << 16) |
                           ((UV)p[2] << 8)  | (UV)p[3];

            if (buf_len - consumed < 4 + frame_len) break;

            /* JSON decode payload */
            {
                SV *msg_sv = NULL;
                dSP;
                int count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVpvn(
                    buf + consumed + 4, frame_len)));
                PUTBACK;
                count = call_pv(
                    "Chandra::Socket::Connection::_xs_json_decode",
                    G_SCALAR);
                SPAGAIN;
                if (count > 0) msg_sv = newSVsv(POPs);
                PUTBACK;
                FREETMPS;
                LEAVE;

                if (msg_sv && SvOK(msg_sv)) {
                    av_push(result, msg_sv);
                } else {
                    if (msg_sv) SvREFCNT_dec(msg_sv);
                }
            }

            consumed += 4 + frame_len;
        }
    }

    /* Push all decoded messages onto Perl stack */
    result_count = av_len(result) + 1;
    for (ri = 0; ri < result_count; ri++) {
        SV **svp = av_fetch(result, ri, 0);
        if (svp) XPUSHs(sv_2mortal(SvREFCNT_inc(*svp)));
    }
    SvREFCNT_dec((SV *)result);
}

int
_xs_do_send(socket_sv, msg_sv)
    SV *socket_sv
    SV *msg_sv
CODE:
{
    SV *json_enc = get_sv("Chandra::Socket::Connection::_xs_json", 0);
    SV *payload = NULL;
    STRLEN payload_len, frame_len;
    unsigned char len_buf[4];
    SV *frame;

    /* $payload = $_xs_json->encode($msg) */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(json_enc);
        XPUSHs(msg_sv);
        PUTBACK;
        count = call_method("encode", G_SCALAR);
        SPAGAIN;
        payload = (count > 0) ? newSVsv(POPs) : newSVpvs("");
        PUTBACK;
        FREETMPS; LEAVE;
    }

    payload_len = SvCUR(payload);

    /* pack('N', length) . payload — build frame in C */
    len_buf[0] = (payload_len >> 24) & 0xFF;
    len_buf[1] = (payload_len >> 16) & 0xFF;
    len_buf[2] = (payload_len >> 8) & 0xFF;
    len_buf[3] = payload_len & 0xFF;

    frame = newSVpvn((char *)len_buf, 4);
    sv_catsv(frame, payload);
    SvREFCNT_dec(payload);
    frame_len = SvCUR(frame);

    /* Ignore SIGPIPE during syswrite — portable across OS */
    {
        SigpipeGuard spg;
        SV *written_sv;
        sigpipe_ignore(&spg);

        /* $socket->syswrite($frame) */
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(socket_sv);
            XPUSHs(frame);
            PUTBACK;
            count = call_method("syswrite", G_SCALAR);
            SPAGAIN;
            written_sv = (count > 0) ? POPs : &PL_sv_undef;
            if (SvOK(written_sv) && SvIV(written_sv) == (IV)frame_len) {
                RETVAL = 1;
            } else {
                RETVAL = 0;
            }
            PUTBACK;
            FREETMPS; LEAVE;
        }

        sigpipe_restore(&spg);
    }

    SvREFCNT_dec(frame);
}
OUTPUT:
    RETVAL

void
_xs_do_recv(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **connected_svp = hv_fetchs(hv, "_connected", 0);
    SV **sock_svp = hv_fetchs(hv, "socket", 0);
    SV **buf_svp;
    AV *messages = newAV();
    I32 mi, msg_count;

    if (!connected_svp || !SvTRUE(*connected_svp) ||
        !sock_svp || !SvOK(*sock_svp)) {
        goto return_messages;
    }

    /* sysread */
    {
        SV *read_buf = newSV(65536);
        SvPOK_on(read_buf);
        SvCUR_set(read_buf, 0);

        {
            dSP;
            int count;
            SV *read_result;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*sock_svp);
            XPUSHs(read_buf);
            XPUSHs(sv_2mortal(newSViv(65536)));
            PUTBACK;
            count = call_method("sysread", G_SCALAR);
            SPAGAIN;
            read_result = (count > 0) ? POPs : &PL_sv_undef;

            if (SvOK(read_result) && SvIV(read_result) > 0) {
                /* Append to buffer */
                buf_svp = hv_fetchs(hv, "_buf", 0);
                if (buf_svp && SvOK(*buf_svp)) {
                    sv_catsv(*buf_svp, read_buf);
                } else {
                    (void)hv_stores(hv, "_buf", newSVsv(read_buf));
                }

                buf_svp = hv_fetchs(hv, "_buf", 0);
                if (buf_svp && SvCUR(*buf_svp) > 64 * 1024 * 1024) {
                    warn("Chandra::Socket::Connection: buffer overflow, disconnecting\n");
                    (void)hv_stores(hv, "_connected", newSViv(0));
                    (void)hv_stores(hv, "_buf", newSVpvs(""));
                    SvREFCNT_dec(read_buf);
                    PUTBACK; FREETMPS; LEAVE;
                    goto return_messages;
                }
            } else if (!SvOK(read_result)) {
                /* Check errno for EAGAIN/EWOULDBLOCK */
                int err_no = errno;
#ifdef EAGAIN
                if (err_no == EAGAIN) { PUTBACK; FREETMPS; LEAVE; SvREFCNT_dec(read_buf); goto parse_frames; }
#endif
#ifdef EWOULDBLOCK
                if (err_no == EWOULDBLOCK) { PUTBACK; FREETMPS; LEAVE; SvREFCNT_dec(read_buf); goto parse_frames; }
#endif
                (void)hv_stores(hv, "_connected", newSViv(0));
                SvREFCNT_dec(read_buf);
                PUTBACK; FREETMPS; LEAVE;
                goto return_messages;
            } else if (SvIV(read_result) == 0) {
                (void)hv_stores(hv, "_connected", newSViv(0));
                SvREFCNT_dec(read_buf);
                PUTBACK; FREETMPS; LEAVE;
                goto return_messages;
            }

            PUTBACK; FREETMPS; LEAVE;
        }

        SvREFCNT_dec(read_buf);
    }

    parse_frames:
    /* Parse length-prefixed frames from buffer */
    buf_svp = hv_fetchs(hv, "_buf", 0);
    if (buf_svp && SvOK(*buf_svp)) {
        SV *json_enc = get_sv("Chandra::Socket::Connection::_xs_json", 0);

        while (SvCUR(*buf_svp) >= 4) {
            const unsigned char *p = (const unsigned char *)SvPVX(*buf_svp);
            UV frame_len = ((UV)p[0] << 24) | ((UV)p[1] << 16) |
                           ((UV)p[2] << 8) | (UV)p[3];

            if (frame_len > 16 * 1024 * 1024) {
                warn("Chandra::Socket::Connection: frame too large (%" UVuf " bytes), disconnecting\n", frame_len);
                (void)hv_stores(hv, "_connected", newSViv(0));
                (void)hv_stores(hv, "_buf", newSVpvs(""));
                goto return_messages;
            }

            if (SvCUR(*buf_svp) < 4 + frame_len) break;

            /* Extract payload and advance buffer */
            {
                SV *payload = newSVpvn(SvPVX(*buf_svp) + 4, (STRLEN)frame_len);
                SV *remaining = newSVpvn(
                    SvPVX(*buf_svp) + 4 + frame_len,
                    SvCUR(*buf_svp) - 4 - (STRLEN)frame_len);
                sv_setsv(*buf_svp, remaining);
                SvREFCNT_dec(remaining);

                /* JSON decode */
                {
                    dSP;
                    int count;
                    SV *decoded;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(json_enc);
                    XPUSHs(payload);
                    PUTBACK;
                    count = call_method("decode", G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (count > 0 && !SvTRUE(ERRSV)) {
                        decoded = newSVsv(POPs);
                        av_push(messages, decoded);
                    } else {
                        warn("Chandra::Socket::Connection: malformed JSON frame\n");
                        if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
                    }
                    PUTBACK;
                    FREETMPS; LEAVE;
                }

                SvREFCNT_dec(payload);
            }
        }
    }

    return_messages:
    msg_count = av_len(messages) + 1;
    for (mi = 0; mi < msg_count; mi++) {
        SV **svp = av_fetch(messages, mi, 0);
        if (svp) XPUSHs(sv_2mortal(SvREFCNT_inc(*svp)));
    }
    SvREFCNT_dec((SV *)messages);
}

SV *
_xs_json_encode(data_sv)
    SV *data_sv
CODE:
{
    SV *json_enc = get_sv("Chandra::Socket::Connection::_xs_json", 0);
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json_enc);
    XPUSHs(data_sv);
    PUTBACK;
    count = call_method("encode", G_SCALAR);
    SPAGAIN;
    RETVAL = (count > 0) ? newSVsv(POPs) : newSVpvs("");
    PUTBACK;
    FREETMPS; LEAVE;
}
OUTPUT:
    RETVAL

SV *
_xs_json_decode(str_sv)
    SV *str_sv
CODE:
{
    SV *json_enc = get_sv("Chandra::Socket::Connection::_xs_json", 0);
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json_enc);
    XPUSHs(str_sv);
    PUTBACK;
    count = call_method("decode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count > 0 && !SvTRUE(ERRSV)) {
        RETVAL = newSVsv(POPs);
    } else {
        RETVAL = &PL_sv_undef;
        if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
    }
    PUTBACK;
    FREETMPS; LEAVE;
}
OUTPUT:
    RETVAL
