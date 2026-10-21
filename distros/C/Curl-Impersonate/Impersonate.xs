#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ctype.h>
#include <string.h>
#include <curl/curl.h>

typedef struct { CURL *easy; } ci_t;

struct buf { char *data; size_t len; };

struct ci_multi_s;

/* One queued async request. Lives from add() until its DONE callback fires. */
typedef struct ci_req_s {
    CURL *easy;                /* borrowed from the owning ci_t */
    SV   *cb;                  /* completion callback / on_done (owns a ref) */
    SV   *owner;              /* ref to the Curl::Impersonate, keeps easy alive */
    struct buf body;           /* response body accumulator (buffered mode) */
    HV   *headers;             /* response headers (owns a ref) */
    struct curl_slist *hlist;  /* request headers, freed on completion */
    SV   *on_headers;          /* streaming: fired once with (status, headers) */
    SV   *on_body;             /* streaming: fired per chunk; truthy return pauses */
    int   streaming;           /* 1 = streaming mode (cb is on_done) */
    int   headers_sent;        /* 1 = on_headers already fired */
    struct ci_multi_s *m;      /* owning multi (for tracking-list unlink) */
    struct ci_req_s *next, *prev;  /* intrusive list of the multi's in-flight reqs */
} ci_req;

typedef struct ci_multi_s {
    CURLM *multi;
    SV    *socket_cb;
    SV    *timer_cb;
    int    still_running;
    ci_req *reqs;              /* head of in-flight requests (for DESTROY reaping) */
} ci_multi;

/* Detach a request from the multi's tracking list. Idempotent (r->m NULL after),
   so it is safe to call before the completion callback AND again in free_ci_req. */
static void unlink_req(ci_req *r) {
    if (r->m) {
        if (r->prev) r->prev->next = r->next; else r->m->reqs = r->next;
        if (r->next) r->next->prev = r->prev;
        r->m = NULL;
    }
}

/* Free a request's resources (not its callbacks' side effects). */
static void free_ci_req(pTHX_ ci_req *r) {
    unlink_req(r);
    if (r->hlist) curl_slist_free_all(r->hlist);
    Safefree(r->body.data);
    SvREFCNT_dec((SV *) r->headers);
    SvREFCNT_dec(r->cb);
    SvREFCNT_dec(r->owner);
    if (r->streaming) { SvREFCNT_dec(r->on_headers); SvREFCNT_dec(r->on_body); }
    Safefree(r);
}

static void link_req(ci_multi *m, ci_req *r) {
    r->m = m; r->prev = NULL; r->next = m->reqs;
    if (m->reqs) m->reqs->prev = r;
    m->reqs = r;
}

static size_t body_cb(char *p, size_t s, size_t n, void *u){
    struct buf *b = (struct buf *) u;
    size_t add = s * n;
    Renew(b->data, b->len + add + 1, char);
    memcpy(b->data + b->len, p, add);
    b->len += add;
    b->data[b->len] = 0;
    return add;
}

static size_t hdr_cb(char *p, size_t s, size_t n, void *u){
    dTHX;
    HV *h = (HV *) u;
    size_t len = s * n;
    char *c;
    /* A new status line starts a new response block (a redirect hop under
       follow_redirects, or a 1xx/103 interim). Reset the accumulator so the result
       carries ONLY the final response's headers, not earlier hops merged in (which
       silently turned singular headers into arrayrefs and leaked 3xx-only ones). */
    if (len >= 5 && memcmp(p, "HTTP/", 5) == 0) { hv_clear(h); return len; }
    c = (char *) memchr(p, ':', len);
    if (c) {
        size_t klen = (size_t)(c - p);
        const char *v = c + 1;
        size_t vlen = (size_t)((p + len) - v);
        while (vlen && (*v==' '||*v=='\t')) { v++; vlen--; }
        while (vlen && (v[vlen-1]=='\r'||v[vlen-1]=='\n'||v[vlen-1]==' ')) vlen--;
        {
            SV *key = sv_2mortal(newSVpvn(p, klen));
            SV *val = newSVpvn(v, vlen);
            SV **existing;
            char *k;
            for (k = SvPVX(key); *k; k++) *k = (char) tolower((unsigned char)*k);
            existing = hv_fetch(h, SvPVX(key), (I32) klen, 0);
            if (existing && SvOK(*existing)) {
                /* a repeated header (e.g. Set-Cookie): keep every value as an arrayref */
                AV *av;
                if (SvROK(*existing) && SvTYPE(SvRV(*existing)) == SVt_PVAV) {
                    av = (AV *) SvRV(*existing);
                } else {
                    av = newAV();
                    av_push(av, newSVsv(*existing));   /* preserve the first value */
                    (void) hv_store(h, SvPVX(key), (I32) klen, newRV_noinc((SV *) av), 0);
                }
                av_push(av, val);
            } else {
                (void) hv_store(h, SvPVX(key), (I32) klen, val, 0);
            }
        }
    }
    return len;
}

/* CR, LF or NUL in a header name or value would split the request: libcurl
   passes such a line through verbatim, so "good\r\nX-Injected: yes" arrives at
   the origin as two headers. None of the three is legal in a header, so reject
   rather than silently strip -- stripping would quietly change what was sent. */
static int hdr_bad_char(const char *s, STRLEN len) {
    STRLEN i;
    for (i = 0; i < len; i++)
        if (s[i] == '\r' || s[i] == '\n' || s[i] == '\0') return 1;
    return 0;
}

static int cmp_hdr_line(const void *a, const void *b) {
    return strcmp(*(const char * const *) a, *(const char * const *) b);
}

/* Apply URL/method/body/headers + response sinks to an easy handle.
   Returns the request-header slist (caller frees after the transfer). */
static struct curl_slist *apply_request(CURL *easy, const char *method,
        const char *url, SV *headers_hv, SV *body_sv, struct buf *body, HV *rh) {
    dTHX;
    struct curl_slist *hlist = NULL;
    STRLEN blen = 0;
    int post = strcmp(method, "POST") == 0;
    int body_method = post || strcmp(method, "PUT") == 0 || strcmp(method, "PATCH") == 0;
    curl_easy_setopt(easy, CURLOPT_URL, url);
    curl_easy_setopt(easy, CURLOPT_CUSTOMREQUEST, method);
    if (SvOK(body_sv)) { const char *bp = SvPV(body_sv, blen);
        if (blen) {
            curl_easy_setopt(easy, CURLOPT_POSTFIELDSIZE, (long) blen);
            curl_easy_setopt(easy, CURLOPT_COPYPOSTFIELDS, bp);  /* curl copies */
        }
    }
    if (!blen) {
        /* An empty body on a body-bearing method still frames Content-Length: 0
           (as Chrome does for an empty POST/PUT). Other methods reset to GET --
           NOT POSTFIELDS=NULL, which leaves method=POST and emits a bogus
           Content-Type/Length on a bodyless GET. CUSTOMREQUEST sets the verb. */
        if (body_method) {
            curl_easy_setopt(easy, CURLOPT_POSTFIELDSIZE, (long) 0);
            curl_easy_setopt(easy, CURLOPT_COPYPOSTFIELDS, "");
        } else {
            curl_easy_setopt(easy, CURLOPT_HTTPGET, 1L);
        }
    }
    if (strcmp(method, "HEAD") == 0)
        curl_easy_setopt(easy, CURLOPT_NOBODY, 1L);
    else if (blen || body_method) {
        curl_easy_setopt(easy, CURLOPT_NOBODY, 0L);
        /* COPYPOSTFIELDS also backs PUT/PATCH; preserve those uploads on 301/302. */
        curl_easy_setopt(easy, CURLOPT_POSTREDIR, post
            ? 0L : (long) (CURL_REDIR_POST_301 | CURL_REDIR_POST_302));
    }
    if (SvROK(headers_hv) && SvTYPE(SvRV(headers_hv)) == SVt_PVHV) {
        HV *hv = (HV *) SvRV(headers_hv); I32 nk = hv_iterinit(hv);
        if (nk > 0) {
            char **lines; HE *e; I32 i = 0, j;
            Newx(lines, nk, char *);
            while ((e = hv_iternext(hv)) && i < nk) {
                STRLEN kl; char *k = HePV(e, kl);
                SV *hval = HeVAL(e);
                STRLEN vl = 0;
                const char *vp = SvOK(hval) ? SvPV(hval, vl) : "";
                if (hdr_bad_char(k, kl) || hdr_bad_char(vp, vl)) {
                    Safefree(lines);
                    croak("Curl::Impersonate: header '%s' contains CR, LF or NUL", k);
                }
                /* an undef value removes the header (curl disables an internal/
                   template header given "Header:" with nothing after the colon);
                   a defined value sets it */
                SV *line = SvOK(hval)
                    ? sv_2mortal(newSVpvf("%s: %s", k, SvPV_nolen(hval)))
                    : sv_2mortal(newSVpvf("%s:", k));
                lines[i++] = SvPVX(line);
            }
            qsort(lines, (size_t) i, sizeof(char *), cmp_hdr_line);  /* deterministic order */
            for (j = 0; j < i; j++) hlist = curl_slist_append(hlist, lines[j]);
            Safefree(lines);
        }
    }
    curl_easy_setopt(easy, CURLOPT_HTTPHEADER, hlist);   /* always: NULL clears a prior list */
    curl_easy_setopt(easy, CURLOPT_WRITEFUNCTION, body_cb);
    curl_easy_setopt(easy, CURLOPT_WRITEDATA, body);
    curl_easy_setopt(easy, CURLOPT_HEADERFUNCTION, hdr_cb);
    curl_easy_setopt(easy, CURLOPT_HEADERDATA, rh);
    return hlist;
}

/* Streaming write callback: fire on_headers once, then on_body per chunk.
   on_body returns 0/undef=continue, a true value=pause (CURLPAUSE_RECV), or the
   value 2=abort the transfer. WRITEDATA is the ci_req itself (set by
   add_streaming, overriding apply_request's &body). Callbacks must NOT free this
   request (do not call remove/resume from inside a streaming callback). */
static size_t body_cb_stream(char *p, size_t s, size_t n, void *u){
    dTHX;
    ci_req *r = (ci_req *) u;
    size_t len = s * n;
    IV act = 0;   /* 0=continue, 1=pause, 2=abort */
    if (!r->headers_sent) {
        r->headers_sent = 1;
        if (SvROK(r->on_headers)) {
            long code = 0;
            curl_easy_getinfo(r->easy, CURLINFO_RESPONSE_CODE, &code);
            {
                dSP; ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSViv(code)));
                XPUSHs(sv_2mortal(newRV_inc((SV *) r->headers)));
                PUTBACK;
                call_sv(r->on_headers, G_VOID|G_DISCARD|G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    warn("Curl::Impersonate on_headers died: %s", SvPV_nolen(ERRSV));
                    FREETMPS; LEAVE;
                    return 0;
                }
                FREETMPS; LEAVE;
            }
        }
    }
    if (SvROK(r->on_body)) {
        int cnt; dSP; ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvn(p, len)));
        PUTBACK;
        cnt = call_sv(r->on_body, G_SCALAR|G_EVAL);
        SPAGAIN;
        if (cnt) {                            /* G_SCALAR always returns one item; pop it */
            SV *rv = POPs;
            if (SvTRUE(ERRSV)) {
                warn("Curl::Impersonate on_body died: %s", SvPV_nolen(ERRSV));
                act = 2;
            }
            else act = SvTRUE(rv) ? (SvIV(rv) == 2 ? 2 : 1) : 0;   /* true=pause, 2=abort */
        }
        PUTBACK;
        FREETMPS; LEAVE;
    }
    if (act == 2) return 0;                          /* abort: != len tells curl to stop */
    /* PAUSE tells curl the chunk was NOT consumed; curl re-delivers it to on_body
       on resume. The documented on_body contract is therefore pause-before-consume
       (do not consume $chunk when returning a pause value); the re-delivery then
       hands it over exactly once. See the add_streaming POD. */
    return act ? CURL_WRITEFUNC_PAUSE : len;          /* any other true value = pause */
}

/* Fire a request's completion callback with ($res, $err), then free it. */
static void dispatch_done(ci_req *r, CURLcode result) {
    dTHX; dSP;
    /* Detach this finished request from m->reqs BEFORE running its callback. The
       callback may re-enter perform_blocking (whose loop condition is
       `still || m->reqs`); if this request were still linked it would spin forever,
       since it can only be freed after the callback -- which can only return after
       the inner loop exits. free_ci_req's unlink then becomes a no-op. */
    unlink_req(r);
    ENTER; SAVETMPS;
    SV *err_sv;
    if (r->streaming && result == CURLE_OK && !r->headers_sent && SvROK(r->on_headers)) {
        /* bodyless response (204/304/HEAD/Content-Length:0): on_body never fired,
           so deliver on_headers here before on_done, else the consumer gets nothing */
        long code = 0;
        curl_easy_getinfo(r->easy, CURLINFO_RESPONSE_CODE, &code);
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(code)));
        XPUSHs(sv_2mortal(newRV_inc((SV *) r->headers)));
        PUTBACK;
        call_sv(r->on_headers, G_VOID|G_DISCARD|G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("Curl::Impersonate on_headers died: %s", SvPV_nolen(ERRSV));
            result = CURLE_ABORTED_BY_CALLBACK;
        }
        r->headers_sent = 1;
    }
    err_sv = (result != CURLE_OK)
        ? sv_2mortal(newSVpv(curl_easy_strerror(result), 0)) : &PL_sv_undef;
    if (SvROK(r->cb)) {                    /* a missing on_done is allowed -> just no completion call */
        PUSHMARK(SP);
        if (r->streaming) {
            XPUSHs(err_sv);                /* on_done($err); headers/body already delivered */
        } else {
            SV *res_sv = &PL_sv_undef;
            if (result == CURLE_OK) {
                long code = 0;
                char *eurl = NULL;
                HV *res = (HV *) sv_2mortal((SV *) newHV());
                curl_easy_getinfo(r->easy, CURLINFO_RESPONSE_CODE, &code);
                (void) hv_stores(res, "status",  newSViv(code));
                (void) hv_stores(res, "headers", newRV_inc((SV *) r->headers));
                (void) hv_stores(res, "body",
                    r->body.data ? newSVpvn(r->body.data, r->body.len) : newSVpvs(""));
                if (curl_easy_getinfo(r->easy, CURLINFO_EFFECTIVE_URL, &eurl) == CURLE_OK && eurl)
                    (void) hv_stores(res, "url", newSVpv(eurl, 0));
                res_sv = sv_2mortal(newRV_inc((SV *) res));
            }
            XPUSHs(res_sv);
            XPUSHs(err_sv);
        }
        PUTBACK;
        call_sv(r->cb, G_VOID|G_DISCARD|G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV))
            warn("Curl::Impersonate::Multi callback died: %s", SvPV_nolen(ERRSV));
    }
    FREETMPS; LEAVE;
    free_ci_req(aTHX_ r);
}

/* Reap finished transfers and dispatch their callbacks. */
static void drain_done(ci_multi *m) {
    CURLMsg *msg; int q;
    while ((msg = curl_multi_info_read(m->multi, &q))) {
        if (msg->msg == CURLMSG_DONE) {
            CURL *e = msg->easy_handle;
            CURLcode result = msg->data.result;
            ci_req *r = NULL;
            curl_easy_getinfo(e, CURLINFO_PRIVATE, &r);
            curl_easy_setopt(e, CURLOPT_PRIVATE, NULL);
            curl_multi_remove_handle(m->multi, e);
            if (r) dispatch_done(r, result);
        }
    }
}

static int socket_fn(CURL *e, curl_socket_t s, int what, void *userp, void *sockp) {
    dTHX; dSP;
    ci_multi *m = (ci_multi *) userp;
    PERL_UNUSED_VAR(e); PERL_UNUSED_VAR(sockp);
    if (!m->socket_cb) return 0;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((int) s)));
    XPUSHs(sv_2mortal(newSViv(what)));
    PUTBACK;
    call_sv(m->socket_cb, G_VOID|G_DISCARD|G_EVAL);
    FREETMPS; LEAVE;
    return 0;
}

static int timer_fn(CURLM *multi, long timeout_ms, void *userp) {
    dTHX; dSP;
    ci_multi *m = (ci_multi *) userp;
    PERL_UNUSED_VAR(multi);
    if (!m->timer_cb) return 0;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(timeout_ms)));
    PUTBACK;
    call_sv(m->timer_cb, G_VOID|G_DISCARD|G_EVAL);
    FREETMPS; LEAVE;
    return 0;
}

MODULE = Curl::Impersonate    PACKAGE = Curl::Impersonate

BOOT:
    curl_global_init(CURL_GLOBAL_DEFAULT);

SV *
_new(klass)
    const char *klass
  PREINIT:
    ci_t *self;
    SV *ref;
  CODE:
    Newxz(self, 1, ci_t);
    self->easy = curl_easy_init();
    if (!self->easy) { Safefree(self); croak("Curl::Impersonate: curl_easy_init failed"); }
    ref = newSV(0);
    sv_setref_pv(ref, klass, (void *) self);
    RETVAL = ref;
  OUTPUT:
    RETVAL

void
DESTROY(self_sv)
    SV *self_sv
  PREINIT:
    ci_t *self;
  CODE:
    self = (ci_t *) SvIV((SV *) SvRV(self_sv));
    if (self) { if (self->easy) curl_easy_cleanup(self->easy); Safefree(self); }

int
impersonate(self_sv, target, default_headers = 1)
    SV *self_sv
    const char *target
    int default_headers
  PREINIT:
    ci_t *self;
  CODE:
    self = (ci_t *) SvIV((SV *) SvRV(self_sv));
    RETVAL = (int) curl_easy_impersonate(self->easy, target, default_headers);
    if (RETVAL == 0)   /* h2 only over TLS (ALPN) -- avoid the h2c Upgrade headers a
                          real Chrome never sends on cleartext */
        curl_easy_setopt(self->easy, CURLOPT_HTTP_VERSION, (long) CURL_HTTP_VERSION_2TLS);
  OUTPUT:
    RETVAL

void
targets(klass)
    const char *klass
  PPCODE:
    PERL_UNUSED_VAR(klass);
    /* No target-list API in the library, so this is a curated set, verified
       against the 2.1.1 build Alien::curlimpersonate 0.02 provides (sorted).
       Any other name that library accepts also works when passed to new(). */
    {
        static const char * const list[] = {
            "chrome100","chrome101","chrome104","chrome107","chrome110",
            "chrome116","chrome119","chrome120","chrome123","chrome124",
            "chrome131","chrome131_android","chrome133a","chrome136",
            "chrome142","chrome145","chrome146","chrome150","chrome99",
            "chrome99_android","edge101","edge99","firefox133","firefox135",
            "firefox144","firefox147","safari153","safari155","safari170",
            "safari172_ios","safari180","safari180_ios","safari184",
            "safari184_ios","safari260","safari2601","safari260_ios","tor145", NULL
        };
        const char * const *t = list;
        for (; *t; t++) mXPUSHp(*t, strlen(*t));
    }

void
_setopt_defaults(self_sv, opt_hv)
    SV *self_sv
    SV *opt_hv
  PREINIT:
    ci_t *self; HV *o; SV **sv;
  CODE:
    self = (ci_t *) SvIV((SV *) SvRV(self_sv));
    o = (HV *) SvRV(opt_hv);
    if ((sv = hv_fetchs(o, "timeout", 0)) && SvOK(*sv))
        curl_easy_setopt(self->easy, CURLOPT_TIMEOUT, (long) SvIV(*sv));
    {
        long on = 1;
        if ((sv = hv_fetchs(o, "verify", 0)) && SvOK(*sv)) on = SvTRUE(*sv) ? 1 : 0;
        curl_easy_setopt(self->easy, CURLOPT_SSL_VERIFYPEER, on);
        curl_easy_setopt(self->easy, CURLOPT_SSL_VERIFYHOST, on ? 2L : 0L);
    }
    if ((sv = hv_fetchs(o, "follow_redirects", 0)) && SvTRUE(*sv))
        curl_easy_setopt(self->easy, CURLOPT_FOLLOWLOCATION, CURLFOLLOW_OBEYCODE);
    if ((sv = hv_fetchs(o, "proxy", 0)) && SvOK(*sv))
        curl_easy_setopt(self->easy, CURLOPT_PROXY, SvPV_nolen(*sv));
    /* "" enables every built-in decoder without pinning a list. The header the
       impersonate target installs is a custom one, and a custom header of the
       same name replaces libcurl's generated Accept-Encoding rather than adding
       to it -- so the bytes on the wire stay the target's and only the decoding
       changes. */
    if ((sv = hv_fetchs(o, "decode", 0)) && SvTRUE(*sv))
        curl_easy_setopt(self->easy, CURLOPT_ACCEPT_ENCODING, "");

SV *
_request(self_sv, method, url, headers_hv, body_sv)
    SV *self_sv
    const char *method
    const char *url
    SV *headers_hv
    SV *body_sv
  PREINIT:
    ci_t *self; struct buf body = {0,0}; HV *rh; HV *res; CURLcode rc;
    struct curl_slist *hlist = NULL; long code = 0;
  CODE:
    self = (ci_t *) SvIV((SV *) SvRV(self_sv));
    {   /* a handle already queued on a Multi must not also perform synchronously */
        ci_req *inuse = NULL;
        curl_easy_getinfo(self->easy, CURLINFO_PRIVATE, &inuse);
        if (inuse) croak("Curl::Impersonate: handle is in use by a Multi (one request at a time)");
    }
    rh = (HV *) sv_2mortal((SV *) newHV());
    hlist = apply_request(self->easy, method, url, headers_hv, body_sv, &body, rh);
    rc = curl_easy_perform(self->easy);
    if (hlist) { curl_easy_setopt(self->easy, CURLOPT_HTTPHEADER, (struct curl_slist *)NULL); curl_slist_free_all(hlist); }
    res = (HV *) sv_2mortal((SV *) newHV());
    if (rc != CURLE_OK) {
        (void) hv_stores(res, "error", newSVpv(curl_easy_strerror(rc), 0));
        (void) hv_stores(res, "code",  newSViv((int) rc));
    } else {
        char *eurl = NULL;
        curl_easy_getinfo(self->easy, CURLINFO_RESPONSE_CODE, &code);
        (void) hv_stores(res, "status",  newSViv(code));
        (void) hv_stores(res, "headers", newRV_inc((SV *) rh));
        (void) hv_stores(res, "body",    body.data ? newSVpvn(body.data, body.len) : newSVpvs(""));
        /* where the request actually ended up, which differs from the url asked
           for whenever follow_redirects sent it somewhere else */
        if (curl_easy_getinfo(self->easy, CURLINFO_EFFECTIVE_URL, &eurl) == CURLE_OK && eurl)
            (void) hv_stores(res, "url", newSVpv(eurl, 0));
    }
    if (body.data) Safefree(body.data);
    RETVAL = newRV_inc((SV *) res);
  OUTPUT:
    RETVAL

MODULE = Curl::Impersonate    PACKAGE = Curl::Impersonate::Multi

SV *
_new(klass)
    const char *klass
  PREINIT:
    ci_multi *m; SV *ref;
  CODE:
    Newxz(m, 1, ci_multi);
    m->multi = curl_multi_init();
    if (!m->multi) { Safefree(m); croak("Curl::Impersonate::Multi: curl_multi_init failed"); }
    ref = newSV(0);
    sv_setref_pv(ref, klass, (void *) m);
    RETVAL = ref;
  OUTPUT:
    RETVAL

void
DESTROY(self_sv)
    SV *self_sv
  PREINIT:
    ci_multi *m;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (m) {
        /* During global destruction the owning Curl::Impersonate handles and the
           callback SVs may already be swept (refcounts not honored), so touching
           r->easy or dec'ing the SVs would be a UAF. Leaking curl state at process
           exit is harmless; only reap/dec when NOT in global destruction. */
        if (!PL_dirty) {
            while (m->reqs) {                /* reap requests abandoned before completion */
                ci_req *r = m->reqs;
                curl_easy_setopt(r->easy, CURLOPT_PRIVATE, NULL);
                curl_multi_remove_handle(m->multi, r->easy);
                free_ci_req(aTHX_ r);        /* unlinks from m->reqs -> advances the loop */
            }
            if (m->socket_cb) SvREFCNT_dec(m->socket_cb);
            if (m->timer_cb)  SvREFCNT_dec(m->timer_cb);
        }
        if (m->multi) curl_multi_cleanup(m->multi);
        Safefree(m);
    }

void
add(self_sv, easy_sv, req_hv, cb)
    SV *self_sv
    SV *easy_sv
    SV *req_hv
    SV *cb
  PREINIT:
    ci_multi *m; ci_t *ci; HV *req; SV **sv; ci_req *r;
    const char *method; const char *url; SV *body_sv; SV *hdrs;
  CODE:
    m  = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (!(SvROK(easy_sv) && sv_isobject(easy_sv)))
        croak("Curl::Impersonate::Multi::add: first arg must be a Curl::Impersonate handle");
    ci = (ci_t *) SvIV((SV *) SvRV(easy_sv));
    { ci_req *inuse = NULL; curl_easy_getinfo(ci->easy, CURLINFO_PRIVATE, &inuse);
      if (inuse) croak("Curl::Impersonate::Multi::add: handle already in use (one request at a time)"); }
    if (!(SvROK(req_hv) && SvTYPE(SvRV(req_hv)) == SVt_PVHV))
        croak("Curl::Impersonate::Multi::add: second arg must be a hashref");
    req = (HV *) SvRV(req_hv);
    method  = (sv = hv_fetchs(req, "method", 0))  && SvOK(*sv) ? SvPV_nolen(*sv) : "GET";
    url     = (sv = hv_fetchs(req, "url", 0))     && SvOK(*sv) ? SvPV_nolen(*sv) : NULL;
    body_sv = (sv = hv_fetchs(req, "body", 0))    ? *sv : &PL_sv_undef;
    hdrs    = (sv = hv_fetchs(req, "headers", 0)) ? *sv : &PL_sv_undef;
    if (!url) croak("Curl::Impersonate::Multi::add: url is required");
    Newxz(r, 1, ci_req);
    r->easy    = ci->easy;
    r->cb      = newSVsv(cb);
    r->owner   = newSVsv(easy_sv);           /* keep the handle alive in-flight */
    r->headers = newHV();
    r->hlist   = apply_request(ci->easy, method, url, hdrs, body_sv, &r->body, r->headers);
    link_req(m, r);
    curl_easy_setopt(ci->easy, CURLOPT_PRIVATE, r);
    {   /* curl_multi_add_handle synchronously fires the timer/socket callback; a
           user callback that undefs the Multi must not free it mid-call (UAF). Free
           r before releasing the guard on the failure path so a deferred DESTROY
           cannot also reap it (double-free). */
        SV *guard = SvREFCNT_inc(SvRV(self_sv));
        CURLMcode mc = curl_multi_add_handle(m->multi, ci->easy);
        if (mc != CURLM_OK) {
            curl_easy_setopt(ci->easy, CURLOPT_PRIVATE, NULL);
            free_ci_req(aTHX_ r);
        }
        SvREFCNT_dec(guard);
        if (mc != CURLM_OK)
            croak("Curl::Impersonate::Multi::add: curl_multi_add_handle failed");
    }

void
add_streaming(self_sv, easy_sv, req_hv, cbs_hv)
    SV *self_sv
    SV *easy_sv
    SV *req_hv
    SV *cbs_hv
  PREINIT:
    ci_multi *m; ci_t *ci; HV *req; HV *cbs; SV **sv; ci_req *r;
    const char *method; const char *url; SV *body_sv; SV *hdrs;
  CODE:
    m  = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (!(SvROK(easy_sv) && sv_isobject(easy_sv)))
        croak("add_streaming: first arg must be a Curl::Impersonate handle");
    ci = (ci_t *) SvIV((SV *) SvRV(easy_sv));
    if (!(SvROK(req_hv) && SvTYPE(SvRV(req_hv)) == SVt_PVHV))
        croak("add_streaming: second arg must be a request hashref");
    if (!(SvROK(cbs_hv) && SvTYPE(SvRV(cbs_hv)) == SVt_PVHV))
        croak("add_streaming: third arg must be a callbacks hashref");
    { ci_req *inuse = NULL; curl_easy_getinfo(ci->easy, CURLINFO_PRIVATE, &inuse);
      if (inuse) croak("add_streaming: handle already in use (one request at a time)"); }
    req = (HV *) SvRV(req_hv); cbs = (HV *) SvRV(cbs_hv);
    method  = (sv = hv_fetchs(req, "method", 0))  && SvOK(*sv) ? SvPV_nolen(*sv) : "GET";
    url     = (sv = hv_fetchs(req, "url", 0))     && SvOK(*sv) ? SvPV_nolen(*sv) : NULL;
    body_sv = (sv = hv_fetchs(req, "body", 0))    ? *sv : &PL_sv_undef;
    hdrs    = (sv = hv_fetchs(req, "headers", 0)) ? *sv : &PL_sv_undef;
    if (!url) croak("add_streaming: url is required");
    Newxz(r, 1, ci_req);
    r->easy       = ci->easy;
    r->owner      = newSVsv(easy_sv);
    r->headers    = newHV();
    r->streaming  = 1;
    r->on_headers = (sv = hv_fetchs(cbs, "on_headers", 0)) ? newSVsv(*sv) : newSV(0);
    r->on_body    = (sv = hv_fetchs(cbs, "on_body", 0))    ? newSVsv(*sv) : newSV(0);
    r->cb         = (sv = hv_fetchs(cbs, "on_done", 0))    ? newSVsv(*sv) : newSV(0);
    r->hlist      = apply_request(ci->easy, method, url, hdrs, body_sv, &r->body, r->headers);
    /* override the buffered write sink: stream chunks through the ci_req */
    curl_easy_setopt(ci->easy, CURLOPT_WRITEFUNCTION, body_cb_stream);
    curl_easy_setopt(ci->easy, CURLOPT_WRITEDATA, r);
    link_req(m, r);
    curl_easy_setopt(ci->easy, CURLOPT_PRIVATE, r);
    {   /* guard against a timer/socket callback undefing the Multi mid-add (see add) */
        SV *guard = SvREFCNT_inc(SvRV(self_sv));
        CURLMcode mc = curl_multi_add_handle(m->multi, ci->easy);
        if (mc != CURLM_OK) {
            curl_easy_setopt(ci->easy, CURLOPT_PRIVATE, NULL);
            free_ci_req(aTHX_ r);
        }
        SvREFCNT_dec(guard);
        if (mc != CURLM_OK)
            croak("add_streaming: curl_multi_add_handle failed");
    }

void
resume(self_sv, easy_sv)
    SV *self_sv
    SV *easy_sv
  PREINIT:
    ci_multi *m; ci_t *ci; SV *guard;
  CODE:
    m  = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (!(SvROK(easy_sv) && sv_isobject(easy_sv)))
        croak("Curl::Impersonate::Multi::resume: arg must be a Curl::Impersonate handle");
    ci = (ci_t *) SvIV((SV *) SvRV(easy_sv));
    guard = SvREFCNT_inc(SvRV(self_sv));   /* keep the guts alive if a callback undefs the multi (see perform_blocking) */
    curl_easy_pause(ci->easy, CURLPAUSE_CONT);
    curl_multi_socket_action(m->multi, CURL_SOCKET_TIMEOUT, 0, &m->still_running);
    drain_done(m);
    SvREFCNT_dec(guard);

void
remove(self_sv, easy_sv)
    SV *self_sv
    SV *easy_sv
  PREINIT:
    ci_multi *m; ci_t *ci; ci_req *r; SV *guard;
  CODE:
    m  = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (!(SvROK(easy_sv) && sv_isobject(easy_sv)))
        croak("Curl::Impersonate::Multi::remove: arg must be a Curl::Impersonate handle");
    ci = (ci_t *) SvIV((SV *) SvRV(easy_sv));
    r = NULL; curl_easy_getinfo(ci->easy, CURLINFO_PRIVATE, &r);
    /* curl_multi_remove_handle fires the timer/socket callback; a callback that
       undefs the Multi would run DESTROY (reaping r) mid-call -> the free_ci_req
       below then double-frees. Hold the guts until both the remove and the free
       are done. */
    guard = SvREFCNT_inc(SvRV(self_sv));
    curl_easy_setopt(ci->easy, CURLOPT_PRIVATE, NULL);
    curl_multi_remove_handle(m->multi, ci->easy);
    if (r) free_ci_req(aTHX_ r);             /* cancel without firing on_done (also unlinks) */
    SvREFCNT_dec(guard);

void
perform_blocking(self_sv)
    SV *self_sv
  PREINIT:
    ci_multi *m; int still; SV *guard;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    /* A callback (on_body/on_done) that does `undef $multi` drops the last ref to
       the blessed GUTS SV, firing Multi::DESTROY (curl_multi_cleanup + reap) mid-
       drive -> UAF/double-free. Hold our own ref to the guts -- NOT self_sv, which
       is the RV that `undef` merely clears in place (leaving the guts unprotected).
       Save the pointer: SvRV(self_sv) is invalid once the RV is cleared. DESTROY
       then defers to SvREFCNT_dec below, the safe point after the drive. */
    guard = SvREFCNT_inc(SvRV(self_sv));
    still = 0;
    do {
        if (curl_multi_perform(m->multi, &still) != CURLM_OK) break;
        if (still) curl_multi_poll(m->multi, NULL, 0, 100, NULL);
        drain_done(m);
        /* keep driving while any request is still tracked, not just while curl
           reports transfers running: a completion callback may add() a new request
           (m->reqs != NULL) after still was latched 0 -- otherwise it is stranded,
           never driven, and (via the callback's $m cycle) leaked. A paused
           streaming transfer also keeps m->reqs set -> the documented
           perform_blocking-can't-drive-pauses limitation, unchanged. */
    } while (still || m->reqs);
    SvREFCNT_dec(guard);

void
socket_action(self_sv, fd, ev_bitmask)
    SV *self_sv
    int fd
    int ev_bitmask
  PREINIT:
    ci_multi *m; int flags; curl_socket_t s; SV *guard;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    guard = SvREFCNT_inc(SvRV(self_sv));   /* keep the guts alive if a callback undefs the multi (see perform_blocking) */
    flags = 0;
    if (ev_bitmask & 1) flags |= CURL_CSELECT_IN;
    if (ev_bitmask & 2) flags |= CURL_CSELECT_OUT;
    s = (fd < 0) ? CURL_SOCKET_TIMEOUT : (curl_socket_t) fd;
    curl_multi_socket_action(m->multi, s, flags, &m->still_running);
    drain_done(m);
    SvREFCNT_dec(guard);

long
timeout_ms(self_sv)
    SV *self_sv
  PREINIT:
    ci_multi *m; long ms;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    ms = -1;
    curl_multi_timeout(m->multi, &ms);
    RETVAL = ms;
  OUTPUT:
    RETVAL

int
still_running(self_sv)
    SV *self_sv
  PREINIT:
    ci_multi *m;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    RETVAL = m->still_running;
  OUTPUT:
    RETVAL

void
set_socket_callback(self_sv, cb)
    SV *self_sv
    SV *cb
  PREINIT:
    ci_multi *m;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (m->socket_cb) SvREFCNT_dec(m->socket_cb);
    m->socket_cb = newSVsv(cb);
    curl_multi_setopt(m->multi, CURLMOPT_SOCKETFUNCTION, socket_fn);
    curl_multi_setopt(m->multi, CURLMOPT_SOCKETDATA, (void *) m);

void
set_timer_callback(self_sv, cb)
    SV *self_sv
    SV *cb
  PREINIT:
    ci_multi *m;
  CODE:
    m = (ci_multi *) SvIV((SV *) SvRV(self_sv));
    if (m->timer_cb) SvREFCNT_dec(m->timer_cb);
    m->timer_cb = newSVsv(cb);
    curl_multi_setopt(m->multi, CURLMOPT_TIMERFUNCTION, timer_fn);
    curl_multi_setopt(m->multi, CURLMOPT_TIMERDATA, (void *) m);
