/*
 * Chandra.xs — Root XS file
 *
 * Thin wrapper: includes shared header, declares globals,
 * then pulls in per-module XS fragments via INCLUDE:.
 */

#define WEBVIEW_IMPLEMENTATION
#include "include/chandra/chandra.h"

/* Store Perl callback globally (prototype limitation) */
static SV *perl_callback = NULL;
static PerlInterpreter *my_perl_interp = NULL;

/* C callback that bridges to Perl */
static void external_invoke_cb(struct webview *w, const char *arg) {
    dTHX;
    if (perl_callback && SvOK(perl_callback)) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(arg, 0)));
        PUTBACK;
        
        call_sv(perl_callback, G_DISCARD);
        
        FREETMPS;
        LEAVE;
    }
}

/* Deferred eval_js callback for webview_dispatch */
static void deferred_eval_cb(struct webview *w, void *arg) {
    char *js = (char *)arg;
    webview_eval(w, js);
    free(js);
}

/* C callback that bridges tray menu actions to Perl */
static void tray_menu_cb(struct webview *w, int item_id) {
    dTHX;
    PerlChandra *pc = (PerlChandra *)((char *)w - offsetof(PerlChandra, wv));
    if (pc->tray_callback && SvOK(pc->tray_callback)) {
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(item_id)));
        PUTBACK;

        call_sv(pc->tray_callback, G_DISCARD);

        FREETMPS;
        LEAVE;
    }
}

MODULE = Chandra    PACKAGE = Chandra

INCLUDE: xs/core.xs
INCLUDE: xs/tray.xs
INCLUDE: xs/error.xs
