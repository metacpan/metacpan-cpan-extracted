/* Cross-platform Nuklear window shim.
 *
 * Exposes a single nk_win_* C API (driven from Perl via Affix) that dispatches
 * to one of two Nuklear backends:
 *
 *   - Windows  -> Win32 GDI  (nuklear_gdi.h)
 *   - Unix     -> X11/Xlib  (nuklear_xlib.h)
 *
 * The Perl side (eg/nuklear.pl) only ever calls nk_win_*, so it is unchanged
 * across platforms. The nuklear core comes from add_packages("nuklear").
 */

/* The backend headers need the implementation macro before nuklear.h sees them. */
#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_IMPLEMENTATION            /* emit the nuklear core implementation */
#ifndef _WIN32
#  define NK_XLIB_IMPLEMENTATION
#else
#  define NK_GDI_IMPLEMENTATION
#endif

#ifdef _WIN32
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
#  define NK_API __declspec(dllexport)
#  include <nuklear.h>
#  include "nuklear_gdi.h"
#  define WIN_CLASS_NAME L"AlienNuklearDemo"
  /* MSVC needs explicit dllexport on a DLL; other compilers export by default. */
#  define NK_WIN_API __declspec(dllexport)
#else
#  include <nuklear.h>
#  include "nuklear_xlib.h"
#  include <X11/Xlib.h>
#  include <X11/keysym.h>
#  include <locale.h>
#  include <stdlib.h>
#  include <stdio.h>
#  include <string.h>
#  define NK_WIN_API
#endif

/* shared state */
static int g_running = 0;

#ifdef _WIN32
/* Win32 / GDI */
static HWND     g_hwnd;
static GdiFont *g_font;
static int      g_needs_refresh = 1;

static LRESULT CALLBACK
win_proc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    if (nk_gdi_handle_event(hwnd, msg, wparam, lparam))
        return 0;
    switch (msg) {
    case WM_DESTROY:
        PostQuitMessage(0);
        g_running = 0;
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wparam, lparam);
}

NK_WIN_API int
nk_win_init(const wchar_t *title, int width, int height, const char *font_name, int font_size) {
    WNDCLASSW wc;
    DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
    RECT rc = { 0, 0, width, height };
    HDC dc;
    GdiFont *font;
    struct nk_context *ctx;

    ZeroMemory(&wc, sizeof(wc));
    wc.style = CS_DBLCLKS | CS_OWNDC;
    wc.lpfnWndProc = win_proc;
    wc.hInstance = GetModuleHandleW(NULL);
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    wc.hIcon = LoadIconW(NULL, (LPCWSTR)IDI_APPLICATION);
    wc.lpszClassName = WIN_CLASS_NAME;
    if (!RegisterClassW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
        return 0;

    AdjustWindowRectEx(&rc, style, FALSE, 0);
    g_hwnd = CreateWindowExW(0, WIN_CLASS_NAME, title, style,
        CW_USEDEFAULT, CW_USEDEFAULT,
        rc.right - rc.left, rc.bottom - rc.top,
        NULL, NULL, wc.hInstance, NULL);
    if (!g_hwnd)
        return 0;

    font = nk_gdifont_create(font_name ? font_name : "Arial", font_size ? font_size : 14);
    if (!font) {
        DestroyWindow(g_hwnd);
        g_hwnd = NULL;
        return 0;
    }
    g_font = font;

    dc = GetDC(g_hwnd);
    ctx = nk_gdi_init(font, dc, (unsigned int)width, (unsigned int)height);
    ReleaseDC(g_hwnd, dc);
    if (!ctx) {
        nk_gdifont_del(font);
        DestroyWindow(g_hwnd);
        g_hwnd = NULL;
        return 0;
    }

    ShowWindow(g_hwnd, SW_SHOW);
    UpdateWindow(g_hwnd);
    g_running = 1;
    return 1;
}

NK_WIN_API int nk_win_running(void) { return g_running; }

NK_WIN_API void nk_win_poll(void) {
    MSG msg;
    nk_input_begin(&gdi.ctx);
    if (g_needs_refresh == 0) {
        if (GetMessageW(&msg, NULL, 0, 0) <= 0) {
            nk_input_end(&gdi.ctx);
            g_running = 0;
            return;
        }
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
        g_needs_refresh = 1;
    }
    else {
        g_needs_refresh = 0;
    }
    while (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) {
            nk_input_end(&gdi.ctx);
            g_running = 0;
            return;
        }
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
        g_needs_refresh = 1;
    }
    nk_input_end(&gdi.ctx);
}

NK_WIN_API void nk_win_render(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    HDC dc;
    if (!g_hwnd)
        return;
    dc = GetDC(g_hwnd);
    nk_gdi_set_font(g_font);
    nk_gdi_render(nk_rgba(r, g, b, a));
    ReleaseDC(g_hwnd, dc);
}

NK_WIN_API void nk_win_shutdown(void) {
    if (g_hwnd) {
        DestroyWindow(g_hwnd);
        g_hwnd = NULL;
    }
    nk_gdi_shutdown();
    if (g_font) {
        nk_gdifont_del(g_font);
        g_font = NULL;
    }
    UnregisterClassW(WIN_CLASS_NAME, GetModuleHandleW(NULL));
    g_running = 0;
}

NK_WIN_API void * nk_win_context(void) { return &gdi.ctx; }

#else /* Unix / X11 */
static Display     *g_dpy;
static Window       g_win;
static int          g_screen;
static Atom         g_wm_delete;
static XFont       *g_font;

/* Convert a wide string (as passed from Perl's WString) to UTF-8 so the X11 window title is
   correct regardless of the platform's wchar_t width.
 */
static void wstr_to_utf8(const wchar_t *ws, char *out, size_t outsz) {
    size_t i = 0, o = 0;
    out[0] = '\0';
    if (!ws)
        return;
    for (i = 0; ws[i] != 0 && o + 4 < outsz; i++) {
        unsigned int cp = (unsigned int)ws[i];
        if (cp < 0x80) {
            out[o++] = (char)cp;
        }
        else if (cp < 0x800) {
            out[o++] = (char)(0xC0 | (cp >> 6));
            out[o++] = (char)(0x80 | (cp & 0x3F));
        }
        else if (cp < 0x10000) {
            out[o++] = (char)(0xE0 | (cp >> 12));
            out[o++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[o++] = (char)(0x80 | (cp & 0x3F));
        }
        else {
            out[o++] = (char)(0xF0 | (cp >> 18));
            out[o++] = (char)(0x80 | ((cp >> 12) & 0x3F));
            out[o++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[o++] = (char)(0x80 | (cp & 0x3F));
        }
    }
    out[o] = '\0';
}

NK_WIN_API int nk_win_init(const wchar_t *title, int width, int height, const char *font_name, int font_size) {
    XSetWindowAttributes attrs;
    unsigned long mask;
    char title_utf8[256];
    const char *fc;

    g_dpy = XOpenDisplay(NULL);
    if (!g_dpy)
        return 0;
    g_screen = XDefaultScreen(g_dpy);

    mask = CWBackPixel | CWEventMask;
    attrs.background_pixel = BlackPixel(g_dpy, g_screen);
    attrs.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask |
        ButtonPressMask | ButtonReleaseMask | PointerMotionMask |
        StructureNotifyMask;
    g_win = XCreateWindow(g_dpy, RootWindow(g_dpy, g_screen),
        0, 0, (unsigned)width, (unsigned)height, 0,
        CopyFromParent, InputOutput, CopyFromParent, mask, &attrs);
    if (!g_win)
        return 0;

    wstr_to_utf8(title, title_utf8, sizeof(title_utf8));
    XStoreName(g_dpy, g_win, title_utf8);
    g_wm_delete = XInternAtom(g_dpy, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(g_dpy, g_win, &g_wm_delete, 1);

    XMapWindow(g_dpy, g_win);
    XFlush(g_dpy);

    fc = font_name && font_name[0] ? font_name : "fixed";
    g_font = nk_xfont_create(g_dpy, fc);
    if (!g_font) {
        XDestroyWindow(g_dpy, g_win);
        XCloseDisplay(g_dpy);
        g_dpy = NULL;
        return 0;
    }

    if (!nk_xlib_init(g_font, g_dpy, g_screen, g_win,
        (unsigned)width, (unsigned)height)) {
        nk_xfont_del(g_dpy, g_font);
        g_font = NULL;
        XDestroyWindow(g_dpy, g_win);
        XCloseDisplay(g_dpy);
        g_dpy = NULL;
        return 0;
    }
    g_running = 1;
    return 1;
}

NK_WIN_API int nk_win_running(void) { return g_running; }

NK_WIN_API void nk_win_poll(void) {
    XEvent ev;
    if (!g_dpy)
        return;
    while (XPending(g_dpy)) {
        XNextEvent(g_dpy, &ev);
        if (ev.type == ClientMessage &&
            (Atom)ev.xclient.data.l[0] == g_wm_delete) {
            g_running = 0;
            return;
        }
        nk_xlib_handle_event(g_dpy, g_screen, g_win, &ev);
    }
}

NK_WIN_API void nk_win_render(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    (void)a;
    if (!g_dpy || !g_win)
        return;
    nk_xlib_set_font(g_font);
    nk_xlib_render(g_win, nk_rgba(r, g, b, 255));
    XFlush(g_dpy);
}

NK_WIN_API void nk_win_shutdown(void) {
    nk_xlib_shutdown();
    if (g_font) {
        nk_xfont_del(g_dpy, g_font);
        g_font = NULL;
    }
    if (g_dpy) {
        XDestroyWindow(g_dpy, g_win);
        XCloseDisplay(g_dpy);
        g_dpy = NULL;
    }
    g_running = 0;
}

NK_WIN_API void * nk_win_context(void) {
    return &xlib.ctx;   /* static struct declared in nuklear_xlib.h */
}
#endif

/* shared API (both backends) */
NK_WIN_API int nk_win_begin(void *ctx, const char *title, float x, float y, float w, float h, unsigned int flags) {
    struct nk_rect rect = { x, y, w, h };
    return nk_begin((struct nk_context *)ctx, title, rect, flags);
}
