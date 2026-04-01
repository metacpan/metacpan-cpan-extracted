MODULE = Chandra    PACKAGE = Chandra::Bind

PROTOTYPES: DISABLE

BOOT:
{
    _bind_registry = newHV();
}

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    int i;
    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", SvREFCNT_inc(ST(i + 1)));
        }
    }
    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
bind(self, name, callback)
    SV *self
    SV *name
    SV *callback
CODE:
{
    if (!SvOK(name))
        croak("bind() requires a name");
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("bind() requires a coderef");

    HV *reg = _bind_get_registry(aTHX);
    STRLEN nlen;
    const char *nstr = SvPV(name, nlen);
    (void)hv_store(reg, nstr, (I32)nlen, SvREFCNT_inc(SvRV(callback)), 0);

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
unbind(self, name)
    SV *self
    SV *name
CODE:
{
    HV *reg = _bind_get_registry(aTHX);
    STRLEN nlen;
    const char *nstr = SvPV(name, nlen);
    (void)hv_delete(reg, nstr, (I32)nlen, G_DISCARD);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

int
is_bound(self, name)
    SV *self
    SV *name
CODE:
{
    PERL_UNUSED_VAR(self);
    HV *reg = _bind_get_registry(aTHX);
    STRLEN nlen;
    const char *nstr = SvPV(name, nlen);
    RETVAL = hv_exists(reg, nstr, (I32)nlen);
}
OUTPUT:
    RETVAL

void
list(self)
    SV *self
PPCODE:
{
    PERL_UNUSED_VAR(self);
    HV *reg = _bind_get_registry(aTHX);
    I32 num = hv_iterinit(reg);
    HE *entry;
    EXTEND(SP, num);
    while ((entry = hv_iternext(reg)) != NULL) {
        PUSHs(sv_2mortal(newSVsv(hv_iterkeysv(entry))));
    }
}

void
register_handler(class, id, callback)
    SV *class
    SV *id
    SV *callback
CODE:
{
    PERL_UNUSED_VAR(class);
    HV *reg = _bind_get_registry(aTHX);
    STRLEN nlen;
    const char *nstr = SvPV(id, nlen);
    (void)hv_store(reg, nstr, (I32)nlen, SvREFCNT_inc(SvROK(callback) ? SvRV(callback) : callback), 0);
}

SV *
dispatch(self, json_str)
    SV *self
    SV *json_str
CODE:
{
    SV *err = NULL;
    SV *decoded = _bind_json_decode(aTHX_ json_str, &err);

    if (err) {
        /* warn "Chandra::Bind: Failed to parse JSON: $@" */
        warn("Chandra::Bind: Failed to parse JSON: %" SVf, SVfARG(err));
        HV *ret = newHV();
        SV *msg = newSVpvs("Invalid JSON: ");
        sv_catsv(msg, err);
        (void)hv_stores(ret, "error", msg);
        SvREFCNT_dec(err);
        RETVAL = newRV_noinc((SV *)ret);
    }
    else if (!SvROK(decoded) || SvTYPE(SvRV(decoded)) != SVt_PVHV) {
        /* Not a hash — raw */
        HV *ret = newHV();
        (void)hv_stores(ret, "type", newSVpvs("raw"));
        (void)hv_stores(ret, "data", SvREFCNT_inc(json_str));
        SvREFCNT_dec(decoded);
        RETVAL = newRV_noinc((SV *)ret);
    }
    else {
        HV *msg_hv = (HV *)SvRV(decoded);
        SV **type_svp = hv_fetchs(msg_hv, "type", 0);
        const char *type = (type_svp && *type_svp && SvOK(*type_svp))
                           ? SvPV_nolen(*type_svp) : "";

        if (strEQ(type, "call")) {
            /* === _handle_call === */
            SV **id_svp     = hv_fetchs(msg_hv, "id", 0);
            SV **method_svp = hv_fetchs(msg_hv, "method", 0);
            SV **args_svp   = hv_fetchs(msg_hv, "args", 0);

            SV *id_sv = (id_svp && *id_svp) ? *id_svp : &PL_sv_undef;
            const char *method = (method_svp && *method_svp && SvOK(*method_svp))
                                 ? SvPV_nolen(*method_svp) : "";

            HV *reg = _bind_get_registry(aTHX);
            STRLEN mlen = strlen(method);
            SV **handler_svp = hv_fetch(reg, method, (I32)mlen, 0);

            HV *ret = newHV();
            (void)hv_stores(ret, "id", SvREFCNT_inc(id_sv));

            if (!handler_svp || !*handler_svp) {
                SV *errmsg = newSVpvf("Unknown method: %s", method);
                (void)hv_stores(ret, "error", errmsg);
            }
            else {
                /* Build args array */
                AV *args_av = NULL;
                if (args_svp && *args_svp && SvROK(*args_svp)
                    && SvTYPE(SvRV(*args_svp)) == SVt_PVAV) {
                    args_av = (AV *)SvRV(*args_svp);
                }

                /* Call handler */
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                if (args_av) {
                    SSize_t len = av_len(args_av) + 1;
                    SSize_t j;
                    EXTEND(SP, len);
                    for (j = 0; j < len; j++) {
                        SV **elem = av_fetch(args_av, j, 0);
                        PUSHs(elem ? *elem : &PL_sv_undef);
                    }
                }
                PUTBACK;

                int count = call_sv(*handler_svp, G_SCALAR | G_EVAL);
                SPAGAIN;

                SV *call_result = &PL_sv_undef;
                if (count > 0) {
                    call_result = SvREFCNT_inc(POPs);
                }
                PUTBACK;

                if (SvTRUE(ERRSV)) {
                    SvREFCNT_dec(call_result);

                    /* Chandra::Error->capture($@, context => "call($method)", skip => 0) */
                    SV *saved_err = sv_2mortal(newSVsv(ERRSV));
                    SV *ctx_sv = sv_2mortal(newSVpvf("call(%s)", method));

                    PUSHMARK(SP);
                    XPUSHs(sv_2mortal(newSVpvs("Chandra::Error")));
                    XPUSHs(saved_err);
                    XPUSHs(sv_2mortal(newSVpvs("context")));
                    XPUSHs(ctx_sv);
                    XPUSHs(sv_2mortal(newSVpvs("skip")));
                    XPUSHs(sv_2mortal(newSViv(0)));
                    PUTBACK;

                    int ec = call_method("capture", G_SCALAR);
                    SPAGAIN;

                    if (ec > 0) {
                        SV *err_ref = POPs;
                        if (SvROK(err_ref) && SvTYPE(SvRV(err_ref)) == SVt_PVHV) {
                            HV *err_hv = (HV *)SvRV(err_ref);
                            SV **msg_svp = hv_fetchs(err_hv, "message", 0);
                            if (msg_svp && *msg_svp) {
                                (void)hv_stores(ret, "error", SvREFCNT_inc(*msg_svp));
                            }
                        }
                    }
                    PUTBACK;
                }
                else {
                    (void)hv_stores(ret, "result", call_result); /* already inc'd */
                }

                FREETMPS;
                LEAVE;
            }

            SvREFCNT_dec(decoded);
            RETVAL = newRV_noinc((SV *)ret);
        }
        else if (strEQ(type, "event")) {
            /* === _handle_event === */
            SV **handler_id_svp = hv_fetchs(msg_hv, "handler", 0);
            SV **event_data_svp = hv_fetchs(msg_hv, "event", 0);

            const char *handler_id = (handler_id_svp && *handler_id_svp && SvOK(*handler_id_svp))
                                     ? SvPV_nolen(*handler_id_svp) : "";

            HV *reg = _bind_get_registry(aTHX);
            STRLEN hlen = strlen(handler_id);
            SV **handler_svp = hv_fetch(reg, handler_id, (I32)hlen, 0);

            if (!handler_svp || !*handler_svp) {
                warn("Chandra::Bind: Unknown event handler: %s", handler_id);
                HV *ret = newHV();
                (void)hv_stores(ret, "error", newSVpvf("Unknown handler: %s", handler_id));
                SvREFCNT_dec(decoded);
                RETVAL = newRV_noinc((SV *)ret);
            }
            else {
                /* Create Event: Chandra::Event->new($event_data) */
                SV *event_data;
                if (event_data_svp && *event_data_svp && SvOK(*event_data_svp)) {
                    event_data = *event_data_svp;
                } else {
                    event_data = sv_2mortal(newRV_noinc((SV *)newHV()));
                }

                SV *event_obj;
                {
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(sv_2mortal(newSVpvs("Chandra::Event")));
                    XPUSHs(event_data);
                    PUTBACK;

                    int ec = call_method("new", G_SCALAR);
                    SPAGAIN;
                    event_obj = (ec > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
                    PUTBACK;
                    FREETMPS;
                    LEAVE;
                }

                /* Get app from self */
                HV *self_hv = (HV *)SvRV(self);
                SV **app_svp = hv_fetchs(self_hv, "app", 0);
                SV *app = (app_svp && *app_svp) ? *app_svp : &PL_sv_undef;

                /* Call handler($event, $app) */
                {
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(event_obj);
                    XPUSHs(app);
                    PUTBACK;

                    call_sv(*handler_svp, G_DISCARD | G_EVAL);
                    SPAGAIN;
                    PUTBACK;

                    if (SvTRUE(ERRSV)) {
                        SV *saved_err = sv_2mortal(newSVsv(ERRSV));
                        SV *ctx_sv = sv_2mortal(newSVpvf("event(%s)", handler_id));

                        PUSHMARK(SP);
                        XPUSHs(sv_2mortal(newSVpvs("Chandra::Error")));
                        XPUSHs(saved_err);
                        XPUSHs(sv_2mortal(newSVpvs("context")));
                        XPUSHs(ctx_sv);
                        XPUSHs(sv_2mortal(newSVpvs("skip")));
                        XPUSHs(sv_2mortal(newSViv(0)));
                        PUTBACK;

                        int cc = call_method("capture", G_SCALAR);
                        SPAGAIN;

                        HV *ret = newHV();
                        if (cc > 0) {
                            SV *err_ref = POPs;
                            if (SvROK(err_ref) && SvTYPE(SvRV(err_ref)) == SVt_PVHV) {
                                HV *err_hv = (HV *)SvRV(err_ref);

                                /* warn Chandra::Error->format_text($err) */
                                PUSHMARK(SP);
                                XPUSHs(sv_2mortal(newSVpvs("Chandra::Error")));
                                XPUSHs(err_ref);
                                PUTBACK;

                                int fc = call_method("format_text", G_SCALAR);
                                SPAGAIN;
                                if (fc > 0) {
                                    SV *fmt = POPs;
                                    warn("%" SVf, SVfARG(fmt));
                                }
                                PUTBACK;

                                SV **msg_svp = hv_fetchs(err_hv, "message", 0);
                                if (msg_svp && *msg_svp) {
                                    (void)hv_stores(ret, "error", SvREFCNT_inc(*msg_svp));
                                }
                            }
                        }
                        PUTBACK;

                        SvREFCNT_dec(event_obj);
                        SvREFCNT_dec(decoded);
                        FREETMPS;
                        LEAVE;
                        RETVAL = newRV_noinc((SV *)ret);
                    }
                    else {
                        SvREFCNT_dec(event_obj);
                        SvREFCNT_dec(decoded);
                        FREETMPS;
                        LEAVE;
                        HV *ret = newHV();
                        (void)hv_stores(ret, "ok", newSViv(1));
                        RETVAL = newRV_noinc((SV *)ret);
                    }
                }
            }
        }
        else {
            /* Unknown type — raw */
            HV *ret = newHV();
            (void)hv_stores(ret, "type", newSVpvs("raw"));
            (void)hv_stores(ret, "data", SvREFCNT_inc(json_str));
            SvREFCNT_dec(decoded);
            RETVAL = newRV_noinc((SV *)ret);
        }
    }
}
OUTPUT:
    RETVAL

SV *
encode_result(self, result)
    SV *self
    SV *result
CODE:
{
    PERL_UNUSED_VAR(self);
    RETVAL = _bind_json_encode(aTHX_ result);
}
OUTPUT:
    RETVAL

SV *
js_resolve(self, id, result, ...)
    SV *self
    SV *id
    SV *result
CODE:
{
    PERL_UNUSED_VAR(self);
    int id_int = (int)SvIV(id);
    SV *error = (items > 3) ? ST(3) : &PL_sv_undef;

    if (SvOK(error)) {
        /* Error path: window.chandra._resolve(id, null, encoded_error) */
        SV *encoded = _bind_json_encode(aTHX_ error);
        RETVAL = newSVpvf("window.chandra._resolve(%d, null, %s)",
                          id_int, SvPV_nolen(encoded));
        SvREFCNT_dec(encoded);
    }
    else {
        /* Success path: window.chandra._resolve(id, encoded_result, null) */
        SV *encoded = _bind_json_encode(aTHX_ result);
        RETVAL = newSVpvf("window.chandra._resolve(%d, %s, null)",
                          id_int, SvPV_nolen(encoded));
        SvREFCNT_dec(encoded);
    }
}
OUTPUT:
    RETVAL
