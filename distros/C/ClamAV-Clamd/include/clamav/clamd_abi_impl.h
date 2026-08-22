/* clamd_abi_impl.h - the wrappers behind clamd_abi.h.
 *
 * Included by the root .xs AFTER the headers defining the real
 * functions. Not installed: a consumer vendors clamd_abi.h and never
 * sees this.
 */
#ifndef CLAMD_ABI_IMPL_H
#define CLAMD_ABI_IMPL_H

#include "clamav/clamd_abi.h"

/* A target is a cc_target plus the storage its char pointers reference.
 * cc_target borrows them, and an ABI consumer's strings are not this
 * dist's to keep alive. */
typedef struct {
    cc_target t;
    char     *path;
    char     *host;
} cca_target;

static void *cca_target_new(pTHX_ const char *socket_path,
                            const char *host, int port) {
    cca_target *g;

    PERL_UNUSED_CONTEXT;

    if (!socket_path && !host) return NULL;
    if (socket_path && host)   return NULL;

#ifndef _WIN32
    /* Refused, never truncated: a shortened sun_path connects to a
     * different socket, and believing an answer from an unidentified
     * peer is worse than not getting one. */
    if (socket_path && strlen(socket_path) >= CC_SUN_PATH_MAX) return NULL;
#else
    if (socket_path) return NULL;
#endif

    g = (cca_target *)malloc(sizeof *g);
    if (!g) return NULL;
    memset(g, 0, sizeof *g);

    g->path = socket_path ? cc_strdup(socket_path) : NULL;
    g->host = host        ? cc_strdup(host)        : NULL;
    if ((socket_path && !g->path) || (host && !g->host)) {
        free(g->path); free(g->host); free(g);
        return NULL;
    }

    g->t.path            = g->path;
    g->t.host            = g->host;
    g->t.port            = port > 0 ? port : 3310;
    g->t.connect_timeout = 5.0;
    g->t.reply_timeout   = 30.0;
    g->t.reply_max       = 1024 * 1024;
    g->t.frame           = CC_FRAME_Z;
    return g;
}

static void cca_target_timeouts(pTHX_ void *target, double ct, double rt) {
    cca_target *g = (cca_target *)target;
    PERL_UNUSED_CONTEXT;
    if (!g) return;
    if (ct > 0) g->t.connect_timeout = ct;
    if (rt > 0) g->t.reply_timeout   = rt;
}

static void cca_target_limits(pTHX_ void *target, size_t reply_max,
                              size_t chunk, size_t max_size) {
    cca_target *g = (cca_target *)target;
    PERL_UNUSED_CONTEXT;
    if (!g) return;
    if (reply_max) g->t.reply_max = reply_max;
    g->t.chunk    = chunk;
    g->t.max_size = max_size;
}

static void cca_target_free(pTHX_ void *target) {
    cca_target *g = (cca_target *)target;
    PERL_UNUSED_CONTEXT;
    if (!g) return;
    free(g->path); free(g->host); free(g);
}

/* A handle is always returned, even for a refusal, so verdict_state is
 * always answerable - the same rule the Perl side follows, for the same
 * reason: the safe reading has to be the short one. */
static cc_scan *cca_scan_new(void) {
    cc_scan *s = (cc_scan *)malloc(sizeof *s);
    if (!s) return NULL;
    memset(s, 0, sizeof *s);
    s->sock    = CC_INVALID_SOCK;
    s->scan_fd = -1;
    s->phase   = CC_PH_DONE;
    return s;
}

static int cca_pick_mode(const cc_target *t) {
    return (CC_HAVE_FD_PASSING && t->path) ? CC_TRANSPORT_FILDES
                                           : CC_TRANSPORT_INSTREAM;
}

static void *cca_start_fd(pTHX_ void *target, int fd, int blocking) {
    cca_target *g = (cca_target *)target;
    cc_scan *s;
    int mode;

    PERL_UNUSED_CONTEXT;
    if (!g) return NULL;
    s = cca_scan_new();
    if (!s) return NULL;

    {
        struct stat st;
        if (fstat(fd, &st) < 0) {
            cc_err_set(&s->err, CC_ERR_IO, "fstat", strerror(errno));
            s->rc = CC_ERR_IO; return s;
        }
        if (!S_ISREG(st.st_mode)) {
            cc_err_set(&s->err, CC_ERR_NOTREG, "not a regular file", NULL);
            s->rc = CC_ERR_NOTREG; return s;
        }
        if (g->t.max_size && (size_t)st.st_size > g->t.max_size) {
            cc_err_set(&s->err, CC_ERR_TOOBIGLOC,
                       "larger than max_size; refused without scanning", NULL);
            s->rc = CC_ERR_TOOBIGLOC; return s;
        }
    }

    mode = cca_pick_mode(&g->t);
    if (mode == CC_TRANSPORT_FILDES)
        (void)cc_scan_start(s, &g->t, mode, fd, 0, NULL, 0, -1);
    else
        (void)cc_scan_start(s, &g->t, mode, -1, 0, NULL, 0, fd);

    if (blocking) {
        char  *out = NULL;
        size_t n   = 0;
        cc_err e;
        (void)cc_scan_run(s, &out, &n, &e);
        /* cc_scan_run hands ownership out; put it straight back, because
         * the verdict is read from the handle. */
        s->reply = out; s->replylen = n;
    }
    return s;
}

static void *cca_start_mem(pTHX_ void *target, const char *buf, size_t len,
                           int blocking) {
    cca_target *g = (cca_target *)target;
    cc_scan *s;

    PERL_UNUSED_CONTEXT;
    if (!g) return NULL;
    s = cca_scan_new();
    if (!s) return NULL;

    if (g->t.max_size && len > g->t.max_size) {
        cc_err_set(&s->err, CC_ERR_TOOBIGLOC,
                   "larger than max_size; refused without scanning", NULL);
        s->rc = CC_ERR_TOOBIGLOC;
        return s;
    }

    (void)cc_scan_start(s, &g->t, CC_TRANSPORT_INSTREAM, -1, 0,
                        buf ? buf : "", len, -1);

    if (blocking) {
        char  *out = NULL;
        size_t n   = 0;
        cc_err e;
        (void)cc_scan_run(s, &out, &n, &e);
        s->reply = out; s->replylen = n;
    }
    return s;
}

static void *cca_scan_fd(pTHX_ void *t, int fd)  { return cca_start_fd(aTHX_ t, fd, 1); }
static void *cca_scan_mem(pTHX_ void *t, const char *b, size_t n) { return cca_start_mem(aTHX_ t, b, n, 1); }
static void *cca_scan_start_fd(pTHX_ void *t, int fd) { return cca_start_fd(aTHX_ t, fd, 0); }
static void *cca_scan_start_mem(pTHX_ void *t, const char *b, size_t n) { return cca_start_mem(aTHX_ t, b, n, 0); }

static int cca_scan_socket(pTHX_ void *scan) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    return s ? s->sock : -1;
}
static int cca_scan_want(pTHX_ void *scan) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    return (s && s->phase != CC_PH_DONE) ? s->want : CC_WANT_NONE;
}
static int cca_scan_step(pTHX_ void *scan) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    return s ? cc_scan_step(s) : CC_STEP_DONE;
}
static int cca_scan_done(pTHX_ void *scan) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    return (!s || s->phase == CC_PH_DONE) ? 1 : 0;
}
static void cca_scan_cancel(pTHX_ void *scan) {
    PERL_UNUSED_CONTEXT;
    if (scan) cc_scan_cancel((cc_scan *)scan);
}
static void cca_scan_free(pTHX_ void *scan) {
    PERL_UNUSED_CONTEXT;
    if (scan) { cc_scan_free((cc_scan *)scan); free(scan); }
}

static int cca_verdict_state(pTHX_ void *scan) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    if (!s) return CLAMD_ABI_ERROR;
    return cc_scan_verdict(s)->state;
}

static const char *cca_verdict_signature(pTHX_ void *scan, size_t *len) {
    cc_scan *s = (cc_scan *)scan;
    const cc_verdict *v;
    PERL_UNUSED_CONTEXT;
    if (len) *len = 0;
    if (!s) return NULL;
    v = cc_scan_verdict(s);
    if (!v->signature[0]) return NULL;
    if (len) *len = strlen(v->signature);
    return v->signature;
}

static const char *cca_verdict_reason(pTHX_ void *scan, size_t *len) {
    cc_scan *s = (cc_scan *)scan;
    const cc_verdict *v;
    PERL_UNUSED_CONTEXT;
    if (len) *len = 0;
    if (!s) return NULL;
    v = cc_scan_verdict(s);
    if (!v->reason[0]) return NULL;
    if (len) *len = strlen(v->reason);
    return v->reason;
}

static const char *cca_verdict_error(pTHX_ void *scan, size_t *len) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    if (len) *len = 0;
    if (!s || s->rc == CC_OK || !s->err.msg[0]) return NULL;
    if (len) *len = strlen(s->err.msg);
    return s->err.msg;
}

static int cca_verdict_transport(pTHX_ void *scan) {
    cc_scan *s = (cc_scan *)scan;
    PERL_UNUSED_CONTEXT;
    return s ? s->transport : CLAMD_ABI_TRANSPORT_NONE;
}

static const clamd_abi CLAMD_ABI = {
    CLAMD_ABI_VERSION,
    cca_target_new,
    cca_target_timeouts,
    cca_target_limits,
    cca_target_free,
    cca_scan_fd,
    cca_scan_mem,
    cca_scan_start_fd,
    cca_scan_start_mem,
    cca_scan_socket,
    cca_scan_want,
    cca_scan_step,
    cca_scan_done,
    cca_scan_cancel,
    cca_scan_free,
    cca_verdict_state,
    cca_verdict_signature,
    cca_verdict_reason,
    cca_verdict_error,
    cca_verdict_transport
};

#endif /* CLAMD_ABI_IMPL_H */
