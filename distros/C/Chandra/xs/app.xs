MODULE = Chandra    PACKAGE = Chandra::App

PROTOTYPES: DISABLE

 # ---- C helper: escape JS string (backslash, single-quote, newline, CR) ----
 # Returns a new mortal SV with the escaped string.

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    SV *webview_sv;
    I32 i;

    (void)hv_stores(self_hv, "_started", newSViv(0));

    /* Create the underlying Chandra webview, forwarding all args */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra")));
        for (i = 1; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        webview_sv = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    (void)hv_stores(self_hv, "_webview", webview_sv);

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
        gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- Direct struct accessors via PerlChandra* ----

SV *
title(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    RETVAL = pc ? newSVpv(pc->wv.title, 0) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
url(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    RETVAL = pc ? newSVpv(pc->wv.url, 0) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

int
width(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    RETVAL = pc ? pc->wv.width : 800;
}
OUTPUT:
    RETVAL

int
height(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    RETVAL = pc ? pc->wv.height : 600;
}
OUTPUT:
    RETVAL

int
resizable(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    RETVAL = pc ? pc->wv.resizable : 1;
}
OUTPUT:
    RETVAL

int
debug(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    RETVAL = pc ? pc->wv.debug : 0;
}
OUTPUT:
    RETVAL

 # ---- webview() accessor ----

SV *
webview(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    RETVAL = (wv_svp && SvOK(*wv_svp)) ? SvREFCNT_inc(*wv_svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

 # ---- bind($name, $coderef) — calls _xs_bind_method directly ----

SV *
bind(self, name_sv, callback)
    SV *self
    SV *name_sv
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    if (wv_svp && SvOK(*wv_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        XPUSHs(name_sv);
        XPUSHs(callback);
        PUTBACK;
        call_pv("Chandra::_xs_bind_method", G_DISCARD);
        FREETMPS; LEAVE;
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- route($path, $handler, %opts) ----

SV *
route(self, path_sv, handler, ...)
    SV *self
    SV *path_sv
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **routes_svp;
    AV *routes;
    AV *entry;
    HV *opts_hv;
    I32 i;

    /* Get or create _routes array */
    routes_svp = hv_fetchs(hv, "_routes", 0);
    if (routes_svp && SvROK(*routes_svp)) {
        routes = (AV *)SvRV(*routes_svp);
    } else {
        routes = newAV();
        (void)hv_stores(hv, "_routes", newRV_noinc((SV *)routes));
    }

    /* Parse optional key-value pairs into opts hash */
    opts_hv = newHV();
    for (i = 3; i + 1 < items; i += 2) {
        const char *key;
        STRLEN key_len;
        key = SvPV(ST(i), key_len);
        (void)hv_store(opts_hv, key, key_len, newSVsv(ST(i + 1)), 0);
    }

    /* Create entry: [$path, $handler, \%opts] */
    entry = newAV();
    av_push(entry, newSVsv(path_sv));
    av_push(entry, newSVsv(handler));
    av_push(entry, newRV_noinc((SV *)opts_hv));

    av_push(routes, newRV_noinc((SV *)entry));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- css($css_string) ----

SV *
css(self, css_sv)
    SV *self
    SV *css_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **arr_svp;
    AV *arr;

    arr_svp = hv_fetchs(hv, "_global_css", 0);
    if (arr_svp && SvROK(*arr_svp)) {
        arr = (AV *)SvRV(*arr_svp);
    } else {
        arr = newAV();
        (void)hv_stores(hv, "_global_css", newRV_noinc((SV *)arr));
    }
    av_push(arr, newSVsv(css_sv));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- theme($name_or_hashref) ----

SV *
theme(self, theme_arg)
    SV *self
    SV *theme_arg
CODE:
{
    /* Call Chandra::Theme->apply($self, $theme_arg) */
    int count;
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Chandra::Theme")));
    XPUSHs(self);
    XPUSHs(theme_arg);
    PUTBACK;

    /* Ensure Chandra::Theme is loaded */
    load_module(PERL_LOADMOD_NOIMPORT,
                newSVpvs("Chandra::Theme"), NULL);

    count = call_method("apply", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        POPs;
        warn("Chandra::App::theme: %s", SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    } else if (count > 0) {
        POPs;
    }
    PUTBACK;
    FREETMPS; LEAVE;

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- toast($message, %opts) ----

SV *
toast(self, message, ...)
    SV *self
    SV *message
CODE:
{
    /* Call Chandra::Toast->show($self, $message, @rest) */
    int count;
    int i;
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Chandra::Toast")));
    XPUSHs(self);
    XPUSHs(message);
    for (i = 2; i < items; i++) {
        XPUSHs(ST(i));
    }
    PUTBACK;

    load_module(PERL_LOADMOD_NOIMPORT,
                newSVpvs("Chandra::Toast"), NULL);

    count = call_method("show", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        RETVAL = &PL_sv_undef;
        if (count > 0) POPs;
        warn("Chandra::App::toast: %s", SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    } else if (count > 0) {
        RETVAL = SvREFCNT_inc(POPs);
    } else {
        RETVAL = &PL_sv_undef;
    }
    PUTBACK;
    FREETMPS; LEAVE;
}
OUTPUT:
    RETVAL

 # ---- dismiss_toast($id) ----

SV *
dismiss_toast(self, toast_id)
    SV *self
    SV *toast_id
CODE:
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Chandra::Toast")));
    XPUSHs(self);
    XPUSHs(toast_id);
    PUTBACK;

    load_module(PERL_LOADMOD_NOIMPORT,
                newSVpvs("Chandra::Toast"), NULL);

    call_method("dismiss", G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("Chandra::App::dismiss_toast: %s", SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    }
    FREETMPS; LEAVE;

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- js($js_string) ----

SV *
js(self, js_sv)
    SV *self
    SV *js_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **arr_svp;
    AV *arr;

    arr_svp = hv_fetchs(hv, "_global_js", 0);
    if (arr_svp && SvROK(*arr_svp)) {
        arr = (AV *)SvRV(*arr_svp);
    } else {
        arr = newAV();
        (void)hv_stores(hv, "_global_js", newRV_noinc((SV *)arr));
    }
    av_push(arr, newSVsv(js_sv));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- layout($handler) ----

SV *
layout(self, handler)
    SV *self
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_layout", newSVsv(handler));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- not_found($handler) ----

SV *
not_found(self, handler)
    SV *self
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_not_found", newSVsv(handler));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- set_content($html_or_element) ----

SV *
set_content(self, content)
    SV *self
    SV *content
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV *html_sv;

    /* If content responds to render(), call it */
    if (SvROK(content) && sv_isobject(content)) {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(content);
        PUTBACK;
        count = call_method("render", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0 && !SvTRUE(ERRSV)) {
            html_sv = newSVsv(POPs);
        } else {
            /* render not available, stringify */
            if (SvTRUE(ERRSV)) {
                /* Clear error from failed render attempt */
                sv_setsv(ERRSV, &PL_sv_undef);
            }
            html_sv = newSVsv(content);
        }
        PUTBACK;
        FREETMPS; LEAVE;
    } else {
        html_sv = newSVsv(content);
    }

    (void)hv_stores(hv, "_html", html_sv);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- _escape_js (also callable from Perl for tests) ----

SV *
_escape_js(str_sv)
    SV *str_sv
CODE:
{
    const char *src;
    STRLEN src_len;
    char *buf;
    STRLEN i, j;

    src = SvPV(str_sv, src_len);
    /* Worst case: every char needs escaping (2x) */
    Newx(buf, src_len * 2 + 1, char);
    j = 0;
    for (i = 0; i < src_len; i++) {
        switch (src[i]) {
            case '\\': buf[j++] = '\\'; buf[j++] = '\\'; break;
            case '\'': buf[j++] = '\\'; buf[j++] = '\''; break;
            case '\n': buf[j++] = '\\'; buf[j++] = 'n';  break;
            case '\r': buf[j++] = '\\'; buf[j++] = 'r';  break;
            default:   buf[j++] = src[i]; break;
        }
    }
    RETVAL = newSVpvn(buf, j);
    Safefree(buf);
}
OUTPUT:
    RETVAL

 # ---- _match_route($path) — returns ($handler, %params) or () ----

void
_match_route(self, path_sv)
    SV *self
    SV *path_sv
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **routes_svp = hv_fetchs(hv, "_routes", 0);
    const char *path;
    STRLEN path_len;
    AV *path_parts;
    I32 path_count;

    path = SvPV(path_sv, path_len);

    if (!routes_svp || !SvROK(*routes_svp)) {
        /* No routes — set empty opts and return nothing */
        (void)hv_stores(hv, "_current_route_opts", newRV_noinc((SV *)newHV()));
        XSRETURN(0);
    }

    /* Split path by '/' */
    path_parts = newAV();
    sv_2mortal((SV *)path_parts);
    {
        const char *p = path;
        const char *seg_start = p;
        while (1) {
            if (*p == '/' || *p == '\0') {
                av_push(path_parts, newSVpvn(seg_start, p - seg_start));
                if (*p == '\0') break;
                p++;
                seg_start = p;
            } else {
                p++;
            }
        }
    }
    path_count = av_len(path_parts) + 1;

    {
        AV *routes = (AV *)SvRV(*routes_svp);
        I32 route_len = av_len(routes) + 1;
        I32 ri;

        for (ri = 0; ri < route_len; ri++) {
            SV **entry_svp = av_fetch(routes, ri, 0);
            AV *entry;
            SV **pat_svp, **handler_svp, **opts_svp;
            const char *pattern;
            STRLEN pat_len;
            AV *pat_parts;
            I32 pat_count;
            I32 pi;
            int match;
            HV *params;

            if (!entry_svp || !SvROK(*entry_svp)) continue;
            entry = (AV *)SvRV(*entry_svp);

            pat_svp = av_fetch(entry, 0, 0);
            handler_svp = av_fetch(entry, 1, 0);
            opts_svp = av_fetch(entry, 2, 0);
            if (!pat_svp || !handler_svp) continue;

            pattern = SvPV(*pat_svp, pat_len);

            /* Split pattern by '/' */
            pat_parts = newAV();
            sv_2mortal((SV *)pat_parts);
            {
                const char *p = pattern;
                const char *seg_start = p;
                while (1) {
                    if (*p == '/' || *p == '\0') {
                        av_push(pat_parts, newSVpvn(seg_start, p - seg_start));
                        if (*p == '\0') break;
                        p++;
                        seg_start = p;
                    } else {
                        p++;
                    }
                }
            }
            pat_count = av_len(pat_parts) + 1;

            if (pat_count != path_count) continue;

            match = 1;
            params = newHV();
            for (pi = 0; pi < pat_count; pi++) {
                SV **ps = av_fetch(pat_parts, pi, 0);
                SV **pp = av_fetch(path_parts, pi, 0);
                const char *pat_seg;
                STRLEN pat_seg_len;

                if (!ps || !pp) { match = 0; break; }

                pat_seg = SvPV(*ps, pat_seg_len);

                if (pat_seg_len > 0 && pat_seg[0] == ':') {
                    /* Parameter capture: store name => value */
                    (void)hv_store(params, pat_seg + 1, pat_seg_len - 1,
                        newSVsv(*pp), 0);
                } else {
                    /* Literal match */
                    const char *path_seg;
                    STRLEN path_seg_len;
                    path_seg = SvPV(*pp, path_seg_len);
                    if (pat_seg_len != path_seg_len ||
                        memNE(pat_seg, path_seg, pat_seg_len)) {
                        match = 0;
                        break;
                    }
                }
            }

            if (match) {
                /* Set _current_route_opts */
                if (opts_svp && SvROK(*opts_svp)) {
                    (void)hv_stores(hv, "_current_route_opts",
                        newSVsv(*opts_svp));
                } else {
                    (void)hv_stores(hv, "_current_route_opts",
                        newRV_noinc((SV *)newHV()));
                }

                /* Return ($handler, %params) */
                XPUSHs(sv_2mortal(newSVsv(*handler_svp)));
                {
                    HE *he;
                    hv_iterinit(params);
                    while ((he = hv_iternext(params)) != NULL) {
                        XPUSHs(sv_2mortal(newSVhek(HeKEY_hek(he))));
                        XPUSHs(sv_2mortal(newSVsv(HeVAL(he))));
                    }
                }
                SvREFCNT_dec((SV *)params);
                XSRETURN(SP - MARK);
            }
            SvREFCNT_dec((SV *)params);
        }
    }

    /* No match — set empty opts */
    (void)hv_stores(hv, "_current_route_opts", newRV_noinc((SV *)newHV()));
    XSRETURN(0);
}

 # ---- _render_route_body($path) — renders body HTML without layout ----

SV *
_render_route_body(self, path_sv)
    SV *self
    SV *path_sv
CODE:
{
    dSP;
    int count;
    SV *handler = NULL;
    HV *params_hv = newHV();
    SV *content_sv;

    /* Call _match_route to get (handler, %params) */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(path_sv);
    PUTBACK;
    count = call_method("_match_route", G_ARRAY);
    SPAGAIN;

    if (count > 0) {
        /* Pop all results — first is handler, rest are key-value pairs */
        int i;
        SV **results;
        Newx(results, count, SV *);
        for (i = count - 1; i >= 0; i--) {
            results[i] = newSVsv(POPs);
        }
        handler = results[0];
        for (i = 1; i + 1 < count; i += 2) {
            const char *key;
            STRLEN key_len;
            key = SvPV(results[i], key_len);
            (void)hv_store(params_hv, key, key_len,
                newSVsv(results[i + 1]), 0);
        }
        /* Free temp copies (handler kept) */
        for (i = 1; i < count; i++) {
            SvREFCNT_dec(results[i]);
        }
        Safefree(results);
    }
    PUTBACK;
    FREETMPS; LEAVE;

    /* If no handler, use _not_found or default 404 */
    if (!handler || !SvOK(handler)) {
        HV *hv = (HV *)SvRV(self);
        SV **nf_svp = hv_fetchs(hv, "_not_found", 0);
        if (nf_svp && SvOK(*nf_svp) && SvROK(*nf_svp)) {
            handler = newSVsv(*nf_svp);
        } else {
            /* Default 404 handler — just return the string */
            SvREFCNT_dec((SV *)params_hv);
            if (handler) SvREFCNT_dec(handler);
            RETVAL = newSVpvs("<h1>404 - Not Found</h1>");
            goto done_render_body;
        }
    }

    /* Call handler->(%params) */
    {
        HE *he;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        hv_iterinit(params_hv);
        while ((he = hv_iternext(params_hv)) != NULL) {
            XPUSHs(sv_2mortal(newSVhek(HeKEY_hek(he))));
            XPUSHs(sv_2mortal(newSVsv(HeVAL(he))));
        }
        PUTBACK;
        count = call_sv(handler, G_SCALAR);
        SPAGAIN;

        if (count > 0) {
            content_sv = POPs;
            /* If content responds to render(), call it */
            if (SvROK(content_sv) && sv_isobject(content_sv)) {
                SV *rendered;
                PUSHMARK(SP);
                XPUSHs(content_sv);
                PUTBACK;
                count = call_method("render", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (count > 0 && !SvTRUE(ERRSV)) {
                    RETVAL = newSVsv(POPs);
                } else {
                    if (SvTRUE(ERRSV)) sv_setsv(ERRSV, &PL_sv_undef);
                    RETVAL = newSVsv(content_sv);
                }
            } else {
                RETVAL = newSVsv(content_sv);
            }
        } else {
            RETVAL = newSVpvs("");
        }
        PUTBACK;
        FREETMPS; LEAVE;
    }

    SvREFCNT_dec(handler);
    SvREFCNT_dec((SV *)params_hv);
    goto done_render_body;

    done_render_body:
    ;
}
OUTPUT:
    RETVAL

 # ---- _render_route($path) — renders full HTML with layout ----

SV *
_render_route(self, path_sv)
    SV *self
    SV *path_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **layout_svp;
    SV *body_sv;

    /* Get body */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(path_sv);
        PUTBACK;
        count = call_method("_render_route_body", G_SCALAR);
        SPAGAIN;
        body_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
        PUTBACK;
        FREETMPS; LEAVE;
    }

    /* If layout exists, wrap body */
    layout_svp = hv_fetchs(hv, "_layout", 0);
    if (layout_svp && SvOK(*layout_svp) && SvROK(*layout_svp)) {
        dSP;
        int count;
        SV *result;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(body_sv));
        PUTBACK;
        count = call_sv(*layout_svp, G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            result = POPs;
            /* If result responds to render(), call it */
            if (SvROK(result) && sv_isobject(result)) {
                PUSHMARK(SP);
                XPUSHs(result);
                PUTBACK;
                count = call_method("render", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (count > 0 && !SvTRUE(ERRSV)) {
                    RETVAL = newSVsv(POPs);
                } else {
                    if (SvTRUE(ERRSV)) sv_setsv(ERRSV, &PL_sv_undef);
                    RETVAL = newSVsv(result);
                }
            } else {
                RETVAL = newSVsv(result);
            }
        } else {
            RETVAL = newSVpvs("");
        }
        PUTBACK;
        FREETMPS; LEAVE;
    } else {
        RETVAL = body_sv;
    }
}
OUTPUT:
    RETVAL

 # ---- _router_js() — returns the client-side router JS ----

SV *
_router_js(...)
CODE:
    RETVAL = newSVpvs(
        "(function(){\n"
        "  document.addEventListener('click', function(e) {\n"
        "    var el = e.target;\n"
        "    while (el && el.tagName !== 'A') el = el.parentElement;\n"
        "    if (!el) return;\n"
        "    var href = el.getAttribute('href');\n"
        "    if (!href || href.match(/^https?:\\/\\//) || href.match(/^#/)) return;\n"
        "    e.preventDefault();\n"
        "    window.chandra.invoke('__chandra_navigate', [href]);\n"
        "  });\n"
        "  window.addEventListener('popstate', function() {\n"
        "    window.chandra.invoke('__chandra_navigate', [location.pathname || '/']);\n"
        "  });\n"
        "})();\n"
    );
OUTPUT:
    RETVAL

 # ---- _call_wv_method: helper to call eval_js or dispatch_eval_js on webview ----
 # dispatch=0 → eval_js, dispatch=1 → dispatch_eval_js

 # ---- _inject_route_css_js($dispatch) ----

void
_inject_route_css_js(self, dispatch_sv)
    SV *self
    SV *dispatch_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    SV **opts_svp = hv_fetchs(hv, "_current_route_opts", 0);
    int dispatch = SvIV(dispatch_sv);
    const char *method = dispatch ? "dispatch_eval_js" : "eval_js";
    HV *opts;

    if (!wv_svp || !SvOK(*wv_svp)) goto done_inject_rcj;

    opts = (opts_svp && SvROK(*opts_svp))
        ? (HV *)SvRV(*opts_svp) : NULL;

    /* Route CSS */
    {
        SV **css_svp = opts ? hv_fetchs(opts, "css", 0) : NULL;
        if (css_svp && SvOK(*css_svp)) {
            SV *escaped = chandra_escape_js(aTHX_ *css_svp);
            SV *js;
            js = newSVpvs("(function(){var s=document.getElementById('chandra-route-css');");
            sv_catpvs(js, "if(!s){s=document.createElement('style');s.id='chandra-route-css';document.head.appendChild(s);}");
            sv_catpvs(js, "s.textContent='");
            sv_catsv(js, escaped);
            sv_catpvs(js, "';})();");
            {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*wv_svp);
                XPUSHs(sv_2mortal(js));
                PUTBACK;
                call_method(method, G_DISCARD);
                FREETMPS; LEAVE;
            }
            SvREFCNT_dec(escaped);
        } else {
            /* Clear route CSS */
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*wv_svp);
            XPUSHs(sv_2mortal(newSVpvs(
                "(function(){var s=document.getElementById('chandra-route-css');if(s)s.textContent='';})();"
            )));
            PUTBACK;
            call_method(method, G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

    /* Route JS */
    {
        SV **js_svp = opts ? hv_fetchs(opts, "js", 0) : NULL;
        if (js_svp && SvOK(*js_svp)) {
            SV *escaped = chandra_escape_js(aTHX_ *js_svp);
            SV *js;
            js = newSVpvs("(function(){var o=document.getElementById('chandra-route-js');");
            sv_catpvs(js, "if(o)o.parentNode.removeChild(o);");
            sv_catpvs(js, "var s=document.createElement('script');s.id='chandra-route-js';");
            sv_catpvs(js, "s.textContent='");
            sv_catsv(js, escaped);
            sv_catpvs(js, "';document.body.appendChild(s);})();");
            {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*wv_svp);
                XPUSHs(sv_2mortal(js));
                PUTBACK;
                call_method(method, G_DISCARD);
                FREETMPS; LEAVE;
            }
            SvREFCNT_dec(escaped);
        } else {
            /* Remove route JS element */
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*wv_svp);
            XPUSHs(sv_2mortal(newSVpvs(
                "(function(){var o=document.getElementById('chandra-route-js');if(o)o.parentNode.removeChild(o);})();"
            )));
            PUTBACK;
            call_method(method, G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

    done_inject_rcj:
    ;
}

 # ---- _inject_post_content_js($dispatch) ----

void
_inject_post_content_js(self, dispatch_sv)
    SV *self
    SV *dispatch_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    int dispatch = SvIV(dispatch_sv);
    const char *method = dispatch ? "dispatch_eval_js" : "eval_js";

    if (!wv_svp || !SvOK(*wv_svp)) goto done_inject_pcj;

    /* Global CSS */
    {
        SV **gcss_svp = hv_fetchs(hv, "_global_css", 0);
        if (gcss_svp && SvROK(*gcss_svp)) {
            AV *arr = (AV *)SvRV(*gcss_svp);
            I32 len = av_len(arr) + 1;
            if (len > 0) {
                SV *joined = newSVpvs("");
                I32 i;
                SV *escaped;
                SV *js;

                for (i = 0; i < len; i++) {
                    SV **elem = av_fetch(arr, i, 0);
                    if (i > 0) sv_catpvs(joined, "\n");
                    if (elem && SvOK(*elem)) sv_catsv(joined, *elem);
                }
                escaped = chandra_escape_js(aTHX_ joined);
                SvREFCNT_dec(joined);

                js = newSVpvs("(function(){var s=document.getElementById('chandra-global-css');");
                sv_catpvs(js, "if(!s){s=document.createElement('style');s.id='chandra-global-css';document.head.appendChild(s);}");
                sv_catpvs(js, "s.textContent='");
                sv_catsv(js, escaped);
                sv_catpvs(js, "';})();");
                {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*wv_svp);
                    XPUSHs(sv_2mortal(js));
                    PUTBACK;
                    call_method(method, G_DISCARD);
                    FREETMPS; LEAVE;
                }
                SvREFCNT_dec(escaped);
            }
        }
    }

    /* Bridge extensions */
    if (_ext_count > 0) {
        SV *ext_js = chandra_ext_generate_js(aTHX);
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        XPUSHs(sv_2mortal(ext_js));
        PUTBACK;
        call_method(method, G_DISCARD);
        FREETMPS; LEAVE;
    }

    /* Route CSS/JS */
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(dispatch_sv);
        PUTBACK;
        call_method("_inject_route_css_js", G_DISCARD);
        FREETMPS; LEAVE;
    }

    /* DevTools */
    {
        SV **dt_svp = hv_fetchs(hv, "_devtools", 0);
        if (dt_svp && SvOK(*dt_svp) && SvROK(*dt_svp)) {
            if (chandra_devtools_is_enabled(aTHX_ *dt_svp)) {
                /* Get DevTools JS code directly */
                SV *dt_js = newSVpv(chandra_devtools_js_code(), 0);
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*wv_svp);
                XPUSHs(sv_2mortal(dt_js));
                PUTBACK;
                call_method(method, G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
    }

    /* Protocol */
    {
        SV **proto_svp = hv_fetchs(hv, "_protocol", 0);
        if (proto_svp && SvOK(*proto_svp) && SvROK(*proto_svp)) {
            HV *proto_hv = (HV *)SvRV(*proto_svp);
            SV **protocols_svp = hv_fetchs(proto_hv, "protocols", 0);
            if (protocols_svp && SvROK(*protocols_svp)
                && SvTYPE(SvRV(*protocols_svp)) == SVt_PVHV
                && HvUSEDKEYS((HV *)SvRV(*protocols_svp)) > 0) {
                if (dispatch) {
                    dSP;
                    int count;
                    SV *proto_js;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*proto_svp);
                    PUTBACK;
                    count = call_method("js_code", G_SCALAR);
                    SPAGAIN;
                    if (count > 0) {
                        proto_js = POPs;
                        PUSHMARK(SP);
                        XPUSHs(*wv_svp);
                        XPUSHs(proto_js);
                        PUTBACK;
                        call_method("dispatch_eval_js", G_DISCARD);
                    }
                    FREETMPS; LEAVE;
                } else {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*proto_svp);
                    PUTBACK;
                    call_method("inject", G_DISCARD);
                    FREETMPS; LEAVE;
                }
            }
        }
    }

    /* Router JS (only when routes exist) */
    {
        SV **routes_svp = hv_fetchs(hv, "_routes", 0);
        if (routes_svp && SvROK(*routes_svp)) {
            SV *router_js = newSVpv(CHANDRA_ROUTER_JS, 0);
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*wv_svp);
            XPUSHs(sv_2mortal(router_js));
            PUTBACK;
            call_method(method, G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

    /* Shortcut */
    {
        SV **sc_svp = hv_fetchs(hv, "_shortcut", 0);
        if (sc_svp && SvOK(*sc_svp) && SvROK(*sc_svp)) {
            HV *sc_hv = (HV *)SvRV(*sc_svp);
            SV **bindings_svp = hv_fetchs(sc_hv, "bindings", 0);
            if (bindings_svp && SvROK(*bindings_svp)
                && SvTYPE(SvRV(*bindings_svp)) == SVt_PVHV
                && HvUSEDKEYS((HV *)SvRV(*bindings_svp)) > 0) {
                if (dispatch) {
                    dSP;
                    int count;
                    SV *sc_js;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*sc_svp);
                    PUTBACK;
                    count = call_method("js_code", G_SCALAR);
                    SPAGAIN;
                    if (count > 0) {
                        sc_js = POPs;
                        PUSHMARK(SP);
                        XPUSHs(*wv_svp);
                        XPUSHs(sc_js);
                        PUTBACK;
                        call_method("dispatch_eval_js", G_DISCARD);
                    }
                    FREETMPS; LEAVE;
                } else {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*sc_svp);
                    PUTBACK;
                    call_method("inject", G_DISCARD);
                    FREETMPS; LEAVE;
                }
            }
        }
    }

    /* DragDrop */
    {
        SV **dd_svp = hv_fetchs(hv, "_dragdrop", 0);
        if (dd_svp && SvOK(*dd_svp) && SvROK(*dd_svp)) {
            HV *dd_hv = (HV *)SvRV(*dd_svp);
            SV **h_svp = hv_fetchs(dd_hv, "_handlers", 0);
            SV **dz_svp = hv_fetchs(dd_hv, "_drop_zones", 0);
            int has_handlers = (h_svp && SvROK(*h_svp)
                && HvUSEDKEYS((HV *)SvRV(*h_svp)) > 0);
            int has_zones = (dz_svp && SvROK(*dz_svp)
                && HvUSEDKEYS((HV *)SvRV(*dz_svp)) > 0);
            if (has_handlers || has_zones) {
                if (dispatch) {
                    dSP;
                    int count;
                    SV *dd_js;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*dd_svp);
                    PUTBACK;
                    count = call_method("js_code", G_SCALAR);
                    SPAGAIN;
                    if (count > 0) {
                        dd_js = POPs;
                        PUSHMARK(SP);
                        XPUSHs(*wv_svp);
                        XPUSHs(dd_js);
                        PUTBACK;
                        call_method("dispatch_eval_js", G_DISCARD);
                    }
                    FREETMPS; LEAVE;
                } else {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*dd_svp);
                    PUTBACK;
                    call_method("inject", G_DISCARD);
                    FREETMPS; LEAVE;
                }
            }
        }
    }

    /* ContextMenu */
    {
        SV **cm_svp = hv_fetchs(hv, "_contextmenu", 0);
        if (cm_svp && SvOK(*cm_svp) && SvROK(*cm_svp)) {
            HV *cm_hv = (HV *)SvRV(*cm_svp);
            SV **att_svp = hv_fetchs(cm_hv, "_attachments", 0);
            SV **gl_svp  = hv_fetchs(cm_hv, "_global", 0);
            int has_attach = (att_svp && SvROK(*att_svp)
                && HvUSEDKEYS((HV *)SvRV(*att_svp)) > 0);
            int is_global = (gl_svp && SvTRUE(*gl_svp));
            if (has_attach || is_global) {
                if (dispatch) {
                    dSP;
                    int count;
                    SV *cm_js;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*cm_svp);
                    PUTBACK;
                    count = call_method("js_code", G_SCALAR);
                    SPAGAIN;
                    if (count > 0) {
                        cm_js = POPs;
                        PUSHMARK(SP);
                        XPUSHs(*wv_svp);
                        XPUSHs(cm_js);
                        PUTBACK;
                        call_method("dispatch_eval_js", G_DISCARD);
                    }
                    FREETMPS; LEAVE;
                } else {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*cm_svp);
                    PUTBACK;
                    call_method("inject", G_DISCARD);
                    FREETMPS; LEAVE;
                }
            }
        }
    }

    /* Global JS */
    {
        SV **gjs_svp = hv_fetchs(hv, "_global_js", 0);
        if (gjs_svp && SvROK(*gjs_svp)) {
            AV *arr = (AV *)SvRV(*gjs_svp);
            I32 len = av_len(arr) + 1;
            if (len > 0) {
                SV *joined = newSVpvs("");
                I32 i;
                SV *escaped;
                SV *js;

                for (i = 0; i < len; i++) {
                    SV **elem = av_fetch(arr, i, 0);
                    if (i > 0) sv_catpvs(joined, ";\n");
                    if (elem && SvOK(*elem)) sv_catsv(joined, *elem);
                }
                escaped = chandra_escape_js(aTHX_ joined);
                SvREFCNT_dec(joined);

                js = newSVpvs("(function(){var s=document.getElementById('chandra-global-js');");
                sv_catpvs(js, "if(!s){s=document.createElement('script');s.id='chandra-global-js';");
                sv_catpvs(js, "document.body.appendChild(s);}s.textContent='");
                sv_catsv(js, escaped);
                sv_catpvs(js, "';})();");
                {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*wv_svp);
                    XPUSHs(sv_2mortal(js));
                    PUTBACK;
                    call_method(method, G_DISCARD);
                    FREETMPS; LEAVE;
                }
                SvREFCNT_dec(escaped);
            }
        }
    }

    /* Reload detection is handled natively via WKUserScript in webview-cocoa.c
     * (runs at document start on every page load including reload). */

    done_inject_pcj:
    ;
}

 # ---- navigate($path) ----

SV *
navigate(self, path_sv)
    SV *self
    SV *path_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **started_svp;

    (void)hv_stores(hv, "_current_route", newSVsv(path_sv));

    started_svp = hv_fetchs(hv, "_started", 0);
    if (started_svp && SvIV(*started_svp)) {
        PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
        SV *body_escaped, *full_escaped, *nav_js;
        const char *path = SvPV_nolen(path_sv);

        /* Get body and full rendered content */
        {
            SV *body_sv, *full_sv;
            dSP;
            int count;

            /* _render_route_body */
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            XPUSHs(path_sv);
            PUTBACK;
            count = call_method("_render_route_body", G_SCALAR);
            SPAGAIN;
            body_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
            PUTBACK;
            FREETMPS; LEAVE;

            /* _render_route */
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            XPUSHs(path_sv);
            PUTBACK;
            count = call_method("_render_route", G_SCALAR);
            SPAGAIN;
            full_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
            PUTBACK;
            FREETMPS; LEAVE;

            /* Escape both — direct C call */
            body_escaped = chandra_escape_js(aTHX_ body_sv);
            SvREFCNT_dec(body_sv);

            full_escaped = chandra_escape_js(aTHX_ full_sv);
            SvREFCNT_dec(full_sv);
        }

        /* Build navigate JS */
        nav_js = newSVpvs("var _c=document.getElementById('chandra-content');");
        sv_catpvs(nav_js, "if(_c){_c.innerHTML='");
        sv_catsv(nav_js, body_escaped);
        sv_catpvs(nav_js, "';Array.prototype.slice.call(_c.getElementsByTagName('script')).forEach(function(_s){");
        sv_catpvs(nav_js, "var _n=document.createElement('script');_n.text=_s.text;_s.parentNode.replaceChild(_n,_s);");
        sv_catpvs(nav_js, "});}else{document.open();document.write('");
        sv_catsv(nav_js, full_escaped);
        sv_catpvs(nav_js, "');document.close();}try{history.pushState({},'','");
        sv_catpv(nav_js, path);
        sv_catpvs(nav_js, "');}catch(_e){}");

        SvREFCNT_dec(body_escaped);
        SvREFCNT_dec(full_escaped);

        /* dispatch */
        if (pc) {
            webview_dispatch(&pc->wv, deferred_eval_cb, strdup(SvPV_nolen(nav_js)));
        } else {
            SV *wv = CHANDRA_WEBVIEW_SV(self);
            if (wv) {
                dSP; ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(wv); XPUSHs(nav_js); PUTBACK;
                call_method("dispatch_eval_js", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
        SvREFCNT_dec(nav_js);

        /* Inject route CSS/JS */
        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            XPUSHs(sv_2mortal(newSViv(1)));
            PUTBACK;
            call_method("_inject_route_css_js", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- eval($js) — direct webview_eval ----

SV *
eval(self, js_sv)
    SV *self
    SV *js_sv
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    if (pc) {
        RETVAL = newSViv(webview_eval(&pc->wv, SvPV_nolen(js_sv)));
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); XPUSHs(js_sv); PUTBACK;
            call_method("eval_js", G_DISCARD);
            FREETMPS; LEAVE;
        }
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

 # ---- dispatch_eval($js) — direct webview_dispatch ----

void
dispatch_eval(self, js_sv)
    SV *self
    SV *js_sv
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    if (pc) {
        webview_dispatch(&pc->wv, deferred_eval_cb, strdup(SvPV_nolen(js_sv)));
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); XPUSHs(js_sv); PUTBACK;
            call_method("dispatch_eval_js", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
}

 # ---- update($selector, $content) ----

void
update(self, selector_sv, content)
    SV *self
    SV *selector_sv
    SV *content
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV *html_sv;
    SV *escaped_html, *escaped_sel, *js;
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);

    /* Resolve content: if renderable object, call render() */
    if (SvROK(content) && sv_isobject(content)) {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(content);
        PUTBACK;
        count = call_method("render", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0 && !SvTRUE(ERRSV)) {
            html_sv = newSVsv(POPs);
        } else {
            if (SvTRUE(ERRSV)) sv_setsv(ERRSV, &PL_sv_undef);
            html_sv = newSVsv(content);
        }
        PUTBACK;
        FREETMPS; LEAVE;
    } else {
        html_sv = newSVsv(content);
    }

    escaped_html = chandra_escape_js(aTHX_ html_sv);
    SvREFCNT_dec(html_sv);

    escaped_sel = chandra_escape_js(aTHX_ selector_sv);

    /* Build JS */
    js = newSVpvs("var _el=document.querySelector('");
    sv_catsv(js, escaped_sel);
    sv_catpvs(js, "');if(_el){_el.innerHTML='");
    sv_catsv(js, escaped_html);
    sv_catpvs(js, "';}");

    SvREFCNT_dec(escaped_html);
    SvREFCNT_dec(escaped_sel);

    if (pc) {
        webview_dispatch(&pc->wv, deferred_eval_cb, strdup(SvPV_nolen(js)));
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); XPUSHs(js); PUTBACK;
            call_method("dispatch_eval_js", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    SvREFCNT_dec(js);
}

 # ---- set_title($title) — direct webview_set_title ----

SV *
set_title(self, title_sv)
    SV *self
    SV *title_sv
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    if (pc) {
        const char *title = SvPV_nolen(title_sv);
        webview_set_title(&pc->wv, title);
        Safefree((char *)pc->wv.title);
        pc->wv.title = savepv(title);
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); XPUSHs(title_sv); PUTBACK;
            call_method("set_title", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- alert($message) ----

void
alert(self, message_sv)
    SV *self
    SV *message_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    if (wv_svp && SvOK(*wv_svp)) {
        SV *encoded;
        SV *js;
        /* JSON encode the message */
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            /* Use Cpanel::JSON::XS to encode */
            {
                SV *json_obj;
                /* Get the encoder: Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed */
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVpvs("Cpanel::JSON::XS")));
                PUTBACK;
                count = call_method("new", G_SCALAR);
                SPAGAIN;
                json_obj = (count > 0) ? POPs : &PL_sv_undef;

                PUSHMARK(SP);
                XPUSHs(json_obj);
                PUTBACK;
                call_method("utf8", G_SCALAR);
                SPAGAIN;
                json_obj = POPs;

                PUSHMARK(SP);
                XPUSHs(json_obj);
                PUTBACK;
                call_method("allow_nonref", G_SCALAR);
                SPAGAIN;
                json_obj = POPs;

                PUSHMARK(SP);
                XPUSHs(json_obj);
                PUTBACK;
                call_method("allow_blessed", G_SCALAR);
                SPAGAIN;
                json_obj = POPs;

                PUSHMARK(SP);
                XPUSHs(json_obj);
                PUTBACK;
                call_method("convert_blessed", G_SCALAR);
                SPAGAIN;
                json_obj = POPs;

                /* encode($message) */
                PUSHMARK(SP);
                XPUSHs(json_obj);
                XPUSHs(message_sv);
                PUTBACK;
                count = call_method("encode", G_SCALAR);
                SPAGAIN;
                encoded = (count > 0) ? newSVsv(POPs) : newSVpvs("\"\"");
            }
            PUTBACK;
            FREETMPS; LEAVE;
        }
        js = newSVpvs("alert(");
        sv_catsv(js, encoded);
        sv_catpvs(js, ")");
        SvREFCNT_dec(encoded);
        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*wv_svp);
            XPUSHs(sv_2mortal(js));
            PUTBACK;
            call_method("dispatch_eval_js", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
}

 # ---- inject_css($css) — direct webview_inject_css ----

SV *
inject_css(self, css_sv)
    SV *self
    SV *css_sv
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    if (pc) {
        webview_inject_css(&pc->wv, SvPV_nolen(css_sv));
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); XPUSHs(css_sv); PUTBACK;
            call_method("inject_css", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- fullscreen($enable) — direct webview_set_fullscreen ----

SV *
fullscreen(self, ...)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    int enable = (items > 1) ? SvIV(ST(1)) : 1;
    if (pc) {
        webview_set_fullscreen(&pc->wv, enable);
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); mXPUSHi(enable); PUTBACK;
            call_method("set_fullscreen", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- set_color($r, $g, $b, $a) — direct webview_set_color ----

SV *
set_color(self, r, g, b, ...)
    SV *self
    int r
    int g
    int b
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    int a = (items > 4) ? SvIV(ST(4)) : 255;
    if (pc) {
        webview_set_color(&pc->wv, (uint8_t)r, (uint8_t)g, (uint8_t)b, (uint8_t)a);
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); mXPUSHi(r); mXPUSHi(g); mXPUSHi(b); mXPUSHi(a); PUTBACK;
            call_method("set_color", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- terminate() — direct webview_terminate ----

void
terminate(self)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    if (pc) {
        webview_terminate(&pc->wv);
    } else {
        SV *wv = CHANDRA_WEBVIEW_SV(self);
        if (wv) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(wv); PUTBACK;
            call_method("terminate", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
}

 # ---- init() — delegates to webview's init (needs _xs_init_bind + Bridge) ----

SV *
init(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    if (wv_svp && SvOK(*wv_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        PUTBACK;
        call_method("init", G_DISCARD);
        FREETMPS; LEAVE;
    }
    (void)hv_stores(hv, "_started", newSViv(1));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- loop($blocking) — direct webview_loop ----

int
loop(self, ...)
    SV *self
CODE:
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
    int blocking = (items > 1) ? SvIV(ST(1)) : 1;
    RETVAL = pc ? webview_loop(&pc->wv, blocking) : 1;
}
OUTPUT:
    RETVAL

 # ---- exit() — direct webview_exit ----

void
exit(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **started_svp = hv_fetchs(hv, "_started", 0);
    if (started_svp && SvIV(*started_svp)) {
        PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
        if (pc && pc->initialized) {
            webview_exit(&pc->wv);
        }
        (void)hv_stores(hv, "_started", newSViv(0));
    }
}

 # ---- devtools() ----

SV *
devtools(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dt_svp = hv_fetchs(hv, "_devtools", 0);
    if (dt_svp && SvOK(*dt_svp)) {
        RETVAL = SvREFCNT_inc(*dt_svp);
    } else {
        SV *dt;
        dSP;
        int count;

        /* require Chandra::DevTools */
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::DevTools"), NULL);

        /* Chandra::DevTools->new(app => $self) */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::DevTools")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        dt = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;

        /* enable */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(dt);
        PUTBACK;
        call_method("enable", G_DISCARD);
        FREETMPS; LEAVE;

        (void)hv_stores(hv, "_devtools", SvREFCNT_inc(dt));
        RETVAL = dt;
    }
}
OUTPUT:
    RETVAL

 # ---- on_error($handler) ----

SV *
on_error(self, handler)
    SV *self
    SV *handler
CODE:
{
    load_module(PERL_LOADMOD_NOIMPORT,
        newSVpvs("Chandra::Error"), NULL);
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Error")));
        XPUSHs(handler);
        PUTBACK;
        call_method("on_error", G_DISCARD);
        FREETMPS; LEAVE;
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- watch($path, $callback) ----

SV *
watch(self, path_sv, callback)
    SV *self
    SV *path_sv
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **hr_svp = hv_fetchs(hv, "_hot_reload", 0);
    SV *hr;

    if (hr_svp && SvOK(*hr_svp)) {
        hr = *hr_svp;
    } else {
        dSP;
        int count;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::HotReload"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::HotReload")));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        hr = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_hot_reload", SvREFCNT_inc(hr));
    }

    /* hr->watch($path, $callback) */
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(hr);
        XPUSHs(path_sv);
        XPUSHs(callback);
        PUTBACK;
        call_method("watch", G_DISCARD);
        FREETMPS; LEAVE;
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- on_reload($coderef) ----

SV *
on_reload(self, cb)
    SV *self
    SV *cb
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_on_reload", SvREFCNT_inc(cb));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- refresh() ----

SV *
refresh(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **routes_svp = hv_fetchs(hv, "_routes", 0);
    SV **cr_svp = hv_fetchs(hv, "_current_route", 0);
    SV **html_svp = hv_fetchs(hv, "_html", 0);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);

    if (!wv_svp || !SvOK(*wv_svp)) goto done_refresh;

    /* Reset injected flags so toast/modal re-inject their JS */
    _toast_injected = 0;
    _modal_injected = 0;

    /* Re-inject the bridge JS (window.chandra) — lost on page reload */
    {
        PerlChandra *pc = CHANDRA_PC_FROM_APP(self);
        if (pc && pc->initialized) {
            webview_eval(&pc->wv, CHANDRA_BRIDGE_JS);
        }
    }

    if (routes_svp && SvROK(*routes_svp) && cr_svp && SvOK(*cr_svp)) {
        /* Re-render current route */
        SV *html_sv, *escaped, *js;
        dSP;
        int count;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(*cr_svp);
        PUTBACK;
        count = call_method("_render_route", G_SCALAR);
        SPAGAIN;
        html_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
        PUTBACK;
        FREETMPS; LEAVE;

        escaped = chandra_escape_js(aTHX_ html_sv);
        SvREFCNT_dec(html_sv);

        js = newSVpvs("document.open();document.write('");
        sv_catsv(js, escaped);
        sv_catpvs(js, "');document.close();");
        SvREFCNT_dec(escaped);

        /* Use eval_js (synchronous) so bridge is ready before on_reload fires */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        XPUSHs(sv_2mortal(js));
        PUTBACK;
        call_method("eval_js", G_DISCARD);
        FREETMPS; LEAVE;

        /* Re-inject post content JS (also synchronous) */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(sv_2mortal(newSViv(0)));  /* 0 = use eval_js, not dispatch */
        PUTBACK;
        call_method("_inject_post_content_js", G_DISCARD);
        FREETMPS; LEAVE;

    } else if (html_svp && SvOK(*html_svp)) {
        SV *escaped = chandra_escape_js(aTHX_ *html_svp);
        SV *js = newSVpvs("document.open();document.write('");
        sv_catsv(js, escaped);
        sv_catpvs(js, "');document.close();");
        SvREFCNT_dec(escaped);

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        XPUSHs(sv_2mortal(js));
        PUTBACK;
        call_method("eval_js", G_DISCARD);
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(sv_2mortal(newSViv(0)));  /* 0 = synchronous */
        PUTBACK;
        call_method("_inject_post_content_js", G_DISCARD);
        FREETMPS; LEAVE;
    }

    done_refresh:
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- dialog() ----

SV *
dialog(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_dialog", 0);
    if (svp && SvOK(*svp)) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        SV *dlg;
        dSP;
        int count;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Dialog"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Dialog")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        dlg = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_dialog", SvREFCNT_inc(dlg));
        RETVAL = dlg;
    }
}
OUTPUT:
    RETVAL

 # ---- tray(%args) ----

SV *
tray(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_tray", 0);
    if (svp && SvOK(*svp)) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        SV *tray_sv;
        dSP;
        int count;
        I32 i;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Tray"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Tray")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        for (i = 1; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        tray_sv = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_tray", SvREFCNT_inc(tray_sv));
        RETVAL = tray_sv;
    }
}
OUTPUT:
    RETVAL

 # ---- protocol() ----

SV *
protocol(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_protocol", 0);
    if (svp && SvOK(*svp)) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        SV *proto;
        dSP;
        int count;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Protocol"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Protocol")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        proto = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_protocol", SvREFCNT_inc(proto));
        RETVAL = proto;
    }
}
OUTPUT:
    RETVAL

 # ---- hub(%args) ----

SV *
hub(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_hub", 0);
    if (svp && SvOK(*svp)) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        SV *hub_sv;
        dSP;
        int count;
        I32 i;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Socket::Hub"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Socket::Hub")));
        for (i = 1; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        hub_sv = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_hub", SvREFCNT_inc(hub_sv));
        RETVAL = hub_sv;
    }
}
OUTPUT:
    RETVAL

 # ---- client(%args) ----

SV *
client(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_client", 0);
    if (svp && SvOK(*svp)) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        SV *client_sv;
        dSP;
        int count;
        I32 i;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Socket::Client"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Socket::Client")));
        for (i = 1; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        client_sv = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_client", SvREFCNT_inc(client_sv));
        RETVAL = client_sv;
    }
}
OUTPUT:
    RETVAL

 # ---- run() ----

void
run(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **wv_svp = hv_fetchs(hv, "_webview", 0);
    int blocking;

    if (!wv_svp || !SvOK(*wv_svp)) croak("No webview available");

    /* Init */
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        PUTBACK;
        call_method("init", G_DISCARD);
        FREETMPS; LEAVE;
    }
    (void)hv_stores(hv, "_started", newSViv(1));

    /* Bind __chandra_refresh for reload recovery */
    {
        SV *refresh_cb;
        CV *refresh_cv;

        /* Store self as refresh target */
        {
            SV *target_sv = get_sv("Chandra::App::_refresh_target", GV_ADD);
            sv_setsv(target_sv, self);
        }

        refresh_cv = newXS(NULL, xs_chandra_refresh_cb, __FILE__);
        refresh_cb = newRV_noinc((SV *)refresh_cv);

        {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*wv_svp);
            XPUSHs(sv_2mortal(newSVpvs("__chandra_refresh")));
            XPUSHs(sv_2mortal(refresh_cb));
            PUTBACK;
            call_method("bind", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

    /* Activate pending tray */
    {
        SV **tray_svp = hv_fetchs(hv, "_tray", 0);
        if (tray_svp && SvOK(*tray_svp) && SvROK(*tray_svp)) {
            HV *tray_hv = (HV *)SvRV(*tray_svp);
            SV **pending = hv_fetchs(tray_hv, "_pending", 0);
            if (pending && SvTRUE(*pending)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*tray_svp);
                PUTBACK;
                call_method("show", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
    }

    /* Routing mode */
    {
        SV **routes_svp = hv_fetchs(hv, "_routes", 0);
        if (routes_svp && SvROK(*routes_svp)) {
            SV **cr_svp = hv_fetchs(hv, "_current_route", 0);
            SV *initial;
            SV *html_sv, *escaped, *js;

            /* Bind __chandra_navigate */
            {
                SV *nav_cb;
                CV *nav_cv;
                dSP;

                /* Store self as the nav target */
                {
                    SV *target_sv = get_sv("Chandra::App::_nav_target", GV_ADD);
                    sv_setsv(target_sv, self);
                }

                /* Create XS callback — no eval_pv needed */
                nav_cv = newXS(NULL, xs_chandra_navigate_cb, __FILE__);
                nav_cb = newRV_noinc((SV *)nav_cv);

                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*wv_svp);
                XPUSHs(sv_2mortal(newSVpvs("__chandra_navigate")));
                XPUSHs(sv_2mortal(nav_cb));
                PUTBACK;
                call_method("bind", G_DISCARD);
                FREETMPS; LEAVE;
            }

            initial = (cr_svp && SvOK(*cr_svp)) ? *cr_svp :
                sv_2mortal(newSVpvs("/"));
            (void)hv_stores(hv, "_current_route", newSVsv(initial));

            /* Render initial route */
            {
                dSP;
                int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(self);
                XPUSHs(initial);
                PUTBACK;
                count = call_method("_render_route", G_SCALAR);
                SPAGAIN;
                html_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
                PUTBACK;
                FREETMPS; LEAVE;
            }

            escaped = chandra_escape_js(aTHX_ html_sv);
            SvREFCNT_dec(html_sv);

            js = newSVpvs("document.open();document.write('");
            sv_catsv(js, escaped);
            sv_catpvs(js, "');document.close();");
            SvREFCNT_dec(escaped);

            {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*wv_svp);
                XPUSHs(sv_2mortal(js));
                PUTBACK;
                call_method("eval_js", G_DISCARD);
                FREETMPS; LEAVE;
            }
        } else {
            /* Static content mode */
            SV **html_svp = hv_fetchs(hv, "_html", 0);
            if (html_svp && SvOK(*html_svp)) {
                SV *escaped = chandra_escape_js(aTHX_ *html_svp);
                SV *js = newSVpvs("document.open();document.write('");
                sv_catsv(js, escaped);
                sv_catpvs(js, "');document.close();");
                SvREFCNT_dec(escaped);

                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*wv_svp);
                XPUSHs(sv_2mortal(js));
                PUTBACK;
                call_method("eval_js", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
    }

    /* Inject post-content JS */
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(sv_2mortal(newSViv(0)));
        PUTBACK;
        call_method("_inject_post_content_js", G_DISCARD);
        FREETMPS; LEAVE;
    }

    /* Determine blocking mode */
    {
        SV **hr_svp = hv_fetchs(hv, "_hot_reload", 0);
        SV **hub_svp = hv_fetchs(hv, "_hub", 0);
        SV **cl_svp = hv_fetchs(hv, "_client", 0);
        blocking = 1;
        if ((hr_svp && SvOK(*hr_svp)) ||
            (hub_svp && SvOK(*hub_svp)) ||
            (cl_svp && SvOK(*cl_svp))) {
            blocking = 0;
        }
    }

    /* Event loop */
    while (1) {
        int loop_result;
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*wv_svp);
            XPUSHs(sv_2mortal(newSViv(blocking)));
            PUTBACK;
            count = call_method("loop", G_SCALAR);
            SPAGAIN;
            loop_result = (count > 0) ? (int)POPi : 1;
            PUTBACK;
            FREETMPS; LEAVE;
        }
        if (loop_result != 0) break;

        /* Poll sub-modules */
        {
            SV **hr_svp = hv_fetchs(hv, "_hot_reload", 0);
            if (hr_svp && SvOK(*hr_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*hr_svp);
                PUTBACK;
                call_method("poll", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
        {
            SV **hub_svp = hv_fetchs(hv, "_hub", 0);
            if (hub_svp && SvOK(*hub_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*hub_svp);
                PUTBACK;
                call_method("poll", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
        {
            SV **cl_svp = hv_fetchs(hv, "_client", 0);
            if (cl_svp && SvOK(*cl_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*cl_svp);
                PUTBACK;
                call_method("poll", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }

        /* Sleep 10ms for non-blocking mode */
        if (!blocking) {
            struct timeval tv;
            tv.tv_sec = 0;
            tv.tv_usec = 10000;
            select(0, NULL, NULL, NULL, &tv);
        }
    }

    /* Exit */
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*wv_svp);
        PUTBACK;
        call_method("exit", G_DISCARD);
        FREETMPS; LEAVE;
    }
    (void)hv_stores(hv, "_started", newSViv(0));
}

 # ---- notify(%args) — send a desktop notification ----

int
notify(self, ...)
    SV *self
CODE:
{
    ChandraNotification notif;
    I32 i;

    memset(&notif, 0, sizeof(notif));

    /* Parse key-value pairs from args */
    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);

        if (strcmp(key, "title") == 0 && SvOK(val)) {
            notif.title = SvPV_nolen(val);
        } else if (strcmp(key, "body") == 0 && SvOK(val)) {
            notif.body = SvPV_nolen(val);
        } else if (strcmp(key, "icon") == 0 && SvOK(val)) {
            notif.icon = SvPV_nolen(val);
        } else if (strcmp(key, "sound") == 0 && SvOK(val)) {
            notif.sound = SvIV(val);
        } else if (strcmp(key, "timeout") == 0 && SvOK(val)) {
            notif.timeout_ms = SvIV(val);
        }
    }

    if (!notif.title) {
        warn("Chandra::App::notify: title is required");
        RETVAL = 0;
    } else {
        RETVAL = chandra_notify_send(aTHX_ &notif);
    }
}
OUTPUT:
    RETVAL

 # ---- shortcuts() — lazy accessor for Chandra::Shortcut instance ----

SV *
shortcuts(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_shortcut", 0);
    if (svp && SvOK(*svp)) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        SV *sc;
        dSP;
        int count;
        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Shortcut"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Shortcut")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        sc = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK;
        FREETMPS; LEAVE;
        (void)hv_stores(hv, "_shortcut", SvREFCNT_inc(sc));
        RETVAL = sc;
    }
}
OUTPUT:
    RETVAL

 # ---- shortcut($combo, $handler, %opts) — convenience method ----

SV *
shortcut(self, combo_sv, handler, ...)
    SV *self
    SV *combo_sv
    SV *handler
CODE:
{
    SV *sc;
    dSP;
    int count;
    I32 i;

    /* Get shortcuts instance */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;
    count = call_method("shortcuts", G_SCALAR);
    SPAGAIN;
    sc = (count > 0) ? newSVsv(POPs) : newSV(0);
    PUTBACK;
    FREETMPS; LEAVE;

    /* Call bind on it, forwarding all args */
    {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(sc));
        XPUSHs(combo_sv);
        XPUSHs(handler);
        for (i = 3; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;
        call_method("bind", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- shortcut_map(\%map) — bulk registration ----

SV *
shortcut_map(self, map_sv)
    SV *self
    SV *map_sv
CODE:
{
    SV *sc;
    HV *map_hv;
    HE *entry;
    dSP;
    int count;

    if (!SvROK(map_sv) || SvTYPE(SvRV(map_sv)) != SVt_PVHV) {
        croak("shortcut_map() requires a hashref");
    }
    map_hv = (HV *)SvRV(map_sv);

    /* Get shortcuts instance */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;
    count = call_method("shortcuts", G_SCALAR);
    SPAGAIN;
    sc = (count > 0) ? newSVsv(POPs) : newSV(0);
    PUTBACK;
    FREETMPS; LEAVE;

    /* Iterate map and bind each */
    hv_iterinit(map_hv);
    while ((entry = hv_iternext(map_hv)) != NULL) {
        SV *combo_key = hv_iterkeysv(entry);
        SV *handler_val = HeVAL(entry);

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sc);
        XPUSHs(sv_2mortal(newSVsv(combo_key)));
        XPUSHs(handler_val);
        PUTBACK;
        call_method("bind", G_DISCARD);
        FREETMPS; LEAVE;
    }

    SvREFCNT_dec(sc);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- store($name) — persistent key-value store for this app ----
 # Caches the Chandra::Store instance on the self hash under _store_ or
 # _store_<name>.  Derives the store name from the app title when no
 # explicit name is given, mirroring the Perl version exactly.

SV *
store(self, ...)
    SV *self
CODE:
{
    HV   *hv        = (HV *)SvRV(self);
    SV   *name_sv   = (items > 1 && SvOK(ST(1))) ? ST(1) : NULL;
    char  cache_key[256];
    SV  **cached_svp;

    if (name_sv) {
        STRLEN nlen;
        const char *nstr = SvPV(name_sv, nlen);
        if (nlen > 240) nlen = 240;
        snprintf(cache_key, sizeof(cache_key), "_store_%.*s", (int)nlen, nstr);
    } else {
        strncpy(cache_key, "_store_", sizeof(cache_key));
    }

    cached_svp = hv_fetch(hv, cache_key, (I32)strlen(cache_key), 0);
    if (cached_svp && SvOK(*cached_svp)) {
        RETVAL = SvREFCNT_inc(*cached_svp);
    } else {
        dSP;
        int   count;
        SV   *store_name_sv;

        if (name_sv) {
            store_name_sv = newSVsv(name_sv);
        } else {
            /* Derive store name from app title: lowercase, replace
             * runs of [^a-z0-9_-] with '_', strip leading/trailing '_' */
            SV *title_sv;
            STRLEN tlen;
            const char *tstr;
            char *buf, *dst;
            const char *p, *end;
            int in_run;

            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            PUTBACK;
            count = call_method("title", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (count > 0 && !SvTRUE(ERRSV))
                title_sv = newSVsv(POPs);
            else
                title_sv = newSVpvs("chandra");
            PUTBACK; FREETMPS; LEAVE;

            tstr = SvPV(title_sv, tlen);
            buf  = (char *)malloc(tlen + 2);
            dst  = buf;
            in_run = 0;
            for (p = tstr, end = tstr + tlen; p < end; p++) {
                unsigned char c = (unsigned char)*p;
                if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
                    || c == '_' || c == '-') {
                    *dst++ = c;
                    in_run = 0;
                } else if (c >= 'A' && c <= 'Z') {
                    *dst++ = (char)(c + 32);  /* tolower */
                    in_run = 0;
                } else {
                    if (!in_run) { *dst++ = '_'; in_run = 1; }
                }
            }
            *dst = '\0';

            /* strip leading underscores */
            p = buf;
            while (*p == '_') p++;
            /* strip trailing underscores */
            dst = buf + strlen(p);
            while (dst > p && *(dst-1) == '_') dst--;
            *dst = '\0';

            store_name_sv = (*p) ? newSVpv(p, dst - p)
                                 : newSVpvs("chandra");
            free(buf);
            SvREFCNT_dec(title_sv);
        }

        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Chandra::Store"), NULL);

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Store")));
        XPUSHs(sv_2mortal(newSVpvs("name")));
        XPUSHs(sv_2mortal(store_name_sv));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK; FREETMPS; LEAVE;

        (void)hv_store(hv, cache_key, (I32)strlen(cache_key),
                       SvREFCNT_inc(RETVAL), 0);
    }
}
OUTPUT:
    RETVAL

 # ---- open_window(%args) — create a child window ----

SV *
open_window(self, ...)
    SV *self
CODE:
{
    dSP;
    int count;
    I32 i;

    load_module(PERL_LOADMOD_NOIMPORT,
        newSVpvs("Chandra::Window"), NULL);

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Chandra::Window")));
    /* Forward all key-value pairs */
    for (i = 1; i < items; i++) {
        XPUSHs(ST(i));
    }
    /* Add parent => $self */
    XPUSHs(sv_2mortal(newSVpvs("parent")));
    XPUSHs(self);
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    RETVAL = (count > 0) ? newSVsv(POPs) : &PL_sv_undef;
    PUTBACK;
    FREETMPS; LEAVE;

    /* Track child windows in _windows array */
    if (SvOK(RETVAL)) {
        HV *hv = (HV *)SvRV(self);
        SV **arr_svp = hv_fetchs(hv, "_windows", 0);
        AV *arr;
        if (arr_svp && SvROK(*arr_svp)) {
            arr = (AV *)SvRV(*arr_svp);
        } else {
            arr = newAV();
            (void)hv_stores(hv, "_windows", newRV_noinc((SV *)arr));
        }
        av_push(arr, SvREFCNT_inc(RETVAL));
    }
}
OUTPUT:
    RETVAL

 # ---- windows() — return all child windows ----

void
windows(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **arr_svp = hv_fetchs(hv, "_windows", 0);

    if (arr_svp && SvROK(*arr_svp)) {
        AV *arr = (AV *)SvRV(*arr_svp);
        I32 len = av_len(arr) + 1;
        I32 i;
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(arr, i, 0);
            if (elem && SvOK(*elem)) {
                XPUSHs(sv_2mortal(newSVsv(*elem)));
            }
        }
    }
}

 # ---- window_by_id($id) — find child window by ID ----

SV *
window_by_id(self, id_sv)
    SV *self
    SV *id_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **arr_svp = hv_fetchs(hv, "_windows", 0);
    const char *target_id = SvPV_nolen(id_sv);

    RETVAL = &PL_sv_undef;

    if (arr_svp && SvROK(*arr_svp)) {
        AV *arr = (AV *)SvRV(*arr_svp);
        I32 len = av_len(arr) + 1;
        I32 i;
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(arr, i, 0);
            if (elem && SvOK(*elem) && SvROK(*elem)) {
                HV *win_hv = (HV *)SvRV(*elem);
                SV **id_svp = hv_fetchs(win_hv, "id", 0);
                if (id_svp && SvOK(*id_svp)) {
                    const char *win_id = SvPV_nolen(*id_svp);
                    if (strcmp(win_id, target_id) == 0) {
                        RETVAL = newSVsv(*elem);
                        break;
                    }
                }
            }
        }
    }
}
OUTPUT:
    RETVAL

 # ---- window_count() — return number of child windows ----

int
window_count(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **arr_svp = hv_fetchs(hv, "_windows", 0);

    if (arr_svp && SvROK(*arr_svp)) {
        AV *arr = (AV *)SvRV(*arr_svp);
        RETVAL = (int)(av_len(arr) + 1);
    } else {
        RETVAL = 0;
    }
}
OUTPUT:
    RETVAL

 # ---- on_close($coderef) — register close handler for main window ----

SV *
on_close(self, handler)
    SV *self
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_on_close", newSVsv(handler));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- assets($root, prefix => $pfx) — lazy Chandra::Assets accessor ----

SV *
assets(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **cached_svp = hv_fetchs(hv, "_assets", 0);

    if (cached_svp && SvOK(*cached_svp)) {
        RETVAL = SvREFCNT_inc(*cached_svp);
    } else {
        dSP;
        int count;
        SV *root_sv = (items > 1 && SvOK(ST(1))) ? ST(1) : NULL;

        if (!root_sv) {
            croak("assets() requires a root directory on first call");
        }

        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::Assets"), NULL);

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Assets")));
        XPUSHs(sv_2mortal(newSVpvs("root")));
        XPUSHs(root_sv);
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);

        /* Forward remaining named args (prefix => 'xxx', etc.) */
        {
            I32 i;
            for (i = 2; i < items; i++) {
                XPUSHs(ST(i));
            }
        }

        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? newSVsv(POPs) : newSV(0);
        PUTBACK; FREETMPS; LEAVE;

        (void)hv_stores(hv, "_assets", SvREFCNT_inc(RETVAL));
    }
}
OUTPUT:
    RETVAL

 # ---- clipboard() — returns Chandra::Clipboard class for convenience ----

SV *
clipboard(self)
    SV *self
CODE:
{
    load_module(PERL_LOADMOD_NOIMPORT,
        newSVpvs("Chandra::Clipboard"), NULL);
    RETVAL = newSVpvs("Chandra::Clipboard");
}
OUTPUT:
    RETVAL

 # ---- drag_drop() — lazy Chandra::DragDrop accessor ----

SV *
drag_drop(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **cached_svp = hv_fetchs(hv, "_dragdrop", 0);

    if (cached_svp && SvOK(*cached_svp)) {
        RETVAL = SvREFCNT_inc(*cached_svp);
    } else {
        dSP;
        int count;

        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::DragDrop"), NULL);

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::DragDrop")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;

        (void)hv_stores(hv, "_dragdrop", SvREFCNT_inc(RETVAL));
    }
}
OUTPUT:
    RETVAL

 # ---- on_file_drop($coderef) — convenience for drag_drop->on_file_drop ----

SV *
on_file_drop(self, callback)
    SV *self
    SV *callback
CODE:
{
    SV *dd;
    dSP;
    int count;

    /* Get or create drag_drop instance */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;
    count = call_method("drag_drop", G_SCALAR);
    SPAGAIN;
    dd = (count > 0) ? POPs : &PL_sv_undef;

    PUSHMARK(SP);
    XPUSHs(dd);
    XPUSHs(callback);
    PUTBACK;
    call_method("on_file_drop", G_DISCARD);
    FREETMPS; LEAVE;

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- drop_zone($selector, $coderef) — convenience for drag_drop->add_drop_zone ----

SV *
drop_zone(self, selector, callback)
    SV *self
    SV *selector
    SV *callback
CODE:
{
    SV *dd;
    dSP;
    int count;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;
    count = call_method("drag_drop", G_SCALAR);
    SPAGAIN;
    dd = (count > 0) ? POPs : &PL_sv_undef;

    PUSHMARK(SP);
    XPUSHs(dd);
    XPUSHs(selector);
    XPUSHs(callback);
    PUTBACK;
    call_method("add_drop_zone", G_DISCARD);
    FREETMPS; LEAVE;

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- context_menu_instance() — lazy Chandra::ContextMenu accessor ----

SV *
context_menu_instance(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **cached_svp = hv_fetchs(hv, "_contextmenu", 0);

    if (cached_svp && SvOK(*cached_svp)) {
        RETVAL = SvREFCNT_inc(*cached_svp);
    } else {
        dSP;
        int count;

        load_module(PERL_LOADMOD_NOIMPORT,
            newSVpvs("Chandra::ContextMenu"), NULL);

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::ContextMenu")));
        XPUSHs(sv_2mortal(newSVpvs("app")));
        XPUSHs(self);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;

        (void)hv_stores(hv, "_contextmenu", SvREFCNT_inc(RETVAL));
    }
}
OUTPUT:
    RETVAL

 # ---- context_menu(selector, items_or_cb) — convenience method ----

SV *
context_menu(self, selector, items_or_cb)
    SV *self
    SV *selector
    SV *items_or_cb
CODE:
{
    SV *cm;
    dSP;
    int count;

    /* Get or create context_menu instance */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;
    count = call_method("context_menu_instance", G_SCALAR);
    SPAGAIN;
    cm = (count > 0) ? POPs : &PL_sv_undef;

    if (SvROK(items_or_cb) && SvTYPE(SvRV(items_or_cb)) == SVt_PVCV) {
        /* Dynamic: attach(selector, coderef) */
        PUSHMARK(SP);
        XPUSHs(cm);
        XPUSHs(selector);
        XPUSHs(items_or_cb);
        PUTBACK;
        call_method("attach", G_DISCARD);
    } else if (SvROK(items_or_cb) && SvTYPE(SvRV(items_or_cb)) == SVt_PVAV) {
        /* Static items: set items, then attach */
        HV *cm_hv = (HV *)SvRV(cm);
        (void)hv_stores(cm_hv, "_items", newSVsv(items_or_cb));

        /* Register actions */
        {
            SV **actions_svp = hv_fetchs(cm_hv, "_actions", 0);
            _cm_register_actions(aTHX_ cm_hv,
                (AV *)SvRV(items_or_cb), (HV *)SvRV(*actions_svp));
        }

        PUSHMARK(SP);
        XPUSHs(cm);
        XPUSHs(selector);
        PUTBACK;
        call_method("attach", G_DISCARD);
    }
    FREETMPS; LEAVE;

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- splash(%args) — convenience wrapper for Chandra::Splash ----

SV *
splash(self, ...)
    SV *self
PREINIT:
    SV *splash_obj;
    SV *init_cb = NULL;
    I32 i;
CODE:
{
    dSP;
    int count;

    /* Scan args for 'init' callback, collect the rest for Splash->new */
    AV *new_args = newAV();
    sv_2mortal((SV *)new_args);

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "init")) {
            init_cb = ST(i + 1);
        } else {
            av_push(new_args, newSVsv(ST(i)));
            av_push(new_args, newSVsv(ST(i + 1)));
        }
    }

    /* Create Chandra::Splash->new(@new_args) */
    {
        I32 n = av_len(new_args) + 1;
        I32 j;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Splash")));
        for (j = 0; j < n; j++) {
            SV **elem = av_fetch(new_args, j, 0);
            if (elem) XPUSHs(*elem);
        }
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        splash_obj = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK;
        FREETMPS; LEAVE;
    }

    if (!SvOK(splash_obj) || !sv_isobject(splash_obj)) {
        RETVAL = &PL_sv_undef;
        goto splash_done;
    }

    /* show() */
    {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(splash_obj);
        PUTBACK;
        call_method("show", G_DISCARD);
        FREETMPS; LEAVE;
    }

    /* Call init callback if provided */
    if (init_cb && SvROK(init_cb) && SvTYPE(SvRV(init_cb)) == SVt_PVCV) {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(splash_obj);
        PUTBACK;
        call_sv(init_cb, G_DISCARD | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("Chandra::App->splash init callback died: %s",
                 SvPV_nolen(ERRSV));
        }
        FREETMPS; LEAVE;
    }

    /* close() */
    {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(splash_obj);
        PUTBACK;
        call_method("close", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = splash_obj;
    splash_done: ;
}
OUTPUT:
    RETVAL

void
extend_bridge(self, name, source, ...)
    SV *self
    const char *name
    const char *source
PPCODE:
{
    char **deps = NULL;
    int    dep_count = 0;
    int    i;

    PERL_UNUSED_VAR(self);

    /* parse optional depends => [...] */
    if (items > 3 && (items - 3) % 2 == 0) {
        for (i = 3; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strcmp(key, "depends") == 0) {
                SV *val = ST(i + 1);
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV *)SvRV(val);
                    SSize_t alen = av_len(av) + 1;
                    int j;
                    dep_count = (int)alen;
                    if (dep_count > 0) {
                        Newx(deps, dep_count, char *);
                        for (j = 0; j < dep_count; j++) {
                            SV **svp = av_fetch(av, j, 0);
                            deps[j] = savepv(svp ? SvPV_nolen(*svp) : "");
                        }
                    }
                }
            }
        }
    }

    chandra_ext_register(aTHX_ name, source, deps, dep_count);

    if (deps) {
        for (i = 0; i < dep_count; i++)
            Safefree(deps[i]);
        Safefree(deps);
    }

    XSRETURN(1);
}
