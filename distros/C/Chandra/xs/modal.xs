MODULE = Chandra    PACKAGE = Chandra::Modal

PROTOTYPES: DISABLE

BOOT:
{
    _modal_id = 0;
    _modal_injected = 0;
}

 # ---- show($app, %opts) ----
 # opts: title, content, message, width, closable, backdrop,
 #       buttons => [{ label, cls, action => 'close' | handler => sub {} }],
 #       input => { label, value }  (for prompt mode)

SV *
show(class, app, ...)
    const char *class
    SV *app
CODE:
{
    PerlChandra *pc;
    char id_buf[32];
    int id_len;
    SV *js;
    int i;
    const char *title = NULL;
    const char *content = NULL;
    const char *message = NULL;
    int modal_width = 400;
    int closable = 1;
    int backdrop = 1;
    AV *buttons = NULL;
    HV *input_opts = NULL;

    PERL_UNUSED_VAR(class);
    pc = CHANDRA_PC_FROM_APP(app);

    /* Parse keyword args */
    for (i = 2; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "title")) title = SvPV_nolen(val);
        else if (strEQ(key, "content")) content = SvPV_nolen(val);
        else if (strEQ(key, "message")) message = SvPV_nolen(val);
        else if (strEQ(key, "width")) modal_width = SvIV(val);
        else if (strEQ(key, "closable")) closable = SvTRUE(val);
        else if (strEQ(key, "backdrop")) backdrop = SvTRUE(val);
        else if (strEQ(key, "buttons") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV)
            buttons = (AV *)SvRV(val);
        else if (strEQ(key, "input") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
            input_opts = (HV *)SvRV(val);
    }

    /* Inject JS on first use */
    if (!_modal_injected) {
        chandra_eval_js(aTHX_ pc, CHANDRA_MODAL_JS);
        _modal_injected = 1;
    }

    id_len = snprintf(id_buf, sizeof(id_buf), "modal_%d", ++_modal_id);

    /* Build JS options object */
    js = newSVpvs("window.__chandraModal.create('");
    sv_catpvn(js, id_buf, id_len);
    sv_catpvs(js, "',{");

    if (title) {
        SV *esc = chandra_escape_js(aTHX_ newSVpv(title, 0));
        sv_catpvs(js, "title:'"); sv_catsv(js, esc); sv_catpvs(js, "'"); sv_catpvs(js, ",");
        SvREFCNT_dec(esc);
    }
    if (content) {
        SV *esc = chandra_escape_js(aTHX_ newSVpv(content, 0));
        sv_catpvs(js, "content:'"); sv_catsv(js, esc); sv_catpvs(js, "'"); sv_catpvs(js, ",");
        SvREFCNT_dec(esc);
    }
    if (message) {
        SV *esc = chandra_escape_js(aTHX_ newSVpv(message, 0));
        sv_catpvs(js, "message:'"); sv_catsv(js, esc); sv_catpvs(js, "'"); sv_catpvs(js, ",");
        SvREFCNT_dec(esc);
    }
    sv_catpvf(js, "width:%d,closable:%s,backdrop:%s,",
              modal_width,
              closable ? "true" : "false",
              backdrop ? "true" : "false");

    /* Input opts */
    if (input_opts) {
        sv_catpvs(js, "input:{");
        SV **label_svp = hv_fetchs(input_opts, "label", 0);
        SV **value_svp = hv_fetchs(input_opts, "value", 0);
        if (label_svp && SvOK(*label_svp)) {
            SV *esc = chandra_escape_js(aTHX_ *label_svp);
            sv_catpvs(js, "label:'"); sv_catsv(js, esc); sv_catpvs(js, "'"); sv_catpvs(js, ",");
            SvREFCNT_dec(esc);
        }
        if (value_svp && SvOK(*value_svp)) {
            SV *esc = chandra_escape_js(aTHX_ *value_svp);
            sv_catpvs(js, "value:'"); sv_catsv(js, esc); sv_catpvs(js, "'");
            SvREFCNT_dec(esc);
        }
        sv_catpvs(js, "},");
    }

    /* Buttons */
    if (buttons) {
        SSize_t blen = av_len(buttons) + 1;
        sv_catpvs(js, "buttons:[");
        for (SSize_t bi = 0; bi < blen; bi++) {
            SV **bsvp = av_fetch(buttons, bi, 0);
            if (!bsvp || !SvROK(*bsvp) || SvTYPE(SvRV(*bsvp)) != SVt_PVHV) continue;
            HV *bhv = (HV *)SvRV(*bsvp);

            if (bi > 0) sv_catpvs(js, ",");
            sv_catpvs(js, "{");

            SV **lbl = hv_fetchs(bhv, "label", 0);
            if (lbl && SvOK(*lbl)) {
                SV *esc = chandra_escape_js(aTHX_ *lbl);
                sv_catpvs(js, "label:'"); sv_catsv(js, esc); sv_catpvs(js, "'"); sv_catpvs(js, ",");
                SvREFCNT_dec(esc);
            }

            SV **cls = hv_fetchs(bhv, "class", 0);
            if (cls && SvOK(*cls)) {
                sv_catpvf(js, "cls:'%s',", SvPV_nolen(*cls));
            }

            SV **act = hv_fetchs(bhv, "action", 0);
            if (act && SvOK(*act)) {
                if (SvROK(*act) && SvTYPE(SvRV(*act)) == SVt_PVCV) {
                    /* Coderef: bind as handler */
                    char handler_name[64];
                    snprintf(handler_name, sizeof(handler_name),
                             "_modal_btn_%s_%d", id_buf, (int)bi);
                    {
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(app);
                        XPUSHs(sv_2mortal(newSVpv(handler_name, 0)));
                        XPUSHs(*act);
                        PUTBACK;
                        call_method("bind", G_DISCARD | G_EVAL);
                        if (SvTRUE(ERRSV)) sv_setsv(ERRSV, &PL_sv_undef);
                        FREETMPS; LEAVE;
                    }
                    sv_catpvf(js, "handler:'%s'", handler_name);
                } else {
                    /* String: 'close' */
                    sv_catpvf(js, "action:'%s'", SvPV_nolen(*act));
                }
            }

            sv_catpvs(js, "}");
        }
        sv_catpvs(js, "],");
    }

    sv_catpvs(js, "})");

    chandra_eval_js(aTHX_ pc, SvPV_nolen(js));
    SvREFCNT_dec(js);

    RETVAL = newSVpvn(id_buf, id_len);
}
OUTPUT:
    RETVAL

 # ---- close($app, $id) ----

SV *
close(class, app, modal_id)
    const char *class
    SV *app
    SV *modal_id
CODE:
{
    PerlChandra *pc;
    STRLEN id_len;
    const char *id_str;
    char js_buf[128];

    PERL_UNUSED_VAR(class);
    pc = CHANDRA_PC_FROM_APP(app);
    id_str = SvPV(modal_id, id_len);

    snprintf(js_buf, sizeof(js_buf),
             "window.__chandraModal.close('%.*s')",
             (int)id_len, id_str);

    chandra_eval_js(aTHX_ pc, js_buf);
    RETVAL = SvREFCNT_inc(app);
}
OUTPUT:
    RETVAL

 # ---- confirm($app, %opts) - convenience for ok/cancel dialog ----

SV *
confirm(class, app, ...)
    const char *class
    SV *app
CODE:
{
    PerlChandra *pc;
    const char *title = "Confirm";
    const char *message = "Are you sure?";
    SV *on_ok = NULL;
    SV *on_cancel = NULL;
    int i;

    PERL_UNUSED_VAR(class);
    pc = CHANDRA_PC_FROM_APP(app);

    for (i = 2; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "title")) title = SvPV_nolen(val);
        else if (strEQ(key, "message")) message = SvPV_nolen(val);
        else if (strEQ(key, "on_ok") && SvROK(val)) on_ok = val;
        else if (strEQ(key, "on_cancel") && SvROK(val)) on_cancel = val;
    }

    /* Build args for show() */
    {
        AV *btns = newAV();
        HV *cancel_btn = newHV();
        HV *ok_btn = newHV();

        hv_stores(cancel_btn, "label", newSVpvs("Cancel"));
        hv_stores(cancel_btn, "class", newSVpvs("secondary"));
        if (on_cancel) {
            hv_stores(cancel_btn, "action", SvREFCNT_inc(on_cancel));
        } else {
            hv_stores(cancel_btn, "action", newSVpvs("close"));
        }

        hv_stores(ok_btn, "label", newSVpvs("OK"));
        hv_stores(ok_btn, "class", newSVpvs("primary"));
        if (on_ok) {
            hv_stores(ok_btn, "action", SvREFCNT_inc(on_ok));
        } else {
            hv_stores(ok_btn, "action", newSVpvs("close"));
        }

        av_push(btns, newRV_noinc((SV *)cancel_btn));
        av_push(btns, newRV_noinc((SV *)ok_btn));

        /* Call self->show() with constructed args */
        {
            int count;
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvs("Chandra::Modal")));
            XPUSHs(app);
            XPUSHs(sv_2mortal(newSVpvs("title")));
            XPUSHs(sv_2mortal(newSVpv(title, 0)));
            XPUSHs(sv_2mortal(newSVpvs("message")));
            XPUSHs(sv_2mortal(newSVpv(message, 0)));
            XPUSHs(sv_2mortal(newSVpvs("buttons")));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)btns)));
            PUTBACK;
            count = call_method("show", G_SCALAR);
            SPAGAIN;
            RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
            PUTBACK;
            FREETMPS; LEAVE;
        }
    }
}
OUTPUT:
    RETVAL

 # ---- prompt($app, %opts) - convenience for text input dialog ----

SV *
prompt(class, app, ...)
    const char *class
    SV *app
CODE:
{
    PerlChandra *pc;
    const char *title = "Input";
    const char *label = NULL;
    const char *value = "";
    SV *on_submit = NULL;
    int i;

    PERL_UNUSED_VAR(class);
    pc = CHANDRA_PC_FROM_APP(app);

    for (i = 2; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "title")) title = SvPV_nolen(val);
        else if (strEQ(key, "label")) label = SvPV_nolen(val);
        else if (strEQ(key, "value")) value = SvPV_nolen(val);
        else if (strEQ(key, "on_submit") && SvROK(val)) on_submit = val;
    }

    {
        AV *btns = newAV();
        HV *cancel_btn = newHV();
        HV *submit_btn = newHV();
        HV *input_hv = newHV();

        if (label) hv_stores(input_hv, "label", newSVpv(label, 0));
        hv_stores(input_hv, "value", newSVpv(value, 0));

        hv_stores(cancel_btn, "label", newSVpvs("Cancel"));
        hv_stores(cancel_btn, "class", newSVpvs("secondary"));
        hv_stores(cancel_btn, "action", newSVpvs("close"));

        hv_stores(submit_btn, "label", newSVpvs("OK"));
        hv_stores(submit_btn, "class", newSVpvs("primary"));
        if (on_submit) {
            hv_stores(submit_btn, "action", SvREFCNT_inc(on_submit));
        } else {
            hv_stores(submit_btn, "action", newSVpvs("close"));
        }

        av_push(btns, newRV_noinc((SV *)cancel_btn));
        av_push(btns, newRV_noinc((SV *)submit_btn));

        {
            int count;
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvs("Chandra::Modal")));
            XPUSHs(app);
            XPUSHs(sv_2mortal(newSVpvs("title")));
            XPUSHs(sv_2mortal(newSVpv(title, 0)));
            XPUSHs(sv_2mortal(newSVpvs("input")));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)input_hv)));
            XPUSHs(sv_2mortal(newSVpvs("buttons")));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)btns)));
            PUTBACK;
            count = call_method("show", G_SCALAR);
            SPAGAIN;
            RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
            PUTBACK;
            FREETMPS; LEAVE;
        }
    }
}
OUTPUT:
    RETVAL

 # ---- reset() ----

void
reset(...)
CODE:
{
    PERL_UNUSED_VAR(items);
    _modal_id = 0;
    _modal_injected = 0;
}
