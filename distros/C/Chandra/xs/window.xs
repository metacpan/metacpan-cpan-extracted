MODULE = Chandra    PACKAGE = Chandra::Window

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
PREINIT:
    HV *self;
    SV *self_ref;
    int wid;
    const char *title = "Window";
    int width = 400, height = 300;
    int x = -1, y = -1;
    int resizable = 1, frameless = 0;
    int modal = 0;
    SV *content = NULL, *url = NULL, *parent = NULL;
    char id_buf[64];
    int i;
CODE:
    id_buf[0] = '\0';  /* Initialize id_buf */
    
    /* Parse named arguments */
    if ((items - 1) % 2 != 0)
        croak("Chandra::Window->new requires key => value pairs");
    
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        
        if (strcmp(key, "title") == 0)     title = SvPV_nolen(val);
        else if (strcmp(key, "width") == 0)     width = SvIV(val);
        else if (strcmp(key, "height") == 0)    height = SvIV(val);
        else if (strcmp(key, "x") == 0)         x = SvIV(val);
        else if (strcmp(key, "y") == 0)         y = SvIV(val);
        else if (strcmp(key, "resizable") == 0) resizable = SvIV(val);
        else if (strcmp(key, "frameless") == 0) frameless = SvIV(val);
        else if (strcmp(key, "modal") == 0)     modal = SvIV(val);
        else if (strcmp(key, "content") == 0)   content = val;
        else if (strcmp(key, "url") == 0)       url = val;
        else if (strcmp(key, "parent") == 0)    parent = val;
        else if (strcmp(key, "id") == 0) {
            snprintf(id_buf, sizeof(id_buf), "%s", SvPV_nolen(val));
        }
    }
    
    /* Create native window */
    wid = cwin_create(title, width, height, x, y, resizable, frameless);
    if (wid < 0) {
        warn("Chandra::Window: multi-window not supported on this platform");
        XSRETURN_UNDEF;
    }
    
    /* Generate ID if not provided */
    if (id_buf[0] == '\0') {
        snprintf(id_buf, sizeof(id_buf), "window-%d", ++_window_id_counter);
    }
    
    /* Create blessed hash */
    self = newHV();
    hv_store(self, "wid", 3, newSViv(wid), 0);
    hv_store(self, "id", 2, newSVpv(id_buf, 0), 0);
    hv_store(self, "title", 5, newSVpv(title, 0), 0);
    hv_store(self, "width", 5, newSViv(width), 0);
    hv_store(self, "height", 6, newSViv(height), 0);
    hv_store(self, "x", 1, newSViv(x), 0);
    hv_store(self, "y", 1, newSViv(y), 0);
    hv_store(self, "resizable", 9, newSViv(resizable), 0);
    hv_store(self, "frameless", 9, newSViv(frameless), 0);
    hv_store(self, "modal", 5, newSViv(modal), 0);
    hv_store(self, "visible", 7, newSViv(1), 0);
    hv_store(self, "_events", 7, newRV_noinc((SV*)newHV()), 0);
    
    if (parent && SvOK(parent))
        hv_store(self, "parent", 6, SvREFCNT_inc(parent), 0);
    if (content && SvOK(content))
        hv_store(self, "content", 7, SvREFCNT_inc(content), 0);
    if (url && SvOK(url))
        hv_store(self, "url", 3, SvREFCNT_inc(url), 0);
    
    self_ref = newRV_noinc((SV*)self);
    sv_bless(self_ref, gv_stashpv(class, GV_ADD));
    
    /* Register in window table */
    REGISTER_WINDOW(wid, self_ref);
    
    /* Set initial content */
    if (content && SvOK(content)) {
        STRLEN len;
        const char *html = SvPV(content, len);
        char *wrapped = NULL;
        
        /* Wrap in HTML structure if needed */
        if (!strstr(html, "<html") && !strstr(html, "<HTML")) {
            wrapped = (char*)malloc(len + 200);
            snprintf(wrapped, len + 200,
                "<!DOCTYPE html>\n<html>\n<head><meta charset=\"UTF-8\"></head>\n<body>%s</body>\n</html>",
                html);
            cwin_set_html(wid, wrapped);
            free(wrapped);
        } else {
            cwin_set_html(wid, html);
        }
    } else if (url && SvOK(url)) {
        cwin_navigate(wid, SvPV_nolen(url));
    }
    
    /* Set modal if requested */
    if (modal && parent && SvOK(parent) && SvROK(parent)) {
        HV *parent_hv = (HV*)SvRV(parent);
        SV **parent_wid_sv = hv_fetch(parent_hv, "wid", 3, 0);
        if (parent_wid_sv && SvIOK(*parent_wid_sv)) {
            cwin_set_modal(wid, SvIV(*parent_wid_sv));
        }
    }
    
    /* Track parent-child relationship */
    if (parent && SvOK(parent) && SvROK(parent)) {
        HV *parent_hv = (HV*)SvRV(parent);
        SV **children_svp = hv_fetch(parent_hv, "_children", 9, 1);
        AV *children;
        
        if (children_svp && SvROK(*children_svp) && SvTYPE(SvRV(*children_svp)) == SVt_PVAV) {
            children = (AV*)SvRV(*children_svp);
        } else {
            children = newAV();
            hv_store(parent_hv, "_children", 9, newRV_noinc((SV*)children), 0);
        }
        av_push(children, SvREFCNT_inc(self_ref));
    }
    
    RETVAL = self_ref;
OUTPUT:
    RETVAL

int
wid(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "wid", 3, 0);
    RETVAL = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
OUTPUT:
    RETVAL

SV *
id(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "id", 2, 0);
    RETVAL = (svp && SvOK(*svp)) ? SvREFCNT_inc(*svp) : newSVpv("", 0);
OUTPUT:
    RETVAL

SV *
set_content(self, html_sv)
    SV *self
    SV *html_sv
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
    STRLEN len;
    const char *html;
    char *wrapped = NULL;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid < 0) {
        ST(0) = self;
        XSRETURN(1);
    }
    
    hv_store(hv, "content", 7, SvREFCNT_inc(html_sv), 0);
    
    html = SvPV(html_sv, len);
    if (!strstr(html, "<html") && !strstr(html, "<HTML")) {
        wrapped = (char*)malloc(len + 200);
        snprintf(wrapped, len + 200,
            "<!DOCTYPE html>\n<html>\n<head><meta charset=\"UTF-8\"></head>\n<body>%s</body>\n</html>",
            html);
        cwin_set_html(wid, wrapped);
        free(wrapped);
    } else {
        cwin_set_html(wid, html);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
navigate(self, url_sv)
    SV *self
    SV *url_sv
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid < 0) {
        ST(0) = self;
        XSRETURN(1);
    }
    
    hv_store(hv, "url", 3, SvREFCNT_inc(url_sv), 0);
    cwin_navigate(wid, SvPV_nolen(url_sv));
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
eval(self, js_sv)
    SV *self
    SV *js_sv
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        cwin_eval_js(wid, SvPV_nolen(js_sv));
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
set_title(self, title_sv)
    SV *self
    SV *title_sv
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        hv_store(hv, "title", 5, SvREFCNT_inc(title_sv), 0);
        cwin_set_title(wid, SvPV_nolen(title_sv));
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
set_size(self, width, height)
    SV *self
    int width
    int height
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        hv_store(hv, "width", 5, newSViv(width), 0);
        hv_store(hv, "height", 6, newSViv(height), 0);
        cwin_set_size(wid, width, height);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
set_position(self, x, y)
    SV *self
    int x
    int y
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        hv_store(hv, "x", 1, newSViv(x), 0);
        hv_store(hv, "y", 1, newSViv(y), 0);
        cwin_set_position(wid, x, y);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
show(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        hv_store(hv, "visible", 7, newSViv(1), 0);
        cwin_show(wid);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
hide(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        hv_store(hv, "visible", 7, newSViv(0), 0);
        cwin_hide(wid);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
focus(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        cwin_focus(wid);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
minimize(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        cwin_minimize(wid);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
maximize(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        cwin_maximize(wid);
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
close(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid < 0) {
        ST(0) = self;
        XSRETURN(1);
    }
    
    /* Call on_close hook if defined */
    svp = hv_fetch(hv, "_on_close", 9, 0);
    if (svp && SvOK(*svp) && SvROK(*svp)) {
        dSP;
        int result;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_sv(*svp, G_SCALAR);
        SPAGAIN;
        result = POPi;
        FREETMPS; LEAVE;
        if (!result) {
            RETVAL = SvREFCNT_inc(self);
            goto done;
        }
    }
    
    /* End modal mode if active */
    svp = hv_fetch(hv, "modal", 5, 0);
    if (svp && SvTRUE(*svp)) {
        cwin_end_modal(wid);
    }
    
    /* Unregister and destroy */
    UNREGISTER_WINDOW(wid);
    cwin_destroy(wid);
    
    RETVAL = SvREFCNT_inc(self);
done:
OUTPUT:
    RETVAL

int
is_visible(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "visible", 7, 0);
    RETVAL = (svp && SvTRUE(*svp)) ? 1 : 0;
OUTPUT:
    RETVAL

int
is_modal(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "modal", 5, 0);
    RETVAL = (svp && SvTRUE(*svp)) ? 1 : 0;
OUTPUT:
    RETVAL

int
is_closed(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    
    /* Check if in registry and native window exists */
    if (wid < 0 || !GET_WINDOW(wid)) {
        RETVAL = 1;
    } else {
        RETVAL = !cwin_exists(wid);
    }
OUTPUT:
    RETVAL

void
get_size(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int width = 0, height = 0;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "width", 5, 0);
    if (svp && SvIOK(*svp)) width = SvIV(*svp);
    svp = hv_fetch(hv, "height", 6, 0);
    if (svp && SvIOK(*svp)) height = SvIV(*svp);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(width)));
    PUSHs(sv_2mortal(newSViv(height)));

void
get_position(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int x = 0, y = 0;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "x", 1, 0);
    if (svp && SvIOK(*svp)) x = SvIV(*svp);
    svp = hv_fetch(hv, "y", 1, 0);
    if (svp && SvIOK(*svp)) y = SvIV(*svp);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(x)));
    PUSHs(sv_2mortal(newSViv(y)));

SV *
set_modal(self, ...)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
    int parent_wid = 0;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    /* Check if already modal */
    svp = hv_fetch(hv, "modal", 5, 0);
    if (svp && SvTRUE(*svp)) {
        RETVAL = SvREFCNT_inc(self);
        goto done;
    }
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid < 0) {
        RETVAL = SvREFCNT_inc(self);
        goto done;
    }
    
    hv_store(hv, "modal", 5, newSViv(1), 0);
    
    if (items > 1 && SvOK(ST(1)) && SvROK(ST(1))) {
        HV *parent_hv = (HV*)SvRV(ST(1));
        SV **parent_svp = hv_fetch(parent_hv, "wid", 3, 0);
        if (parent_svp && SvIOK(*parent_svp)) {
            parent_wid = SvIV(*parent_svp);
            hv_store(hv, "parent", 6, SvREFCNT_inc(ST(1)), 0);
        }
    }
    
    cwin_set_modal(wid, parent_wid);
    RETVAL = SvREFCNT_inc(self);
done:
OUTPUT:
    RETVAL

SV *
end_modal(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "modal", 5, 0);
    if (!svp || !SvTRUE(*svp)) {
        RETVAL = SvREFCNT_inc(self);
        goto done;
    }
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    if (wid >= 0) {
        cwin_end_modal(wid);
    }
    
    hv_store(hv, "modal", 5, newSViv(0), 0);
    RETVAL = SvREFCNT_inc(self);
done:
OUTPUT:
    RETVAL

SV *
on_close(self, coderef)
    SV *self
    SV *coderef
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    hv_store(hv, "_on_close", 9, SvREFCNT_inc(coderef), 0);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
on_resize(self, coderef)
    SV *self
    SV *coderef
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    hv_store(hv, "_on_resize", 10, SvREFCNT_inc(coderef), 0);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
on_focus(self, coderef)
    SV *self
    SV *coderef
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    hv_store(hv, "_on_focus", 9, SvREFCNT_inc(coderef), 0);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
on_blur(self, coderef)
    SV *self
    SV *coderef
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    hv_store(hv, "_on_blur", 8, SvREFCNT_inc(coderef), 0);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
on(self, event, coderef)
    SV *self
    const char *event
    SV *coderef
PREINIT:
    HV *hv;
    SV **svp;
    HV *events;
    AV *handlers;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_events", 7, 0);
    if (!svp || !SvROK(*svp)) {
        events = newHV();
        hv_store(hv, "_events", 7, newRV_noinc((SV*)events), 0);
    } else {
        events = (HV*)SvRV(*svp);
    }
    
    svp = hv_fetch(events, event, strlen(event), 0);
    if (!svp || !SvROK(*svp)) {
        handlers = newAV();
        hv_store(events, event, strlen(event), newRV_noinc((SV*)handlers), 0);
    } else {
        handlers = (AV*)SvRV(*svp);
    }
    
    av_push(handlers, SvREFCNT_inc(coderef));
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
emit(self, event, ...)
    SV *self
    const char *event
PREINIT:
    HV *hv;
    SV **svp;
    HV *events;
    AV *handlers;
    int i, len;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_events", 7, 0);
    if (svp && SvROK(*svp)) {
        events = (HV*)SvRV(*svp);
        svp = hv_fetch(events, event, strlen(event), 0);
        if (svp && SvROK(*svp)) {
            handlers = (AV*)SvRV(*svp);
            len = av_len(handlers) + 1;
            for (i = 0; i < len; i++) {
                SV **cbp = av_fetch(handlers, i, 0);
                if (cbp && SvOK(*cbp)) {
                    dSP;
                    int j;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    for (j = 2; j < items; j++) {
                        XPUSHs(ST(j));
                    }
                    PUTBACK;
                    call_sv(*cbp, G_DISCARD);
                    FREETMPS; LEAVE;
                }
            }
        }
    }
    
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

void
windows(class)
    const char *class
PREINIT:
    HE *entry;
PPCODE:
    PERL_UNUSED_VAR(class);
    ENSURE_REGISTRY();
    hv_iterinit(_window_registry);
    while ((entry = hv_iternext(_window_registry))) {
        SV *val = hv_iterval(_window_registry, entry);
        if (val && SvOK(val)) {
            XPUSHs(sv_2mortal(SvREFCNT_inc(val)));
        }
    }

SV *
window_by_id(class, target_id)
    const char *class
    const char *target_id
PREINIT:
    HE *entry;
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = &PL_sv_undef;
    ENSURE_REGISTRY();
    hv_iterinit(_window_registry);
    while ((entry = hv_iternext(_window_registry))) {
        SV *val = hv_iterval(_window_registry, entry);
        if (val && SvROK(val)) {
            HV *win_hv = (HV*)SvRV(val);
            SV **id_svp = hv_fetch(win_hv, "id", 2, 0);
            if (id_svp && SvOK(*id_svp)) {
                const char *win_id = SvPV_nolen(*id_svp);
                if (strcmp(win_id, target_id) == 0) {
                    RETVAL = SvREFCNT_inc(val);
                    break;
                }
            }
        }
    }
OUTPUT:
    RETVAL

SV *
window_by_wid(class, wid)
    const char *class
    int wid
PREINIT:
    SV *win;
CODE:
    PERL_UNUSED_VAR(class);
    win = GET_WINDOW(wid);
    RETVAL = win ? SvREFCNT_inc(win) : &PL_sv_undef;
OUTPUT:
    RETVAL

int
window_count(class)
    const char *class
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = GET_WINDOW_COUNT();
OUTPUT:
    RETVAL

SV *
parent(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "parent", 6, 0);
    RETVAL = (svp && SvOK(*svp)) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
OUTPUT:
    RETVAL

void
children(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    AV *children_av;
    int i, len;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_children", 9, 0);
    if (svp && SvROK(*svp)) {
        children_av = (AV*)SvRV(*svp);
        len = av_len(children_av) + 1;
        EXTEND(SP, len);
        for (i = 0; i < len; i++) {
            SV **child = av_fetch(children_av, i, 0);
            if (child && SvOK(*child)) {
                PUSHs(sv_2mortal(SvREFCNT_inc(*child)));
            }
        }
    }

SV *
_add_child(self, child)
    SV *self
    SV *child
PREINIT:
    HV *hv;
    SV **svp;
    AV *children_av;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Not a Chandra::Window object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_children", 9, 0);
    if (!svp || !SvROK(*svp)) {
        children_av = newAV();
        hv_store(hv, "_children", 9, newRV_noinc((SV*)children_av), 0);
    } else {
        children_av = (AV*)SvRV(*svp);
    }
    
    av_push(children_av, SvREFCNT_inc(child));
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int wid;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        return;
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "wid", 3, 0);
    wid = (svp && SvIOK(*svp)) ? SvIV(*svp) : -1;
    
    if (wid >= 0 && GET_WINDOW(wid)) {
        /* End modal if active */
        svp = hv_fetch(hv, "modal", 5, 0);
        if (svp && SvTRUE(*svp)) {
            cwin_end_modal(wid);
        }
        UNREGISTER_WINDOW(wid);
        cwin_destroy(wid);
    }

# Low-level functions retained for direct access
int
_window_create(title, width, height, x, y, resizable, frameless)
    const char *title
    int width
    int height
    int x
    int y
    int resizable
    int frameless
CODE:
    RETVAL = cwin_create(title, width, height, x, y, resizable, frameless);
OUTPUT:
    RETVAL

void
_window_destroy(wid)
    int wid
CODE:
    cwin_destroy(wid);

void
_window_set_html(wid, html)
    int wid
    const char *html
CODE:
    cwin_set_html(wid, html);

void
_window_eval_js(wid, js)
    int wid
    const char *js
CODE:
    cwin_eval_js(wid, js);

void
_window_set_title(wid, title)
    int wid
    const char *title
CODE:
    cwin_set_title(wid, title);

void
_window_set_size(wid, w, h)
    int wid
    int w
    int h
CODE:
    cwin_set_size(wid, w, h);

void
_window_set_position(wid, x, y)
    int wid
    int x
    int y
CODE:
    cwin_set_position(wid, x, y);

void
_window_show(wid)
    int wid
CODE:
    cwin_show(wid);

void
_window_hide(wid)
    int wid
CODE:
    cwin_hide(wid);

void
_window_focus(wid)
    int wid
CODE:
    cwin_focus(wid);

void
_window_minimize(wid)
    int wid
CODE:
    cwin_minimize(wid);

void
_window_maximize(wid)
    int wid
CODE:
    cwin_maximize(wid);

void
_window_navigate(wid, url)
    int wid
    const char *url
CODE:
    cwin_navigate(wid, url);

void
_window_set_modal(wid, parent_wid)
    int wid
    int parent_wid
CODE:
    cwin_set_modal(wid, parent_wid);

void
_window_end_modal(wid)
    int wid
CODE:
    cwin_end_modal(wid);

int
_window_is_modal(wid)
    int wid
CODE:
    RETVAL = cwin_is_modal(wid);
OUTPUT:
    RETVAL

int
_window_exists(wid)
    int wid
CODE:
    RETVAL = cwin_exists(wid);
OUTPUT:
    RETVAL
