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

#endif /* CHANDRA_H */
