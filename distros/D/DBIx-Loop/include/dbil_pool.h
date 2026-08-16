#ifndef DBIL_POOL_H
#define DBIL_POOL_H

/* Backend B - the forked worker pool (the universal backend).
 *
 * Each worker is a forked process holding its own DBI connection (a live dbh
 * cannot be shared across fork). Parent and worker share a duplex socketpair;
 * requests and results cross it as length-prefixed frames whose payload is a
 * Storable-frozen structure. The parent registers each worker's fd with the
 * event loop (via the adapter seam) through a magic-CV closure, so a response
 * resolves the matching future without blocking the loop.
 *
 * request frame  : [ is_query, sql, [ @bind ] ]
 * response frame : [ ok, data ]   ok=1 -> result hashref, ok=0 -> error string
 */

#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>

#include "dbil_vt.h"   /* the pure-C loop seam (adapter vtable) */

/* ---- Storable (core) serialisation, via cached CVs ------------------------- */

static SV *DBIL_FREEZE = NULL;   /* \&Storable::nfreeze */
static SV *DBIL_THAW   = NULL;   /* \&Storable::thaw    */

static void dbil_storable_init(pTHX) {
    if (DBIL_FREEZE) return;
    eval_pv("require Storable;", 0);
    DBIL_FREEZE = (SV *)get_cv("Storable::nfreeze", 0);
    DBIL_THAW   = (SV *)get_cv("Storable::thaw", 0);
    if (!DBIL_FREEZE || !DBIL_THAW)
        croak("DBIx::Loop: Storable (nfreeze/thaw) is required for the pool");
}

static SV *dbil_freeze(pTHX_ SV *data) {   /* mortal PV of bytes, or NULL */
    dSP; int n; SV *r = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 1); PUSHs(data); PUTBACK;
    n = call_sv(DBIL_FREEZE, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && n > 0) { SV *s = POPs; if (SvOK(s)) r = newSVsv(s); }
    else if (n > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return r ? sv_2mortal(r) : NULL;
}

static SV *dbil_thaw(pTHX_ const char *p, STRLEN len) {   /* mortal ref, or NULL */
    dSP; int n; SV *r = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 1); mPUSHp(p, len); PUTBACK;
    n = call_sv(DBIL_THAW, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && n > 0) { SV *s = POPs; if (SvOK(s)) r = newSVsv(s); }
    else if (n > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return r ? sv_2mortal(r) : NULL;
}

/* ---- frame I/O ------------------------------------------------------------- */

/* write all n bytes (EINTR-safe). 0 ok, -1 on error.
 *
 * A peer that died mid-conversation must surface as the -1 the callers
 * treat as a death notice - NOT as SIGPIPE, whose default disposition
 * kills the whole process before write() can return EPIPE (CPAN Testers:
 * t/02-pool.t exited with signal 13 after every assertion had passed).
 * Linux suppresses it per-send with MSG_NOSIGNAL; where that is missing
 * (macOS, the BSDs) dbil_pool_spawn sets SO_NOSIGPIPE on the pair. */
static int dbil_write_all(int fd, const char *p, STRLEN n) {
    STRLEN off = 0;
    while (off < n) {
        ssize_t w;
#ifdef MSG_NOSIGNAL
        w = send(fd, p + off, n - off, MSG_NOSIGNAL);
#else
        w = write(fd, p + off, n - off);
#endif
        if (w < 0) { if (errno == EINTR) continue; return -1; }
        off += (STRLEN)w;
    }
    return 0;
}

/* write a length-prefixed frame (4-byte big-endian len + payload) */
static int dbil_write_frame(pTHX_ int fd, SV *bytes) {
    STRLEN len; const char *p = SvPV_const(bytes, len);
    unsigned char hdr[4];
    hdr[0] = (unsigned char)(len >> 24); hdr[1] = (unsigned char)(len >> 16);
    hdr[2] = (unsigned char)(len >> 8);  hdr[3] = (unsigned char)(len);
    if (dbil_write_all(fd, (const char *)hdr, 4) < 0) return -1;
    return dbil_write_all(fd, p, len);
}

/* blocking read of exactly n bytes into buf; 1 ok, 0 EOF, -1 error */
static int dbil_read_exact(int fd, char *buf, STRLEN n) {
    STRLEN off = 0;
    while (off < n) {
        ssize_t r = read(fd, buf + off, n - off);
        if (r < 0) { if (errno == EINTR) continue; return -1; }
        if (r == 0) return 0;
        off += (STRLEN)r;
    }
    return 1;
}

/* blocking read of one frame; returns a mortal PV of the payload, or NULL on
 * EOF / error (used by the worker child) */
static SV *dbil_read_frame_blocking(pTHX_ int fd) {
    unsigned char hdr[4];
    STRLEN len;
    SV *payload;
    int rc = dbil_read_exact(fd, (char *)hdr, 4);
    if (rc <= 0) return NULL;
    len = ((STRLEN)hdr[0] << 24) | ((STRLEN)hdr[1] << 16)
        | ((STRLEN)hdr[2] << 8)  | (STRLEN)hdr[3];
    payload = newSV(len ? len : 1);
    SvPOK_on(payload);
    if (len && dbil_read_exact(fd, SvPVX(payload), len) <= 0) {
        SvREFCNT_dec(payload); return NULL;
    }
    SvCUR_set(payload, len);
    return sv_2mortal(payload);
}

/* ---- magic-CV closures (the rp_closure / oa_closure pattern) --------------- */

typedef struct dbil_clos { AV *cap; } dbil_clos;

static int dbil_clos_free(pTHX_ SV *sv, MAGIC *mg) {
    dbil_clos *c = (dbil_clos *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) { if (c->cap) SvREFCNT_dec((SV *)c->cap); Safefree(c); }
    return 0;
}
static MGVTBL dbil_clos_vtbl =
    { NULL, NULL, NULL, NULL, dbil_clos_free, NULL, NULL, NULL };

static SV *dbil_closure(pTHX_ XSUBADDR_t body, AV *cap) {
    CV *cv = (CV *)newXS(NULL, body, __FILE__);
    dbil_clos *c;
    Newxz(c, 1, dbil_clos);
    c->cap = cap;
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &dbil_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}
static AV *dbil_clos_cap(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &dbil_clos_vtbl);
    return mg ? ((dbil_clos *)mg->mg_ptr)->cap : NULL;
}

/* ---- pool + workers -------------------------------------------------------- */

typedef struct dbil_worker {
    pid_t pid;
    int   fd;         /* parent's end of the duplex socketpair */
    int   busy;
    int   reserved;   /* checked out to a transaction          */
    int   gen;        /* bumped on respawn: a txn pinned to an  */
                      /* earlier gen is lost, not silently moved */
    SV   *future;     /* in-flight future (+1), or NULL        */
    SV   *rbuf;       /* accumulated response bytes (+1)       */
    AV   *txq;        /* reserved-slot queue [bytes,future,...] (+1) */
    struct dbil_pool *p;   /* back-pointers: the C read-ready  */
    int   wi;              /* callback's ud is the worker      */
} dbil_worker;

typedef struct dbil_pool {
    pid_t        pid;         /* the process that forked these workers */
    SV          *loop;        /* the loop adapter SV (+1)   */
    dbil_vt     *vt;          /* adapter's C vtable, or NULL (Perl seam) */
    SV          *cargs;       /* connect args arrayref (+1) */
    dbil_worker *w;
    int          nw;
    int          restarts;    /* lifetime respawn count (storm cap) */
    int          max_queue;   /* pending-request cap; 0 = unlimited */
    AV          *queue;       /* pending [bytes, future, bytes, future, ...] */
    AV          *acq;         /* futures waiting to acquire a slot (+1 each) */
} dbil_pool;

/* ---- fork ownership --------------------------------------------------------
 *
 * A pool belongs to the process that forked its workers, and to no other. If
 * that process forks - which is exactly what a preforking server does - the
 * child inherits `p`, the worker pids and, worst of all, the parent's ends of
 * the socketpairs. Two processes then read() the same socket, so a response
 * lands in whichever happens to read first and a request can be answered with
 * ANOTHER request's rows. And on the child's exit, dbil_pool_free would
 * kill(SIGTERM) workers the parent and every sibling are still using.
 *
 * So: every entry point checks the owning pid, and an inherited pool is
 * disowned - its fds closed and its memory freed, its processes left alone -
 * and rebuilt for this process. dbil_pool_owned() is the one predicate. */
static int dbil_pool_owned(const dbil_pool *p) {
    return p && p->pid == getpid();
}

static void dbil_worker_main(pTHX_ int fd, SV *cargs);   /* child; below */
static void dbil_pool_dispatch(pTHX_ dbil_pool *p, int wi);
static void dbil_pool_on_readable(pTHX_ dbil_pool *p, int wi);
/* dbil_pool_send needs this: a failed write is a death notice, and the slot
 * has to be taken out of service there and then. */
static void dbil_pool_worker_died(pTHX_ dbil_pool *p, int wi);

/* In a freshly forked worker: close every descriptor except stdio and `keep`.
 * Called before any Perl runs in the child, so nothing here can be observed by
 * a DESTROY or an END block. */
static void dbil_close_inherited_fds(int keep) {
    int max = -1;
#ifdef RLIMIT_NOFILE
    struct rlimit rl;
    if (getrlimit(RLIMIT_NOFILE, &rl) == 0 && rl.rlim_cur != RLIM_INFINITY)
        max = (int)rl.rlim_cur;
#endif
    if (max < 0) max = (int)sysconf(_SC_OPEN_MAX);
    if (max < 0 || max > 4096) max = 4096;      /* bounded: this is a loop */
    {
        int fd;
        for (fd = 3; fd < max; fd++)
            if (fd != keep) (void)close(fd);
    }
}

/* the C-vtable read-ready callback: ud is the worker itself, no Perl frame */
static void dbil_pool_reader_c(pTHX_ int fd, int mask, void *ud) {
    dbil_worker *w = (dbil_worker *)ud;
    PERL_UNUSED_VAR(fd);
    PERL_UNUSED_VAR(mask);
    dbil_pool_on_readable(aTHX_ w->p, w->wi);
}

/* the loop's read-ready callback for worker wi: capture = [ poolIV, wiIV ] */
XS_INTERNAL(dbil_pool_reader_cb);
XS_INTERNAL(dbil_pool_reader_cb) {
    dXSARGS;
    AV *cap = dbil_clos_cap(aTHX_ cv);
    dbil_pool *p;
    int wi;
    PERL_UNUSED_VAR(items);
    if (!cap) XSRETURN_EMPTY;
    p  = INT2PTR(dbil_pool *, SvIV(*av_fetch(cap, 0, 0)));
    wi = (int)SvIV(*av_fetch(cap, 1, 0));
    dbil_pool_on_readable(aTHX_ p, wi);
    XSRETURN_EMPTY;
}

/* spawn worker wi: socketpair + fork; child runs dbil_worker_main. Registers
 * the parent fd with the loop. Returns 0 ok, -1 on failure. */
static int dbil_pool_spawn(pTHX_ dbil_pool *p, int wi) {
    int sp[2];
    pid_t pid;
    dbil_worker *w = &p->w[wi];
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sp) < 0) return -1;
#ifdef SO_NOSIGPIPE
    /* no MSG_NOSIGNAL on this platform: suppress SIGPIPE at the socket,
     * so a write to a dead peer returns EPIPE (see dbil_write_all) */
    {
        int one = 1;
        (void)setsockopt(sp[0], SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
        (void)setsockopt(sp[1], SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
    }
#endif
    pid = fork();
    if (pid < 0) { close(sp[0]); close(sp[1]); return -1; }
    if (pid == 0) {
        int j;
        close(sp[0]);
        for (j = 0; j < wi; j++)          /* drop siblings' parent fds so their */
            if (p->w[j].fd >= 0) close(p->w[j].fd);   /* EOF is seen when they die */
        /* Drop everything else this process inherited. A DB worker needs one
         * fd - its end of the socketpair - and nothing more. Without this it
         * holds a duplicate of whatever the embedding program had open, and in
         * a web server that includes the listening socket: the port then stays
         * bound for the worker's whole life, long after the HTTP worker that
         * started it has exited, and a graceful drain that waits for the last
         * holder to close never completes. */
        dbil_close_inherited_fds(sp[1]);
        dbil_worker_main(aTHX_ sp[1], p->cargs);   /* never returns */
        _exit(0);
    }
    close(sp[1]);
    /* The parent's end must not survive an exec either. */
    {
        int fl = fcntl(sp[0], F_GETFD);
        if (fl >= 0) (void)fcntl(sp[0], F_SETFD, fl | FD_CLOEXEC);
    }
    w->pid    = pid;
    w->fd     = sp[0];
    w->busy   = 0;
    w->reserved = 0;
    w->gen++;                               /* txns pinned to the old gen fail */
    w->future = NULL;
    if (!w->rbuf) w->rbuf = newSVpvs("");   /* reused across respawns */
    if (!w->txq)  w->txq  = newAV();
    w->p      = p;
    w->wi     = wi;
    if (p->vt) {
        /* C-vtable adapter: readiness dispatches C-to-C, no Perl frame */
        p->vt->add_reader(aTHX_ p->vt->ctx, w->fd, dbil_pool_reader_c, w);
    } else {
        /* $loop->add_reader($fd, $cb) */
        AV *cap = newAV();
        SV *cb;
        av_push(cap, newSViv(PTR2IV(p)));
        av_push(cap, newSViv(wi));
        cb = sv_2mortal(dbil_closure(aTHX_ dbil_pool_reader_cb, cap));
        {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 3);
            PUSHs(p->loop);
            mPUSHi(w->fd);
            PUSHs(cb);
            PUTBACK;
            call_method("add_reader", G_VOID | G_DISCARD | G_EVAL);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        }
    }
    return 0;
}

/* the worker child: its own dbh, then serve request frames until EOF */
static void dbil_worker_main(pTHX_ int fd, SV *cargs) {
    SV *dbh = NULL;
    DBIL_PREPARE_CACHED = 1;   /* statement reuse inside the worker */
    AV *ca  = (cargs && SvROK(cargs)) ? (AV *)SvRV(cargs) : NULL;
    /* DBI->connect(@$cargs) */
    if (ca) {
        dSP; int n;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSVpvs("DBI")));
        PUSHs(*av_fetch(ca, 0, 0));    /* dsn  */
        PUSHs(av_exists(ca, 1) ? *av_fetch(ca, 1, 0) : &PL_sv_undef);
        PUSHs(av_exists(ca, 2) ? *av_fetch(ca, 2, 0) : &PL_sv_undef);
        PUSHs(av_exists(ca, 3) ? *av_fetch(ca, 3, 0) : &PL_sv_undef);
        PUTBACK;
        n = call_method("connect", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && n > 0) { SV *s = POPs; if (SvROK(s)) dbh = SvREFCNT_inc(s); }
        else if (n > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
    }
    for (;;) {
        SV *req = dbil_read_frame_blocking(aTHX_ fd);
        SV *reqd, *resp, *frozen;
        AV *ra;
        int is_query;
        SV *sql, *err = NULL, *res;
        if (!req) break;                       /* parent closed: exit */
        { STRLEN l; const char *pv = SvPV_const(req, l); reqd = dbil_thaw(aTHX_ pv, l); }
        if (!reqd || !SvROK(reqd) || SvTYPE(SvRV(reqd)) != SVt_PVAV) continue;
        ra       = (AV *)SvRV(reqd);
        is_query = (int)SvIV(*av_fetch(ra, 0, 0));
        sql      = *av_fetch(ra, 1, 0);
        {
            SV **bp = av_fetch(ra, 2, 0);
            AV *bind = (bp && *bp && SvROK(*bp)) ? (AV *)SvRV(*bp) : NULL;
            res = dbh ? dbil_run_dbi(aTHX_ dbh, is_query, sql, bind, &err)
                      : (err = sv_2mortal(newSVpvs("worker has no database handle")), NULL);
        }
        {
            AV *out = newAV();
            av_push(out, newSViv(res ? 1 : 0));
            av_push(out, res ? newSVsv(res)
                             : newSVsv(err ? err : sv_2mortal(newSVpvs("failed"))));
            resp = sv_2mortal(newRV_noinc((SV *)out));
        }
        frozen = dbil_freeze(aTHX_ resp);
        if (frozen) (void)dbil_write_frame(aTHX_ fd, frozen);
    }
    close(fd);
    _exit(0);
}

/* send request bytes to worker wi and mark it busy with `future` (+1 taken) */
/* Can anything still take general (non-transaction) work? */
static int dbil_pool_has_live_worker(const dbil_pool *p) {
    int wi;
    for (wi = 0; wi < p->nw; wi++)
        if (p->w[wi].fd >= 0 && !p->w[wi].reserved) return 1;
    return 0;
}

static void dbil_pool_send(pTHX_ dbil_pool *p, int wi, SV *bytes, SV *future) {
    dbil_worker *w = &p->w[wi];
    int reserved;

    w->busy   = 1;
    w->future = SvREFCNT_inc(future);
    if (dbil_write_frame(aTHX_ w->fd, bytes) >= 0) return;

    /* The write failed, so the frame did not arrive whole and the statement
     * provably never ran: dbil_write_frame only returns < 0 having written
     * less than all of it.
     *
     * What matters here is the SLOT, not this one request. A worker killed
     * while idle is invisible until something is written to it - death is
     * otherwise only ever noticed as EOF on the read side, and an idle
     * worker's fd is not readable - so this is the first and only moment we
     * learn about it. Leaving the slot alive meant dbil_pool_run kept
     * choosing it, being the lowest-numbered idle worker with a live fd, and
     * failed every future from then on while the healthy workers sat idle.
     * Treat a failed write as the death notice it is. */
    reserved = w->reserved;

    if (!reserved) {
        /* Nothing executed, so this is a retry and not a loss. Put it back at
         * the head of the queue so it keeps its place, and let the respawn
         * inside worker_died pick it up. */
        SvREFCNT_dec(w->future);
        w->future = NULL;
        w->busy   = 0;
        av_unshift(p->queue, 2);
        av_store(p->queue, 0, newSVsv(bytes));
        av_store(p->queue, 1, SvREFCNT_inc(future));
    }
    /* A reserved slot is a transaction pinned to that one connection. It
     * cannot be moved, so leave the future in place for worker_died to fail
     * alongside the rest of the transaction. */

    dbil_pool_worker_died(aTHX_ p, wi);

    /* Respawn is capped and can fail. If it did, and nothing is left to run
     * on, fail what we just queued rather than leave callers waiting on a
     * pool that can no longer answer. */
    if (!reserved && !dbil_pool_has_live_worker(p)) {
        while (av_len(p->queue) >= 1) {
            SV *qb = av_shift(p->queue);
            SV *qf = av_shift(p->queue);
            SvREFCNT_dec(qb);
            dbil_future_settle_fail(aTHX_ qf,
                sv_2mortal(newSVpvs("pool has no live workers")));
            SvREFCNT_dec(qf);
        }
    }
}

/* run one statement on the pool; returns the future (+1) */
static SV *dbil_pool_run(pTHX_ dbil_pool *p, int is_query, SV *sql, AV *bind) {
    SV *future = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    SV *bytes;
    int wi;
    {   /* freeze the request tuple */
        AV *req = newAV();
        av_push(req, newSViv(is_query));
        av_push(req, newSVsv(sql));
        av_push(req, dbil_bind_rv(aTHX_ bind));
        bytes = dbil_freeze(aTHX_ sv_2mortal(newRV_noinc((SV *)req)));
    }
    if (!bytes) {
        dbil_future_settle_fail(aTHX_ future,
            sv_2mortal(newSVpvs("could not serialise request")));
        return future;
    }
    for (wi = 0; wi < p->nw; wi++)
        if (!p->w[wi].busy && !p->w[wi].reserved && p->w[wi].fd >= 0)
            { dbil_pool_send(aTHX_ p, wi, bytes, future); return future; }
    /* all busy: queue (bytes, future) - unless the backpressure cap is hit */
    if (p->max_queue > 0 && (av_len(p->queue) + 1) / 2 >= p->max_queue) {
        dbil_future_settle_fail(aTHX_ future,
            sv_2mortal(newSVpvs("queue full (max_queue exceeded)")));
        return future;
    }
    av_push(p->queue, newSVsv(bytes));
    av_push(p->queue, SvREFCNT_inc(future));
    return future;
}

/* pull the next queued request onto the now-free worker wi. A reserved
 * worker only drains its own transaction queue; a free worker first serves a
 * waiting acquire() (reserving itself), then the general queue. */
static void dbil_pool_dispatch(pTHX_ dbil_pool *p, int wi) {
    dbil_worker *w = &p->w[wi];
    if (w->reserved) {
        if (!w->busy && av_len(w->txq) >= 1) {
            SV *bytes  = av_shift(w->txq);
            SV *future = av_shift(w->txq);
            dbil_pool_send(aTHX_ p, wi, sv_2mortal(bytes), future);
            SvREFCNT_dec(future);   /* send took its own +1 */
        }
        return;
    }
    if (av_len(p->acq) >= 0) {          /* a txn is waiting for a slot */
        SV *fut = av_shift(p->acq);
        w->reserved = 1;
        dbil_future_settle_done1(aTHX_ fut, sv_2mortal(newSViv(wi)));
        SvREFCNT_dec(fut);
        return;
    }
    if (av_len(p->queue) >= 1) {
        SV *bytes  = av_shift(p->queue);
        SV *future = av_shift(p->queue);
        dbil_pool_send(aTHX_ p, wi, sv_2mortal(bytes), future);
        SvREFCNT_dec(future);   /* send took its own +1 */
    }
}

/* ---- slot checkout (transactions) ------------------------------------------ */

/* acquire a slot: future resolves with the worker index (reserved for the
 * caller). Resolves immediately when a slot is free. (+1) */
static SV *dbil_pool_acquire(pTHX_ dbil_pool *p) {
    SV *future = dbil_future_new(aTHX_ "DBIx::Loop::Future");
    int wi;
    for (wi = 0; wi < p->nw; wi++) {
        dbil_worker *w = &p->w[wi];
        if (!w->busy && !w->reserved && w->fd >= 0) {
            w->reserved = 1;
            dbil_future_settle_done1(aTHX_ future, sv_2mortal(newSViv(wi)));
            return future;
        }
    }
    av_push(p->acq, SvREFCNT_inc(future));
    return future;
}

/* release a reserved slot back to the pool and let it pick up work */
static void dbil_pool_release(pTHX_ dbil_pool *p, int wi) {
    if (wi < 0 || wi >= p->nw) return;
    p->w[wi].reserved = 0;
    if (!p->w[wi].busy) dbil_pool_dispatch(aTHX_ p, wi);
}

/* send a statement on a reserved slot (FIFO behind any in-flight one).
 * gen guards a txn whose worker died and respawned: that txn is lost, not
 * silently continued on a fresh connection. */
static void dbil_pool_send_tx(pTHX_ dbil_pool *p, int wi, int gen,
                              SV *bytes, SV *future) {
    dbil_worker *w;
    if (wi < 0 || wi >= p->nw) {
        dbil_future_settle_fail(aTHX_ future,
            sv_2mortal(newSVpvs("transaction has no slot")));
        return;
    }
    w = &p->w[wi];
    if (w->fd < 0 || w->gen != gen) {
        dbil_future_settle_fail(aTHX_ future,
            sv_2mortal(newSVpvs("transaction lost (worker died)")));
        return;
    }
    if (w->busy) {
        av_push(w->txq, newSVsv(bytes));
        av_push(w->txq, SvREFCNT_inc(future));
        return;
    }
    dbil_pool_send(aTHX_ p, wi, bytes, future);
}

/* unregister fd from the loop via whichever seam the adapter has */
static void dbil_pool_loop_remove(pTHX_ dbil_pool *p, int fd) {
    if (p->vt) {
        p->vt->remove(aTHX_ p->vt->ctx, fd);
    } else {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 2); PUSHs(p->loop); mPUSHi(fd); PUTBACK;
        call_method("remove", G_VOID | G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    }
}

/* worker wi died (EOF/error on its fd): fail the in-flight future, drop the
 * dead fd from the loop, reap the zombie, and spawn a replacement in place
 * (capped, so a fast-crashing worker cannot respawn-storm). Queued work is
 * re-dispatched onto the replacement. */
#define DBIL_MAX_RESTARTS 64

static void dbil_pool_worker_died(pTHX_ dbil_pool *p, int wi) {
    dbil_worker *w = &p->w[wi];
    if (w->future) {
        dbil_future_settle_fail(aTHX_ w->future,
            sv_2mortal(newSVpvs("worker exited unexpectedly")));
        SvREFCNT_dec(w->future); w->future = NULL;
    }
    dbil_pool_loop_remove(aTHX_ p, w->fd);
    close(w->fd);
    w->fd   = -1;
    w->busy = 0;
    if (w->pid > 0) { waitpid(w->pid, NULL, 0); w->pid = 0; }
    if (w->rbuf) SvCUR_set(w->rbuf, 0);          /* drop any partial frame */
    /* a transaction pinned here is lost: fail everything queued on the slot
     * (the gen bump in spawn stops later tx statements too) */
    while (av_len(w->txq) >= 1) {
        SV *bytes = av_shift(w->txq);
        SV *fut   = av_shift(w->txq);
        SvREFCNT_dec(bytes);
        dbil_future_settle_fail(aTHX_ fut,
            sv_2mortal(newSVpvs("transaction lost (worker died)")));
        SvREFCNT_dec(fut);
    }
    w->reserved = 0;
    if (p->restarts >= DBIL_MAX_RESTARTS) {
        warn("DBIx::Loop: worker restart limit reached; slot %d left dead", wi);
        return;
    }
    p->restarts++;
    if (dbil_pool_spawn(aTHX_ p, wi) < 0) {
        warn("DBIx::Loop: could not respawn pool worker %d: %s",
             wi, strerror(errno));
        return;
    }
    dbil_pool_dispatch(aTHX_ p, wi);             /* pick up queued work */
}

/* worker wi is readable: drain bytes, settle any complete frame's future */
static void dbil_pool_on_readable(pTHX_ dbil_pool *p, int wi) {
    dbil_worker *w = &p->w[wi];
    char chunk[65536];
    ssize_t r;
    if (w->fd < 0) return;                        /* already dead */
    r = read(w->fd, chunk, sizeof chunk);
    if (r <= 0) {
        if (r < 0 && errno == EINTR) return;
        dbil_pool_worker_died(aTHX_ p, wi);
        return;
    }
    sv_catpvn(w->rbuf, chunk, (STRLEN)r);
    for (;;) {
        STRLEN have = SvCUR(w->rbuf);
        const unsigned char *b = (const unsigned char *)SvPVX(w->rbuf);
        STRLEN len;
        if (have < 4) break;
        len = ((STRLEN)b[0] << 24) | ((STRLEN)b[1] << 16)
            | ((STRLEN)b[2] << 8)  | (STRLEN)b[3];
        if (have < 4 + len) break;
        {
            SV *resp = dbil_thaw(aTHX_ (const char *)b + 4, len);
            SV *fut  = w->future;
            w->future = NULL;
            w->busy   = 0;
            if (fut) {
                if (resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV) {
                    AV *ra = (AV *)SvRV(resp);
                    int ok = (int)SvIV(*av_fetch(ra, 0, 0));
                    SV *data = *av_fetch(ra, 1, 0);
                    if (ok) dbil_future_settle_done1(aTHX_ fut, data);
                    else    dbil_future_settle_fail(aTHX_ fut, data);
                } else {
                    dbil_future_settle_fail(aTHX_ fut,
                        sv_2mortal(newSVpvs("bad response frame from worker")));
                }
                SvREFCNT_dec(fut);
            }
        }
        /* consume the frame from the buffer */
        sv_chop(w->rbuf, SvPVX(w->rbuf) + 4 + len);
        dbil_pool_dispatch(aTHX_ p, wi);
    }
}

/* create + spawn the pool for this object (stored back as _pool IV) */
static dbil_pool *dbil_pool_new(pTHX_ SV *loop, SV *cargs, int nworkers) {
    dbil_pool *p;
    int i;
    dbil_storable_init(aTHX);
    Newxz(p, 1, dbil_pool);
    p->pid   = getpid();                 /* the owner; see dbil_pool_owned */
    p->loop  = SvREFCNT_inc(loop);
    p->vt    = dbil_vt_of(aTHX_ loop);   /* C seam when the adapter has one */
    p->cargs = SvREFCNT_inc(cargs);
    p->nw    = nworkers;
    p->queue = newAV();
    p->acq   = newAV();
    Newxz(p->w, nworkers, dbil_worker);
    for (i = 0; i < nworkers; i++) {
        if (dbil_pool_spawn(aTHX_ p, i) < 0)
            croak("DBIx::Loop: could not spawn pool worker %d: %s", i, strerror(errno));
    }
    return p;
}

/* Release an INHERITED pool: close the fds this process got by forking, free
 * the memory, and leave the workers alone - they are not ours to signal, and
 * the process that forked them is still using them. No futures are settled and
 * no loop callbacks are removed, because none of that state belongs to us
 * either; it is the parent's, and we are only holding copies of the pointers. */
static void dbil_pool_disown(pTHX_ dbil_pool *p) {
    int i;
    if (!p) return;
    for (i = 0; i < p->nw; i++) {
        dbil_worker *w = &p->w[i];
        if (w->fd >= 0) {
            /* Unregister before closing. The loop object was copied by the
             * fork, so this watcher list is OURS - the parent's is untouched -
             * and a registration left behind here would still name this fd
             * number after the close. The very next socketpair() hands that
             * number straight back for the replacement pool, and the stale
             * entry would then be pointing at this freed struct. */
            if (!PL_dirty) {
                if (p->vt) {
                    p->vt->remove(aTHX_ p->vt->ctx, w->fd);
                } else if (p->loop) {
                    dSP;
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    EXTEND(SP, 2); PUSHs(p->loop); mPUSHi(w->fd); PUTBACK;
                    call_method("remove", G_VOID | G_DISCARD | G_EVAL);
                    SPAGAIN; PUTBACK; FREETMPS; LEAVE;
                }
            }
            close(w->fd);   /* our copy only; the parent keeps its own */
        }
        if (w->rbuf) SvREFCNT_dec(w->rbuf);
        if (w->txq)  SvREFCNT_dec((SV *)w->txq);
        if (w->future) SvREFCNT_dec(w->future);
    }
    Safefree(p->w);
    if (p->acq)   SvREFCNT_dec((SV *)p->acq);
    if (p->queue) SvREFCNT_dec((SV *)p->queue);
    if (p->loop)  SvREFCNT_dec(p->loop);
    if (p->cargs) SvREFCNT_dec(p->cargs);
    Safefree(p);
}

static void dbil_pool_free(pTHX_ dbil_pool *p) {
    int i;
    if (!p) return;
    /* Not ours: never signal another process's workers. This is the whole
     * reason a child exiting used to take down the parent's pool. */
    if (!dbil_pool_owned(p)) { dbil_pool_disown(aTHX_ p); return; }
    for (i = 0; i < p->nw; i++) {
        dbil_worker *w = &p->w[i];
        if (w->fd >= 0) {
            /* only call back into the loop when the interpreter is healthy;
             * during global destruction (PL_dirty) the loop object may already
             * be gone, so just close the fd and reap. */
            if (!PL_dirty) {
                if (p->vt) {
                    p->vt->remove(aTHX_ p->vt->ctx, w->fd);
                } else {
                    dSP;
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    EXTEND(SP, 2); PUSHs(p->loop); mPUSHi(w->fd); PUTBACK;
                    call_method("remove", G_VOID | G_DISCARD | G_EVAL);
                    SPAGAIN; PUTBACK; FREETMPS; LEAVE;
                }
            }
            close(w->fd);
        }
        if (w->pid > 0) { kill(w->pid, SIGTERM); waitpid(w->pid, NULL, 0); }
        if (w->future) {   /* never leave an in-flight future pending forever */
            if (!PL_dirty)
                dbil_future_settle_fail(aTHX_ w->future,
                    sv_2mortal(newSVpvs("disconnected with query in flight")));
            SvREFCNT_dec(w->future);
        }
        while (av_len(w->txq) >= 1) {   /* and nothing queued on the slot */
            SV *b = av_shift(w->txq); SV *f = av_shift(w->txq);
            SvREFCNT_dec(b);
            if (!PL_dirty)
                dbil_future_settle_fail(aTHX_ f,
                    sv_2mortal(newSVpvs("disconnected with query in flight")));
            SvREFCNT_dec(f);
        }
        if (w->rbuf)   SvREFCNT_dec(w->rbuf);
        if (w->txq)    SvREFCNT_dec((SV *)w->txq);
    }
    Safefree(p->w);
    if (p->acq) {   /* anyone still waiting for a slot loses */
        while (av_len(p->acq) >= 0) {
            SV *fut = av_shift(p->acq);
            dbil_future_settle_fail(aTHX_ fut,
                sv_2mortal(newSVpvs("pool destroyed")));
            SvREFCNT_dec(fut);
        }
        SvREFCNT_dec((SV *)p->acq);
    }
    if (p->queue) {   /* settle anything still waiting for a worker */
        while (av_len(p->queue) >= 1) {
            SV *b = av_shift(p->queue); SV *f = av_shift(p->queue);
            SvREFCNT_dec(b);
            if (!PL_dirty)
                dbil_future_settle_fail(aTHX_ f,
                    sv_2mortal(newSVpvs("disconnected with query queued")));
            SvREFCNT_dec(f);
        }
        SvREFCNT_dec((SV *)p->queue);
    }
    if (p->loop)  SvREFCNT_dec(p->loop);
    if (p->cargs) SvREFCNT_dec(p->cargs);
    Safefree(p);
}

#endif /* DBIL_POOL_H */
