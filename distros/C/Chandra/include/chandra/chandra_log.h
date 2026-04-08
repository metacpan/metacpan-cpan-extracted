/*
 * chandra_log.h — Structured logging for Chandra
 *
 * Levels: debug(0), info(1), warn(2), error(3), fatal(4)
 * Outputs: stderr, file (with rotation + flock), callback
 * Formatters: text (default), json, minimal, custom coderef
 * Features: contextual child loggers via with(), structured data, DevTools bridge
 *
 * Include with CHANDRA_XS_IMPLEMENTATION defined to get implementations.
 */
#ifndef CHANDRA_LOG_H
#define CHANDRA_LOG_H

#include "chandra.h"
#include <sys/time.h>
#include <time.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>

#ifndef _WIN32
#include <sys/file.h>
#include <unistd.h>
#else
#include <windows.h>
#include <io.h>
#ifndef LOCK_EX
#define LOCK_EX 2
#define LOCK_UN 8
#endif
#endif

/* ============================================================
 * Constants
 * ============================================================ */

#define CHANDRA_LOG_DEBUG  0
#define CHANDRA_LOG_INFO   1
#define CHANDRA_LOG_WARN   2
#define CHANDRA_LOG_ERROR  3
#define CHANDRA_LOG_FATAL  4

/* Output types */
#define CHANDRA_LOG_OUT_STDERR   0
#define CHANDRA_LOG_OUT_STDOUT   1
#define CHANDRA_LOG_OUT_FILE     2
#define CHANDRA_LOG_OUT_CALLBACK 3

/* Formatter types */
#define CHANDRA_LOG_FMT_TEXT     0
#define CHANDRA_LOG_FMT_JSON     1
#define CHANDRA_LOG_FMT_MINIMAL  2
#define CHANDRA_LOG_FMT_CUSTOM   3

/* Max outputs per logger */
#define CHANDRA_LOG_MAX_OUTPUTS 16

/* Max rotated files */
#define CHANDRA_LOG_MAX_KEEP 100

/* ============================================================
 * Structures
 * ============================================================ */

typedef struct {
    int   type;        /* CHANDRA_LOG_OUT_* */
    int   level;       /* per-output level filter, -1 = use logger level */
    SV   *path;        /* file path (for file output) */
    SV   *callback;    /* coderef (for callback output) */
} chandra_log_output;

typedef struct {
    int    level;
    int    fmt_type;
    SV    *fmt_custom;  /* custom formatter coderef */
    HV    *context;     /* contextual key-value pairs */

    chandra_log_output outputs[CHANDRA_LOG_MAX_OUTPUTS];
    int    output_count;

    /* rotation config */
    IV     rotate_max_size;  /* 0 = no rotation */
    int    rotate_keep;      /* number of rotated files to keep */
} chandra_log_ctx;

/* ============================================================
 * Implementation
 * ============================================================ */
#ifdef CHANDRA_XS_IMPLEMENTATION

/* --- Level name lookup --- */

static const char *chandra_log_level_names[] = {
    "debug", "info", "warn", "error", "fatal"
};

static const char *chandra_log_level_NAMES[] = {
    "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
};

static int
chandra_log_parse_level(const char *name)
{
    if (strEQ(name, "debug")) return CHANDRA_LOG_DEBUG;
    if (strEQ(name, "info"))  return CHANDRA_LOG_INFO;
    if (strEQ(name, "warn"))  return CHANDRA_LOG_WARN;
    if (strEQ(name, "error")) return CHANDRA_LOG_ERROR;
    if (strEQ(name, "fatal")) return CHANDRA_LOG_FATAL;
    return CHANDRA_LOG_DEBUG;
}

/* --- Size parsing (e.g. "10M" → bytes) --- */

static IV
chandra_log_parse_size(pTHX_ SV *spec_sv)
{
    STRLEN len;
    const char *s;
    double num;
    char unit;
    char *end;

    if (!spec_sv || !SvOK(spec_sv))
        return 0;

    if (SvIOK(spec_sv))
        return SvIV(spec_sv);

    s = SvPV(spec_sv, len);
    num = strtod(s, &end);
    if (end == s) return 0;

    while (*end == ' ') end++;
    unit = *end;

    switch (unit) {
        case 'K': case 'k': return (IV)(num * 1024);
        case 'M': case 'm': return (IV)(num * 1024 * 1024);
        case 'G': case 'g': return (IV)(num * 1024 * 1024 * 1024);
        default:            return (IV)num;
    }
}

/* --- Extract ctx from blessed HV --- */

static chandra_log_ctx *
chandra_log_get_ctx(pTHX_ SV *self)
{
    SV **svp;
    HV *hv;

    if (!SvROK(self))
        croak("Chandra::Log: not a reference");
    hv = (HV *)SvRV(self);
    svp = hv_fetchs(hv, "_ctx", 0);
    if (!svp || !SvIOK(*svp))
        croak("Chandra::Log: invalid object (missing _ctx)");
    return INT2PTR(chandra_log_ctx *, SvIV(*svp));
}

/* --- Create a new ctx --- */

static chandra_log_ctx *
chandra_log_new_ctx(pTHX)
{
    chandra_log_ctx *ctx;
    Newxz(ctx, 1, chandra_log_ctx);
    ctx->level        = CHANDRA_LOG_DEBUG;
    ctx->fmt_type     = CHANDRA_LOG_FMT_TEXT;
    ctx->fmt_custom   = NULL;
    ctx->context      = newHV();
    ctx->output_count = 0;
    ctx->rotate_max_size = 0;
    ctx->rotate_keep     = 5;
    return ctx;
}

/* --- Free a ctx --- */

static void
chandra_log_free_ctx(pTHX_ chandra_log_ctx *ctx)
{
    int i;
    for (i = 0; i < ctx->output_count; i++) {
        if (ctx->outputs[i].path)
            SvREFCNT_dec(ctx->outputs[i].path);
        if (ctx->outputs[i].callback)
            SvREFCNT_dec(ctx->outputs[i].callback);
    }
    if (ctx->fmt_custom)
        SvREFCNT_dec(ctx->fmt_custom);
    if (ctx->context)
        SvREFCNT_dec((SV *)ctx->context);
    Safefree(ctx);
}

/* --- Add output to ctx --- */

static void
chandra_log_add_output_stderr(chandra_log_ctx *ctx)
{
    if (ctx->output_count >= CHANDRA_LOG_MAX_OUTPUTS) return;
    ctx->outputs[ctx->output_count].type     = CHANDRA_LOG_OUT_STDERR;
    ctx->outputs[ctx->output_count].level    = -1;
    ctx->outputs[ctx->output_count].path     = NULL;
    ctx->outputs[ctx->output_count].callback = NULL;
    ctx->output_count++;
}

static void
chandra_log_add_output_stdout(chandra_log_ctx *ctx)
{
    if (ctx->output_count >= CHANDRA_LOG_MAX_OUTPUTS) return;
    ctx->outputs[ctx->output_count].type     = CHANDRA_LOG_OUT_STDOUT;
    ctx->outputs[ctx->output_count].level    = -1;
    ctx->outputs[ctx->output_count].path     = NULL;
    ctx->outputs[ctx->output_count].callback = NULL;
    ctx->output_count++;
}

static void
chandra_log_add_output_file(chandra_log_ctx *ctx, SV *path, int level)
{
    if (ctx->output_count >= CHANDRA_LOG_MAX_OUTPUTS) return;
    ctx->outputs[ctx->output_count].type     = CHANDRA_LOG_OUT_FILE;
    ctx->outputs[ctx->output_count].level    = level;
    ctx->outputs[ctx->output_count].path     = SvREFCNT_inc(path);
    ctx->outputs[ctx->output_count].callback = NULL;
    ctx->output_count++;
}

static void
chandra_log_add_output_callback(chandra_log_ctx *ctx, SV *cb, int level)
{
    if (ctx->output_count >= CHANDRA_LOG_MAX_OUTPUTS) return;
    ctx->outputs[ctx->output_count].type     = CHANDRA_LOG_OUT_CALLBACK;
    ctx->outputs[ctx->output_count].level    = level;
    ctx->outputs[ctx->output_count].path     = NULL;
    ctx->outputs[ctx->output_count].callback = SvREFCNT_inc(cb);
    ctx->output_count++;
}

/* --- Parse output argument (scalar, hashref, or arrayref) --- */

static void
chandra_log_parse_output(pTHX_ chandra_log_ctx *ctx, SV *output)
{
    if (!SvOK(output)) {
        chandra_log_add_output_stderr(ctx);
        return;
    }

    if (SvROK(output) && SvTYPE(SvRV(output)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(output);
        SSize_t i, len = av_len(av) + 1;
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(av, i, 0);
            if (svp) chandra_log_parse_output(aTHX_ ctx, *svp);
        }
        return;
    }

    if (SvROK(output) && SvTYPE(SvRV(output)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(output);
        SV **file_svp = hv_fetchs(hv, "file", 0);
        SV **cb_svp   = hv_fetchs(hv, "callback", 0);
        SV **lv_svp   = hv_fetchs(hv, "level", 0);
        int  lvl      = -1;

        if (lv_svp && SvOK(*lv_svp))
            lvl = chandra_log_parse_level(SvPV_nolen(*lv_svp));

        if (file_svp && SvOK(*file_svp)) {
            chandra_log_add_output_file(ctx, *file_svp, lvl);
        } else if (cb_svp && SvROK(*cb_svp)) {
            chandra_log_add_output_callback(ctx, *cb_svp, lvl);
        }
        return;
    }

    /* Plain string */
    {
        const char *s = SvPV_nolen(output);
        if (strEQ(s, "stderr"))
            chandra_log_add_output_stderr(ctx);
        else if (strEQ(s, "stdout"))
            chandra_log_add_output_stdout(ctx);
    }
}

/* --- Timestamp --- */

static SV *
chandra_log_timestamp(pTHX)
{
    struct timeval tv;
    struct tm t;
    char buf[64];

    gettimeofday(&tv, NULL);
#ifdef _WIN32
    {
        struct tm *tp = localtime(&tv.tv_sec);
        if (tp) { t = *tp; } else { memset(&t, 0, sizeof(t)); }
    }
#else
    localtime_r(&tv.tv_sec, &t);
#endif
    snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d.%03d",
             t.tm_year + 1900, t.tm_mon + 1, t.tm_mday,
             t.tm_hour, t.tm_min, t.tm_sec,
             (int)(tv.tv_usec / 1000));
    return newSVpv(buf, 0);
}

/* --- Build log entry hash --- */

static HV *
chandra_log_build_entry(pTHX_ chandra_log_ctx *ctx, int level,
                        SV *message, SV *data)
{
    HV *entry = newHV();
    SV *ts = chandra_log_timestamp(aTHX);

    (void)hv_stores(entry, "timestamp", ts);
    (void)hv_stores(entry, "level",
                    newSVpv(chandra_log_level_names[level], 0));
    (void)hv_stores(entry, "message",
                    (message && SvOK(message))
                        ? newSVsv(message)
                        : newSVpvs(""));

    if (data && SvOK(data))
        (void)hv_stores(entry, "data", newSVsv(data));

    if (ctx->context && HvKEYS(ctx->context)) {
        HV *ctx_copy = newHVhv(ctx->context);
        (void)hv_stores(entry, "context", newRV_noinc((SV *)ctx_copy));
    }

    return entry;
}

/* --- JSON singleton (reuses Cpanel::JSON::XS) --- */

static SV *_log_json_obj = NULL;

static SV *
chandra_log_get_json(pTHX)
{
    if (!_log_json_obj || !SvOK(_log_json_obj)) {
        _log_json_obj = eval_pv(
            "require Cpanel::JSON::XS;"
            "Cpanel::JSON::XS->new->utf8->canonical->allow_nonref->convert_blessed",
            TRUE
        );
        SvREFCNT_inc_simple_void(_log_json_obj);
    }
    return _log_json_obj;
}

static SV *
chandra_log_json_encode(pTHX_ SV *val)
{
    dSP;
    SV *json = chandra_log_get_json(aTHX);
    int count;
    SV *result;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json);
    XPUSHs(val);
    PUTBACK;
    count = call_method("encode", G_SCALAR);
    SPAGAIN;
    result = (count > 0) ? SvREFCNT_inc(POPs) : newSVpvs("null");
    PUTBACK;
    FREETMPS; LEAVE;
    return result;
}

/* --- Hash to display string {k: "v", ...} --- */

static SV *
chandra_log_hash_to_str(pTHX_ HV *hv)
{
    SV *out;
    HE *he;
    int first = 1;

    if (!hv || !HvKEYS(hv))
        return newSVpvs("{}");

    out = newSVpvs("{");
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        I32 klen;
        const char *key = hv_iterkey(he, &klen);
        SV *val = hv_iterval(hv, he);

        if (!first) sv_catpvs(out, ", ");
        first = 0;

        sv_catpv(out, key);
        sv_catpvs(out, ": ");

        if (!SvOK(val)) {
            sv_catpvs(out, "undef");
        } else if (SvROK(val)) {
            SV *encoded = chandra_log_json_encode(aTHX_ val);
            sv_catsv(out, encoded);
            SvREFCNT_dec(encoded);
        } else {
            sv_catpvs(out, "\"");
            sv_catsv(out, val);
            sv_catpvs(out, "\"");
        }
    }
    sv_catpvs(out, "}");
    return out;
}

/* --- Formatters --- */

static SV *
chandra_log_format_text(pTHX_ HV *entry)
{
    SV **ts_svp  = hv_fetchs(entry, "timestamp", 0);
    SV **lv_svp  = hv_fetchs(entry, "level", 0);
    SV **msg_svp = hv_fetchs(entry, "message", 0);
    SV **dat_svp = hv_fetchs(entry, "data", 0);
    SV **ctx_svp = hv_fetchs(entry, "context", 0);
    SV *out;
    const char *lvl;

    /* Map level name to uppercase */
    lvl = (lv_svp && SvOK(*lv_svp)) ? SvPV_nolen(*lv_svp) : "debug";

    out = newSVpvs("[");
    if (ts_svp && SvOK(*ts_svp))
        sv_catsv(out, *ts_svp);
    sv_catpvs(out, "] [");
    {
        int i;
        for (i = 0; i < 5; i++) {
            if (strEQ(lvl, chandra_log_level_names[i])) {
                sv_catpv(out, chandra_log_level_NAMES[i]);
                break;
            }
        }
    }
    sv_catpvs(out, "] ");
    if (msg_svp && SvOK(*msg_svp))
        sv_catsv(out, *msg_svp);

    if (dat_svp && SvOK(*dat_svp) && SvROK(*dat_svp)
        && SvTYPE(SvRV(*dat_svp)) == SVt_PVHV) {
        SV *ds = chandra_log_hash_to_str(aTHX_ (HV *)SvRV(*dat_svp));
        sv_catpvs(out, " ");
        sv_catsv(out, ds);
        SvREFCNT_dec(ds);
    }

    if (ctx_svp && SvOK(*ctx_svp) && SvROK(*ctx_svp)
        && SvTYPE(SvRV(*ctx_svp)) == SVt_PVHV) {
        SV *cs = chandra_log_hash_to_str(aTHX_ (HV *)SvRV(*ctx_svp));
        sv_catpvs(out, " ");
        sv_catsv(out, cs);
        SvREFCNT_dec(cs);
    }

    sv_catpvs(out, "\n");
    return out;
}

static SV *
chandra_log_format_json(pTHX_ HV *entry)
{
    HV *obj = newHV();
    SV **svp;
    SV *encoded;

    svp = hv_fetchs(entry, "timestamp", 0);
    if (svp) (void)hv_stores(obj, "ts", newSVsv(*svp));

    svp = hv_fetchs(entry, "level", 0);
    if (svp) (void)hv_stores(obj, "level", newSVsv(*svp));

    svp = hv_fetchs(entry, "message", 0);
    if (svp) (void)hv_stores(obj, "msg", newSVsv(*svp));

    svp = hv_fetchs(entry, "data", 0);
    if (svp && SvOK(*svp)) (void)hv_stores(obj, "data", newSVsv(*svp));

    svp = hv_fetchs(entry, "context", 0);
    if (svp && SvOK(*svp)) (void)hv_stores(obj, "context", newSVsv(*svp));

    encoded = chandra_log_json_encode(aTHX_ newRV_noinc((SV *)obj));
    sv_catpvs(encoded, "\n");
    return encoded;
}

static SV *
chandra_log_format_minimal(pTHX_ HV *entry)
{
    SV **lv_svp  = hv_fetchs(entry, "level", 0);
    SV **msg_svp = hv_fetchs(entry, "message", 0);
    SV *out;
    const char *lvl;
    int i;

    lvl = (lv_svp && SvOK(*lv_svp)) ? SvPV_nolen(*lv_svp) : "debug";
    out = newSVpvs("");
    for (i = 0; i < 5; i++) {
        if (strEQ(lvl, chandra_log_level_names[i])) {
            sv_catpv(out, chandra_log_level_NAMES[i]);
            break;
        }
    }
    sv_catpvs(out, ": ");
    if (msg_svp && SvOK(*msg_svp))
        sv_catsv(out, *msg_svp);
    sv_catpvs(out, "\n");
    return out;
}

static SV *
chandra_log_format_custom(pTHX_ SV *formatter, HV *entry)
{
    dSP;
    int count;
    SV *result;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(newRV_noinc((SV *)entry));
    PUTBACK;
    count = call_sv(formatter, G_SCALAR);
    SPAGAIN;
    result = (count > 0) ? SvREFCNT_inc(POPs) : newSVpvs("");
    PUTBACK;
    FREETMPS; LEAVE;
    return result;
}

static SV *
chandra_log_format(pTHX_ chandra_log_ctx *ctx, HV *entry)
{
    switch (ctx->fmt_type) {
        case CHANDRA_LOG_FMT_JSON:
            return chandra_log_format_json(aTHX_ entry);
        case CHANDRA_LOG_FMT_MINIMAL:
            return chandra_log_format_minimal(aTHX_ entry);
        case CHANDRA_LOG_FMT_CUSTOM:
            /* For custom, entry HV ownership is transferred to formatter */
            return chandra_log_format_custom(aTHX_ ctx->fmt_custom,
                                             (HV *)newHVhv(entry));
        default:
            return chandra_log_format_text(aTHX_ entry);
    }
}

/* --- File rotation --- */

static void
chandra_log_maybe_rotate(pTHX_ chandra_log_ctx *ctx, const char *path)
{
    Stat_t st;
    int keep, i;
    char from[4096], to[4096];

    if (ctx->rotate_max_size <= 0)
        return;
    if (PerlLIO_stat(path, &st) != 0)
        return;
    if (st.st_size < ctx->rotate_max_size)
        return;

    keep = ctx->rotate_keep;
    if (keep > CHANDRA_LOG_MAX_KEEP)
        keep = CHANDRA_LOG_MAX_KEEP;

    /* Delete oldest */
    snprintf(to, sizeof(to), "%s.%d", path, keep);
    (void)PerlLIO_unlink(to);

    /* Shift existing */
    for (i = keep - 1; i >= 1; i--) {
        snprintf(from, sizeof(from), "%s.%d", path, i);
        snprintf(to,   sizeof(to),   "%s.%d", path, i + 1);
        (void)PerlLIO_rename(from, to);
    }

    /* Rotate current */
    snprintf(to, sizeof(to), "%s.1", path);
    (void)PerlLIO_rename(path, to);
}

/* --- Emit to a single output --- */

static void
chandra_log_emit(pTHX_ chandra_log_ctx *ctx, chandra_log_output *out,
                 int level, HV *entry, SV *formatted)
{
    /* Per-output level filter */
    if (out->level >= 0 && level < out->level)
        return;

    switch (out->type) {
        case CHANDRA_LOG_OUT_STDERR:
            {
                STRLEN len;
                const char *s = SvPV(formatted, len);
                PerlIO_write(PerlIO_stderr(), s, len);
                PerlIO_flush(PerlIO_stderr());
            }
            break;

        case CHANDRA_LOG_OUT_STDOUT:
            {
                STRLEN len;
                const char *s = SvPV(formatted, len);
                PerlIO_write(PerlIO_stdout(), s, len);
                PerlIO_flush(PerlIO_stdout());
            }
            break;

        case CHANDRA_LOG_OUT_FILE:
            {
                const char *path = SvPV_nolen(out->path);
                PerlIO *fh;

                chandra_log_maybe_rotate(aTHX_ ctx, path);

                fh = PerlIO_open(path, "a");
                if (fh) {
                    STRLEN len;
                    const char *s = SvPV(formatted, len);
#ifndef _WIN32
                    flock(PerlIO_fileno(fh), LOCK_EX);
#endif
                    PerlIO_write(fh, s, len);
#ifndef _WIN32
                    flock(PerlIO_fileno(fh), LOCK_UN);
#endif
                    PerlIO_close(fh);
                }
            }
            break;

        case CHANDRA_LOG_OUT_CALLBACK:
            {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_inc((SV *)entry)));
                PUTBACK;
                call_sv(out->callback, G_DISCARD);
                FREETMPS; LEAVE;
            }
            break;
    }
}

/* --- Core log dispatch --- */

static void
chandra_log_dispatch(pTHX_ chandra_log_ctx *ctx, int level,
                     SV *message, SV *data)
{
    HV *entry;
    SV *formatted;
    int i;

    if (level < ctx->level)
        return;

    entry     = chandra_log_build_entry(aTHX_ ctx, level, message, data);
    formatted = chandra_log_format(aTHX_ ctx, entry);

    for (i = 0; i < ctx->output_count; i++) {
        chandra_log_emit(aTHX_ ctx, &ctx->outputs[i], level,
                         entry, formatted);
    }

    SvREFCNT_dec(formatted);
    SvREFCNT_dec((SV *)entry);
}

/* --- DevTools bridge helper --- */

static SV *
chandra_log_devtools_entry(pTHX_ HV *entry)
{
    HV *result = newHV();
    SV **lv_svp  = hv_fetchs(entry, "level", 0);
    SV **msg_svp = hv_fetchs(entry, "message", 0);
    SV **dat_svp = hv_fetchs(entry, "data", 0);
    const char *lvl;
    const char *method;
    SV *msg;

    lvl = (lv_svp && SvOK(*lv_svp)) ? SvPV_nolen(*lv_svp) : "debug";

    if (strEQ(lvl, "warn"))
        method = "console.warn";
    else if (strEQ(lvl, "error") || strEQ(lvl, "fatal"))
        method = "console.error";
    else
        method = "console.log";

    (void)hv_stores(result, "method", newSVpv(method, 0));

    msg = (msg_svp && SvOK(*msg_svp)) ? newSVsv(*msg_svp) : newSVpvs("");
    if (dat_svp && SvOK(*dat_svp)) {
        SV *encoded = chandra_log_json_encode(aTHX_ *dat_svp);
        sv_catpvs(msg, " ");
        sv_catsv(msg, encoded);
        SvREFCNT_dec(encoded);
    }
    (void)hv_stores(result, "message", msg);

    return newRV_noinc((SV *)result);
}

#endif /* CHANDRA_XS_IMPLEMENTATION */
#endif /* CHANDRA_LOG_H */
