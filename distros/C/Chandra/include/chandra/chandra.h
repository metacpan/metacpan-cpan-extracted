#ifndef CHANDRA_H
#define CHANDRA_H

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Platform detection */
#if defined(__APPLE__)
#define WEBVIEW_COCOA 1
#elif defined(__linux__)
#define WEBVIEW_GTK 1
#elif defined(_WIN32)
#define WEBVIEW_WINAPI 1
#endif

/* Undo MULTIPLICITY malloc redefinitions for webview.h when it is
 * included with WEBVIEW_IMPLEMENTATION (in Chandra.xs only).
 * Other C files only need the struct/type declarations. */
#ifdef WEBVIEW_IMPLEMENTATION
#  ifdef MULTIPLICITY
#    undef malloc
#    undef calloc
#    undef realloc
#    undef free
#  endif
#endif

#include "webview.h"

/* ---- PerlChandra: wrapper struct for webview + Perl data ---- */

typedef struct {
    struct webview wv;
    SV *callback;
    int initialized;
    struct webview_tray tray;
    SV *tray_callback;
    int tray_active;
} PerlChandra;

/* ---- Extract PerlChandra* from an app's _webview ---- */
/* Returns NULL if app has no valid _webview or if _webview is not a Chandra */
#define CHANDRA_PC_FROM_APP(app_sv) \
    chandra_pc_from_app(aTHX_ (app_sv))

/* ---- Get _webview SV from app (for fallback Perl calls) ---- */
#define CHANDRA_WEBVIEW_SV(app_sv) \
    chandra_webview_sv(aTHX_ (app_sv))

static SV *
chandra_webview_sv(pTHX_ SV *app_sv)
{
    HV *app_hv;
    SV **wv_svp;
    if (!SvROK(app_sv)) return NULL;
    app_hv = (HV *)SvRV(app_sv);
    wv_svp = hv_fetchs(app_hv, "_webview", 0);
    if (!wv_svp || !SvOK(*wv_svp)) return NULL;
    return *wv_svp;
}

static PerlChandra *
chandra_pc_from_app(pTHX_ SV *app_sv)
{
    HV *app_hv;
    SV **wv_svp;
    SV *wv_sv;
    SV *wv_rv;
    svtype t;
    if (!SvROK(app_sv)) return NULL;
    app_hv = (HV *)SvRV(app_sv);
    wv_svp = hv_fetchs(app_hv, "_webview", 0);
    if (!wv_svp || !SvOK(*wv_svp)) return NULL;
    wv_sv = *wv_svp;
    if (!SvROK(wv_sv)) return NULL;
    wv_rv = SvRV(wv_sv);
    /* Mocks use hashes/arrays, real Chandra is a blessed IV scalar */
    t = SvTYPE(wv_rv);
    if (t == SVt_PVHV || t == SVt_PVAV || t == SVt_PVCV) return NULL;
    if (!SvIOK(wv_rv)) return NULL;  /* Must have valid IV */
    return INT2PTR(PerlChandra *, SvIV(wv_rv));
}

/* ---- Parse JSON menu string into tray items ---- */

static void
chandra_tray_parse_menu_json(const char *menu_json, struct webview_tray *tray)
{
    int item_idx = 0;

    if (!menu_json || strlen(menu_json) <= 2) return;

    {
        const char *p = menu_json;

        while (*p && item_idx < WEBVIEW_TRAY_MAX_ITEMS) {
            while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;

            if (*p == '[') { p++; continue; }
            if (*p == ']') break;
            if (*p == ',') { p++; continue; }

            if (*p == '{') {
                struct webview_tray_item *it = &tray->items[item_idx];
                memset(it, 0, sizeof(*it));
                p++;

                while (*p && *p != '}') {
                    const char *key_start;
                    int key_len;

                    while (*p == ' ' || *p == ',' || *p == '\t' || *p == '\n') p++;
                    if (*p == '}') break;
                    if (*p != '"') { p++; continue; }

                    p++;
                    key_start = p;
                    while (*p && *p != '"') p++;
                    key_len = (int)(p - key_start);
                    p++;

                    while (*p == ' ' || *p == ':') p++;

                    if (key_len == 2 && strncmp(key_start, "id", 2) == 0) {
                        it->id = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 5 && strncmp(key_start, "label", 5) == 0) {
                        if (*p == '"') {
                            const char *val_start;
                            int val_len;
                            char *label;
                            p++;
                            val_start = p;
                            while (*p && *p != '"') {
                                if (*p == '\\') p++;
                                p++;
                            }
                            val_len = (int)(p - val_start);
                            label = (char *)malloc(val_len + 1);
                            memcpy(label, val_start, val_len);
                            label[val_len] = '\0';
                            it->label = label;
                            if (*p == '"') p++;
                        }
                    } else if (key_len == 9 && strncmp(key_start, "separator", 9) == 0) {
                        it->is_separator = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 8 && strncmp(key_start, "disabled", 8) == 0) {
                        it->is_disabled = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 7 && strncmp(key_start, "checked", 7) == 0) {
                        it->is_checked = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else {
                        while (*p && *p != ',' && *p != '}') p++;
                    }
                }
                if (*p == '}') p++;
                item_idx++;
            } else {
                p++;
            }
        }
    }
    tray->item_count = item_idx;
}

/* ---- Free tray item labels ---- */

static void
chandra_tray_free_item_labels(struct webview_tray *tray)
{
    int i;
    for (i = 0; i < tray->item_count; i++) {
        if (tray->items[i].label) {
            free((char *)tray->items[i].label);
            tray->items[i].label = NULL;
        }
    }
}

/* ---- Escape JS string (backslash, single-quote, newline, CR) ---- */
/* Returns a new (non-mortal) SV with the escaped string.           */

static SV *
chandra_escape_js(pTHX_ SV *str_sv)
{
    const char *src;
    STRLEN src_len, i, j;
    char *buf;
    SV *result;

    src = SvPV(str_sv, src_len);
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
    result = newSVpvn(buf, j);
    Safefree(buf);
    return result;
}

/* ---- Safe string helpers using Perl memory ---- */

#define chandra_savepv(s) ((s) ? savepv(s) : NULL)
#define chandra_freepv(s) do { if (s) { Safefree((char*)(s)); (s) = NULL; } } while(0)

/* ---- Callback helpers ---- */

void chandra_call_sv(pTHX_ SV *callback, SV *arg);
void chandra_call_sv_iv(pTHX_ SV *callback, IV val);

/* ---- Error module ---- */

#define CHANDRA_ERROR_MAX_HANDLERS  32
#define CHANDRA_ERROR_MAX_TRACE     10

struct chandra_error_frame {
    char *package;
    char *file;
    int   line;
    char *sub_name;
};

struct chandra_error_ctx {
    SV *handlers[CHANDRA_ERROR_MAX_HANDLERS];
    int handler_count;
};

/* Global error context */
extern struct chandra_error_ctx chandra_error_ctx;

void  chandra_error_add_handler(pTHX_ SV *handler);
void  chandra_error_clear_handlers(pTHX);
AV   *chandra_error_get_handlers(pTHX);
HV   *chandra_error_capture(pTHX_ SV *error_sv, const char *context, int skip);
AV   *chandra_error_stack_trace(pTHX_ int skip);
SV   *chandra_error_format_text(pTHX_ HV *err);
SV   *chandra_error_format_js(pTHX_ HV *err);

/* ================================================================
 * Implementation-only section — compiled only in Chandra.xs
 * (CHANDRA_XS_IMPLEMENTATION is defined there before including us)
 * ================================================================ */
#ifdef CHANDRA_XS_IMPLEMENTATION

/* ---- Globals (single translation unit) ---- */

static SV *perl_callback = NULL;
static PerlInterpreter *my_perl_interp = NULL;

/* ---- Webview ↔ Perl callback bridges ---- */

static void external_invoke_cb(struct webview *w, const char *arg) {
    dTHX;
    if (perl_callback && SvOK(perl_callback)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(arg, 0)));
        PUTBACK;
        call_sv(perl_callback, G_DISCARD);
        FREETMPS; LEAVE;
    }
}

static void deferred_eval_cb(struct webview *w, void *arg) {
    char *js = (char *)arg;
    webview_eval(w, js);
    free(js);
}

static void tray_menu_cb(struct webview *w, int item_id) {
    dTHX;
    PerlChandra *pc = (PerlChandra *)((char *)w - offsetof(PerlChandra, wv));
    if (pc->tray_callback && SvOK(pc->tray_callback)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(item_id)));
        PUTBACK;
        call_sv(pc->tray_callback, G_DISCARD);
        FREETMPS; LEAVE;
    }
}

/* ---- Create PerlChandra struct and bless as "Chandra" ---- */
/* Returns a new (non-mortal) blessed SV.                     */

static SV *
chandra_create_pc(pTHX_ const char *title, const char *url,
                  int width, int height, int resizable,
                  int debug, SV *callback_sv)
{
    PerlChandra *pc;
    SV *sv;

    Newxz(pc, 1, PerlChandra);
    pc->wv.title     = savepv(title);
    pc->wv.url       = savepv(url);
    pc->wv.width     = width;
    pc->wv.height    = height;
    pc->wv.resizable = resizable;
    pc->wv.debug     = debug;
    pc->initialized  = 0;

    if (callback_sv && SvOK(callback_sv) && SvROK(callback_sv)) {
        perl_callback = SvREFCNT_inc(callback_sv);
        pc->callback  = perl_callback;
        pc->wv.external_invoke_cb = external_invoke_cb;
        my_perl_interp = PERL_GET_THX;
    } else {
        pc->wv.external_invoke_cb = NULL;
        pc->callback = NULL;
    }

    sv = sv_newmortal();
    sv_setref_pv(sv, "Chandra", (void *)pc);
    return newSVsv(sv);   /* non-mortal copy */
}

/* ---- Static XS callback for App navigate ---- */

static XS(xs_chandra_navigate_cb)
{
    dXSARGS;
    PERL_UNUSED_VAR(cv);
    {
        SV *target = get_sv("Chandra::App::_nav_target", 0);
        if (target && SvOK(target) && items > 0) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(target);
            XPUSHs(ST(0));
            PUTBACK;
            call_method("navigate", G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
    XSRETURN_EMPTY;
}

/* ---- Portable SIGPIPE suppression ---- */

typedef struct {
#ifdef SIGPIPE
    void (*old_handler)(int);
#else
    int dummy;
#endif
} SigpipeGuard;

static void sigpipe_ignore(SigpipeGuard *guard) {
#ifdef SIGPIPE
    guard->old_handler = signal(SIGPIPE, SIG_IGN);
#else
    (void)guard;
#endif
}

static void sigpipe_restore(SigpipeGuard *guard) {
#ifdef SIGPIPE
    signal(SIGPIPE, guard->old_handler);
#else
    (void)guard;
#endif
}

/* ---- Recursive directory walker for HotReload ---- */

#include <dirent.h>
static void
_hotreload_scan_recursive(pTHX_ const char *dir, HV *files_hv)
{
    DIR *dh;
    struct dirent *entry;

    dh = opendir(dir);
    if (!dh) return;

    while ((entry = readdir(dh)) != NULL) {
        const char *name = entry->d_name;
        SV *fullpath_sv;
        const char *fullpv;
        STRLEN fulllen;
        Stat_t st;

        if (name[0] == '.') {
            if (name[1] == '\0') continue;
            if (name[1] == '.' && name[2] == '\0') continue;
        }

        fullpath_sv = newSVpvf("%s/%s", dir, name);
        fullpv = SvPV(fullpath_sv, fulllen);

        if (PerlLIO_stat(fullpv, &st) == 0) {
            if (S_ISREG(st.st_mode)) {
                (void)hv_store(files_hv, fullpv, (I32)fulllen,
                    newSVnv((NV)st.st_mtime), 0);
            } else if (S_ISDIR(st.st_mode)) {
                _hotreload_scan_recursive(aTHX_ fullpv, files_hv);
            }
        }

        SvREFCNT_dec(fullpath_sv);
    }

    closedir(dh);
}

/* ---- DevTools static XS callbacks ---- */

static XS(xs_devtools_list_bindings)
{
    dXSARGS;
    PERL_UNUSED_VAR(cv);
    PERL_UNUSED_VAR(items);
    {
        dSP;
        int count;
        AV *result_av;
        SV *bind;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Bind")));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        bind = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(bind);
        PUTBACK;

        PUSHMARK(SP);
        XPUSHs(bind);
        PUTBACK;
        count = call_method("list", G_ARRAY);
        SPAGAIN;

        result_av = newAV();
        while (count-- > 0) {
            SV *name = POPs;
            const char *n = SvPV_nolen(name);
            if (strncmp(n, "__devtools_", 11) != 0) {
                av_push(result_av, newSVsv(name));
            }
        }
        PUTBACK;

        if (av_len(result_av) >= 1) {
            sortsv(AvARRAY(result_av), (size_t)(av_len(result_av) + 1),
                   Perl_sv_cmp);
        }

        SvREFCNT_dec(bind);

        {
            SV *retval = newRV_noinc((SV *)result_av);
            FREETMPS; LEAVE;
            ST(0) = sv_2mortal(retval);
        }
    }
    XSRETURN(1);
}

static XS(xs_devtools_reload_cb)
{
    dXSARGS;
    SV *dt = (SV *)CvXSUBANY(cv).any_ptr;
    PERL_UNUSED_VAR(items);

    if (dt && SvOK(dt) && SvROK(dt)) {
        HV *dt_hv = (HV *)SvRV(dt);
        SV **cb_svp = hv_fetchs(dt_hv, "reload_cb", 0);
        if (cb_svp && SvOK(*cb_svp)) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(*cb_svp, G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

    {
        HV *result = newHV();
        (void)hv_stores(result, "ok", newSViv(1));
        ST(0) = sv_2mortal(newRV_noinc((SV *)result));
    }
    XSRETURN(1);
}

static XS(xs_devtools_error_handler)
{
    dXSARGS;
    SV *dt = (SV *)CvXSUBANY(cv).any_ptr;
    SV *err_copy;

    if (!dt || !SvOK(dt) || !SvROK(dt) || items < 1)
        XSRETURN_EMPTY;

    err_copy = newSVsv(ST(0));

    {
        HV *dt_hv = (HV *)SvRV(dt);
        SV **enabled_svp = hv_fetchs(dt_hv, "enabled", 0);
        SV **app_svp = hv_fetchs(dt_hv, "app", 0);

        if (!enabled_svp || !SvTRUE(*enabled_svp)) XSRETURN_EMPTY;
        if (!app_svp || !SvOK(*app_svp)) XSRETURN_EMPTY;

        {
            dSP;
            int count;
            SV *msg;

            ENTER; SAVETMPS;

            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvs("Chandra::Error")));
            XPUSHs(err_copy);
            PUTBACK;
            count = call_method("format_text", G_SCALAR);
            SPAGAIN;
            msg = (count > 0) ? newSVsv(POPs) : newSVpvs("");
            PUTBACK;

            {
                STRLEN mlen;
                const char *m = SvPV(msg, mlen);
                const char *p;
                SV *js = newSVpvs(
                    "if(window.__chandraDevTools)window.__chandraDevTools.addError('");

                for (p = m; p < m + mlen; p++) {
                    if (*p == '\\')     sv_catpvs(js, "\\\\");
                    else if (*p == '\'') sv_catpvs(js, "\\'");
                    else if (*p == '\n') sv_catpvs(js, "\\n");
                    else                 sv_catpvn(js, p, 1);
                }
                sv_catpvs(js, "')");

                PUSHMARK(SP);
                XPUSHs(*app_svp);
                XPUSHs(sv_2mortal(js));
                PUTBACK;
                call_method("dispatch_eval", G_DISCARD | G_EVAL);
                if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
            }

            SvREFCNT_dec(msg);
            FREETMPS; LEAVE;
        }
    }
    SvREFCNT_dec(err_copy);
    XSRETURN_EMPTY;
}

/* ---- Protocol static XS callback ---- */

typedef struct {
    SV *handler;
    SV *json_encoder;
} ProtocolBindCtx;

static XS(xs_protocol_bound_callback)
{
    dXSARGS;
    ProtocolBindCtx *ctx = (ProtocolBindCtx *)CvXSUBANY(cv).any_ptr;
    SV *path = (items > 0) ? newSVsv(ST(0)) : newSVsv(&PL_sv_undef);
    SV *params_json = (items > 1) ? newSVsv(ST(1)) : newSVsv(&PL_sv_undef);
    SV *params;
    SV *result = &PL_sv_undef;

    params = newRV_noinc((SV *)newHV());
    if (SvOK(params_json) && SvCUR(params_json) > 0) {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(ctx->json_encoder);
        XPUSHs(params_json);
        PUTBACK;
        count = call_method("decode", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0 && !SvTRUE(ERRSV)) {
            SV *decoded = POPs;
            SvREFCNT_dec(params);
            params = newSVsv(decoded);
        }
        PUTBACK;
        FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
    }

    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(path));
        XPUSHs(sv_2mortal(params));
        PUTBACK;
        count = call_sv(ctx->handler, G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            result = newSVsv(POPs);
        }
        PUTBACK;
        FREETMPS; LEAVE;
    }

    SvREFCNT_dec(params_json);
    if (result == &PL_sv_undef) {
        ST(0) = &PL_sv_undef;
    } else {
        ST(0) = sv_2mortal(result);
    }
    XSRETURN(1);
}

#endif /* CHANDRA_XS_IMPLEMENTATION */

#endif /* CHANDRA_H */
