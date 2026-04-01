MODULE = Chandra    PACKAGE = Chandra::DevTools

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    int i;

    (void)hv_stores(self_hv, "enabled", newSViv(0));

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
enable(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV *app_sv = NULL;
    SV **app_svp;

    /* Use explicit app arg or stored app */
    if (items > 1 && SvOK(ST(1))) {
        (void)hv_stores(hv, "app", SvREFCNT_inc(ST(1)));
    }

    (void)hv_stores(hv, "enabled", newSViv(1));

    app_svp = hv_fetchs(hv, "app", 0);
    if (app_svp && *app_svp && SvOK(*app_svp))
        app_sv = *app_svp;

    if (app_sv) {
        /* Bind __devtools_list_bindings — static XS callback, no closure */
        {
            CV *cb_cv = newXS(NULL, xs_devtools_list_bindings, __FILE__);
            SV *cb_ref = sv_2mortal(newRV_noinc((SV *)cb_cv));
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(app_sv);
            XPUSHs(sv_2mortal(newSVpvs("__devtools_list_bindings")));
            XPUSHs(cb_ref);
            PUTBACK;
            call_method("bind", G_DISCARD);
            FREETMPS; LEAVE;
        }

        /* Bind __devtools_reload — closure captures $dt via CvXSUBANY */
        {
            CV *cb_cv = newXS(NULL, xs_devtools_reload_cb, __FILE__);
            CvXSUBANY(cb_cv).any_ptr = (void *)SvREFCNT_inc(self);
            SV *cb_ref = sv_2mortal(newRV_noinc((SV *)cb_cv));
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(app_sv);
            XPUSHs(sv_2mortal(newSVpvs("__devtools_reload")));
            XPUSHs(cb_ref);
            PUTBACK;
            call_method("bind", G_DISCARD);
            FREETMPS; LEAVE;
        }

        /* Register error handler — closure captures $dt via CvXSUBANY */
        {
            CV *cb_cv = newXS(NULL, xs_devtools_error_handler, __FILE__);
            CvXSUBANY(cb_cv).any_ptr = (void *)SvREFCNT_inc(self);
            SV *cb_ref = sv_2mortal(newRV_noinc((SV *)cb_cv));
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvs("Chandra::Error")));
            XPUSHs(cb_ref);
            PUTBACK;
            call_method("on_error", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
inject(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV *app_sv;
    SV **app_svp;

    if (items > 1 && SvOK(ST(1))) {
        app_sv = ST(1);
    } else {
        app_svp = hv_fetchs(hv, "app", 0);
        app_sv = (app_svp && *app_svp && SvOK(*app_svp)) ? *app_svp : NULL;
    }

    if (app_sv) {
        SV *js = newSVpv(Chandra__DevTools__js_code_str, 0);
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(app_sv);
        XPUSHs(sv_2mortal(js));
        PUTBACK;
        call_method("eval", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
on_reload(self, cb)
    SV *self
    SV *cb
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "reload_cb", SvREFCNT_inc(cb));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
js_code(...)
CODE:
{
    PERL_UNUSED_VAR(items);
    RETVAL = newSVpv(Chandra__DevTools__js_code_str, 0);
}
OUTPUT:
    RETVAL

int
is_enabled(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "enabled", 0);
    RETVAL = (svp && *svp && SvTRUE(*svp)) ? 1 : 0;
}
OUTPUT:
    RETVAL

SV *
disable(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp;

    (void)hv_stores(hv, "enabled", newSViv(0));

    app_svp = hv_fetchs(hv, "app", 0);
    if (app_svp && *app_svp && SvOK(*app_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        XPUSHs(sv_2mortal(newSVpvs(
            "if(window.__chandraDevTools)window.__chandraDevTools.hide()")));
        PUTBACK;
        call_method("eval", G_EVAL | G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
toggle(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);

    if (app_svp && *app_svp && SvOK(*app_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        XPUSHs(sv_2mortal(newSVpvs(
            "if(window.__chandraDevTools)window.__chandraDevTools.toggle()")));
        PUTBACK;
        call_method("eval", G_EVAL | G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
show(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);

    if (app_svp && *app_svp && SvOK(*app_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        XPUSHs(sv_2mortal(newSVpvs(
            "if(window.__chandraDevTools)window.__chandraDevTools.show()")));
        PUTBACK;
        call_method("eval", G_EVAL | G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
hide(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);

    if (app_svp && *app_svp && SvOK(*app_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        XPUSHs(sv_2mortal(newSVpvs(
            "if(window.__chandraDevTools)window.__chandraDevTools.hide()")));
        PUTBACK;
        call_method("eval", G_EVAL | G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
log(self, message)
    SV *self
    SV *message
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **enabled_svp = hv_fetchs(hv, "enabled", 0);
    SV **app_svp = hv_fetchs(hv, "app", 0);

    if (enabled_svp && *enabled_svp && SvTRUE(*enabled_svp) &&
        app_svp && *app_svp && SvOK(*app_svp)) {
        STRLEN mlen;
        const char *mstr = SvPV(message, mlen);
        SV *escaped = newSVpvn(mstr, mlen);
        SV *js;
        STRLEN elen;
        const char *estr;

        /* Escape: \ -> \\, ' -> \', \n -> literal \n */
        {
            SV *tmp = newSVpvs("");
            STRLEN i;
            const char *src = SvPV_nolen(escaped);
            STRLEN slen = SvCUR(escaped);
            for (i = 0; i < slen; i++) {
                switch (src[i]) {
                    case '\\': sv_catpvs(tmp, "\\\\"); break;
                    case '\'': sv_catpvs(tmp, "\\'"); break;
                    case '\n': sv_catpvs(tmp, "\\n"); break;
                    default: {
                        char c = src[i];
                        sv_catpvn(tmp, &c, 1);
                    }
                }
            }
            SvREFCNT_dec(escaped);
            escaped = tmp;
        }

        estr = SvPV(escaped, elen);
        js = newSVpvs("if(window.__chandraDevTools)window.__chandraDevTools.addLog('info','");
        sv_catpvn(js, estr, elen);
        sv_catpvs(js, "')");
        SvREFCNT_dec(escaped);

        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*app_svp);
            XPUSHs(sv_2mortal(js));
            PUTBACK;
            call_method("dispatch_eval", G_EVAL | G_DISCARD);
            FREETMPS; LEAVE;
        }

        RETVAL = SvREFCNT_inc(self);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

SV *
warn(self, message)
    SV *self
    SV *message
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **enabled_svp = hv_fetchs(hv, "enabled", 0);
    SV **app_svp = hv_fetchs(hv, "app", 0);

    if (enabled_svp && *enabled_svp && SvTRUE(*enabled_svp) &&
        app_svp && *app_svp && SvOK(*app_svp)) {
        STRLEN mlen;
        const char *mstr = SvPV(message, mlen);
        SV *escaped = newSVpvn(mstr, mlen);
        SV *js;
        STRLEN elen;
        const char *estr;

        /* Escape: \ -> \\, ' -> \', \n -> literal \n */
        {
            SV *tmp = newSVpvs("");
            STRLEN i;
            const char *src = SvPV_nolen(escaped);
            STRLEN slen = SvCUR(escaped);
            for (i = 0; i < slen; i++) {
                switch (src[i]) {
                    case '\\': sv_catpvs(tmp, "\\\\"); break;
                    case '\'': sv_catpvs(tmp, "\\'"); break;
                    case '\n': sv_catpvs(tmp, "\\n"); break;
                    default: {
                        char c = src[i];
                        sv_catpvn(tmp, &c, 1);
                    }
                }
            }
            SvREFCNT_dec(escaped);
            escaped = tmp;
        }

        estr = SvPV(escaped, elen);
        js = newSVpvs("if(window.__chandraDevTools)window.__chandraDevTools.addLog('warn','");
        sv_catpvn(js, estr, elen);
        sv_catpvs(js, "')");
        SvREFCNT_dec(escaped);

        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*app_svp);
            XPUSHs(sv_2mortal(js));
            PUTBACK;
            call_method("dispatch_eval", G_EVAL | G_DISCARD);
            FREETMPS; LEAVE;
        }

        RETVAL = SvREFCNT_inc(self);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL
