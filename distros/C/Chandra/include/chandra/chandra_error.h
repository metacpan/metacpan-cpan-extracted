/*
 * chandra_error.h — Chandra::Error in C
 *
 * Implements: on_error, clear_handlers, handlers, capture,
 *             stack_trace, format_text, format_js_console
 *
 * Include with CHANDRA_XS_IMPLEMENTATION defined to get implementations.
 */
#ifndef CHANDRA_ERROR_H
#define CHANDRA_ERROR_H

#include "chandra.h"

/* ================================================================
 * Implementation-only section — compiled only in Chandra.xs
 * (CHANDRA_XS_IMPLEMENTATION is defined there before including us)
 * ================================================================ */
#ifdef CHANDRA_XS_IMPLEMENTATION

/* Global error handler registry */
struct chandra_error_ctx chandra_error_ctx = { .handler_count = 0 };

void chandra_error_add_handler(pTHX_ SV *handler) {
    if (!handler || !SvROK(handler) || SvTYPE(SvRV(handler)) != SVt_PVCV)
        return;
    if (chandra_error_ctx.handler_count >= CHANDRA_ERROR_MAX_HANDLERS)
        return;
    chandra_error_ctx.handlers[chandra_error_ctx.handler_count++] =
        SvREFCNT_inc(handler);
}

void chandra_error_clear_handlers(pTHX) {
    int i;
    for (i = 0; i < chandra_error_ctx.handler_count; i++) {
        if (chandra_error_ctx.handlers[i]) {
            SvREFCNT_dec(chandra_error_ctx.handlers[i]);
            chandra_error_ctx.handlers[i] = NULL;
        }
    }
    chandra_error_ctx.handler_count = 0;
}

AV *chandra_error_get_handlers(pTHX) {
    AV *av = newAV();
    int i;
    for (i = 0; i < chandra_error_ctx.handler_count; i++) {
        if (chandra_error_ctx.handlers[i]) {
            av_push(av, SvREFCNT_inc(chandra_error_ctx.handlers[i]));
        }
    }
    return av;
}

AV *chandra_error_stack_trace(pTHX_ int skip) {
    AV *trace = newAV();
    int level = skip;
    int count = 0;

    while (count < CHANDRA_ERROR_MAX_TRACE) {
        /* Use Perl's caller() by calling it as an op - simpler: just use
           the cx stack directly or call_pv.  The simplest correct approach
           is to replicate what caller() does. */
        const PERL_CONTEXT *cx;
        const PERL_CONTEXT *dbcx;
        I32 cxix;
        int found = 0;

        /* Walk up the context stack to find the frame at 'level' */
        {
            int seen = 0;
            for (cxix = cxstack_ix; cxix >= 0; cxix--) {
                cx = &cxstack[cxix];
                if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_EVAL) {
                    if (seen == level) {
                        found = 1;
                        break;
                    }
                    seen++;
                }
            }
        }

        if (!found) break;

        {
            HV *frame = newHV();
            const COP *cop = cx->blk_oldcop;

            (void)hv_stores(frame, "package",
                newSVpv(CopSTASHPV(cop), 0));
            (void)hv_stores(frame, "file",
                newSVpv(CopFILE(cop), 0));
            (void)hv_stores(frame, "line",
                newSViv(CopLINE(cop)));

            /* Get subroutine name */
            if (CxTYPE(cx) == CXt_SUB && CxHASARGS(cx)) {
                GV *gv = CvGV(cx->blk_sub.cv);
                if (gv) {
                    SV *fullname = newSVpvf("%s::%s",
                        HvNAME(GvSTASH(gv)), GvNAME(gv));
                    (void)hv_stores(frame, "sub", fullname);
                } else {
                    (void)hv_stores(frame, "sub", newSVpvs("(unknown)"));
                }
            } else if (CxTYPE(cx) == CXt_SUB) {
                GV *gv = CvGV(cx->blk_sub.cv);
                if (gv) {
                    SV *fullname = newSVpvf("%s::%s",
                        HvNAME(GvSTASH(gv)), GvNAME(gv));
                    (void)hv_stores(frame, "sub", fullname);
                } else {
                    (void)hv_stores(frame, "sub", newSVpvs("(unknown)"));
                }
            } else {
                (void)hv_stores(frame, "sub", newSVpvs("(eval)"));
            }

            av_push(trace, newRV_noinc((SV *)frame));
            count++;
        }
        level++;
    }

    return trace;
}

HV *chandra_error_capture(pTHX_ SV *error_sv, const char *context, int skip) {
    HV *err = newHV();
    SV *message_sv;
    STRLEN len;
    const char *raw;
    char *trimmed;
    AV *trace;
    int i;

    /* Stringify the error and trim trailing whitespace */
    if (error_sv && SvOK(error_sv)) {
        raw = SvPV(error_sv, len);
    } else {
        raw = "";
        len = 0;
    }

    /* Trim trailing whitespace */
    while (len > 0 && (raw[len-1] == ' ' || raw[len-1] == '\t' ||
                       raw[len-1] == '\n' || raw[len-1] == '\r')) {
        len--;
    }
    message_sv = newSVpvn(raw, len);

    (void)hv_stores(err, "message", message_sv);
    (void)hv_stores(err, "context", newSVpv(context, 0));

    trace = chandra_error_stack_trace(aTHX_ skip);
    (void)hv_stores(err, "trace", newRV_noinc((SV *)trace));

    (void)hv_stores(err, "time", newSViv((IV)time(NULL)));

    /* Call all registered handlers */
    for (i = 0; i < chandra_error_ctx.handler_count; i++) {
        SV *handler = chandra_error_ctx.handlers[i];
        if (handler && SvOK(handler)) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(newRV_inc((SV *)err));
            PUTBACK;
            call_sv(handler, G_DISCARD | G_EVAL);
            FREETMPS;
            LEAVE;
        }
    }

    return err;
}

SV *chandra_error_format_text(pTHX_ HV *err) {
    SV *result;
    SV **msg_sv  = hv_fetchs(err, "message", 0);
    SV **ctx_sv  = hv_fetchs(err, "context", 0);
    SV **trace_sv = hv_fetchs(err, "trace", 0);
    const char *msg = (msg_sv && *msg_sv && SvOK(*msg_sv)) ? SvPV_nolen(*msg_sv) : "";
    const char *ctx = (ctx_sv && *ctx_sv && SvOK(*ctx_sv)) ? SvPV_nolen(*ctx_sv) : "unknown";

    result = newSVpvf("[Chandra::%s] %s", ctx, msg);

    if (trace_sv && *trace_sv && SvROK(*trace_sv) &&
        SvTYPE(SvRV(*trace_sv)) == SVt_PVAV) {
        AV *trace = (AV *)SvRV(*trace_sv);
        SSize_t len = av_len(trace) + 1;
        SSize_t i;
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(trace, i, 0);
            if (elem && *elem && SvROK(*elem) &&
                SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *frame = (HV *)SvRV(*elem);
                SV **sub_sv  = hv_fetchs(frame, "sub", 0);
                SV **file_sv = hv_fetchs(frame, "file", 0);
                SV **line_sv = hv_fetchs(frame, "line", 0);
                const char *sub_name = (sub_sv && *sub_sv && SvOK(*sub_sv))
                    ? SvPV_nolen(*sub_sv) : "(main)";
                const char *file = (file_sv && *file_sv) ? SvPV_nolen(*file_sv) : "?";
                int line = (line_sv && *line_sv) ? (int)SvIV(*line_sv) : 0;
                sv_catpvf(result, "\n    %s at %s line %d", sub_name, file, line);
            }
        }
    }

    return result;
}

SV *chandra_error_format_js(pTHX_ HV *err) {
    SV *text = chandra_error_format_text(aTHX_ err);
    STRLEN len;
    const char *src = SvPV(text, len);
    SV *result;
    STRLEN i;

    /* Allocate enough for escaping: worst case 2x + wrapper */
    result = newSVpvs("console.error('");

    for (i = 0; i < len; i++) {
        char c = src[i];
        if (c == '\\') {
            sv_catpvs(result, "\\\\");
        } else if (c == '\'') {
            sv_catpvs(result, "\\'");
        } else if (c == '\n') {
            sv_catpvs(result, "\\n");
        } else {
            sv_catpvn(result, &c, 1);
        }
    }

    sv_catpvs(result, "')");
    SvREFCNT_dec(text);

    return result;
}

/* Generic callback helpers */
void chandra_call_sv(pTHX_ SV *callback, SV *arg) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if (arg)
        XPUSHs(arg);
    PUTBACK;
    call_sv(callback, G_DISCARD);
    FREETMPS;
    LEAVE;
}

void chandra_call_sv_iv(pTHX_ SV *callback, IV val) {
    chandra_call_sv(aTHX_ callback, sv_2mortal(newSViv(val)));
}

#endif /* CHANDRA_XS_IMPLEMENTATION */

#endif /* CHANDRA_ERROR_H */
