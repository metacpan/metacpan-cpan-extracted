/* clamd_async.h - a scan that proceeds on somebody else's loop.
 *
 * Phase 5 of plan_clamav_clamd.
 *
 * WHY NOT AN ADAPTER. DBIx::Loop, the house precedent, takes a loop
 * adapter - add_reader/add_writer/remove/timer/new_future - plus a C
 * vtable so a C-side loop dispatches without a Perl frame. That is right
 * for DBIx::Loop: it has long-lived connections, a worker pool,
 * transactions and futures, and it genuinely needs timers.
 *
 * This has one short-lived connection and one request/response. An
 * adapter interface plus a conformance suite plus a dist per loop would
 * be more machinery than the protocol. So the surface is smaller:
 *
 *     fd        - register it with whatever loop you have
 *     want      - readable, writable, or neither
 *     step      - advance as far as possible without blocking
 *     verdict   - once finished
 *
 * Twenty lines wraps that in a Punk::Future, an IO::Async one, or a bare
 * select loop, and none of those wrappers are this file's problem.
 *
 * THE BLOCKING PATH IS THIS MACHINE UNDER poll(). There is deliberately
 * no second implementation of the protocol - one being a re-run of the
 * other is how the rarely-used path rots.
 *
 * WHAT THE CALLER OWNS. Without a timer this cannot wake anybody, so the
 * deadline lives in here instead: it is checked on every step, and a
 * step taken after it expires fails. A driver that stops stepping is a
 * driver that never learns it timed out - which is the honest division,
 * and it is documented rather than papered over.
 */
#ifndef CLAMD_ASYNC_H
#define CLAMD_ASYNC_H

#include "clamav/clamd_verdict.h"

#define CC_WANT_NONE   0
#define CC_WANT_READ   1
#define CC_WANT_WRITE  2

#define CC_STEP_MORE   0    /* not finished; wait for cc_want() then step */
#define CC_STEP_DONE   1    /* finished; the verdict is ready */

typedef enum {
    CC_PH_CONNECT,
    CC_PH_SEND_CMD,
    CC_PH_SEND_FD,
    CC_PH_STREAM,
    CC_PH_STREAM_END,
    CC_PH_READ,
    CC_PH_DONE
} cc_phase;

typedef struct {
    cc_phase phase;
    int      sock;
    int      want;
    double   deadline;

    /* An async scan outlives the call that started it, so the address
     * cannot stay a borrowed pointer into a Perl scalar. */
    cc_target t;
    char    *path_copy;
    char    *host_copy;

    char     cmd[32];
    size_t   cmdlen, cmdoff;

    int      scan_fd;        /* FILDES: borrowed unless own_fd */
    int      own_fd;

    cc_source src;
    unsigned char hdr[4];
    size_t   hdroff;
    const char *chunk;
    size_t   chunklen, chunkoff;
    int      have_chunk;

    char    *reply;
    size_t   replylen, replycap;

    int      transport;
    int      rc;
    cc_err   err;

    /* Parsed once, on demand. Both the XS layer and the C ABI read the
     * verdict from here, so there is one parse and one answer - an
     * accessor that reparses can disagree with itself, which phase 5
     * already got caught doing. */
    cc_verdict verdict;
    int        verdict_ready;

    /* A step that neither consumes nor produces anything, repeatedly, is
     * a busy loop wearing the shape of progress. On a level-triggered
     * loop the caller will call straight back, so the machine counts its
     * own idle steps and gives up rather than pinning a core. */
    int      idle_steps;
} cc_scan;

#define CC_MAX_IDLE_STEPS 10000

static void cc_scan_free(cc_scan *s) {
    if (!s) return;
    if (s->sock != CC_INVALID_SOCK) { cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK; }
    if (s->own_fd && s->scan_fd >= 0) { close(s->scan_fd); }
    s->scan_fd = -1; s->own_fd = 0;
    if (s->src.iobuf) { free(s->src.iobuf); s->src.iobuf = NULL; }
    if (s->reply)     { free(s->reply);     s->reply = NULL; }
    if (s->path_copy) { free(s->path_copy); s->path_copy = NULL; }
    if (s->host_copy) { free(s->host_copy); s->host_copy = NULL; }
}

static void cc_fail(cc_scan *s, int code, const char *msg, const char *detail) {
    cc_err_set(&s->err, code, msg, detail);
    s->rc = code;
    s->phase = CC_PH_DONE;
    s->want = CC_WANT_NONE;
    if (s->sock != CC_INVALID_SOCK) { cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK; }
}

static char *cc_strdup(const char *p) {
    size_t n;
    char *d;
    if (!p) return NULL;
    n = strlen(p) + 1;
    d = (char *)malloc(n);
    if (d) memcpy(d, p, n);
    return d;
}

/* Start a scan. Does not block: the connect is begun and left in flight.
 *
 * mode is CC_TRANSPORT_FILDES or CC_TRANSPORT_INSTREAM. For FILDES the
 * descriptor is borrowed (own_fd 0) unless the caller opened it here.
 * For INSTREAM either mem/memlen or a source fd is used.
 */
static int cc_scan_start(cc_scan *s, const cc_target *t, int mode,
                         int fd, int own_fd,
                         const char *mem, size_t memlen, int src_fd) {
    memset(s, 0, sizeof *s);
    s->sock    = CC_INVALID_SOCK;
    s->scan_fd = -1;
    s->rc      = CC_OK;

    s->t = *t;
    s->path_copy = cc_strdup(t->path);
    s->host_copy = cc_strdup(t->host);
    s->t.path = s->path_copy;
    s->t.host = s->host_copy;

    s->deadline = cc_now() + (t->reply_timeout > 0 ? t->reply_timeout : 30.0);
    s->transport = mode;

    if (mode == CC_TRANSPORT_FILDES) {
        s->scan_fd = fd;
        s->own_fd  = own_fd;
    } else {
        s->src.chunk  = t->chunk ? t->chunk : CC_DEF_CHUNK;
        s->src.fd     = -1;
        if (mem) {
            s->src.mem    = mem;
            s->src.memlen = memlen;
        } else {
            s->src.fd    = src_fd;
            s->scan_fd   = src_fd;
            s->own_fd    = own_fd;
            s->src.iobuf = (char *)malloc(s->src.chunk);
            if (!s->src.iobuf) {
                cc_fail(s, CC_ERR_IO, "out of memory", NULL);
                return s->rc;
            }
        }
    }

    /* Begin the connect. cc_connect leaves the socket non-blocking and
     * has already waited for writability, which is the one thing here
     * that is not yet fully incremental - a UNIX connect completes
     * immediately and a TCP one is bounded by connect_timeout. */
    s->sock = cc_connect(&s->t, &s->err);
    if (s->sock == CC_INVALID_SOCK) {
        s->rc = s->err.code ? s->err.code : CC_ERR_CONNECT;
        s->phase = CC_PH_DONE;
        s->want = CC_WANT_NONE;
        return s->rc;
    }

    {
        const char *name = (mode == CC_TRANSPORT_FILDES) ? "FILDES" : "INSTREAM";
        size_t n = strlen(name);
        s->cmd[0] = (t->frame == CC_FRAME_N) ? 'n' : 'z';
        memcpy(s->cmd + 1, name, n);
        s->cmd[n + 1] = (t->frame == CC_FRAME_N) ? '\n' : '\0';
        s->cmdlen = n + 2;
        s->cmdoff = 0;
    }

    s->phase = CC_PH_SEND_CMD;
    s->want  = CC_WANT_WRITE;
    return CC_OK;
}

static int cc_want(const cc_scan *s) { return s->want; }
static int cc_scan_fd_of(const cc_scan *s) { return s->sock; }

/* Advance as far as possible without blocking.
 *
 * Returns CC_STEP_DONE when finished (check s->rc and s->reply), or
 * CC_STEP_MORE with s->want naming the readiness to wait for.
 */
static int cc_scan_step(cc_scan *s) {
    int progressed = 0;

    if (s->phase == CC_PH_DONE) return CC_STEP_DONE;

    if (cc_now() > s->deadline) {
        cc_fail(s, CC_ERR_TIMEOUT, "scan deadline exceeded", NULL);
        return CC_STEP_DONE;
    }

    for (;;) {
        switch (s->phase) {

        case CC_PH_SEND_CMD: {
            ssize_t n = send(s->sock, s->cmd + s->cmdoff,
                             (int)(s->cmdlen - s->cmdoff), CC_MSG_NOSIGNAL);
            if (n > 0) {
                s->cmdoff += (size_t)n;
                progressed = 1;
                if (s->cmdoff < s->cmdlen) continue;
                s->phase = (s->transport == CC_TRANSPORT_FILDES)
                         ? CC_PH_SEND_FD : CC_PH_STREAM;
                continue;
            }
            if (n < 0 && errno == EINTR) continue;
            if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                s->want = CC_WANT_WRITE;
                goto more;
            }
            cc_fail(s, cc_errno_is_closed(errno) ? CC_ERR_CLOSED : CC_ERR_IO,
                    "send", strerror(errno));
            return CC_STEP_DONE;
        }

        case CC_PH_SEND_FD: {
#if CC_HAVE_FD_PASSING
            /* The descriptor rides its own one-byte message, after the
             * command - see clamd_scan.h for why. It is a single
             * sendmsg, so there is no partial-progress state to keep. */
            struct msghdr msg;
            struct iovec  iov;
            union { struct cmsghdr align; char buf[CMSG_SPACE(sizeof(int))]; } ctl;
            struct cmsghdr *cm;
            char pad = '\0';
            ssize_t n;

            memset(&msg, 0, sizeof msg);
            memset(&ctl, 0, sizeof ctl);
            iov.iov_base = &pad; iov.iov_len = 1;
            msg.msg_iov = &iov; msg.msg_iovlen = 1;
            msg.msg_control = ctl.buf;
            msg.msg_controllen = CMSG_SPACE(sizeof(int));
            cm = CMSG_FIRSTHDR(&msg);
            cm->cmsg_level = SOL_SOCKET;
            cm->cmsg_type  = SCM_RIGHTS;
            cm->cmsg_len   = CMSG_LEN(sizeof(int));
            memcpy(CMSG_DATA(cm), &s->scan_fd, sizeof(int));

            n = sendmsg(s->sock, &msg, CC_MSG_NOSIGNAL);
            if (n >= 0) {
                progressed = 1;
                s->phase = CC_PH_READ;
                continue;
            }
            if (errno == EINTR) continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                s->want = CC_WANT_WRITE;
                goto more;
            }
            cc_fail(s, cc_errno_is_closed(errno) ? CC_ERR_CLOSED : CC_ERR_IO,
                    "sendmsg", strerror(errno));
            return CC_STEP_DONE;
#else
            cc_fail(s, CC_ERR_NOFDPASS,
                    "this platform cannot pass file descriptors", NULL);
            return CC_STEP_DONE;
#endif
        }

        case CC_PH_STREAM: {
            /* A reply arriving mid-write is a VERDICT. Checked before
             * every chunk, exactly as the blocking path did. */
            if (cc_reply_pending(s->sock)) {
                progressed = 1;
                s->phase = CC_PH_READ;
                continue;
            }

            if (!s->have_chunk) {
                const char *p = NULL;
                ssize_t n = cc_source_next(&s->src, &p, &s->err);
                if (n < 0) { cc_fail(s, CC_ERR_IO, "read", NULL); return CC_STEP_DONE; }
                if (n == 0) {
                    s->phase = CC_PH_STREAM_END;
                    s->hdroff = 0;
                    memset(s->hdr, 0, 4);
                    progressed = 1;
                    continue;
                }
                s->chunk    = p;
                s->chunklen = (size_t)n;
                s->chunkoff = 0;
                s->hdr[0] = (unsigned char)((s->chunklen >> 24) & 0xff);
                s->hdr[1] = (unsigned char)((s->chunklen >> 16) & 0xff);
                s->hdr[2] = (unsigned char)((s->chunklen >>  8) & 0xff);
                s->hdr[3] = (unsigned char)( s->chunklen        & 0xff);
                s->hdroff = 0;
                s->have_chunk = 1;
                progressed = 1;
            }

            /* Header first, then payload. Both carry an offset, because
             * a partial write is the normal case here rather than an
             * exception - and an offset that does not survive between
             * steps corrupts the stream silently. */
            if (s->hdroff < 4) {
                ssize_t n = send(s->sock, (const char *)s->hdr + s->hdroff,
                                 (int)(4 - s->hdroff), CC_MSG_NOSIGNAL);
                if (n > 0) { s->hdroff += (size_t)n; progressed = 1; continue; }
                if (n < 0 && errno == EINTR) continue;
                if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                    s->want = CC_WANT_WRITE; goto more;
                }
                if (cc_errno_is_closed(errno)) { s->phase = CC_PH_READ; progressed = 1; continue; }
                cc_fail(s, CC_ERR_IO, "send", strerror(errno));
                return CC_STEP_DONE;
            }

            if (s->chunkoff < s->chunklen) {
                ssize_t n = send(s->sock, s->chunk + s->chunkoff,
                                 (int)(s->chunklen - s->chunkoff), CC_MSG_NOSIGNAL);
                if (n > 0) { s->chunkoff += (size_t)n; progressed = 1; continue; }
                if (n < 0 && errno == EINTR) continue;
                if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                    s->want = CC_WANT_WRITE; goto more;
                }
                if (cc_errno_is_closed(errno)) { s->phase = CC_PH_READ; progressed = 1; continue; }
                cc_fail(s, CC_ERR_IO, "send", strerror(errno));
                return CC_STEP_DONE;
            }

            s->have_chunk = 0;
            continue;
        }

        case CC_PH_STREAM_END: {
            ssize_t n = send(s->sock, (const char *)s->hdr + s->hdroff,
                             (int)(4 - s->hdroff), CC_MSG_NOSIGNAL);
            if (n > 0) {
                s->hdroff += (size_t)n;
                progressed = 1;
                if (s->hdroff < 4) continue;
                s->phase = CC_PH_READ;
                continue;
            }
            if (n < 0 && errno == EINTR) continue;
            if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                s->want = CC_WANT_WRITE; goto more;
            }
            if (cc_errno_is_closed(errno)) { s->phase = CC_PH_READ; progressed = 1; continue; }
            cc_fail(s, CC_ERR_IO, "send", strerror(errno));
            return CC_STEP_DONE;
        }

        case CC_PH_READ: {
            char   term = (s->t.frame == CC_FRAME_N) ? '\n' : '\0';
            size_t hard = s->t.reply_max ? s->t.reply_max : (1024 * 1024);
            ssize_t n;
            size_t  room;

            if (!s->reply) {
                s->replycap = 512;
                if (s->replycap > hard + 1) s->replycap = hard + 1;
                s->reply = (char *)malloc(s->replycap);
                if (!s->reply) { cc_fail(s, CC_ERR_IO, "out of memory", NULL); return CC_STEP_DONE; }
                s->replylen = 0;
            }

            if (s->replylen >= hard) {
                cc_fail(s, CC_ERR_TOOBIG, "reply exceeded the configured ceiling", NULL);
                return CC_STEP_DONE;
            }
            if (s->replylen + 1 >= s->replycap) {
                size_t ncap = s->replycap * 2;
                char  *nb;
                if (ncap > hard + 1) ncap = hard + 1;
                if (s->replylen + 1 >= ncap) {
                    cc_fail(s, CC_ERR_TOOBIG, "reply exceeded the configured ceiling", NULL);
                    return CC_STEP_DONE;
                }
                nb = (char *)realloc(s->reply, ncap);
                if (!nb) { cc_fail(s, CC_ERR_IO, "out of memory", NULL); return CC_STEP_DONE; }
                s->reply = nb; s->replycap = ncap;
            }

            room = s->replycap - s->replylen - 1;
            if (s->replylen + room > hard) room = hard - s->replylen;

            n = recv(s->sock, s->reply + s->replylen, (int)room, 0);
            if (n > 0) {
                size_t start = s->replylen, i;
                s->replylen += (size_t)n;
                progressed = 1;
                for (i = start; i < s->replylen; i++) {
                    if (s->reply[i] == term) {
                        s->reply[i] = '\0';
                        s->replylen = i;
                        s->rc = CC_OK;
                        s->phase = CC_PH_DONE;
                        s->want = CC_WANT_NONE;
                        cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK;
                        return CC_STEP_DONE;
                    }
                }
                continue;
            }
            if (n == 0) {
                if (s->replylen == 0) {
                    cc_fail(s, CC_ERR_STREAMCUT,
                            "clamd closed the stream without a verdict "
                            "(usually StreamMaxLength exceeded)", NULL);
                    return CC_STEP_DONE;
                }
                s->reply[s->replylen] = '\0';
                s->rc = CC_OK;
                s->phase = CC_PH_DONE;
                s->want = CC_WANT_NONE;
                cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK;
                return CC_STEP_DONE;
            }
            if (errno == EINTR) continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                s->want = CC_WANT_READ;
                goto more;
            }
            cc_fail(s, CC_ERR_IO, "recv", strerror(errno));
            return CC_STEP_DONE;
        }

        case CC_PH_CONNECT:
        case CC_PH_DONE:
        default:
            s->want = CC_WANT_NONE;
            return CC_STEP_DONE;
        }
    }

more:
    if (progressed) s->idle_steps = 0;
    else if (++s->idle_steps > CC_MAX_IDLE_STEPS) {
        cc_fail(s, CC_ERR_IO,
                "scan made no progress over many steps; the driver is spinning",
                NULL);
        return CC_STEP_DONE;
    }
    return CC_STEP_MORE;
}

/* The verdict, parsed once and kept. */
static const cc_verdict *cc_scan_verdict(cc_scan *s) {
    if (!s->verdict_ready) {
        if (s->rc == CC_OK)
            cc_parse_reply(s->reply ? s->reply : "", s->replylen, &s->verdict);
        else
            cc_verdict_from_error(s->rc, &s->verdict);
        s->verdict_ready = 1;
    }
    return &s->verdict;
}

/* Cancellation.
 *
 * The connection is CLOSED, never returned to anything. clamd is still
 * going to answer, and a connection carrying an unread verdict handed to
 * an unrelated scan would give that scan this one's answer - a
 * cross-request result confusion bug, and the reason phase 0 chose a
 * connection per scan in the first place.
 */
static void cc_scan_cancel(cc_scan *s) {
    if (!s) return;
    if (s->sock != CC_INVALID_SOCK) { cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK; }
    s->phase = CC_PH_DONE;
    s->want  = CC_WANT_NONE;
    s->rc    = CC_ERR_CLOSED;
    cc_err_set(&s->err, CC_ERR_CLOSED, "scan cancelled", NULL);
}

/* The blocking driver: this same machine, under poll.
 *
 * There is no second copy of the protocol anywhere in this dist. Any bug
 * fixed here is fixed on both paths, and the async path cannot rot from
 * disuse because the blocking one exercises it on every call.
 */
static int cc_scan_run(cc_scan *s, char **out, size_t *outlen, cc_err *err) {
    *out = NULL; *outlen = 0;

    while (cc_scan_step(s) == CC_STEP_MORE) {
        int w = cc_wait(s->sock, s->want == CC_WANT_WRITE, s->deadline);
        if (w == 0) { cc_fail(s, CC_ERR_TIMEOUT, "scan timed out", NULL); break; }
        if (w < 0)  { cc_fail(s, CC_ERR_IO, "poll", strerror(errno)); break; }
    }

    *err = s->err;
    if (s->rc == CC_OK) {
        *out = s->reply; *outlen = s->replylen;
        s->reply = NULL;              /* ownership moves to the caller */
    }
    return s->rc;
}

#endif /* CLAMD_ASYNC_H */
