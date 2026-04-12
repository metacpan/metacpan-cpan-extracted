/*
 * webview-edge.c — Edge/WebView2 backend for Windows
 *
 * This file implements the WebView2 (Chromium-based) backend for Windows.
 * It is included by webview-win32.c and provides runtime detection of
 * WebView2 availability. If WebView2 is not available, the MSHTML fallback
 * in webview-win32.c is used instead.
 *
 * WebView2 requires:
 *   - Windows 10 1803+ or Windows Server 2019+
 *   - WebView2 Runtime (installed separately or via Evergreen installer)
 *   - WebView2Loader.dll (loaded at runtime)
 *
 * The WebView2 SDK header is vendored at include/WebView2.h
 */

#ifndef WEBVIEW_EDGE_C
#define WEBVIEW_EDGE_C

#include <windows.h>
#include <shlwapi.h>
#include <shlobj.h>
#include <stdio.h>

/* ---- WebView2 COM interface definitions ---- */

/* 
 * Minimal WebView2 interface definitions to avoid requiring the full SDK.
 * Based on Microsoft WebView2 SDK 1.0.x
 */

/* GUIDs */
static const GUID CHANDRA_IID_ICoreWebView2 = 
    {0x76eceacb, 0x0462, 0x4d94, {0xac, 0x83, 0x42, 0x3a, 0x67, 0x93, 0x77, 0x5e}};
static const GUID CHANDRA_IID_ICoreWebView2Controller = 
    {0x4d00c0d1, 0x9434, 0x4eb6, {0x80, 0x78, 0x86, 0x97, 0xa5, 0x60, 0x33, 0x4f}};
static const GUID CHANDRA_IID_ICoreWebView2Environment = 
    {0xb96d755e, 0x0319, 0x4e92, {0xa2, 0x96, 0x23, 0x43, 0x6f, 0x46, 0xa1, 0xfc}};
static const GUID CHANDRA_IID_ICoreWebView2Settings = 
    {0xe562e4f0, 0xd7fa, 0x43ac, {0x8d, 0x71, 0xc0, 0x51, 0x50, 0x49, 0x9f, 0x00}};
static const GUID CHANDRA_IID_ICoreWebView2WebMessageReceivedEventArgs =
    {0x0f99a40c, 0xe962, 0x4207, {0x9e, 0x92, 0xe3, 0xd5, 0x42, 0xef, 0xf8, 0x49}};

/* Forward declarations of WebView2 interfaces */
typedef struct ICoreWebView2 ICoreWebView2;
typedef struct ICoreWebView2Controller ICoreWebView2Controller;
typedef struct ICoreWebView2Environment ICoreWebView2Environment;
typedef struct ICoreWebView2Settings ICoreWebView2Settings;
typedef struct ICoreWebView2WebMessageReceivedEventArgs ICoreWebView2WebMessageReceivedEventArgs;
typedef struct ICoreWebView2WebMessageReceivedEventHandler ICoreWebView2WebMessageReceivedEventHandler;
typedef struct ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler;
typedef struct ICoreWebView2CreateCoreWebView2ControllerCompletedHandler ICoreWebView2CreateCoreWebView2ControllerCompletedHandler;
typedef struct ICoreWebView2ExecuteScriptCompletedHandler ICoreWebView2ExecuteScriptCompletedHandler;

/* EventRegistrationToken */
typedef struct {
    INT64 value;
} EventRegistrationToken;

/* ---- ICoreWebView2 interface ---- */

typedef struct ICoreWebView2Vtbl {
    /* IUnknown */
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2*);
    /* ICoreWebView2 */
    HRESULT (STDMETHODCALLTYPE *get_Settings)(ICoreWebView2*, ICoreWebView2Settings**);
    HRESULT (STDMETHODCALLTYPE *get_Source)(ICoreWebView2*, LPWSTR*);
    HRESULT (STDMETHODCALLTYPE *Navigate)(ICoreWebView2*, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *NavigateToString)(ICoreWebView2*, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *add_NavigationStarting)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_NavigationStarting)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_ContentLoading)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_ContentLoading)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_SourceChanged)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_SourceChanged)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_HistoryChanged)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_HistoryChanged)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_NavigationCompleted)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_NavigationCompleted)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_FrameNavigationStarting)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_FrameNavigationStarting)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_FrameNavigationCompleted)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_FrameNavigationCompleted)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_ScriptDialogOpening)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_ScriptDialogOpening)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_PermissionRequested)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_PermissionRequested)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_ProcessFailed)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_ProcessFailed)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *AddScriptToExecuteOnDocumentCreated)(ICoreWebView2*, LPCWSTR, void*);
    HRESULT (STDMETHODCALLTYPE *RemoveScriptToExecuteOnDocumentCreated)(ICoreWebView2*, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *ExecuteScript)(ICoreWebView2*, LPCWSTR, ICoreWebView2ExecuteScriptCompletedHandler*);
    HRESULT (STDMETHODCALLTYPE *CapturePreview)(ICoreWebView2*, int, void*, void*);
    HRESULT (STDMETHODCALLTYPE *Reload)(ICoreWebView2*);
    HRESULT (STDMETHODCALLTYPE *PostWebMessageAsJson)(ICoreWebView2*, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *PostWebMessageAsString)(ICoreWebView2*, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *add_WebMessageReceived)(ICoreWebView2*, ICoreWebView2WebMessageReceivedEventHandler*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_WebMessageReceived)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *CallDevToolsProtocolMethod)(ICoreWebView2*, LPCWSTR, LPCWSTR, void*);
    HRESULT (STDMETHODCALLTYPE *get_BrowserProcessId)(ICoreWebView2*, UINT32*);
    HRESULT (STDMETHODCALLTYPE *get_CanGoBack)(ICoreWebView2*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *get_CanGoForward)(ICoreWebView2*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *GoBack)(ICoreWebView2*);
    HRESULT (STDMETHODCALLTYPE *GoForward)(ICoreWebView2*);
    HRESULT (STDMETHODCALLTYPE *GetDevToolsProtocolEventReceiver)(ICoreWebView2*, LPCWSTR, void**);
    HRESULT (STDMETHODCALLTYPE *Stop)(ICoreWebView2*);
    HRESULT (STDMETHODCALLTYPE *add_NewWindowRequested)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_NewWindowRequested)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_DocumentTitleChanged)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_DocumentTitleChanged)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *get_DocumentTitle)(ICoreWebView2*, LPWSTR*);
    HRESULT (STDMETHODCALLTYPE *AddHostObjectToScript)(ICoreWebView2*, LPCWSTR, VARIANT*);
    HRESULT (STDMETHODCALLTYPE *RemoveHostObjectFromScript)(ICoreWebView2*, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *OpenDevToolsWindow)(ICoreWebView2*);
    HRESULT (STDMETHODCALLTYPE *add_ContainsFullScreenElementChanged)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_ContainsFullScreenElementChanged)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *get_ContainsFullScreenElement)(ICoreWebView2*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *add_WebResourceRequested)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_WebResourceRequested)(ICoreWebView2*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *AddWebResourceRequestedFilter)(ICoreWebView2*, LPCWSTR, int);
    HRESULT (STDMETHODCALLTYPE *RemoveWebResourceRequestedFilter)(ICoreWebView2*, LPCWSTR, int);
    HRESULT (STDMETHODCALLTYPE *add_WindowCloseRequested)(ICoreWebView2*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_WindowCloseRequested)(ICoreWebView2*, EventRegistrationToken);
} ICoreWebView2Vtbl;

struct ICoreWebView2 {
    const ICoreWebView2Vtbl *lpVtbl;
};

/* ---- ICoreWebView2Controller interface ---- */

typedef struct ICoreWebView2ControllerVtbl {
    /* IUnknown */
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2Controller*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2Controller*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2Controller*);
    /* ICoreWebView2Controller */
    HRESULT (STDMETHODCALLTYPE *get_IsVisible)(ICoreWebView2Controller*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_IsVisible)(ICoreWebView2Controller*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_Bounds)(ICoreWebView2Controller*, RECT*);
    HRESULT (STDMETHODCALLTYPE *put_Bounds)(ICoreWebView2Controller*, RECT);
    HRESULT (STDMETHODCALLTYPE *get_ZoomFactor)(ICoreWebView2Controller*, double*);
    HRESULT (STDMETHODCALLTYPE *put_ZoomFactor)(ICoreWebView2Controller*, double);
    HRESULT (STDMETHODCALLTYPE *add_ZoomFactorChanged)(ICoreWebView2Controller*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_ZoomFactorChanged)(ICoreWebView2Controller*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *SetBoundsAndZoomFactor)(ICoreWebView2Controller*, RECT, double);
    HRESULT (STDMETHODCALLTYPE *MoveFocus)(ICoreWebView2Controller*, int);
    HRESULT (STDMETHODCALLTYPE *add_MoveFocusRequested)(ICoreWebView2Controller*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_MoveFocusRequested)(ICoreWebView2Controller*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_GotFocus)(ICoreWebView2Controller*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_GotFocus)(ICoreWebView2Controller*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_LostFocus)(ICoreWebView2Controller*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_LostFocus)(ICoreWebView2Controller*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *add_AcceleratorKeyPressed)(ICoreWebView2Controller*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_AcceleratorKeyPressed)(ICoreWebView2Controller*, EventRegistrationToken);
    HRESULT (STDMETHODCALLTYPE *get_ParentWindow)(ICoreWebView2Controller*, HWND*);
    HRESULT (STDMETHODCALLTYPE *put_ParentWindow)(ICoreWebView2Controller*, HWND);
    HRESULT (STDMETHODCALLTYPE *NotifyParentWindowPositionChanged)(ICoreWebView2Controller*);
    HRESULT (STDMETHODCALLTYPE *Close)(ICoreWebView2Controller*);
    HRESULT (STDMETHODCALLTYPE *get_CoreWebView2)(ICoreWebView2Controller*, ICoreWebView2**);
} ICoreWebView2ControllerVtbl;

struct ICoreWebView2Controller {
    const ICoreWebView2ControllerVtbl *lpVtbl;
};

/* ---- ICoreWebView2Environment interface ---- */

typedef struct ICoreWebView2EnvironmentVtbl {
    /* IUnknown */
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2Environment*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2Environment*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2Environment*);
    /* ICoreWebView2Environment */
    HRESULT (STDMETHODCALLTYPE *CreateCoreWebView2Controller)(
        ICoreWebView2Environment*, HWND, ICoreWebView2CreateCoreWebView2ControllerCompletedHandler*);
    HRESULT (STDMETHODCALLTYPE *CreateWebResourceResponse)(
        ICoreWebView2Environment*, void*, int, LPCWSTR, LPCWSTR, void**);
    HRESULT (STDMETHODCALLTYPE *get_BrowserVersionString)(ICoreWebView2Environment*, LPWSTR*);
    HRESULT (STDMETHODCALLTYPE *add_NewBrowserVersionAvailable)(
        ICoreWebView2Environment*, void*, EventRegistrationToken*);
    HRESULT (STDMETHODCALLTYPE *remove_NewBrowserVersionAvailable)(
        ICoreWebView2Environment*, EventRegistrationToken);
} ICoreWebView2EnvironmentVtbl;

struct ICoreWebView2Environment {
    const ICoreWebView2EnvironmentVtbl *lpVtbl;
};

/* ---- ICoreWebView2Settings interface ---- */

typedef struct ICoreWebView2SettingsVtbl {
    /* IUnknown */
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2Settings*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2Settings*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2Settings*);
    /* ICoreWebView2Settings */
    HRESULT (STDMETHODCALLTYPE *get_IsScriptEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_IsScriptEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_IsWebMessageEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_IsWebMessageEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_AreDefaultScriptDialogsEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_AreDefaultScriptDialogsEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_IsStatusBarEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_IsStatusBarEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_AreDevToolsEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_AreDevToolsEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_AreDefaultContextMenusEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_AreDefaultContextMenusEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_AreHostObjectsAllowed)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_AreHostObjectsAllowed)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_IsZoomControlEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_IsZoomControlEnabled)(ICoreWebView2Settings*, BOOL);
    HRESULT (STDMETHODCALLTYPE *get_IsBuiltInErrorPageEnabled)(ICoreWebView2Settings*, BOOL*);
    HRESULT (STDMETHODCALLTYPE *put_IsBuiltInErrorPageEnabled)(ICoreWebView2Settings*, BOOL);
} ICoreWebView2SettingsVtbl;

struct ICoreWebView2Settings {
    const ICoreWebView2SettingsVtbl *lpVtbl;
};

/* ---- WebMessageReceivedEventArgs interface ---- */

typedef struct ICoreWebView2WebMessageReceivedEventArgsVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2WebMessageReceivedEventArgs*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2WebMessageReceivedEventArgs*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2WebMessageReceivedEventArgs*);
    HRESULT (STDMETHODCALLTYPE *get_Source)(ICoreWebView2WebMessageReceivedEventArgs*, LPWSTR*);
    HRESULT (STDMETHODCALLTYPE *get_WebMessageAsJson)(ICoreWebView2WebMessageReceivedEventArgs*, LPWSTR*);
    HRESULT (STDMETHODCALLTYPE *TryGetWebMessageAsString)(ICoreWebView2WebMessageReceivedEventArgs*, LPWSTR*);
} ICoreWebView2WebMessageReceivedEventArgsVtbl;

struct ICoreWebView2WebMessageReceivedEventArgs {
    const ICoreWebView2WebMessageReceivedEventArgsVtbl *lpVtbl;
};

/* ---- Handler interfaces ---- */

typedef struct ICoreWebView2WebMessageReceivedEventHandlerVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2WebMessageReceivedEventHandler*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2WebMessageReceivedEventHandler*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2WebMessageReceivedEventHandler*);
    HRESULT (STDMETHODCALLTYPE *Invoke)(ICoreWebView2WebMessageReceivedEventHandler*, ICoreWebView2*, ICoreWebView2WebMessageReceivedEventArgs*);
} ICoreWebView2WebMessageReceivedEventHandlerVtbl;

struct ICoreWebView2WebMessageReceivedEventHandler {
    const ICoreWebView2WebMessageReceivedEventHandlerVtbl *lpVtbl;
};

/* ---- Completed handler interfaces ---- */

typedef struct ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler*);
    HRESULT (STDMETHODCALLTYPE *Invoke)(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler*, HRESULT, ICoreWebView2Environment*);
} ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl;

struct ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler {
    const ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl *lpVtbl;
};

typedef struct ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler*);
    HRESULT (STDMETHODCALLTYPE *Invoke)(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler*, HRESULT, ICoreWebView2Controller*);
} ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl;

struct ICoreWebView2CreateCoreWebView2ControllerCompletedHandler {
    const ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl *lpVtbl;
};

typedef struct ICoreWebView2ExecuteScriptCompletedHandlerVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICoreWebView2ExecuteScriptCompletedHandler*, REFIID, void**);
    ULONG (STDMETHODCALLTYPE *AddRef)(ICoreWebView2ExecuteScriptCompletedHandler*);
    ULONG (STDMETHODCALLTYPE *Release)(ICoreWebView2ExecuteScriptCompletedHandler*);
    HRESULT (STDMETHODCALLTYPE *Invoke)(ICoreWebView2ExecuteScriptCompletedHandler*, HRESULT, LPCWSTR);
} ICoreWebView2ExecuteScriptCompletedHandlerVtbl;

struct ICoreWebView2ExecuteScriptCompletedHandler {
    const ICoreWebView2ExecuteScriptCompletedHandlerVtbl *lpVtbl;
};

/* ---- WebView2 loader function type ---- */
typedef HRESULT (STDMETHODCALLTYPE *CreateCoreWebView2EnvironmentWithOptionsFunc)(
    LPCWSTR browserExecutableFolder,
    LPCWSTR userDataFolder,
    void *environmentOptions,
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *handler
);

typedef HRESULT (STDMETHODCALLTYPE *GetAvailableCoreWebView2BrowserVersionStringFunc)(
    LPCWSTR browserExecutableFolder,
    LPWSTR *versionInfo
);

/* ---- webview2 struct (referenced from webview.h) ---- */

struct webview2_struct {
    HMODULE loader_dll;
    ICoreWebView2Environment *environment;
    ICoreWebView2Controller *controller;
    ICoreWebView2 *webview;
    struct webview *parent;
    int ready;
    EventRegistrationToken message_token;
    char *pending_url;
    char *pending_html;
};

/* ---- Handler implementations ---- */

typedef struct {
    ICoreWebView2WebMessageReceivedEventHandlerVtbl *lpVtbl;
    LONG ref;
    struct webview *w;
} WebMessageHandler;

typedef struct {
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl *lpVtbl;
    LONG ref;
    struct webview *w;
} EnvironmentHandler;

typedef struct {
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl *lpVtbl;
    LONG ref;
    struct webview *w;
} ControllerHandler;

/* Forward declarations */
static int webview2_available(void);
static int webview2_init(struct webview *w);
static void webview2_navigate(struct webview *w, const char *url);
static void webview2_set_html(struct webview *w, const char *html);
static int webview2_eval(struct webview *w, const char *js);
static void webview2_resize(struct webview *w);
static void webview2_cleanup(struct webview *w);

/* ---- WebView2 availability check ---- */

static HMODULE webview2_load_dll(void) {
    static HMODULE dll = NULL;
    static int tried = 0;
    
    if (tried) return dll;
    tried = 1;
    
    /* Try loading WebView2Loader.dll from various locations */
    dll = LoadLibraryA("WebView2Loader.dll");
    if (dll) return dll;
    
    /* Try application directory */
    char path[MAX_PATH];
    if (GetModuleFileNameA(NULL, path, MAX_PATH)) {
        char *slash = strrchr(path, '\\');
        if (slash) {
            strcpy(slash + 1, "WebView2Loader.dll");
            dll = LoadLibraryA(path);
            if (dll) return dll;
        }
    }
    
    /* Try System32 */
    if (GetSystemDirectoryA(path, MAX_PATH)) {
        strcat(path, "\\WebView2Loader.dll");
        dll = LoadLibraryA(path);
    }
    
    return dll;
}

static int webview2_available(void) {
    HMODULE dll = webview2_load_dll();
    if (!dll) return 0;
    
    GetAvailableCoreWebView2BrowserVersionStringFunc getVersion = 
        (GetAvailableCoreWebView2BrowserVersionStringFunc)GetProcAddress(dll, "GetAvailableCoreWebView2BrowserVersionString");
    if (!getVersion) return 0;
    
    LPWSTR version = NULL;
    HRESULT hr = getVersion(NULL, &version);
    if (SUCCEEDED(hr) && version) {
        CoTaskMemFree(version);
        return 1;
    }
    
    return 0;
}

/* ---- Handler vtables and implementations ---- */

/* WebMessageHandler */
static HRESULT STDMETHODCALLTYPE wmh_QueryInterface(ICoreWebView2WebMessageReceivedEventHandler *This, REFIID riid, void **ppv) {
    (void)riid;
    *ppv = This;
    This->lpVtbl->AddRef(This);
    return S_OK;
}

static ULONG STDMETHODCALLTYPE wmh_AddRef(ICoreWebView2WebMessageReceivedEventHandler *This) {
    WebMessageHandler *h = (WebMessageHandler *)This;
    return InterlockedIncrement(&h->ref);
}

static ULONG STDMETHODCALLTYPE wmh_Release(ICoreWebView2WebMessageReceivedEventHandler *This) {
    WebMessageHandler *h = (WebMessageHandler *)This;
    LONG ref = InterlockedDecrement(&h->ref);
    if (ref == 0) {
        GlobalFree(h);
    }
    return ref;
}

static HRESULT STDMETHODCALLTYPE wmh_Invoke(
    ICoreWebView2WebMessageReceivedEventHandler *This,
    ICoreWebView2 *sender,
    ICoreWebView2WebMessageReceivedEventArgs *args) {
    
    (void)sender;
    WebMessageHandler *h = (WebMessageHandler *)This;
    
    LPWSTR message = NULL;
    HRESULT hr = args->lpVtbl->TryGetWebMessageAsString(args, &message);
    
    if (SUCCEEDED(hr) && message && h->w && h->w->external_invoke_cb) {
        /* Convert wide string to UTF-8 */
        int len = WideCharToMultiByte(CP_UTF8, 0, message, -1, NULL, 0, NULL, NULL);
        char *utf8 = (char *)GlobalAlloc(GPTR, len);
        if (utf8) {
            WideCharToMultiByte(CP_UTF8, 0, message, -1, utf8, len, NULL, NULL);
            h->w->external_invoke_cb(h->w, utf8);
            GlobalFree(utf8);
        }
        CoTaskMemFree(message);
    }
    
    return S_OK;
}

static ICoreWebView2WebMessageReceivedEventHandlerVtbl wmh_vtbl = {
    wmh_QueryInterface, wmh_AddRef, wmh_Release, wmh_Invoke
};

/* EnvironmentHandler */
static HRESULT STDMETHODCALLTYPE eh_QueryInterface(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This, REFIID riid, void **ppv) {
    (void)riid;
    *ppv = This;
    This->lpVtbl->AddRef(This);
    return S_OK;
}

static ULONG STDMETHODCALLTYPE eh_AddRef(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This) {
    EnvironmentHandler *h = (EnvironmentHandler *)This;
    return InterlockedIncrement(&h->ref);
}

static ULONG STDMETHODCALLTYPE eh_Release(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This) {
    EnvironmentHandler *h = (EnvironmentHandler *)This;
    LONG ref = InterlockedDecrement(&h->ref);
    if (ref == 0) {
        GlobalFree(h);
    }
    return ref;
}

/* Forward declaration for controller creation */
static void webview2_create_controller(struct webview *w);

static HRESULT STDMETHODCALLTYPE eh_Invoke(
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This,
    HRESULT result,
    ICoreWebView2Environment *environment) {
    
    EnvironmentHandler *h = (EnvironmentHandler *)This;
    
    if (FAILED(result) || !environment) {
        return S_OK;
    }
    
    if (h->w && h->w->priv.webview2) {
        h->w->priv.webview2->environment = environment;
        environment->lpVtbl->AddRef(environment);
        webview2_create_controller(h->w);
    }
    
    return S_OK;
}

static ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl eh_vtbl = {
    eh_QueryInterface, eh_AddRef, eh_Release, eh_Invoke
};

/* ControllerHandler */
static HRESULT STDMETHODCALLTYPE ch_QueryInterface(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This, REFIID riid, void **ppv) {
    (void)riid;
    *ppv = This;
    This->lpVtbl->AddRef(This);
    return S_OK;
}

static ULONG STDMETHODCALLTYPE ch_AddRef(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This) {
    ControllerHandler *h = (ControllerHandler *)This;
    return InterlockedIncrement(&h->ref);
}

static ULONG STDMETHODCALLTYPE ch_Release(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This) {
    ControllerHandler *h = (ControllerHandler *)This;
    LONG ref = InterlockedDecrement(&h->ref);
    if (ref == 0) {
        GlobalFree(h);
    }
    return ref;
}

static HRESULT STDMETHODCALLTYPE ch_Invoke(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This,
    HRESULT result,
    ICoreWebView2Controller *controller) {
    
    ControllerHandler *h = (ControllerHandler *)This;
    
    if (FAILED(result) || !controller) {
        return S_OK;
    }
    
    if (!h->w || !h->w->priv.webview2) {
        return S_OK;
    }
    
    webview2 *wv2 = h->w->priv.webview2;
    wv2->controller = controller;
    controller->lpVtbl->AddRef(controller);
    
    /* Get the CoreWebView2 */
    ICoreWebView2 *webview = NULL;
    controller->lpVtbl->get_CoreWebView2(controller, &webview);
    if (!webview) {
        return S_OK;
    }
    
    wv2->webview = webview;
    
    /* Configure settings */
    ICoreWebView2Settings *settings = NULL;
    webview->lpVtbl->get_Settings(webview, &settings);
    if (settings) {
        settings->lpVtbl->put_IsScriptEnabled(settings, TRUE);
        settings->lpVtbl->put_IsWebMessageEnabled(settings, TRUE);
        settings->lpVtbl->put_AreDefaultContextMenusEnabled(settings, h->w->debug ? TRUE : FALSE);
        settings->lpVtbl->put_AreDevToolsEnabled(settings, h->w->debug ? TRUE : FALSE);
        settings->lpVtbl->Release(settings);
    }
    
    /* Add web message handler */
    WebMessageHandler *wmh = (WebMessageHandler *)GlobalAlloc(GPTR, sizeof(WebMessageHandler));
    if (wmh) {
        wmh->lpVtbl = &wmh_vtbl;
        wmh->ref = 1;
        wmh->w = h->w;
        webview->lpVtbl->add_WebMessageReceived(webview, (ICoreWebView2WebMessageReceivedEventHandler *)wmh, &wv2->message_token);
        wmh->lpVtbl->Release((ICoreWebView2WebMessageReceivedEventHandler *)wmh);
    }
    
    /* Inject bridge script */
    static const wchar_t bridge_js[] = 
        L"window.external = window.external || {};"
        L"window.external.invoke = function(s) {"
        L"  window.chrome.webview.postMessage(s);"
        L"};";
    webview->lpVtbl->AddScriptToExecuteOnDocumentCreated(webview, bridge_js, NULL);
    
    /* Set bounds */
    RECT rc;
    GetClientRect(h->w->priv.hwnd, &rc);
    controller->lpVtbl->put_Bounds(controller, rc);
    controller->lpVtbl->put_IsVisible(controller, TRUE);
    
    /* Mark as ready */
    wv2->ready = 1;
    
    /* Navigate to pending URL or HTML */
    if (wv2->pending_url) {
        webview2_navigate(h->w, wv2->pending_url);
        GlobalFree(wv2->pending_url);
        wv2->pending_url = NULL;
    } else if (wv2->pending_html) {
        webview2_set_html(h->w, wv2->pending_html);
        GlobalFree(wv2->pending_html);
        wv2->pending_html = NULL;
    }
    
    return S_OK;
}

static ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl ch_vtbl = {
    ch_QueryInterface, ch_AddRef, ch_Release, ch_Invoke
};

/* ---- WebView2 operations ---- */

static void webview2_create_controller(struct webview *w) {
    if (!w || !w->priv.webview2 || !w->priv.webview2->environment) {
        return;
    }
    
    ControllerHandler *ch = (ControllerHandler *)GlobalAlloc(GPTR, sizeof(ControllerHandler));
    if (!ch) return;
    
    ch->lpVtbl = &ch_vtbl;
    ch->ref = 1;
    ch->w = w;
    
    w->priv.webview2->environment->lpVtbl->CreateCoreWebView2Controller(
        w->priv.webview2->environment,
        w->priv.hwnd,
        (ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *)ch
    );
    
    ch->lpVtbl->Release((ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *)ch);
}

static int webview2_init(struct webview *w) {
    HMODULE dll = webview2_load_dll();
    if (!dll) return -1;
    
    CreateCoreWebView2EnvironmentWithOptionsFunc createEnv = 
        (CreateCoreWebView2EnvironmentWithOptionsFunc)GetProcAddress(dll, "CreateCoreWebView2EnvironmentWithOptions");
    if (!createEnv) return -1;
    
    /* Allocate webview2 struct */
    webview2 *wv2 = (webview2 *)GlobalAlloc(GPTR, sizeof(webview2));
    if (!wv2) return -1;
    
    wv2->loader_dll = dll;
    wv2->parent = w;
    wv2->ready = 0;
    w->priv.webview2 = wv2;
    
    /* Store URL for later navigation */
    if (w->url && strlen(w->url) > 0) {
        wv2->pending_url = (char *)GlobalAlloc(GPTR, strlen(w->url) + 1);
        if (wv2->pending_url) {
            strcpy(wv2->pending_url, w->url);
        }
    }
    
    /* Create environment handler */
    EnvironmentHandler *eh = (EnvironmentHandler *)GlobalAlloc(GPTR, sizeof(EnvironmentHandler));
    if (!eh) {
        GlobalFree(wv2);
        w->priv.webview2 = NULL;
        return -1;
    }
    
    eh->lpVtbl = &eh_vtbl;
    eh->ref = 1;
    eh->w = w;
    
    /* Get user data folder */
    wchar_t userDataFolder[MAX_PATH];
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, userDataFolder))) {
        wcscat(userDataFolder, L"\\Chandra\\WebView2Data");
    } else {
        wcscpy(userDataFolder, L"");
    }
    
    HRESULT hr = createEnv(
        NULL,                          /* browserExecutableFolder - use default */
        userDataFolder[0] ? userDataFolder : NULL,
        NULL,                          /* environmentOptions */
        (ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *)eh
    );
    
    eh->lpVtbl->Release((ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *)eh);
    
    if (FAILED(hr)) {
        GlobalFree(wv2);
        w->priv.webview2 = NULL;
        return -1;
    }
    
    return 0;
}

static void webview2_navigate(struct webview *w, const char *url) {
    if (!w || !w->priv.webview2) return;
    webview2 *wv2 = w->priv.webview2;
    
    if (!wv2->ready || !wv2->webview) {
        /* Store for later */
        if (wv2->pending_url) GlobalFree(wv2->pending_url);
        wv2->pending_url = (char *)GlobalAlloc(GPTR, strlen(url) + 1);
        if (wv2->pending_url) strcpy(wv2->pending_url, url);
        return;
    }
    
    int len = MultiByteToWideChar(CP_UTF8, 0, url, -1, NULL, 0);
    wchar_t *wurl = (wchar_t *)GlobalAlloc(GPTR, len * sizeof(wchar_t));
    if (wurl) {
        MultiByteToWideChar(CP_UTF8, 0, url, -1, wurl, len);
        wv2->webview->lpVtbl->Navigate(wv2->webview, wurl);
        GlobalFree(wurl);
    }
}

static void webview2_set_html(struct webview *w, const char *html) {
    if (!w || !w->priv.webview2) return;
    webview2 *wv2 = w->priv.webview2;
    
    if (!wv2->ready || !wv2->webview) {
        /* Store for later */
        if (wv2->pending_html) GlobalFree(wv2->pending_html);
        wv2->pending_html = (char *)GlobalAlloc(GPTR, strlen(html) + 1);
        if (wv2->pending_html) strcpy(wv2->pending_html, html);
        return;
    }
    
    int len = MultiByteToWideChar(CP_UTF8, 0, html, -1, NULL, 0);
    wchar_t *whtml = (wchar_t *)GlobalAlloc(GPTR, len * sizeof(wchar_t));
    if (whtml) {
        MultiByteToWideChar(CP_UTF8, 0, html, -1, whtml, len);
        wv2->webview->lpVtbl->NavigateToString(wv2->webview, whtml);
        GlobalFree(whtml);
    }
}

static int webview2_eval(struct webview *w, const char *js) {
    if (!w || !w->priv.webview2) return -1;
    webview2 *wv2 = w->priv.webview2;
    
    if (!wv2->ready || !wv2->webview) return -1;
    
    int len = MultiByteToWideChar(CP_UTF8, 0, js, -1, NULL, 0);
    wchar_t *wjs = (wchar_t *)GlobalAlloc(GPTR, len * sizeof(wchar_t));
    if (!wjs) return -1;
    
    MultiByteToWideChar(CP_UTF8, 0, js, -1, wjs, len);
    
    /* Execute without waiting for result */
    HRESULT hr = wv2->webview->lpVtbl->ExecuteScript(wv2->webview, wjs, NULL);
    GlobalFree(wjs);
    
    return SUCCEEDED(hr) ? 0 : -1;
}

static void webview2_resize(struct webview *w) {
    if (!w || !w->priv.webview2) return;
    webview2 *wv2 = w->priv.webview2;
    
    if (!wv2->ready || !wv2->controller) return;
    
    RECT rc;
    GetClientRect(w->priv.hwnd, &rc);
    wv2->controller->lpVtbl->put_Bounds(wv2->controller, rc);
}

static void webview2_cleanup(struct webview *w) {
    if (!w || !w->priv.webview2) return;
    webview2 *wv2 = w->priv.webview2;
    
    if (wv2->webview) {
        wv2->webview->lpVtbl->remove_WebMessageReceived(wv2->webview, wv2->message_token);
        wv2->webview->lpVtbl->Release(wv2->webview);
    }
    
    if (wv2->controller) {
        wv2->controller->lpVtbl->Close(wv2->controller);
        wv2->controller->lpVtbl->Release(wv2->controller);
    }
    
    if (wv2->environment) {
        wv2->environment->lpVtbl->Release(wv2->environment);
    }
    
    if (wv2->pending_url) GlobalFree(wv2->pending_url);
    if (wv2->pending_html) GlobalFree(wv2->pending_html);
    
    /* Don't FreeLibrary the DLL - it may still be in use */
    
    GlobalFree(wv2);
    w->priv.webview2 = NULL;
}

#endif /* WEBVIEW_EDGE_C */
