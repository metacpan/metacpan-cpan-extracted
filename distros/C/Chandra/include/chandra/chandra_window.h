/*
 * chandra_window.h — Child-window management for Chandra
 *
 * On macOS: creates real NSWindow + WKWebView instances that share the
 * existing NSApplication event loop.  Messages from child-window JS
 * are routed through the global perl_callback (same as the main window),
 * so all $app->bind() handlers work from any window.
 *
 * On Windows: creates Win32 HWND + OLE IWebBrowser2 child windows.
 *
 * On Linux: creates GtkWindow + WebKitWebView child windows.
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

    /* Bring the application to the foreground so the window is visible
       without requiring the user to click the dock icon. */
    ((void(*)(id, SEL, int))objc_msgSend)(
        ((id(*)(id, SEL))objc_msgSend)(
            (id)objc_getClass("NSApplication"),
            sel_registerName("sharedApplication")),
        sel_registerName("activateIgnoringOtherApps:"), 1);

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

#elif defined(WEBVIEW_WINAPI) /* ========================================= Win32 */

typedef struct {
    int   active;
    int   wid;
    int   parent_wid;
    int   is_modal;
    HWND  hwnd;
    IOleObject *browser;
} ChandraChildWin;

static ChandraChildWin _cwin_table[CHANDRA_MAX_CHILD_WINDOWS];
static int             _cwin_next_id = 1;
static int             _cwin_child_class_ready = 0;

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

/* ---- Child window procedure ---- */
/* Separate from main wndproc so WM_DESTROY doesn't PostQuitMessage.       */

static LRESULT CALLBACK _cwin_wndproc(HWND hwnd, UINT msg,
                                      WPARAM wParam, LPARAM lParam) {
    ChandraChildWin *cw = (ChandraChildWin *)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCT *cs = (CREATESTRUCT *)lParam;
        SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR)cs->lpCreateParams);
        return 0;
    }
    case WM_SIZE: {
        if (cw && cw->browser) {
            IOleInPlaceObject *ipo = NULL;
            cw->browser->lpVtbl->QueryInterface(
                cw->browser, &IID_IOleInPlaceObject, (void **)&ipo);
            if (ipo) {
                RECT rc;
                GetClientRect(hwnd, &rc);
                ipo->lpVtbl->SetObjectRects(ipo, &rc, &rc);
                ipo->lpVtbl->Release(ipo);
            }
        }
        return 0;
    }
    case WM_CLOSE:
        /* Deactivate in table, just destroy window — don't quit app */
        if (cw) {
            cw->active = 0;
            if (cw->browser) {
                cw->browser->lpVtbl->Close(cw->browser, OLECLOSE_NOSAVE);
                cw->browser->lpVtbl->Release(cw->browser);
                cw->browser = NULL;
            }
        }
        DestroyWindow(hwnd);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

static void _cwin_ensure_class(void) {
    if (_cwin_child_class_ready) return;
    WNDCLASSEX wc;
    HINSTANCE hInstance = GetModuleHandle(NULL);
    ZeroMemory(&wc, sizeof(WNDCLASSEX));
    wc.cbSize      = sizeof(WNDCLASSEX);
    wc.hInstance   = hInstance;
    wc.lpfnWndProc = _cwin_wndproc;
    wc.lpszClassName = "Chandra_ChildWin";
    wc.hIcon       = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor     = LoadCursor(NULL, IDC_ARROW);
    RegisterClassEx(&wc);
    _cwin_child_class_ready = 1;
}

/* Navigate helper (duplicated from webview-win32.c to avoid linkage issues) */
static void _cwin_navigate_ole(IOleObject *browser, const char *url) {
    IWebBrowser2 *wb = NULL;
    browser->lpVtbl->QueryInterface(browser, &IID_IWebBrowser2, (void **)&wb);
    if (wb) {
        int len = MultiByteToWideChar(CP_UTF8, 0, url, -1, NULL, 0);
        BSTR burl = SysAllocStringLen(NULL, len);
        if (burl) {
            MultiByteToWideChar(CP_UTF8, 0, url, -1, burl, len);
            VARIANT empty;
            VariantInit(&empty);
            wb->lpVtbl->Navigate(wb, burl, &empty, &empty, &empty, &empty);
            SysFreeString(burl);
        }
        wb->lpVtbl->Release(wb);
    }
}

/* Eval JS in child OLE browser */
static int _cwin_eval_ole(IOleObject *browser, const char *js) {
    IWebBrowser2 *wb = NULL;
    IDispatch *doc_disp = NULL;
    IHTMLDocument2 *doc = NULL;
    HRESULT hr;

    if (!browser) return -1;

    hr = browser->lpVtbl->QueryInterface(browser, &IID_IWebBrowser2, (void **)&wb);
    if (FAILED(hr) || !wb) return -1;

    hr = wb->lpVtbl->get_Document(wb, &doc_disp);
    if (FAILED(hr) || !doc_disp) { wb->lpVtbl->Release(wb); return -1; }

    hr = doc_disp->lpVtbl->QueryInterface(doc_disp, &IID_IHTMLDocument2, (void **)&doc);
    doc_disp->lpVtbl->Release(doc_disp);
    if (FAILED(hr) || !doc) { wb->lpVtbl->Release(wb); return -1; }

    IHTMLWindow2 *win = NULL;
    hr = doc->lpVtbl->get_parentWindow(doc, &win);
    if (SUCCEEDED(hr) && win) {
        int len = MultiByteToWideChar(CP_UTF8, 0, js, -1, NULL, 0);
        BSTR bjs = SysAllocStringLen(NULL, len);
        if (bjs) {
            MultiByteToWideChar(CP_UTF8, 0, js, -1, bjs, len);
            BSTR lang = SysAllocString(L"JavaScript");
            VARIANT ret;
            VariantInit(&ret);
            win->lpVtbl->execScript(win, bjs, lang, &ret);
            VariantClear(&ret);
            SysFreeString(lang);
            SysFreeString(bjs);
        }
        win->lpVtbl->Release(win);
    }
    doc->lpVtbl->Release(doc);
    wb->lpVtbl->Release(wb);
    return 0;
}

/* ---- Public C API --------------------------------------------------------- */

static int
cwin_create(const char *title, int width, int height,
            int x, int y, int resizable, int frameless)
{
    ChandraChildWin *cw = _cwin_alloc();
    if (!cw) return -1;

    _cwin_ensure_class();

    HINSTANCE hInstance = GetModuleHandle(NULL);
    DWORD style = WS_OVERLAPPEDWINDOW;
    if (!resizable)
        style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
    if (frameless)
        style = WS_POPUP | WS_VISIBLE;

    RECT rc = {0, 0, width, height};
    AdjustWindowRect(&rc, style, FALSE);

    cw->hwnd = CreateWindowEx(
        0, "Chandra_ChildWin",
        title ? title : "Window",
        style,
        (x >= 0 ? x : CW_USEDEFAULT),
        (y >= 0 ? y : CW_USEDEFAULT),
        rc.right - rc.left, rc.bottom - rc.top,
        NULL, NULL, hInstance, cw);

    if (!cw->hwnd) { cw->active = 0; return -1; }

    /* Embed OLE browser */
    IOleObject *ole = NULL;
    HRESULT hr = CoCreateInstance(&CLSID_WebBrowser, NULL,
        CLSCTX_INPROC_SERVER, &IID_IOleObject, (void **)&ole);
    if (FAILED(hr) || !ole) {
        DestroyWindow(cw->hwnd);
        cw->active = 0;
        return -1;
    }
    cw->browser = ole;

    WebviewSite *site = create_site(NULL, cw->hwnd);
    if (!site) {
        ole->lpVtbl->Release(ole);
        DestroyWindow(cw->hwnd);
        cw->active = 0;
        return -1;
    }

    ole->lpVtbl->SetClientSite(ole, &site->client_site);
    ole->lpVtbl->SetHostNames(ole, L"Chandra", L"Chandra");

    RECT rect;
    GetClientRect(cw->hwnd, &rect);
    OleSetContainedObject((IUnknown *)ole, TRUE);
    ole->lpVtbl->DoVerb(ole, OLEIVERB_INPLACEACTIVATE, NULL,
                         &site->client_site, 0, cw->hwnd, &rect);

    _cwin_navigate_ole(ole, "about:blank");

    ShowWindow(cw->hwnd, SW_SHOW);
    UpdateWindow(cw->hwnd);

    /* Inject the invoke bridge */
    {
        static const char *bridge_js =
            "window.external={invoke:function(s){"
            "var img=new Image();"
            "img.src='invoke://localhost/'+encodeURIComponent(s);"
            "}};";
        _cwin_eval_ole(ole, bridge_js);
    }

    return cw->wid;
}

static void
cwin_destroy(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    if (cw->browser) {
        cw->browser->lpVtbl->Close(cw->browser, OLECLOSE_NOSAVE);
        cw->browser->lpVtbl->Release(cw->browser);
        cw->browser = NULL;
    }
    if (cw->hwnd) {
        DestroyWindow(cw->hwnd);
        cw->hwnd = NULL;
    }
    cw->active = 0;
}

static void
cwin_set_html(int wid, const char *html)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->browser) return;
    /* Navigate to about:blank then write HTML via document.write */
    char *js;
    size_t html_len = strlen(html);
    /* Escape for JS string */
    size_t js_alloc = html_len * 6 + 128;
    js = (char *)malloc(js_alloc);
    if (!js) return;
    char *p = js;
    p += sprintf(p, "document.open();document.write('");
    const char *s;
    for (s = html; *s; s++) {
        if (*s == '\'') { *p++ = '\\'; *p++ = '\''; }
        else if (*s == '\\') { *p++ = '\\'; *p++ = '\\'; }
        else if (*s == '\n') { *p++ = '\\'; *p++ = 'n'; }
        else if (*s == '\r') { *p++ = '\\'; *p++ = 'r'; }
        else *p++ = *s;
    }
    p += sprintf(p, "');document.close();");
    *p = '\0';
    _cwin_eval_ole(cw->browser, js);
    free(js);
}

static void
cwin_eval_js(int wid, const char *js)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->browser) return;
    _cwin_eval_ole(cw->browser, js);
}

static void
cwin_set_title(int wid, const char *title)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    SetWindowTextA(cw->hwnd, title);
}

static void
cwin_set_size(int wid, int w, int h)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    RECT rc;
    GetWindowRect(cw->hwnd, &rc);
    MoveWindow(cw->hwnd, rc.left, rc.top, w, h, TRUE);
}

static void
cwin_set_position(int wid, int x, int y)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    RECT rc;
    GetWindowRect(cw->hwnd, &rc);
    int w = rc.right - rc.left;
    int h = rc.bottom - rc.top;
    MoveWindow(cw->hwnd, x, y, w, h, TRUE);
}

static void
cwin_show(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    ShowWindow(cw->hwnd, SW_SHOW);
}

static void
cwin_hide(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    ShowWindow(cw->hwnd, SW_HIDE);
}

static void
cwin_focus(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    SetForegroundWindow(cw->hwnd);
    SetFocus(cw->hwnd);
}

static void
cwin_minimize(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    ShowWindow(cw->hwnd, SW_MINIMIZE);
}

static void
cwin_maximize(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->hwnd) return;
    ShowWindow(cw->hwnd, SW_MAXIMIZE);
}

static void
cwin_navigate(int wid, const char *url)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->browser) return;
    _cwin_navigate_ole(cw->browser, url);
}

static void
cwin_set_modal(int wid, int parent_wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    cw->parent_wid = parent_wid;
    cw->is_modal = 1;

    /* Set as topmost */
    SetWindowPos(cw->hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE);

    /* Disable parent if found */
    ChandraChildWin *parent = parent_wid > 0 ? _cwin_find(parent_wid) : NULL;
    if (parent && parent->hwnd)
        EnableWindow(parent->hwnd, FALSE);
}

static void
cwin_end_modal(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->is_modal) return;

    SetWindowPos(cw->hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE);

    ChandraChildWin *parent = cw->parent_wid > 0 ? _cwin_find(cw->parent_wid) : NULL;
    if (parent && parent->hwnd) {
        EnableWindow(parent->hwnd, TRUE);
        SetForegroundWindow(parent->hwnd);
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
    return IsWindow(cw->hwnd) && IsWindowVisible(cw->hwnd);
}

#elif defined(WEBVIEW_GTK) /* ============================================ GTK */

typedef struct {
    int         active;
    int         wid;
    int         parent_wid;
    int         is_modal;
    GtkWidget  *window;
    GtkWidget  *webview;
    GtkWidget  *scroller;
} ChandraChildWin;

static ChandraChildWin _cwin_table[CHANDRA_MAX_CHILD_WINDOWS];
static int             _cwin_next_id = 1;

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

/* ---- GTK signal: script message from child webview ---- */
static void
_cwin_gtk_message_cb(WebKitUserContentManager *m,
                     WebKitJavascriptResult *r,
                     gpointer arg)
{
    (void)m; (void)arg;
    if (!perl_callback || !SvOK(perl_callback)) return;

#if WEBKIT_MAJOR_VERSION >= 2 && WEBKIT_MINOR_VERSION >= 22
    JSCValue *value = webkit_javascript_result_get_js_value(r);
    char *s = jsc_value_to_string(value);
#else
    JSGlobalContextRef context = webkit_javascript_result_get_global_context(r);
    JSValueRef value = webkit_javascript_result_get_value(r);
    JSStringRef js = JSValueToStringCopy(context, value, NULL);
    size_t n = JSStringGetMaximumUTF8CStringSize(js);
    char *s = g_new(char, n);
    JSStringGetUTF8CString(js, s, n);
    JSStringRelease(js);
#endif

    {
        dTHX;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(s, 0)));
        PUTBACK;
        call_sv(perl_callback, G_DISCARD);
        FREETMPS; LEAVE;
    }
    g_free(s);
}

/* ---- GTK signal: child window destroyed by user ---- */
static void
_cwin_gtk_destroy_cb(GtkWidget *widget, gpointer arg)
{
    (void)widget;
    int wid = GPOINTER_TO_INT(arg);
    ChandraChildWin *cw = _cwin_find(wid);
    if (cw) {
        cw->active  = 0;
        cw->window  = NULL;
        cw->webview = NULL;
        cw->scroller = NULL;
    }
}

/* ---- Public C API --------------------------------------------------------- */

static int
cwin_create(const char *title, int width, int height,
            int x, int y, int resizable, int frameless)
{
    ChandraChildWin *cw = _cwin_alloc();
    if (!cw) return -1;

    cw->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(cw->window), title ? title : "Window");

    if (resizable) {
        gtk_window_set_default_size(GTK_WINDOW(cw->window), width, height);
    } else {
        gtk_widget_set_size_request(cw->window, width, height);
    }
    gtk_window_set_resizable(GTK_WINDOW(cw->window), !!resizable);

    if (frameless)
        gtk_window_set_decorated(GTK_WINDOW(cw->window), FALSE);

    if (x >= 0 && y >= 0)
        gtk_window_move(GTK_WINDOW(cw->window), x, y);
    else
        gtk_window_set_position(GTK_WINDOW(cw->window), GTK_WIN_POS_CENTER);

    cw->scroller = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(cw->window), cw->scroller);

    /* WebKit with user content manager for JS bridge */
    WebKitUserContentManager *ucm = webkit_user_content_manager_new();
    webkit_user_content_manager_register_script_message_handler(ucm, "external");
    g_signal_connect(ucm, "script-message-received::external",
                     G_CALLBACK(_cwin_gtk_message_cb),
                     GINT_TO_POINTER(cw->wid));

    cw->webview = webkit_web_view_new_with_user_content_manager(ucm);
    gtk_container_add(GTK_CONTAINER(cw->scroller), cw->webview);

    /* Inject window.external.invoke bridge */
    {
        const char *bridge =
            "window.external={invoke:function(x){"
            "window.webkit.messageHandlers.external.postMessage(x);"
            "}};";
        WebKitUserScript *us = webkit_user_script_new(
            bridge,
            WEBKIT_USER_CONTENT_INJECT_ALL_FRAMES,
            WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START,
            NULL, NULL);
        webkit_user_content_manager_add_script(ucm, us);
        webkit_user_script_unref(us);
    }

    /* Inject the Chandra promise bridge */
    {
        WebKitUserScript *us = webkit_user_script_new(
            CHANDRA_BRIDGE_JS,
            WEBKIT_USER_CONTENT_INJECT_ALL_FRAMES,
            WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START,
            NULL, NULL);
        webkit_user_content_manager_add_script(ucm, us);
        webkit_user_script_unref(us);
    }

    g_signal_connect(G_OBJECT(cw->window), "destroy",
                     G_CALLBACK(_cwin_gtk_destroy_cb),
                     GINT_TO_POINTER(cw->wid));

    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(cw->webview), "about:blank");
    gtk_widget_show_all(cw->window);

    return cw->wid;
}

static void
cwin_destroy(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw) return;
    if (cw->window) {
        gtk_widget_destroy(cw->window);
        cw->window = NULL;
        cw->webview = NULL;
        cw->scroller = NULL;
    }
    cw->active = 0;
}

static void
cwin_set_html(int wid, const char *html)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->webview) return;
    webkit_web_view_load_html(WEBKIT_WEB_VIEW(cw->webview), html, "about:blank");
}

static void
cwin_eval_js(int wid, const char *js)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->webview) return;
    webkit_web_view_run_javascript(WEBKIT_WEB_VIEW(cw->webview),
                                   js, NULL, NULL, NULL);
}

static void
cwin_set_title(int wid, const char *title)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_window_set_title(GTK_WINDOW(cw->window), title);
}

static void
cwin_set_size(int wid, int w, int h)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_window_resize(GTK_WINDOW(cw->window), w, h);
}

static void
cwin_set_position(int wid, int x, int y)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_window_move(GTK_WINDOW(cw->window), x, y);
}

static void
cwin_show(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_widget_show_all(cw->window);
}

static void
cwin_hide(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_widget_hide(cw->window);
}

static void
cwin_focus(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_window_present(GTK_WINDOW(cw->window));
}

static void
cwin_minimize(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_window_iconify(GTK_WINDOW(cw->window));
}

static void
cwin_maximize(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    gtk_window_maximize(GTK_WINDOW(cw->window));
}

static void
cwin_navigate(int wid, const char *url)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->webview) return;
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(cw->webview), url);
}

static void
cwin_set_modal(int wid, int parent_wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->window) return;
    cw->parent_wid = parent_wid;
    cw->is_modal = 1;

    gtk_window_set_modal(GTK_WINDOW(cw->window), TRUE);
    gtk_window_set_keep_above(GTK_WINDOW(cw->window), TRUE);

    ChandraChildWin *parent = parent_wid > 0 ? _cwin_find(parent_wid) : NULL;
    if (parent && parent->window)
        gtk_window_set_transient_for(GTK_WINDOW(cw->window),
                                     GTK_WINDOW(parent->window));
}

static void
cwin_end_modal(int wid)
{
    ChandraChildWin *cw = _cwin_find(wid);
    if (!cw || !cw->is_modal || !cw->window) return;

    gtk_window_set_modal(GTK_WINDOW(cw->window), FALSE);
    gtk_window_set_keep_above(GTK_WINDOW(cw->window), FALSE);
    gtk_window_set_transient_for(GTK_WINDOW(cw->window), NULL);

    ChandraChildWin *parent = cw->parent_wid > 0 ? _cwin_find(cw->parent_wid) : NULL;
    if (parent && parent->window)
        gtk_window_present(GTK_WINDOW(parent->window));

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
    if (!cw || !cw->active || !cw->window) return 0;
    return gtk_widget_get_visible(cw->window);
}

#else  /* ============================================== fallback stubs */

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

#endif  /* platform selection */
#endif  /* CHANDRA_WINDOW_IMPLEMENTATION */

#endif  /* CHANDRA_WINDOW_H */
