/*
 * webview-win32.c — Windows backend for webview.h
 *
 * Uses MSHTML (Internet Explorer) COM embedding via OLE.
 * Included by webview.h when WEBVIEW_WINAPI is defined.
 *
 * Required link libraries: ole32, oleaut32, uuid, comctl32, gdi32
 */

#include <stdio.h>
#include <shlobj.h>
#include <commdlg.h>   /* OPENFILENAMEA, GetOpenFileNameA, GetSaveFileNameA */
#include <shellapi.h>  /* NOTIFYICONDATAA, Shell_NotifyIconA */

/* ---- OLE / IWebBrowser2 helpers ---- */

/* CLSID_WebBrowser and IID_IWebBrowser2 */
DEFINE_GUID(CLSID_WebBrowser, 0x8856F961, 0x340A, 0x11D0, 0xA9, 0x6B,
            0x00, 0xC0, 0x4F, 0xD7, 0x05, 0xA2);
DEFINE_GUID(IID_IWebBrowser2, 0xD30C1661, 0xCDAF, 0x11D0, 0x8A, 0x3E,
            0x00, 0xC0, 0x4F, 0xC9, 0xE2, 0x6E);
DEFINE_GUID(IID_IOleObject, 0x00000112, 0x0000, 0x0000, 0xC0, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
DEFINE_GUID(IID_IOleInPlaceObject, 0x00000113, 0x0000, 0x0000, 0xC0, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

/* ---- Minimal IOleClientSite / IOleInPlaceSite / IDocHostUIHandler ---- */

typedef struct {
  IOleClientSite client_site;
  IOleInPlaceSite inplace_site;
  IOleInPlaceFrame inplace_frame;
  IDocHostUIHandler ui_handler;
  LONG ref;
  struct webview *webview;
  HWND hwnd;
} WebviewSite;

/* Forward declarations */
static HRESULT STDMETHODCALLTYPE site_QueryInterface(IOleClientSite *, REFIID, void **);
static ULONG STDMETHODCALLTYPE site_AddRef(IOleClientSite *);
static ULONG STDMETHODCALLTYPE site_Release(IOleClientSite *);
static WebviewSite *create_site(struct webview *w, HWND hwnd);

/* ---- IOleClientSite ---- */

static HRESULT STDMETHODCALLTYPE site_SaveObject(IOleClientSite *This) {
  (void)This; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE site_GetMoniker(IOleClientSite *This, DWORD a, DWORD b, IMoniker **c) {
  (void)This; (void)a; (void)b; (void)c; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE site_GetContainer(IOleClientSite *This, IOleContainer **c) {
  (void)This; *c = NULL; return E_NOINTERFACE;
}
static HRESULT STDMETHODCALLTYPE site_ShowObject(IOleClientSite *This) {
  (void)This; return S_OK;
}
static HRESULT STDMETHODCALLTYPE site_OnShowWindow(IOleClientSite *This, BOOL f) {
  (void)This; (void)f; return S_OK;
}
static HRESULT STDMETHODCALLTYPE site_RequestNewObjectLayout(IOleClientSite *This) {
  (void)This; return E_NOTIMPL;
}

static IOleClientSiteVtbl client_site_vtbl = {
  site_QueryInterface, site_AddRef, site_Release,
  site_SaveObject, site_GetMoniker, site_GetContainer,
  site_ShowObject, site_OnShowWindow, site_RequestNewObjectLayout
};

/* ---- IOleInPlaceSite ---- */

static HRESULT STDMETHODCALLTYPE ips_QueryInterface(IOleInPlaceSite *This, REFIID riid, void **ppv) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, inplace_site));
  return site_QueryInterface(&s->client_site, riid, ppv);
}
static ULONG STDMETHODCALLTYPE ips_AddRef(IOleInPlaceSite *This) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, inplace_site));
  return site_AddRef(&s->client_site);
}
static ULONG STDMETHODCALLTYPE ips_Release(IOleInPlaceSite *This) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, inplace_site));
  return site_Release(&s->client_site);
}
static HRESULT STDMETHODCALLTYPE ips_GetWindow(IOleInPlaceSite *This, HWND *phwnd) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, inplace_site));
  *phwnd = s->hwnd;
  return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_ContextSensitiveHelp(IOleInPlaceSite *This, BOOL f) {
  (void)This; (void)f; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ips_CanInPlaceActivate(IOleInPlaceSite *This) {
  (void)This; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_OnInPlaceActivate(IOleInPlaceSite *This) {
  (void)This; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_OnUIActivate(IOleInPlaceSite *This) {
  (void)This; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_GetWindowContext(IOleInPlaceSite *This,
    IOleInPlaceFrame **ppFrame, IOleInPlaceUIWindow **ppDoc,
    LPRECT lprcPosRect, LPRECT lprcClipRect,
    LPOLEINPLACEFRAMEINFO lpFrameInfo) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, inplace_site));
  *ppFrame = &s->inplace_frame;
  *ppDoc = NULL;
  GetClientRect(s->hwnd, lprcPosRect);
  GetClientRect(s->hwnd, lprcClipRect);
  lpFrameInfo->fMDIApp = FALSE;
  lpFrameInfo->hwndFrame = s->hwnd;
  lpFrameInfo->haccel = NULL;
  lpFrameInfo->cAccelEntries = 0;
  return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_Scroll(IOleInPlaceSite *This, SIZE s) {
  (void)This; (void)s; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ips_OnUIDeactivate(IOleInPlaceSite *This, BOOL f) {
  (void)This; (void)f; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_OnInPlaceDeactivate(IOleInPlaceSite *This) {
  (void)This; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ips_DiscardUndoState(IOleInPlaceSite *This) {
  (void)This; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ips_DeactivateAndUndo(IOleInPlaceSite *This) {
  (void)This; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ips_OnPosRectChange(IOleInPlaceSite *This, LPCRECT lprcPosRect) {
  (void)This; (void)lprcPosRect; return S_OK;
}

static IOleInPlaceSiteVtbl inplace_site_vtbl = {
  ips_QueryInterface, ips_AddRef, ips_Release,
  (HRESULT(STDMETHODCALLTYPE *)(IOleInPlaceSite *, HWND *))ips_GetWindow,
  ips_ContextSensitiveHelp,
  ips_CanInPlaceActivate, ips_OnInPlaceActivate, ips_OnUIActivate,
  ips_GetWindowContext, ips_Scroll, ips_OnUIDeactivate,
  ips_OnInPlaceDeactivate, ips_DiscardUndoState, ips_DeactivateAndUndo,
  ips_OnPosRectChange
};

/* ---- IOleInPlaceFrame (minimal) ---- */

static HRESULT STDMETHODCALLTYPE ipf_QueryInterface(IOleInPlaceFrame *This, REFIID riid, void **ppv) {
  (void)This; (void)riid; *ppv = NULL; return E_NOINTERFACE;
}
static ULONG STDMETHODCALLTYPE ipf_AddRef(IOleInPlaceFrame *This) { (void)This; return 1; }
static ULONG STDMETHODCALLTYPE ipf_Release(IOleInPlaceFrame *This) { (void)This; return 1; }
static HRESULT STDMETHODCALLTYPE ipf_GetWindow(IOleInPlaceFrame *This, HWND *phwnd) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, inplace_frame));
  *phwnd = s->hwnd;
  return S_OK;
}
static HRESULT STDMETHODCALLTYPE ipf_ContextSensitiveHelp(IOleInPlaceFrame *This, BOOL f) {
  (void)This; (void)f; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ipf_GetBorder(IOleInPlaceFrame *This, LPRECT r) {
  (void)This; (void)r; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ipf_RequestBorderSpace(IOleInPlaceFrame *This, LPCBORDERWIDTHS b) {
  (void)This; (void)b; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ipf_SetBorderSpace(IOleInPlaceFrame *This, LPCBORDERWIDTHS b) {
  (void)This; (void)b; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ipf_SetActiveObject(IOleInPlaceFrame *This, IOleInPlaceActiveObject *a, LPCOLESTR s) {
  (void)This; (void)a; (void)s; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ipf_InsertMenus(IOleInPlaceFrame *This, HMENU h, LPOLEMENUGROUPWIDTHS m) {
  (void)This; (void)h; (void)m; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ipf_SetMenu(IOleInPlaceFrame *This, HMENU a, HOLEMENU b, HWND c) {
  (void)This; (void)a; (void)b; (void)c; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ipf_RemoveMenus(IOleInPlaceFrame *This, HMENU h) {
  (void)This; (void)h; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE ipf_SetStatusText(IOleInPlaceFrame *This, LPCOLESTR s) {
  (void)This; (void)s; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ipf_EnableModeless(IOleInPlaceFrame *This, BOOL f) {
  (void)This; (void)f; return S_OK;
}
static HRESULT STDMETHODCALLTYPE ipf_TranslateAccelerator(IOleInPlaceFrame *This, LPMSG m, WORD w) {
  (void)This; (void)m; (void)w; return E_NOTIMPL;
}

static IOleInPlaceFrameVtbl inplace_frame_vtbl = {
  ipf_QueryInterface, ipf_AddRef, ipf_Release,
  (HRESULT(STDMETHODCALLTYPE *)(IOleInPlaceFrame *, HWND *))ipf_GetWindow,
  ipf_ContextSensitiveHelp,
  ipf_GetBorder, ipf_RequestBorderSpace, ipf_SetBorderSpace,
  ipf_SetActiveObject, ipf_InsertMenus, ipf_SetMenu, ipf_RemoveMenus,
  ipf_SetStatusText, ipf_EnableModeless, ipf_TranslateAccelerator
};

/* ---- IDocHostUIHandler ---- */

static HRESULT STDMETHODCALLTYPE uih_QueryInterface(IDocHostUIHandler *This, REFIID riid, void **ppv) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, ui_handler));
  return site_QueryInterface(&s->client_site, riid, ppv);
}
static ULONG STDMETHODCALLTYPE uih_AddRef(IDocHostUIHandler *This) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, ui_handler));
  return site_AddRef(&s->client_site);
}
static ULONG STDMETHODCALLTYPE uih_Release(IDocHostUIHandler *This) {
  WebviewSite *s = (WebviewSite *)((char *)This - offsetof(WebviewSite, ui_handler));
  return site_Release(&s->client_site);
}
static HRESULT STDMETHODCALLTYPE uih_ShowContextMenu(IDocHostUIHandler *This, DWORD id,
    POINT *pt, IUnknown *pcmdtReserved, IDispatch *pdispReserved) {
  (void)This; (void)id; (void)pt; (void)pcmdtReserved; (void)pdispReserved;
  return S_OK; /* Suppress default context menu */
}
static HRESULT STDMETHODCALLTYPE uih_GetHostInfo(IDocHostUIHandler *This, DOCHOSTUIINFO *pInfo) {
  (void)This;
  pInfo->cbSize = sizeof(DOCHOSTUIINFO);
  pInfo->dwFlags = DOCHOSTUIFLAG_NO3DBORDER;
  pInfo->dwDoubleClick = DOCHOSTUIDBLCLK_DEFAULT;
  return S_OK;
}
static HRESULT STDMETHODCALLTYPE uih_ShowUI(IDocHostUIHandler *This, DWORD id,
    IOleInPlaceActiveObject *a, IOleCommandTarget *b, IOleInPlaceFrame *c, IOleInPlaceUIWindow *d) {
  (void)This; (void)id; (void)a; (void)b; (void)c; (void)d; return S_OK;
}
static HRESULT STDMETHODCALLTYPE uih_HideUI(IDocHostUIHandler *This) { (void)This; return S_OK; }
static HRESULT STDMETHODCALLTYPE uih_UpdateUI(IDocHostUIHandler *This) { (void)This; return S_OK; }
static HRESULT STDMETHODCALLTYPE uih_EnableModeless(IDocHostUIHandler *This, BOOL f) { (void)This; (void)f; return S_OK; }
static HRESULT STDMETHODCALLTYPE uih_OnDocWindowActivate(IDocHostUIHandler *This, BOOL f) { (void)This; (void)f; return S_OK; }
static HRESULT STDMETHODCALLTYPE uih_OnFrameWindowActivate(IDocHostUIHandler *This, BOOL f) { (void)This; (void)f; return S_OK; }
static HRESULT STDMETHODCALLTYPE uih_ResizeBorder(IDocHostUIHandler *This, LPCRECT r, IOleInPlaceUIWindow *w, BOOL f) {
  (void)This; (void)r; (void)w; (void)f; return S_OK;
}
static HRESULT STDMETHODCALLTYPE uih_TranslateAccelerator(IDocHostUIHandler *This, LPMSG m, const GUID *g, DWORD d) {
  (void)This; (void)m; (void)g; (void)d; return S_FALSE;
}
static HRESULT STDMETHODCALLTYPE uih_GetOptionKeyPath(IDocHostUIHandler *This, LPOLESTR *p, DWORD d) {
  (void)This; (void)p; (void)d; return S_FALSE;
}
static HRESULT STDMETHODCALLTYPE uih_GetDropTarget(IDocHostUIHandler *This, IDropTarget *dt, IDropTarget **pdt) {
  (void)This; (void)dt; (void)pdt; return E_NOTIMPL;
}
static HRESULT STDMETHODCALLTYPE uih_GetExternal(IDocHostUIHandler *This, IDispatch **ppDispatch) {
  (void)This; *ppDispatch = NULL; return S_FALSE;
}
static HRESULT STDMETHODCALLTYPE uih_TranslateUrl(IDocHostUIHandler *This, DWORD f, OLECHAR *url, OLECHAR **purl) {
  (void)This; (void)f; (void)url; (void)purl; return S_FALSE;
}
static HRESULT STDMETHODCALLTYPE uih_FilterDataObject(IDocHostUIHandler *This, IDataObject *d, IDataObject **pd) {
  (void)This; (void)d; (void)pd; return S_FALSE;
}

static IDocHostUIHandlerVtbl ui_handler_vtbl = {
  uih_QueryInterface, uih_AddRef, uih_Release,
  uih_ShowContextMenu, uih_GetHostInfo, uih_ShowUI,
  uih_HideUI, uih_UpdateUI, uih_EnableModeless,
  uih_OnDocWindowActivate, uih_OnFrameWindowActivate,
  uih_ResizeBorder, uih_TranslateAccelerator,
  uih_GetOptionKeyPath, uih_GetDropTarget,
  uih_GetExternal, uih_TranslateUrl, uih_FilterDataObject
};

/* ---- QueryInterface / AddRef / Release ---- */

static HRESULT STDMETHODCALLTYPE site_QueryInterface(IOleClientSite *This, REFIID riid, void **ppv) {
  WebviewSite *s = (WebviewSite *)This;
  *ppv = NULL;
  if (IsEqualIID(riid, &IID_IUnknown) || IsEqualIID(riid, &IID_IOleClientSite)) {
    *ppv = &s->client_site;
  } else if (IsEqualIID(riid, &IID_IOleInPlaceSite)) {
    *ppv = &s->inplace_site;
  } else if (IsEqualIID(riid, &IID_IDocHostUIHandler)) {
    *ppv = &s->ui_handler;
  } else {
    return E_NOINTERFACE;
  }
  site_AddRef(This);
  return S_OK;
}

static ULONG STDMETHODCALLTYPE site_AddRef(IOleClientSite *This) {
  WebviewSite *s = (WebviewSite *)This;
  return InterlockedIncrement(&s->ref);
}

static ULONG STDMETHODCALLTYPE site_Release(IOleClientSite *This) {
  WebviewSite *s = (WebviewSite *)This;
  LONG ref = InterlockedDecrement(&s->ref);
  if (ref == 0) {
    GlobalFree(s);
  }
  return ref;
}

static WebviewSite *create_site(struct webview *w, HWND hwnd) {
  WebviewSite *s = (WebviewSite *)GlobalAlloc(GPTR, sizeof(WebviewSite));
  if (!s) return NULL;
  s->client_site.lpVtbl = &client_site_vtbl;
  s->inplace_site.lpVtbl = &inplace_site_vtbl;
  s->inplace_frame.lpVtbl = &inplace_frame_vtbl;
  s->ui_handler.lpVtbl = &ui_handler_vtbl;
  s->ref = 1;
  s->webview = w;
  s->hwnd = hwnd;
  return s;
}

/* ---- Navigate helper ---- */

static void navigate(IOleObject *browser, const char *url) {
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

/* ---- Window procedure ---- */

static LRESULT CALLBACK webview_wndproc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  struct webview *w = (struct webview *)GetWindowLongPtr(hwnd, GWLP_USERDATA);
  switch (msg) {
  case WM_CREATE: {
    CREATESTRUCT *cs = (CREATESTRUCT *)lParam;
    w = (struct webview *)cs->lpCreateParams;
    SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR)w);
    return 0;
  }
  case WM_SIZE: {
    if (w && w->priv.browser) {
      IOleInPlaceObject *ipo = NULL;
      w->priv.browser->lpVtbl->QueryInterface(
          w->priv.browser, &IID_IOleInPlaceObject, (void **)&ipo);
      if (ipo) {
        RECT rc;
        GetClientRect(hwnd, &rc);
        ipo->lpVtbl->SetObjectRects(ipo, &rc, &rc);
        ipo->lpVtbl->Release(ipo);
      }
    }
    return 0;
  }
  case WM_APP: {
    webview_dispatch_fn fn = (webview_dispatch_fn)wParam;
    void *arg = (void *)lParam;
    if (fn && w) {
      fn(w, arg);
    }
    return 0;
  }
  case WM_CLOSE:
    if (w) {
      DestroyWindow(hwnd);
    }
    return 0;
  case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
  }
  return DefWindowProc(hwnd, msg, wParam, lParam);
}

/* ---- Inject external.invoke JS bridge ---- */

static void inject_invoke_bridge(struct webview *w) {
  /* Inject window.external.invoke via execScript on the document */
  static const char *bridge_js =
    "window.external={invoke:function(s){"
    "var img=new Image();"
    "img.src='invoke://localhost/'+encodeURIComponent(s);"
    "}};";
  webview_eval(w, bridge_js);
}

/* ---- Public API ---- */

WEBVIEW_API int webview_init(struct webview *w) {
  WNDCLASSEX wc;
  HINSTANCE hInstance = GetModuleHandle(NULL);
  static int class_registered = 0;

  OleInitialize(NULL);

  if (!class_registered) {
    ZeroMemory(&wc, sizeof(WNDCLASSEX));
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.hInstance = hInstance;
    wc.lpfnWndProc = webview_wndproc;
    wc.lpszClassName = "Chandra_WebView";
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    RegisterClassEx(&wc);
    class_registered = 1;
  }

  DWORD style = WS_OVERLAPPEDWINDOW;
  if (!w->resizable) {
    style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  }

  RECT rc = {0, 0, w->width, w->height};
  AdjustWindowRect(&rc, style, FALSE);

  w->priv.hwnd = CreateWindowEx(
      0, "Chandra_WebView",
      w->title ? w->title : "Chandra",
      style,
      CW_USEDEFAULT, CW_USEDEFAULT,
      rc.right - rc.left, rc.bottom - rc.top,
      NULL, NULL, hInstance, w);

  if (!w->priv.hwnd) {
    return -1;
  }

  /* Create OLE browser object */
  IOleObject *ole = NULL;
  HRESULT hr = CoCreateInstance(&CLSID_WebBrowser, NULL, CLSCTX_INPROC_SERVER,
                                &IID_IOleObject, (void **)&ole);
  if (FAILED(hr) || !ole) {
    DestroyWindow(w->priv.hwnd);
    return -1;
  }

  w->priv.browser = ole;

  WebviewSite *site = create_site(w, w->priv.hwnd);
  if (!site) {
    ole->lpVtbl->Release(ole);
    DestroyWindow(w->priv.hwnd);
    return -1;
  }

  ole->lpVtbl->SetClientSite(ole, &site->client_site);
  ole->lpVtbl->SetHostNames(ole, L"Chandra", L"Chandra");

  RECT rect;
  GetClientRect(w->priv.hwnd, &rect);
  OleSetContainedObject((IUnknown *)ole, TRUE);
  ole->lpVtbl->DoVerb(ole, OLEIVERB_INPLACEACTIVATE, NULL,
                       &site->client_site, 0, w->priv.hwnd, &rect);

  /* Navigate to URL */
  const char *url = webview_check_url(w->url);
  navigate(w->priv.browser, url);

  ShowWindow(w->priv.hwnd, SW_SHOW);
  UpdateWindow(w->priv.hwnd);

  /* Schedule bridge injection after page loads */
  inject_invoke_bridge(w);

  w->priv.is_fullscreen = FALSE;

  return 0;
}

WEBVIEW_API int webview_loop(struct webview *w, int blocking) {
  MSG msg;
  if (blocking) {
    if (GetMessage(&msg, NULL, 0, 0) > 0) {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
      return 0;
    }
    return -1;
  } else {
    if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
      if (msg.message == WM_QUIT) {
        return -1;
      }
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }
    return 0;
  }
}

WEBVIEW_API int webview_eval(struct webview *w, const char *js) {
  IWebBrowser2 *wb = NULL;
  IDispatch *doc_disp = NULL;
  IHTMLDocument2 *doc = NULL;
  HRESULT hr;

  if (!w->priv.browser) return -1;

  hr = w->priv.browser->lpVtbl->QueryInterface(
      w->priv.browser, &IID_IWebBrowser2, (void **)&wb);
  if (FAILED(hr) || !wb) return -1;

  hr = wb->lpVtbl->get_Document(wb, &doc_disp);
  if (FAILED(hr) || !doc_disp) {
    wb->lpVtbl->Release(wb);
    return -1;
  }

  hr = doc_disp->lpVtbl->QueryInterface(doc_disp, &IID_IHTMLDocument2, (void **)&doc);
  doc_disp->lpVtbl->Release(doc_disp);
  if (FAILED(hr) || !doc) {
    wb->lpVtbl->Release(wb);
    return -1;
  }

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

WEBVIEW_API void webview_set_title(struct webview *w, const char *title) {
  SetWindowTextA(w->priv.hwnd, title);
}

WEBVIEW_API void webview_set_size(struct webview *w, int width, int height) {
  RECT rc;
  GetWindowRect(w->priv.hwnd, &rc);
  MoveWindow(w->priv.hwnd, rc.left, rc.top, width, height, TRUE);
  w->width = width;
  w->height = height;
}

WEBVIEW_API void webview_set_fullscreen(struct webview *w, int fullscreen) {
  if (w->priv.is_fullscreen == (BOOL)fullscreen) return;
  w->priv.is_fullscreen = fullscreen;

  if (fullscreen) {
    w->priv.saved_style = GetWindowLong(w->priv.hwnd, GWL_STYLE);
    w->priv.saved_ex_style = GetWindowLong(w->priv.hwnd, GWL_EXSTYLE);
    GetWindowRect(w->priv.hwnd, &w->priv.saved_rect);

    MONITORINFO mi = {sizeof(mi)};
    GetMonitorInfo(MonitorFromWindow(w->priv.hwnd, MONITOR_DEFAULTTOPRIMARY), &mi);
    SetWindowLong(w->priv.hwnd, GWL_STYLE, w->priv.saved_style & ~(WS_CAPTION | WS_THICKFRAME));
    SetWindowLong(w->priv.hwnd, GWL_EXSTYLE,
                  w->priv.saved_ex_style & ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE |
                                              WS_EX_CLIENTEDGE | WS_EX_STATICEDGE));
    SetWindowPos(w->priv.hwnd, HWND_TOP,
                 mi.rcMonitor.left, mi.rcMonitor.top,
                 mi.rcMonitor.right - mi.rcMonitor.left,
                 mi.rcMonitor.bottom - mi.rcMonitor.top,
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  } else {
    SetWindowLong(w->priv.hwnd, GWL_STYLE, w->priv.saved_style);
    SetWindowLong(w->priv.hwnd, GWL_EXSTYLE, w->priv.saved_ex_style);
    SetWindowPos(w->priv.hwnd, NULL,
                 w->priv.saved_rect.left, w->priv.saved_rect.top,
                 w->priv.saved_rect.right - w->priv.saved_rect.left,
                 w->priv.saved_rect.bottom - w->priv.saved_rect.top,
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  }
}

WEBVIEW_API void webview_set_color(struct webview *w, uint8_t r, uint8_t g,
                                   uint8_t b, uint8_t a) {
  (void)a; /* Alpha not directly supported in MSHTML */
  HBRUSH brush = CreateSolidBrush(RGB(r, g, b));
  SetClassLongPtr(w->priv.hwnd, GCLP_HBRBACKGROUND, (LONG_PTR)brush);
  InvalidateRect(w->priv.hwnd, NULL, TRUE);
}

WEBVIEW_API void webview_dialog(struct webview *w,
                                enum webview_dialog_type dlgtype, int flags,
                                const char *title, const char *arg,
                                char *result, size_t resultsz) {
  if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN || dlgtype == WEBVIEW_DIALOG_TYPE_SAVE) {
    OPENFILENAMEA ofn;
    char filename[MAX_PATH] = "";
    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = w->priv.hwnd;
    ofn.lpstrFile = filename;
    ofn.nMaxFile = sizeof(filename);
    ofn.lpstrFilter = arg ? arg : "All Files\0*.*\0";
    ofn.nFilterIndex = 1;
    ofn.lpstrTitle = title;
    ofn.Flags = OFN_PATHMUSTEXIST;

    if (flags & WEBVIEW_DIALOG_FLAG_DIRECTORY) {
      /* Use SHBrowseForFolder for directory selection */
      BROWSEINFOA bi;
      ZeroMemory(&bi, sizeof(bi));
      bi.hwndOwner = w->priv.hwnd;
      bi.lpszTitle = title ? title : "Select Folder";
      bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
      LPITEMIDLIST pidl = SHBrowseForFolderA(&bi);
      if (pidl) {
        SHGetPathFromIDListA(pidl, filename);
        CoTaskMemFree(pidl);
        if (result && resultsz > 0) {
          strncpy(result, filename, resultsz - 1);
          result[resultsz - 1] = '\0';
        }
      }
    } else if (dlgtype == WEBVIEW_DIALOG_TYPE_SAVE) {
      ofn.Flags |= OFN_OVERWRITEPROMPT;
      if (GetSaveFileNameA(&ofn)) {
        if (result && resultsz > 0) {
          strncpy(result, filename, resultsz - 1);
          result[resultsz - 1] = '\0';
        }
      }
    } else {
      ofn.Flags |= OFN_FILEMUSTEXIST;
      if (GetOpenFileNameA(&ofn)) {
        if (result && resultsz > 0) {
          strncpy(result, filename, resultsz - 1);
          result[resultsz - 1] = '\0';
        }
      }
    }
  } else if (dlgtype == WEBVIEW_DIALOG_TYPE_ALERT) {
    UINT type = MB_OK;
    int alert_flags = flags & WEBVIEW_DIALOG_FLAG_ALERT_MASK;
    if (alert_flags == WEBVIEW_DIALOG_FLAG_INFO) {
      type |= MB_ICONINFORMATION;
    } else if (alert_flags == WEBVIEW_DIALOG_FLAG_WARNING) {
      type |= MB_ICONWARNING;
    } else if (alert_flags == WEBVIEW_DIALOG_FLAG_ERROR) {
      type |= MB_ICONERROR;
    }
    MessageBoxA(w->priv.hwnd, arg ? arg : "", title ? title : "", type);
  }
}

WEBVIEW_API void webview_dispatch(struct webview *w, webview_dispatch_fn fn,
                                  void *arg) {
  PostMessage(w->priv.hwnd, WM_APP, (WPARAM)fn, (LPARAM)arg);
  /* Handle WM_APP in the message loop or wndproc */
}

WEBVIEW_API void webview_terminate(struct webview *w) {
  PostMessage(w->priv.hwnd, WM_CLOSE, 0, 0);
}

WEBVIEW_API void webview_exit(struct webview *w) {
  if (w->priv.browser) {
    w->priv.browser->lpVtbl->Close(w->priv.browser, OLECLOSE_NOSAVE);
    w->priv.browser->lpVtbl->Release(w->priv.browser);
    w->priv.browser = NULL;
  }
  OleUninitialize();
  DestroyWindow(w->priv.hwnd);
}

WEBVIEW_API void webview_print_log(const char *s) {
  OutputDebugStringA(s);
  OutputDebugStringA("\n");
#ifdef MULTIPLICITY
  /* stderr is redefined by Perl under MULTIPLICITY; use Win32 API instead */
  {
    HANDLE h = GetStdHandle(STD_ERROR_HANDLE);
    if (h && h != INVALID_HANDLE_VALUE) {
      DWORD written;
      WriteFile(h, s, (DWORD)strlen(s), &written, NULL);
      WriteFile(h, "\n", 1, &written, NULL);
    }
  }
#else
  fprintf(stderr, "%s\n", s);
#endif
}
