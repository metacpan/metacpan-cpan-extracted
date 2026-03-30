MODULE = Chandra    PACKAGE = Chandra

PROTOTYPES: DISABLE

PerlChandra *
new(class, ...)
    const char *class
PREINIT:
    HV *opts = NULL;
    SV **val;
    const char *title = "Chandra";
    const char *url = "about:blank";
    int width = 800;
    int height = 600;
    int resizable = 1;
    int debug = 0;
    SV *callback = NULL;
CODE:
    /* Parse hash arguments */
    if (items > 1) {
        int i;
        if (items % 2 == 0) {
            croak("Odd number of arguments to new()");
        }
        for (i = 1; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *value = ST(i + 1);
            
            if (strEQ(key, "title")) {
                title = SvPV_nolen(value);
            } else if (strEQ(key, "url")) {
                url = SvPV_nolen(value);
            } else if (strEQ(key, "width")) {
                width = SvIV(value);
            } else if (strEQ(key, "height")) {
                height = SvIV(value);
            } else if (strEQ(key, "resizable")) {
                resizable = SvIV(value);
            } else if (strEQ(key, "debug")) {
                debug = SvIV(value);
            } else if (strEQ(key, "callback")) {
                callback = value;
            }
        }
    }
    
    Newxz(RETVAL, 1, PerlChandra);
    RETVAL->wv.title = savepv(title);
    RETVAL->wv.url = savepv(url);
    RETVAL->wv.width = width;
    RETVAL->wv.height = height;
    RETVAL->wv.resizable = resizable;
    RETVAL->wv.debug = debug;
    RETVAL->initialized = 0;
    
    /* Set up callback if provided */
    if (callback && SvOK(callback) && SvROK(callback)) {
        perl_callback = SvREFCNT_inc(callback);
        RETVAL->callback = perl_callback;
        RETVAL->wv.external_invoke_cb = external_invoke_cb;
        my_perl_interp = PERL_GET_THX;
    } else {
        RETVAL->wv.external_invoke_cb = NULL;
        RETVAL->callback = NULL;
    }
OUTPUT:
    RETVAL

void
run(self)
    PerlChandra *self
CODE:
    webview_run(self->wv.title, self->wv.url, self->wv.width, self->wv.height, self->wv.resizable);

void
init(self)
    PerlChandra *self
CODE:
    if (webview_init(&self->wv) != 0) {
        croak("Failed to initialize webview");
    }
    self->initialized = 1;

int
loop(self, ...)
    PerlChandra *self
PREINIT:
    int blocking = 1;
CODE:
    if (items > 1) {
        blocking = SvIV(ST(1));
    }
    RETVAL = webview_loop(&self->wv, blocking);
OUTPUT:
    RETVAL

int
eval_js(self, js)
    PerlChandra *self
    const char *js
CODE:
    RETVAL = webview_eval(&self->wv, js);
OUTPUT:
    RETVAL

void
dispatch_eval_js(self, js)
    PerlChandra *self
    const char *js
CODE:
    webview_dispatch(&self->wv, deferred_eval_cb, strdup(js));

void
set_title(self, title)
    PerlChandra *self
    const char *title
CODE:
    webview_set_title(&self->wv, title);
    Safefree((char*)self->wv.title);
    self->wv.title = savepv(title);

void
terminate(self)
    PerlChandra *self
CODE:
    webview_terminate(&self->wv);

void
exit(self)
    PerlChandra *self
CODE:
    if (self->initialized) {
        webview_exit(&self->wv);
    }

void
DESTROY(self)
    PerlChandra *self
CODE:
    if (self->callback) {
        SvREFCNT_dec(self->callback);
        perl_callback = NULL;
    }
    if (self->wv.title) {
        Safefree((char*)self->wv.title);
    }
    if (self->wv.url) {
        Safefree((char*)self->wv.url);
    }
    /* Clean up tray */
    if (self->tray_active) {
        webview_tray_destroy(&self->tray);
        self->tray_active = 0;
    }
    if (self->tray.icon_path) {
        Safefree((char *)self->tray.icon_path);
    }
    if (self->tray.tooltip) {
        Safefree((char *)self->tray.tooltip);
    }
    if (self->tray_callback) {
        SvREFCNT_dec(self->tray_callback);
        self->tray_callback = NULL;
    }
    Safefree(self);

const char *
title(self)
    PerlChandra *self
CODE:
    RETVAL = self->wv.title;
OUTPUT:
    RETVAL

const char *
url(self)
    PerlChandra *self
CODE:
    RETVAL = self->wv.url;
OUTPUT:
    RETVAL

int
width(self)
    PerlChandra *self
CODE:
    RETVAL = self->wv.width;
OUTPUT:
    RETVAL

int
height(self)
    PerlChandra *self
CODE:
    RETVAL = self->wv.height;
OUTPUT:
    RETVAL

void
_set_callback(self, callback)
    PerlChandra *self
    SV *callback
CODE:
    if (self->callback) {
        SvREFCNT_dec(self->callback);
        perl_callback = NULL;
    }
    if (SvOK(callback) && SvROK(callback)) {
        perl_callback = SvREFCNT_inc(callback);
        self->callback = perl_callback;
        self->wv.external_invoke_cb = external_invoke_cb;
        my_perl_interp = PERL_GET_THX;
    } else {
        self->wv.external_invoke_cb = NULL;
        self->callback = NULL;
    }

int
resizable(self)
    PerlChandra *self
CODE:
    RETVAL = self->wv.resizable;
OUTPUT:
    RETVAL

int
debug(self)
    PerlChandra *self
CODE:
    RETVAL = self->wv.debug;
OUTPUT:
    RETVAL

SV *
dialog(self, dlgtype, flags, title, arg)
    PerlChandra *self
    int dlgtype
    int flags
    const char *title
    const char *arg
PREINIT:
    char result[4096];
CODE:
    memset(result, 0, sizeof(result));
    webview_dialog(&self->wv, dlgtype, flags, title, arg, result, sizeof(result));
    if (strlen(result) > 0) {
        RETVAL = newSVpv(result, 0);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

int
inject_css(self, css)
    PerlChandra *self
    const char *css
CODE:
    RETVAL = webview_inject_css(&self->wv, css);
OUTPUT:
    RETVAL

void
set_fullscreen(self, fullscreen)
    PerlChandra *self
    int fullscreen
CODE:
    webview_set_fullscreen(&self->wv, fullscreen);

void
set_color(self, r, g, b, a)
    PerlChandra *self
    int r
    int g
    int b
    int a
CODE:
    webview_set_color(&self->wv, (uint8_t)r, (uint8_t)g, (uint8_t)b, (uint8_t)a);
