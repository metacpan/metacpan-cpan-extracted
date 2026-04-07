/*
 * chandra_splash.h — Splash screen support for Chandra
 *
 * Builds on the child-window infrastructure (chandra_window.h) to provide
 * a lightweight splash/loading-screen window with optional progress bar and
 * status text updates via JS eval.
 *
 * Gated by CHANDRA_XS_IMPLEMENTATION (set in Chandra.xs).
 * Must be included AFTER chandra_window.h (needs cwin_* functions).
 */

#ifndef CHANDRA_SPLASH_H
#define CHANDRA_SPLASH_H

#ifdef CHANDRA_XS_IMPLEMENTATION

/* Default HTML template used when content is not supplied but progress => 1 */
#define CHANDRA_SPLASH_DEFAULT_TMPL \
    "<!DOCTYPE html><html><head><meta charset='utf-8'>" \
    "<style>" \
    "* { box-sizing: border-box; margin: 0; padding: 0; }" \
    "body { display: flex; align-items: center; justify-content: center;" \
    "       height: 100vh; background: #fff; font-family: -apple-system," \
    "       BlinkMacSystemFont, 'Segoe UI', sans-serif; }" \
    ".splash { text-align: center; padding: 40px; width: 100%%; }" \
    ".splash-title { font-size: 1.4em; font-weight: 600; color: #111;" \
    "                margin-bottom: 8px; }" \
    ".splash-status { font-size: 0.9em; color: #666; margin-bottom: 16px;" \
    "                 min-height: 1.2em; }" \
    ".splash-track { width: 80%%; max-width: 320px; height: 4px;" \
    "                background: #e0e0e0; border-radius: 2px;" \
    "                margin: 0 auto; overflow: hidden; }" \
    ".splash-bar { height: 100%%; width: 0%%; background: #0066cc;" \
    "              border-radius: 2px; transition: width 0.3s ease; }" \
    "</style></head><body>" \
    "<div class='splash'>" \
    "<div class='splash-title' id='chandra-splash-title'>%s</div>" \
    "<div class='splash-status' id='chandra-splash-status'>Loading...</div>" \
    "<div class='splash-track'>" \
    "<div class='splash-bar' id='chandra-splash-bar'></div>" \
    "</div></div></body></html>"

/* Image-only template — base64 src filled in at runtime */
#define CHANDRA_SPLASH_IMAGE_TMPL \
    "<!DOCTYPE html><html><head><meta charset='utf-8'>" \
    "<style>" \
    "* { margin: 0; padding: 0; }" \
    "body { display: flex; align-items: center; justify-content: center;" \
    "       height: 100vh; background: transparent; overflow: hidden; }" \
    "img { max-width: 100%%; max-height: 100%%; object-fit: contain; }" \
    "</style></head><body><img src='data:%s;base64,%s'></body></html>"

/* JS snippets for live updates — use textContent (safe) not innerHTML */
#define CHANDRA_SPLASH_JS_STATUS \
    "var el=document.getElementById('chandra-splash-status');" \
    "if(el)el.textContent=%s;"

#define CHANDRA_SPLASH_JS_PROGRESS \
    "var el=document.getElementById('chandra-splash-bar');" \
    "if(el)el.style.width='%d%%';"

/* ---- Internal helpers ---------------------------------------------------- */

/*
 * csplash_js_escape — produce a JS string literal (with quotes) safe for
 * embedding in eval'd code. Escapes backslash, single/double quotes, newline,
 * carriage return, and control chars. Caller must free() the result.
 */
static char *
csplash_js_escape(const char *input)
{
    size_t i, len, out_len;
    char  *buf, *p;

    if (!input) input = "";
    len = strlen(input);

    /* Worst case: every char becomes \uXXXX (6 chars) + quotes + NUL */
    buf = (char *)malloc(len * 6 + 3);
    if (!buf) return NULL;

    p = buf;
    *p++ = '"';
    for (i = 0; i < len; i++) {
        unsigned char c = (unsigned char)input[i];
        switch (c) {
            case '\\': *p++ = '\\'; *p++ = '\\'; break;
            case '"':  *p++ = '\\'; *p++ = '"';  break;
            case '\'': *p++ = '\\'; *p++ = '\''; break;
            case '\n': *p++ = '\\'; *p++ = 'n';  break;
            case '\r': *p++ = '\\'; *p++ = 'r';  break;
            case '\t': *p++ = '\\'; *p++ = 't';  break;
            default:
                if (c < 0x20) {
                    p += sprintf(p, "\\u%04x", c);
                } else {
                    *p++ = (char)c;
                }
        }
    }
    *p++ = '"';
    *p = '\0';
    return buf;
}

/* ---- Public C API -------------------------------------------------------- */

/*
 * csplash_build_html — generate default splash HTML.
 * title may be NULL (renders as empty string).
 * Caller must free() the returned string.
 */
static char *
csplash_build_html(const char *title)
{
    const char *t = (title && *title) ? title : "";
    size_t len = strlen(CHANDRA_SPLASH_DEFAULT_TMPL) + strlen(t) + 1;
    char *buf = (char *)malloc(len);
    if (!buf) return NULL;
    snprintf(buf, len, CHANDRA_SPLASH_DEFAULT_TMPL, t);
    return buf;
}

/*
 * csplash_create — create the splash window (does NOT display content yet).
 * Returns native wid (>= 1) on success, -1 on failure / unsupported platform.
 */
static int
csplash_create(const char *title, int width, int height, int frameless)
{
    /* -1/-1 → center on screen */
    return cwin_create(title ? title : "", width, height, -1, -1, 0, frameless);
}

/*
 * csplash_show_html — set HTML content and make the window visible.
 */
static void
csplash_show_html(int wid, const char *html)
{
    cwin_set_html(wid, html);
    cwin_show(wid);
}

/*
 * csplash_update_status — update the status text line via JS eval.
 * text is escaped to prevent JS injection.
 */
static void
csplash_update_status(int wid, const char *text)
{
    char *escaped = csplash_js_escape(text);
    if (!escaped) return;
    /* JS_STATUS expects a %s that is already a quoted JS string literal */
    size_t js_len = strlen(CHANDRA_SPLASH_JS_STATUS) + strlen(escaped) + 1;
    char *js = (char *)malloc(js_len);
    if (js) {
        snprintf(js, js_len, CHANDRA_SPLASH_JS_STATUS, escaped);
        cwin_eval_js(wid, js);
        free(js);
    }
    free(escaped);
}

/*
 * csplash_update_progress — update progress bar width (0–100).
 */
static void
csplash_update_progress(int wid, int percent)
{
    char js[256];
    if (percent < 0)   percent = 0;
    if (percent > 100) percent = 100;
    snprintf(js, sizeof(js), CHANDRA_SPLASH_JS_PROGRESS, percent);
    cwin_eval_js(wid, js);
}

/*
 * csplash_close — destroy the splash window.
 */
static void
csplash_close(int wid)
{
    cwin_destroy(wid);
}

/*
 * csplash_is_open — 1 if the window is still alive, 0 otherwise.
 */
static int
csplash_is_open(int wid)
{
    return (wid > 0) ? cwin_exists(wid) : 0;
}

#endif /* CHANDRA_XS_IMPLEMENTATION */
#endif /* CHANDRA_SPLASH_H */
