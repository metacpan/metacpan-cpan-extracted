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
 * other is how the rarely-used path rots. That goes for PING, VERSION and
 * the rest as well: a command is a scan with nothing to stream, so the
 * reply reader and its ceiling are the same code whichever way clamd is
 * asked.
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
    CC_PH_SEND_CMD,
    CC_PH_SEND_FD,
    CC_PH_STREAM,
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
    if (s->sock != CC_INVALID_SOCK) { cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK; }
    if (s->own_fd) cc_close_fd(s->scan_fd);
    s->scan_fd = -1; s->own_fd = 0;
    if (s->src.iobuf) { free(s->src.iobuf); s->src.iobuf = NULL; }
    if (s->reply)     { free(s->reply);     s->reply = NULL; }
    if (s->path_copy) { free(s->path_copy); s->path_copy = NULL; }
    if (s->host_copy) { free(s->host_copy); s->host_copy = NULL; }
}

/* Finish with a failure. A NULL msg keeps the error already recorded. */
static void cc_fail(cc_scan *s, int code, const char *msg, const char *detail) {
    if (msg) cc_err_set(&s->err, code, msg, detail);
    s->rc = code;
    s->phase = CC_PH_DONE;
    s->want = CC_WANT_NONE;
    if (s->sock != CC_INVALID_SOCK) { cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK; }
}

/* Finish with clamd's reply in hand. */
static void cc_finish(cc_scan *s) {
    s->reply[s->replylen] = '\0';
    s->rc = CC_OK;
    s->phase = CC_PH_DONE;
    s->want = CC_WANT_NONE;
    cc_close_sock(s->sock); s->sock = CC_INVALID_SOCK;
}

static char *cc_strdup(const char *p) {
    size_t n;
    char *d;
    if (!p) return NULL;
    n = strlen(p) + 1;
    d = (char *)malloc(n);
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (d) memcpy(d, p, n);
    return d;
}

static void cc_scan_reset(cc_scan *s, const cc_target *t, int transport) {
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
    s->transport = transport;
}

/* Frame the command and begin the connect. Does not block: cc_connect
 * leaves the socket non-blocking, and has already waited for
 * writability, which is the one thing here that is not yet fully
 * incremental - a UNIX connect completes immediately and a TCP one is
 * bounded by connect_timeout. */
static int cc_scan_open(cc_scan *s, const char *cmd) {
    size_t n = strlen(cmd);

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (n + 2 > sizeof s->cmd) {
        cc_fail(s, CC_ERR_CONFIG, "command too long", cmd); /* # uncoverable statement */
        return s->rc; /* # uncoverable statement */
    }
    s->cmd[0] = (s->t.frame == CC_FRAME_N) ? 'n' : 'z';
    memcpy(s->cmd + 1, cmd, n);
    s->cmd[n + 1] = (s->t.frame == CC_FRAME_N) ? '\n' : '\0';
    s->cmdlen = n + 2;
    s->cmdoff = 0;

    s->sock = cc_connect(&s->t, &s->err);
    if (s->sock == CC_INVALID_SOCK) {
        cc_fail(s, s->err.code, NULL, NULL);
        return s->rc;
    }

    s->phase = CC_PH_SEND_CMD;
    s->want  = CC_WANT_WRITE;
    return CC_OK;
}

/* Start a scan.
 *
 * mode is CC_TRANSPORT_FILDES or CC_TRANSPORT_INSTREAM. For FILDES the
 * descriptor is borrowed (own_fd 0) unless the caller opened it here.
 * For INSTREAM either mem/memlen or a source fd is used.
 */
static int cc_scan_start(cc_scan *s, const cc_target *t, int mode,
                         int fd, int own_fd,
                         const char *mem, size_t memlen, int src_fd) {
    cc_scan_reset(s, t, mode);

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
            /*
             # uncoverable branch true
             # uncoverable condition left count:1 */
            if (!s->src.iobuf) {
                cc_fail(s, CC_ERR_IO, "out of memory", NULL); /* # uncoverable statement */
                return s->rc; /* # uncoverable statement */
            }
        }
    }
    return cc_scan_open(s, mode == CC_TRANSPORT_FILDES ? "FILDES" : "INSTREAM");
}

/* A command with nothing to stream: PING, VERSION, STATS, RELOAD. */
static int cc_scan_command(cc_scan *s, const cc_target *t, const char *cmd) {
    cc_scan_reset(s, t, CC_TRANSPORT_NONE);
    return cc_scan_open(s, cmd);
}

static cc_phase cc_after_command(int transport) {
    if (transport == CC_TRANSPORT_FILDES)   return CC_PH_SEND_FD;
    if (transport == CC_TRANSPORT_INSTREAM) return CC_PH_STREAM;
    return CC_PH_READ;
}

#if CC_HAVE_FD_PASSING
/* The descriptor rides its own one-byte message, after the command -
 * see clamd_scan.h for why. It is a single sendmsg, so there is no
 * partial-progress state to keep. */
static ssize_t cc_send_fd(int sock, int fd) {
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
    memcpy(CMSG_DATA(cm), &fd, sizeof(int));

    do {
        n = sendmsg(sock, &msg, CC_MSG_NOSIGNAL);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1
     # uncoverable condition left count:2
     # uncoverable condition right count:2 */
    } while (n < 0 && errno == EINTR);
    return n;
}
#endif

/* Send what is left of a buffer. 1 when all of it has gone, 0 when the
 * socket is full and the caller should wait for it, -1 when the peer has
 * gone, -2 when the scan has failed. A partial send is the normal case
 * here rather than an exception, and an offset that does not survive
 * between steps corrupts the stream silently.
 *
 * The peer going mid-send is real - clamd hangs up at StreamMaxLength -
 * but a hangup is also readable, and the check for a pending reply
 * before every chunk sees it first unless clamd closes in the few
 * microseconds between that check and the send. No test can arrange
 * that on purpose, so the arm is marked as one a run may or may not
 * meet. */
static int cc_send_some(cc_scan *s, const char *buf, size_t len, size_t *off, int *progressed) {
    while (*off < len) {
        ssize_t n = cc_send(s->sock, buf + *off, len - *off, CC_MSG_NOSIGNAL);
        if (n > 0) { *off += (size_t)n; *progressed = 1; continue; }
        if (cc_would_block(errno)) return 0; /* # uncoverable branch false class:ignore_covered_err */
        /*
         # uncoverable statement class:ignore_covered_err
         # uncoverable branch true class:ignore_covered_err
         # uncoverable branch false
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition right count:1 */
        if (cc_errno_is_closed(errno)) return -1;
        cc_fail(s, CC_ERR_IO, "send", strerror(errno)); /* # uncoverable statement */
        return -2; /* # uncoverable statement */
    }
    return 1;
}

/* Advance as far as possible without blocking.
 *
 * Returns CC_STEP_DONE when finished (check s->rc and s->reply), or
 * CC_STEP_MORE with s->want naming the readiness to wait for.
 */
static int cc_scan_step(cc_scan *s) {
    int progressed = 0;

    if (s->phase == CC_PH_DONE) return CC_STEP_DONE;

    if (cc_now() > s->deadline) {
        cc_fail(s, CC_ERR_TIMEOUT, "deadline exceeded", NULL);
        return CC_STEP_DONE;
    }

    for (;;) {
        switch (s->phase) { /* # uncoverable branch true count:4 */

        /* The command, then for FILDES the descriptor's own message.
         * Neither can meet a full socket: both go out first on a fresh
         * connection, and the second is one byte. */
        case CC_PH_SEND_CMD:
        case CC_PH_SEND_FD: {
            ssize_t n;
            if (s->phase == CC_PH_SEND_CMD) {
                n = cc_send(s->sock, s->cmd + s->cmdoff, s->cmdlen - s->cmdoff, CC_MSG_NOSIGNAL);
                if (n > 0) {
                    s->cmdoff += (size_t)n;
                    progressed = 1;
                    /*
                     # uncoverable branch true
                     # uncoverable condition left count:1 */
                    if (s->cmdoff < s->cmdlen) continue;
                    s->phase = cc_after_command(s->transport);
                    continue;
                }
            } else {
#if CC_HAVE_FD_PASSING
                n = cc_send_fd(s->sock, s->scan_fd);
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                if (n >= 0) {
                    progressed = 1;
                    s->phase = CC_PH_READ;
                    continue;
                }
#else
                cc_fail(s, CC_ERR_NOFDPASS,
                        "this platform cannot pass file descriptors", NULL);
                return CC_STEP_DONE;
#endif
            }
            /*
             # uncoverable branch true
             # uncoverable condition left count:1 */
            if (cc_would_block(errno)) {
                s->want = CC_WANT_WRITE; /* # uncoverable statement */
                goto more; /* # uncoverable statement */
            }
            cc_fail(s, cc_errno_is_closed(errno) ? CC_ERR_CLOSED : CC_ERR_IO, /* # uncoverable condition right count:1 */
                    "send", strerror(errno));
            return CC_STEP_DONE;
        }

        case CC_PH_STREAM: {
            int r;

            /* A reply arriving mid-write is a VERDICT. Checked before
             * every chunk, exactly as the blocking path did. */
            if (cc_reply_pending(s->sock)) {
                progressed = 1;
                s->phase = CC_PH_READ;
                continue;
            }

            /* The end of the input is a chunk of length zero, which is
             * exactly how the protocol spells the end of the stream. */
            if (!s->have_chunk) {
                const char *p = NULL;
                ssize_t n = cc_source_next(&s->src, &p, &s->err);
                if (n < 0) { cc_fail(s, CC_ERR_IO, NULL, NULL); return CC_STEP_DONE; }
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

            r = cc_send_some(s, (const char *)s->hdr, 4, &s->hdroff, &progressed);
            if (r == 1) r = cc_send_some(s, s->chunk, s->chunklen, &s->chunkoff, &progressed);
            if (r == 0) { s->want = CC_WANT_WRITE; goto more; }
            /*
             # uncoverable branch true class:ignore_covered_err
             # uncoverable condition left count:1 class:ignore_covered_err */
            if (r == -1) {
                /* clamd hung up mid-stream. Whatever it had to say is
                 * still there to be read, and that is the verdict. */
                s->phase = CC_PH_READ; /* # uncoverable statement class:ignore_covered_err */
                progressed = 1; /* # uncoverable statement class:ignore_covered_err */
                continue; /* # uncoverable statement class:ignore_covered_err */
            }
            /*
             # uncoverable branch true
             # uncoverable condition left count:1 */
            if (r < 0) return CC_STEP_DONE;

            s->have_chunk = 0;
            if (s->chunklen == 0) s->phase = CC_PH_READ;
            continue;
        }

        case CC_PH_READ: {
            char   term = (s->t.frame == CC_FRAME_N) ? '\n' : '\0';
            size_t hard = s->t.reply_max ? s->t.reply_max : (1024 * 1024);
            ssize_t n;
            size_t  room;

            /* INVARIANT: replycap never exceeds reply_max + 1, so the
             * ceiling binds on every read rather than only on the reads
             * that happen to grow the buffer. Getting this wrong makes
             * reply_max unenforced for any reply smaller than the initial
             * allocation, which is most of them. */
            if (!s->reply) {
                s->replycap = 512;
                if (s->replycap > hard + 1) s->replycap = hard + 1;
                s->reply = (char *)malloc(s->replycap);
                /*
                 # uncoverable branch true
                 # uncoverable condition left count:1 */
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
                nb = (char *)realloc(s->reply, ncap);
                /*
                 # uncoverable branch true
                 # uncoverable condition left count:1 */
                if (!nb) { cc_fail(s, CC_ERR_IO, "out of memory", NULL); return CC_STEP_DONE; }
                s->reply = nb; s->replycap = ncap;
            }

            room = s->replycap - s->replylen - 1;

            n = cc_recv(s->sock, s->reply + s->replylen, room);
            if (n > 0) {
                size_t start = s->replylen, i;
                s->replylen += (size_t)n;
                progressed = 1;
                /* the terminator can land anywhere in what just arrived */
                for (i = start; i < s->replylen; i++) {
                    if (s->reply[i] == term) {
                        s->replylen = i;
                        cc_finish(s);
                        return CC_STEP_DONE;
                    }
                }
                continue;
            }
            if (n == 0 || cc_errno_is_closed(errno)) {
                /* A reset IS the close being looked for: when the peer
                 * hangs up with our bytes still unread - which is
                 * exactly what clamd does at StreamMaxLength - Linux
                 * reports ECONNRESET here, not EOF. Same event, same
                 * handling, or the cut shows up as a generic IO error
                 * on every Linux box.
                 *
                 * clamd does close after most replies, so a
                 * complete-looking reply that simply ended is still a
                 * reply; an empty one is not. */
                if (s->replylen > 0) {
                    cc_finish(s);
                    return CC_STEP_DONE;
                }
                if (s->transport == CC_TRANSPORT_NONE)
                    cc_fail(s, CC_ERR_CLOSED, "peer closed without a reply", NULL);
                else
                    cc_fail(s, CC_ERR_STREAMCUT,
                            "clamd closed the stream without a verdict "
                            "(usually StreamMaxLength exceeded)", NULL);
                return CC_STEP_DONE;
            }
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (cc_would_block(errno)) {
                s->want = CC_WANT_READ;
                goto more;
            }
            cc_fail(s, CC_ERR_IO, "recv", strerror(errno)); /* # uncoverable statement */
            return CC_STEP_DONE; /* # uncoverable statement */
        }

        default: /* # uncoverable statement */
            s->want = CC_WANT_NONE; /* # uncoverable statement */
            return CC_STEP_DONE; /* # uncoverable statement */
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
            cc_parse_reply(s->reply, s->replylen, &s->verdict);
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
    cc_fail(s, CC_ERR_CLOSED, "scan cancelled", NULL);
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
        if (w == 0) { cc_fail(s, CC_ERR_TIMEOUT, "timed out waiting for clamd", NULL); break; }
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 */
        if (w < 0)  { cc_fail(s, CC_ERR_IO, "poll", strerror(errno)); break; }
    }

    *err = s->err;
    if (s->rc == CC_OK) {
        *out = s->reply; *outlen = s->replylen;
        s->reply = NULL;              /* ownership moves to the caller */
    }
    return s->rc;
}

/* connect, send one command, read one reply, close. Phase 0 decided on
 * a connection per command: IDSESSION dies whole when any one command in
 * it fails, taking every outstanding reply with it. */
static int cc_roundtrip(const cc_target *t, const char *cmd,
                        char **out, size_t *outlen, cc_err *err) {
    cc_scan sc;
    int rc = cc_scan_command(&sc, t, cmd);
    if (rc == CC_OK) rc = cc_scan_run(&sc, out, outlen, err);
    else *err = sc.err;
    cc_scan_free(&sc);
    return rc;
}

#endif /* CLAMD_ASYNC_H */
