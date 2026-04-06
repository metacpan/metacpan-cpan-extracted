/*
 * chandra_window.h — Child-window management for Chandra
 *
 * On macOS: creates real NSWindow + WKWebView instances that share the
 * existing NSApplication event loop.  Messages from child-window JS
 * are routed through the global perl_callback (same as the main window),
 * so all $app->bind() handlers work from any window.
 *
 * On other platforms: every entry point is a no-op stub that returns -1.
 * Window.pm falls back to a "stub" mode and logs a warning.
 *
 * Define CHANDRA_WINDOW_IMPLEMENTATION before including this header
 * (Chandra.xs does this).
 */

#ifndef CHANDRA_WINDOW_H
#define CHANDRA_WINDOW_H

/* ---- Registry of child windows ---- */
#define CHANDRA_MAX_CHILD_WINDOWS 64

#ifdef CHANDRA_WINDOW_IMPLEMENTATION

#ifdef WEBVIEW_COCOA  /* ======================================================= macOS */

typedef struct {
    int  active;
    int  wid;
    int  parent_wid;   /* 0 = no parent, >0 = parent window id */
    int  is_modal;     /* 1 = modal mode active */
    id   nswindow;
    id   wkwebview;
} ChandraChildWin;

static ChandraChildWin _cwin_table[CHANDRA_MAX_CHILD_WINDOWS];
static int             _cwin_next_id = 1;
static int             _cwin_handler_class_ready = 0;

static ChandraChildWin *_cwin_find(int wid) {
    int i;
    for (i = 0; i < CHANDRA_MAX_CHILD_WINDOWS; i++)
        if (_cwin_table[i].active && _cwin_table[i].wid == wid)
            return &_cwin_table[i];
    return NULL;
}

static ChandraChildWin *_cwin_alloc(void) {
    int i;
    for (i = 0; i < CHANDRA_MAX_CHILD_WINDOWS; i++) {
        if (!_cwin_table[i].active) {
            memset(&_cwin_table[i], 0, sizeof(ChandraChildWin));
            _cwin_table[i].active = 1;
            _cwin_table[i].wid    = _cwin_next_id++;
            return &_cwin_table[i];
        }
    }
    return NULL;
}

/* ---- Script message handler IMP ----------------------------------------- */
/* Routes child-window JS messages to the same perl_callback as the main     */
/* window (the global Chandra::_xs_dispatch coderef).                        */

static void
_cwin_did_receive_message(id self, SEL cmd, id controller, id message)
{
    (void)self; (void)cmd; (void)controller;
    id body = ((id(*)(id, SEL))objc_msgSend)(
        message, sel_registerName("body"));
    const char *utf8 = ((const char *(*)(id, SEL))objc_msgSend)(
        body, sel_registerName("UTF8String"));
    if (!utf8) return;

    if (perl_callback && SvOK(perl_callback)) {
        dTHX;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(utf8, 0)));
        PUTBACK;
        call_sv(perl_callback, G_DISCARD);
        FREETMPS; LEAVE;
    }
}

/* Register "__ChandraWinHandler" ObjC class once; reuse across all windows */
static void
_cwin_ensure_handler_class(void)
{
    if (_cwin_handler_class_ready) return;
    if (objc_lookUpClass("__ChandraWinHandler")) {
        _cwin_handler_class_ready = 1;
        return;
    }
    Class cls = objc_allocateClassPair(
        objc_getClass("NSObject"), "__ChandraWinHandler", 0);
    if (cls) {
        class_addMethod(
            cls,
            sel_registerName(
                "userContentController:didReceiveScriptMessage:"),
            (IMP)_cwin_did_receive_message, "v@:@@");
        objc_registerClassPair(cls);
    }
    _cwin_handler_class_ready = 1;
}

/* ---- Window delegate to detect native close via X button ---------------- */
static int _cwin_delegate_class_ready = 0;

static void
_cwin_window_will_close(id self, SEL cmd, id notification)
{
    (void)cmd;
    id win = ((id(*)(id, SEL))objc_msgSend)(
        notification, sel_registerName("object"));
    
    /* Find and deactivate the window in our table */
    int i;
    for (i = 0; i < CHANDRA_MAX_CHILD_WINDOWS; i++) {
        if (_cwin_table[i].active && _cwin_table[i].nswindow == win) {
            _cwin_table[i].active = 0;
            _cwin_table[i].nswindow = (id)0;
            _cwin_table[i].wkwebview = (id)0;
            break;
        }
    }
}

static void
_cwin_ensure_delegate_class(void)
{
    if (_cwin_delegate_class_ready) return;
    if (objc_lookUpClass("__ChandraWinDelegate")) {
        _cwin_delegate_class_ready = 1;
        return;
    }
    Class cls = objc_allocateClassPair(
        objc_getClass("NSObject"), "__ChandraWinDelegate", 0);
    if (cls) {
        class_addMethod(
            cls,
            sel_registerName("windowWillClose:"),
            (IMP)_cwin_window_will_close, "v@:@");
        objc_registerClassPair(cls);
    }
    _cwin_delegate_class_ready = 1;
}

/* ---- Build an NSString from a C string ------------------------------------ */
static id _cwin_nsstr(const char *s) {
    return ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"), s);
}

/* ---- Public C API --------------------------------------------------------- */

static int
cwin_create(const char *title, int width, int height,
            int x, int y, int resizable, int frameless)
{
    ChandraChildWin *cw = _cwin_alloc();
    if (!cw) return -1;

    _cwin_ensure_handler_class();

    /* Script message handler instance */
    id handler = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("__ChandraWinHandler"),
        sel_registerName("new"));

    /* WKUserContentController */
    id uc = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("WKUserContentController"),
        sel_registerName("new"));
    ((void(*)(id, SEL, id, id))objc_msgSend)(
        uc, sel_registerName("addScriptMessageHandler:name:"),
        handler, _cwin_nsstr("invoke"));

    /* Inject window.external.invoke → webkit bridge shim */
    {
        const char *shim =
            "window.external = this;"
            "invoke = function(arg){"
            "  webkit.messageHandlers.invoke.postMessage(arg);"
            "};";
        id script = ((id(*)(id, SEL))objc_msgSend)(
            (id)objc_getClass("WKUserScript"),
            sel_registerName("alloc"));
        ((void(*)(id, SEL, id, int, int))objc_msgSend)(
            script,
            sel_registerName("initWithSource:injectionTime:forMainFrameOnly:"),
            _cwin_nsstr(shim),
            WKUserScriptInjectionTimeAtDocumentStart, 0);
        ((void(*)(id, SEL, id))objc_msgSend)(
            uc, sel_registerName("addUserScript:"), script);
    }

    /* Inject the window.chandra promise bridge */
    {
        id script = ((id(*)(id, SEL))objc_msgSend)(
            (id)objc_getClass("WKUserScript"),
            sel_registerName("alloc"));
        ((void(*)(id, SEL, id, int, int))objc_msgSend)(
            script,
            sel_registerName("initWithSource:injectionTime:forMainFrameOnly:"),
            _cwin_nsstr(CHANDRA_BRIDGE_JS),
            WKUserScriptInjectionTimeAtDocumentStart, 0);
        ((void(*)(id, SEL, id))objc_msgSend)(
            uc, sel_registerName("addUserScript:"), script);
    }

    /* WKWebViewConfiguration */
    id config = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("WKWebViewConfiguration"),
        sel_registerName("new"));
    ((void(*)(id, SEL, id))objc_msgSend)(
        config, sel_registerName("setUserContentController:"), uc);

    CGRect r = CGRectMake(0, 0, width, height);

    /* WKWebView */
    id wv = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("WKWebView"), sel_registerName("alloc"));
    ((void(*)(id, SEL, CGRect, id))objc_msgSend)(
        wv, sel_registerName("initWithFrame:configuration:"), r, config);

    /* NSWindow */
    unsigned int mask = NSWindowStyleMaskTitled
                      | NSWindowStyleMaskClosable
                      | NSWindowStyleMaskMiniaturizable;
    if (!frameless && resizable) mask |= NSWindowStyleMaskResizable;
    if (frameless) mask = 0;

    CGRect wr = CGRectMake(
        (x >= 0 ? x : 0), (y >= 0 ? y : 0), width, height);

    id win = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSWindow"), sel_registerName("alloc"));
    ((void(*)(id, SEL, CGRect, unsigned int, int, int))objc_msgSend)(
        win,
        sel_registerName("initWithContentRect:styleMask:backing:defer:"),
        wr, mask, NSBackingStoreBuffered, 0);

    ((void(*)(id, SEL, id))objc_msgSend)(
        win, sel_registerName("setTitle:"), _cwin_nsstr(title));
    ((void(*)(id, SEL, id))objc_msgSend)(
        win, sel_registerName("setContentView:"), wv);

    /* Set window delegate to detect native close */
    _cwin_ensure_delegate_class();
    id delegate = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("__ChandraWinDelegate"),
        sel_registerName("new"));
    ((void(*)(id, SEL, id))objc_msgSend)(
        win, sel_registerName("setDelegate:"), delegate);

    if (x < 0 || y < 0)
        ((void(*)(id, SEL))objc_msgSend)(win, sel_registerName("center"));

    ((void(*)(id, SEL, id))objc_msgSend)(
        win, sel_registerName("makeKeyAndOrderFront:"), win);

    cw->nswindow  = win;
    cw->wkwebview = wv;
    return cw->wid;
}

static void
cwin_destroy(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("orderOut:"), cw->nswindow);
    ((void(*)(id, SEL))objc_msgSend)(
        cw->nswindow, sel_registerName("close"));
    cw->active    = 0;
    cw->nswindow  = (id)0;
    cw->wkwebview = (id)0;
}

static void
cwin_set_html(int wid, const char *html)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    id base = ((id(*)(id, SEL, id))objc_msgSend)(
        (id)objc_getClass("NSURL"),
        sel_registerName("URLWithString:"),
        _cwin_nsstr("about:blank"));
    ((void(*)(id, SEL, id, id))objc_msgSend)(
        cw->wkwebview,
        sel_registerName("loadHTMLString:baseURL:"),
        _cwin_nsstr(html), base);
}

static void
cwin_eval_js(int wid, const char *js)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id, id))objc_msgSend)(
        cw->wkwebview,
        sel_registerName("evaluateJavaScript:completionHandler:"),
        _cwin_nsstr(js), (id)0);
}

static void
cwin_set_title(int wid, const char *title)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("setTitle:"), _cwin_nsstr(title));
}

static void
cwin_set_size(int wid, int w, int h)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    CGSize sz;
    sz.width  = (CGFloat)w;
    sz.height = (CGFloat)h;
    ((void(*)(id, SEL, CGSize))objc_msgSend)(
        cw->nswindow, sel_registerName("setContentSize:"), sz);
}

static void
cwin_set_position(int wid, int x, int y)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    CGPoint pt;
    pt.x = (CGFloat)x;
    pt.y = (CGFloat)y;
    ((void(*)(id, SEL, CGPoint))objc_msgSend)(
        cw->nswindow, sel_registerName("setFrameOrigin:"), pt);
}

static void
cwin_show(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("makeKeyAndOrderFront:"), cw->nswindow);
}

static void
cwin_hide(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("orderOut:"), cw->nswindow);
}

static void
cwin_focus(int wid)
{
    cwin_show(wid);  /* makeKeyAndOrderFront brings to front and focuses */
}

static void
cwin_minimize(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("miniaturize:"), cw->nswindow);
}

static void
cwin_maximize(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("zoom:"), cw->nswindow);
}

static void
cwin_navigate(int wid, const char *url)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    id nsurl = ((id(*)(id, SEL, id))objc_msgSend)(
        (id)objc_getClass("NSURL"),
        sel_registerName("URLWithString:"), _cwin_nsstr(url));
    id req = ((id(*)(id, SEL, id))objc_msgSend)(
        (id)objc_getClass("NSURLRequest"),
        sel_registerName("requestWithURL:"), nsurl);
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->wkwebview, sel_registerName("loadRequest:"), req);
}

/* ---- Modal window support ------------------------------------------------ */
/* Makes a child window modal relative to a parent window.                    */
/* On macOS: sets window level to floating and ignores events on parent.      */

static void
cwin_set_modal(int wid, int parent_wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    ChandraChildWin *parent = parent_wid > 0 ? _cwin_find(parent_wid) : NULL;
    if (!cw) return;

    cw->parent_wid = parent_wid;
    cw->is_modal = 1;

    /* Set window level to modal panel (floats above normal windows) */
    /* NSModalPanelWindowLevel = 8 */
    ((void(*)(id, SEL, long))objc_msgSend)(
        cw->nswindow, sel_registerName("setLevel:"), 8);

    /* Disable parent window interaction if we have a parent */
    if (parent && parent->nswindow) {
        ((void(*)(id, SEL, int))objc_msgSend)(
            parent->nswindow, sel_registerName("setIgnoresMouseEvents:"), 1);
    }

    /* Make modal window key */
    ((void(*)(id, SEL, id))objc_msgSend)(
        cw->nswindow, sel_registerName("makeKeyAndOrderFront:"), cw->nswindow);
}

static void
cwin_end_modal(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->is_modal) return;

    ChandraChildWin *parent = cw->parent_wid > 0 ? _cwin_find(cw->parent_wid) : NULL;

    /* Reset window level to normal (NSNormalWindowLevel = 0) */
    ((void(*)(id, SEL, long))objc_msgSend)(
        cw->nswindow, sel_registerName("setLevel:"), 0);

    /* Re-enable parent window interaction */
    if (parent && parent->nswindow) {
        ((void(*)(id, SEL, int))objc_msgSend)(
            parent->nswindow, sel_registerName("setIgnoresMouseEvents:"), 0);
        /* Bring parent back to front */
        ((void(*)(id, SEL, id))objc_msgSend)(
            parent->nswindow, sel_registerName("makeKeyAndOrderFront:"), parent->nswindow);
    }

    cw->is_modal = 0;
    cw->parent_wid = 0;
}

static int
cwin_is_modal(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    return cw ? cw->is_modal : 0;
}

static int
cwin_exists(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->active) return 0;
    /* Check if the NSWindow is still visible/valid */
    int visible = (int)((long)((id(*)(id, SEL))objc_msgSend)(
        cw->nswindow, sel_registerName("isVisible")));
    return visible;
}

#else  /* ============================================================ stubs */

static int  cwin_create(const char *t, int w, int h, int x, int y,
                        int r, int f) {
    (void)t;(void)w;(void)h;(void)x;(void)y;(void)r;(void)f; return -1; }
static void cwin_destroy(int wid)                       { (void)wid; }
static void cwin_set_html(int wid, const char *html)    { (void)wid;(void)html; }
static void cwin_eval_js(int wid, const char *js)       { (void)wid;(void)js; }
static void cwin_set_title(int wid, const char *title)  { (void)wid;(void)title; }
static void cwin_set_size(int wid, int w, int h)        { (void)wid;(void)w;(void)h; }
static void cwin_set_position(int wid, int x, int y)    { (void)wid;(void)x;(void)y; }
static void cwin_show(int wid)                          { (void)wid; }
static void cwin_hide(int wid)                          { (void)wid; }
static void cwin_focus(int wid)                         { (void)wid; }
static void cwin_minimize(int wid)                      { (void)wid; }
static void cwin_maximize(int wid)                      { (void)wid; }
static void cwin_navigate(int wid, const char *url)     { (void)wid;(void)url; }
static void cwin_set_modal(int wid, int parent_wid)     { (void)wid;(void)parent_wid; }
static void cwin_end_modal(int wid)                     { (void)wid; }
static int  cwin_is_modal(int wid)                      { (void)wid; return 0; }
static int  cwin_exists(int wid)                        { (void)wid; return 0; }

#endif  /* WEBVIEW_COCOA */
#endif  /* CHANDRA_WINDOW_IMPLEMENTATION */

#endif  /* CHANDRA_WINDOW_H */
