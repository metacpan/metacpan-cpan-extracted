MODULE = Chandra    PACKAGE = Chandra::Toast

PROTOTYPES: DISABLE

BOOT:
{
    _toast_id = 0;
    _toast_injected = 0;
}

 # ---- show($app, $message, %opts) ----
 #  opts: type => 'info', duration => 3000, action => { label => '...', handler => sub {} }
 #  Returns toast ID string.

SV *
show(class, app, message, ...)
    const char *class
    SV *app
    SV *message
CODE:
{
    PerlChandra *pc;
    SV **svp;
    const char *type = "info";
    int duration = 3000;
    SV *action_handler = NULL;
    const char *action_label = NULL;
    char id_buf[32];
    int id_len;
    SV *js;
    SV *escaped_msg;
    int i;

    PERL_UNUSED_VAR(class);

    if (!SvROK(app) || !sv_isobject(app))
        croak("Chandra::Toast::show: first argument must be a Chandra::App");

    pc = CHANDRA_PC_FROM_APP(app);

    /* Parse keyword args */
    for (i = 3; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "type")) {
            type = SvPV_nolen(val);
        } else if (strEQ(key, "duration")) {
            duration = SvIV(val);
        } else if (strEQ(key, "action") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
            HV *act_hv = (HV *)SvRV(val);
            SV **label_svp = hv_fetchs(act_hv, "label", 0);
            SV **handler_svp = hv_fetchs(act_hv, "handler", 0);
            if (label_svp && SvOK(*label_svp))
                action_label = SvPV_nolen(*label_svp);
            if (handler_svp && SvOK(*handler_svp))
                action_handler = *handler_svp;
        }
    }

    /* Inject JS on first use */
    if (!_toast_injected) {
        chandra_eval_js(aTHX_ pc, CHANDRA_TOAST_JS);
        _toast_injected = 1;
    }

    /* Generate toast ID */
    id_len = snprintf(id_buf, sizeof(id_buf), "toast_%d", ++_toast_id);

    /* If action has a handler, bind it */
    if (action_handler && action_label) {
        char handler_name[64];
        snprintf(handler_name, sizeof(handler_name), "_toast_action_%s", id_buf);

        /* Call $app->bind($handler_name, $handler) */
        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(app);
            XPUSHs(sv_2mortal(newSVpv(handler_name, 0)));
            XPUSHs(action_handler);
            PUTBACK;
            call_method("bind", G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) sv_setsv(ERRSV, &PL_sv_undef);
            FREETMPS; LEAVE;
        }
    }

    /* Build JS call */
    escaped_msg = chandra_escape_js(aTHX_ message);
    js = newSVpvs("window.__chandraToast.show('");
    sv_catpvn(js, id_buf, id_len);
    sv_catpvs(js, "',");
    sv_catsv(js, escaped_msg);
    sv_catpvs(js, ",'");
    sv_catpv(js, type);
    sv_catpvf(js, "',%d,", duration);

    if (action_label) {
        char handler_name[64];
        SV *escaped_label;
        SV *label_sv;

        snprintf(handler_name, sizeof(handler_name), "_toast_action_%s", id_buf);
        label_sv = newSVpv(action_label, 0);
        escaped_label = chandra_escape_js(aTHX_ label_sv);
        SvREFCNT_dec(label_sv);

        sv_catpvs(js, "{label:");
        sv_catsv(js, escaped_label);
        sv_catpvf(js, ",handler:'%s'}", handler_name);
        SvREFCNT_dec(escaped_label);
    } else {
        sv_catpvs(js, "null");
    }

    sv_catpvs(js, ")");

    chandra_eval_js(aTHX_ pc, SvPV_nolen(js));

    SvREFCNT_dec(escaped_msg);
    SvREFCNT_dec(js);

    RETVAL = newSVpvn(id_buf, id_len);
}
OUTPUT:
    RETVAL

 # ---- dismiss($app, $id) ----

SV *
dismiss(class, app, toast_id)
    const char *class
    SV *app
    SV *toast_id
CODE:
{
    PerlChandra *pc;
    STRLEN id_len;
    const char *id_str;
    char js_buf[128];

    PERL_UNUSED_VAR(class);

    pc = CHANDRA_PC_FROM_APP(app);
    id_str = SvPV(toast_id, id_len);

    snprintf(js_buf, sizeof(js_buf),
             "window.__chandraToast.dismiss('%.*s')",
             (int)id_len, id_str);

    chandra_eval_js(aTHX_ pc, js_buf);
    RETVAL = SvREFCNT_inc(app);
}
OUTPUT:
    RETVAL

 # ---- reset() ----

void
reset(...)
CODE:
{
    PERL_UNUSED_VAR(items);
    _toast_id = 0;
    _toast_injected = 0;
}
