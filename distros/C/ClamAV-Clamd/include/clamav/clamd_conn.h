/* clamd_conn.h - a connection, a framed command, and a bounded reply.
 *
 * Phase 1 of plan_clamav_clamd. Everything here is deliberately
 * transport-only: no verdicts, no scanning, no interpretation of what
 * came back beyond finding where it ends.
 */
#ifndef CLAMD_CONN_H
#define CLAMD_CONN_H

#include "clamav/clamd_compat.h"

#define CC_OK             0
#define CC_ERR_CONNECT   -1
#define CC_ERR_TIMEOUT   -2
#define CC_ERR_IO        -3
#define CC_ERR_TOOBIG    -4
#define CC_ERR_CONFIG    -5
#define CC_ERR_CLOSED    -6

#define CC_ERRLEN 256

/* Reply framing. clamd terminates its reply the same way the request was
 * terminated - measured, not assumed: zPING\0 answers PONG\0 and
 * nPING\n answers PONG\n. The client picks one and reads for it. */
#define CC_FRAME_Z  0   /* NUL-terminated - the default */
#define CC_FRAME_N  1   /* newline-terminated */

typedef struct {
    char   *path;              /* UNIX socket path, or NULL for TCP */
    char   *host;              /* TCP host, or NULL for UNIX */
    int     port;
    double  connect_timeout;
    double  reply_timeout;
    size_t  reply_max;         /* ceiling on a single reply */
    size_t  chunk;             /* INSTREAM chunk size, 0 = default */
    size_t  max_size;          /* local refusal ceiling, 0 = unset */
    int     frame;
} cc_target;

/* Which transport actually produced a verdict. A scan that fell back
 * from FILDES to INSTREAM crossed the socket in full, and an operator
 * wondering why one deployment is slower than another should be able to
 * read that off a field rather than infer it from a graph. */
#define CC_TRANSPORT_NONE     0
#define CC_TRANSPORT_FILDES   1
#define CC_TRANSPORT_INSTREAM 2

typedef struct {
    int   code;
    char  msg[CC_ERRLEN];
} cc_err;

static void cc_err_set(cc_err *e, int code, const char *fmt_prefix, const char *detail) {
    if (!e) return;
    e->code = code;
    e->msg[0] = '\0';
    if (fmt_prefix) {
        size_t n = strlen(fmt_prefix);
        if (n >= CC_ERRLEN) n = CC_ERRLEN - 1;
        memcpy(e->msg, fmt_prefix, n);
        e->msg[n] = '\0';
    }
    if (detail) {
        size_t have = strlen(e->msg), room = CC_ERRLEN - 1 - have;
        if (room > 2) {
            memcpy(e->msg + have, ": ", 2);
            have += 2; room -= 2;
            {
                size_t dn = strlen(detail);
                if (dn > room) dn = room;
                memcpy(e->msg + have, detail, dn);
                e->msg[have + dn] = '\0';
            }
        }
    }
}

#ifndef _WIN32
/* A UNIX socket path that does not fit is REFUSED, never truncated.
 * strncpy into sun_path silently drops the tail, and the process then
 * binds or connects to a different socket than the one configured -
 * which for a scanner means talking to something that is not clamd.
 * This was found the hard way in phase 0: a 105-byte path became a
 * socket called "fake.so". */
static int cc_connect_unix(const cc_target *t, cc_err *err) {
    struct sockaddr_un addr;
    size_t len = strlen(t->path);
    int fd, r;
    double deadline;

    if (len >= CC_SUN_PATH_MAX) {
        cc_err_set(err, CC_ERR_CONFIG,
                   "socket path too long for this platform's sockaddr_un",
                   t->path);
        return CC_INVALID_SOCK;
    }

    fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) { cc_err_set(err, CC_ERR_CONNECT, "socket", strerror(errno)); return CC_INVALID_SOCK; }
    cc_suppress_sigpipe(fd);

    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    memcpy(addr.sun_path, t->path, len);
    addr.sun_path[len] = '\0';

    if (cc_set_nonblock(fd, 1) < 0) {
        cc_err_set(err, CC_ERR_CONNECT, "fcntl", strerror(errno));
        cc_close_sock(fd); return CC_INVALID_SOCK;
    }

    deadline = cc_now() + t->connect_timeout;
    r = connect(fd, (struct sockaddr *)&addr, (cc_socklen_t)sizeof addr);
    if (r < 0 && errno != EINPROGRESS) {
        cc_err_set(err, CC_ERR_CONNECT, "connect", strerror(errno));
        cc_close_sock(fd); return CC_INVALID_SOCK;
    }
    if (r < 0) {
        int w = cc_wait(fd, 1, deadline);
        int soerr = 0;
        cc_socklen_t sl = sizeof soerr;
        if (w == 0) {
            cc_err_set(err, CC_ERR_TIMEOUT, "connect timed out", t->path);
            cc_close_sock(fd); return CC_INVALID_SOCK;
        }
        if (w < 0) {
            cc_err_set(err, CC_ERR_CONNECT, "poll", strerror(errno));
            cc_close_sock(fd); return CC_INVALID_SOCK;
        }
        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &soerr, &sl) < 0 || soerr) {
            cc_err_set(err, CC_ERR_CONNECT, "connect", strerror(soerr ? soerr : errno));
            cc_close_sock(fd); return CC_INVALID_SOCK;
        }
    }
    return fd;
}
#endif

static int cc_connect_tcp(const cc_target *t, cc_err *err) {
    struct addrinfo hints, *res = NULL, *ai;
    char portbuf[16];
    int fd = CC_INVALID_SOCK, gai;
    double deadline = cc_now() + t->connect_timeout;

    memset(&hints, 0, sizeof hints);
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    snprintf(portbuf, sizeof portbuf, "%d", t->port);
    gai = getaddrinfo(t->host, portbuf, &hints, &res);
    if (gai != 0 || !res) {
        cc_err_set(err, CC_ERR_CONNECT, "resolve", gai_strerror(gai));
        return CC_INVALID_SOCK;
    }

    for (ai = res; ai; ai = ai->ai_next) {
        int r;
        fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
        if (fd < 0) continue;
        cc_suppress_sigpipe(fd);
        if (cc_set_nonblock(fd, 1) < 0) { cc_close_sock(fd); fd = CC_INVALID_SOCK; continue; }

        r = connect(fd, ai->ai_addr, (cc_socklen_t)ai->ai_addrlen);
#ifdef _WIN32
        if (r < 0 && cc_sock_errno() != WSAEWOULDBLOCK) {
#else
        if (r < 0 && errno != EINPROGRESS) {
#endif
            cc_close_sock(fd); fd = CC_INVALID_SOCK; continue;
        }
        if (r < 0) {
            int w = cc_wait(fd, 1, deadline);
            int soerr = 0;
            cc_socklen_t sl = sizeof soerr;
            if (w == 0) {
                cc_err_set(err, CC_ERR_TIMEOUT, "connect timed out", t->host);
                cc_close_sock(fd); freeaddrinfo(res); return CC_INVALID_SOCK;
            }
            if (w < 0 || getsockopt(fd, SOL_SOCKET, SO_ERROR, (void *)&soerr, &sl) < 0 || soerr) {
                cc_close_sock(fd); fd = CC_INVALID_SOCK; continue;
            }
        }
        break;
    }
    freeaddrinfo(res);

    if (fd == CC_INVALID_SOCK) {
        cc_err_set(err, CC_ERR_CONNECT, "connect", t->host);
        return CC_INVALID_SOCK;
    }
    {   /* clamd replies are small and latency matters more than packing */
        int one = 1;
        (void)setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (void *)&one, sizeof one);
    }
    return fd;
}

static int cc_connect(const cc_target *t, cc_err *err) {
    if (t->path) {
#ifdef _WIN32
        cc_err_set(err, CC_ERR_CONFIG, "UNIX sockets are not supported on this platform", NULL);
        return CC_INVALID_SOCK;
#else
        return cc_connect_unix(t, err);
#endif
    }
    if (t->host) return cc_connect_tcp(t, err);
    cc_err_set(err, CC_ERR_CONFIG, "no socket path and no host configured", NULL);
    return CC_INVALID_SOCK;
}

/* Write everything, against a deadline. A short write on a non-blocking
 * socket is normal, not an error. */
static int cc_write_all(int fd, const char *buf, size_t len, double deadline, cc_err *err) {
    size_t off = 0;
    while (off < len) {
        int w;
        ssize_t n;
        /* send(), not write(): only send() takes MSG_NOSIGNAL, and a
         * SIGPIPE here would kill the caller's process. */
        n = send(fd, buf + off, (int)(len - off), CC_MSG_NOSIGNAL);
        if (n > 0) { off += (size_t)n; continue; }
        if (n == 0) { cc_err_set(err, CC_ERR_CLOSED, "peer closed during write", NULL); return CC_ERR_CLOSED; }
#ifndef _WIN32
        if (errno == EINTR) continue;
        if (cc_errno_is_closed(errno)) {
            cc_err_set(err, CC_ERR_CLOSED, "peer closed during write", NULL);
            return CC_ERR_CLOSED;
            }
        if (errno != EAGAIN && errno != EWOULDBLOCK) {
            cc_err_set(err, CC_ERR_IO, "send", strerror(errno));
            return CC_ERR_IO;
        }
#endif
        w = cc_wait(fd, 1, deadline);
        if (w == 0) { cc_err_set(err, CC_ERR_TIMEOUT, "write timed out", NULL); return CC_ERR_TIMEOUT; }
        if (w < 0)  { cc_err_set(err, CC_ERR_IO, "poll", strerror(errno)); return CC_ERR_IO; }
    }
    return CC_OK;
}

/* Send a command with the configured framing: "zPING\0" or "nPING\n".
 * One implementation, so no command builds its own frame by hand and
 * gets the terminator wrong - which phase 0 showed is not an error but
 * a silent hang. */
static int cc_send_command(int fd, const char *cmd, int frame, double deadline, cc_err *err) {
    char buf[256];
    size_t n = strlen(cmd);
    if (n + 2 > sizeof buf) { cc_err_set(err, CC_ERR_CONFIG, "command too long", cmd); return CC_ERR_CONFIG; }
    buf[0] = (frame == CC_FRAME_N) ? 'n' : 'z';
    memcpy(buf + 1, cmd, n);
    buf[n + 1] = (frame == CC_FRAME_N) ? '\n' : '\0';
    return cc_write_all(fd, buf, n + 2, deadline, err);
}

/* Read one reply, bounded.
 *
 * A reply is delimited, not length-prefixed, so this reads for the
 * terminator - and a reply is remote input, so it reads for the
 * terminator OR the ceiling, whichever comes first. Without the ceiling
 * a peer that never terminates is an allocation loop.
 *
 * Returns CC_OK and fills *out (malloc'd, NUL-terminated for
 * convenience) plus *outlen with the length excluding the terminator.
 * The caller frees.
 */
static int cc_read_reply(int fd, const cc_target *t, char **out, size_t *outlen, cc_err *err) {
    /* INVARIANT: cap never exceeds reply_max + 1, so the ceiling binds
     * on every read rather than only on the reads that happen to grow
     * the buffer. Getting this wrong makes reply_max unenforced for any
     * reply smaller than the initial allocation, which is most of them. */
    size_t hard = t->reply_max;
    size_t cap  = 512;
    size_t len  = 0;
    char  *buf;
    char   term = (t->frame == CC_FRAME_N) ? '\n' : '\0';
    double deadline = cc_now() + t->reply_timeout;

    *out = NULL; *outlen = 0;

    if (cap > hard + 1) cap = hard + 1;
    buf = (char *)malloc(cap);
    if (!buf) { cc_err_set(err, CC_ERR_IO, "out of memory", NULL); return CC_ERR_IO; }

    for (;;) {
        ssize_t n;
        int w;
        size_t room;

        if (len >= hard) {
            free(buf);
            cc_err_set(err, CC_ERR_TOOBIG, "reply exceeded the configured ceiling", NULL);
            return CC_ERR_TOOBIG;
        }

        if (len + 1 >= cap) {
            char *nb;
            size_t ncap = cap * 2;
            if (ncap > hard + 1) ncap = hard + 1;
            if (len + 1 >= ncap) {
                free(buf);
                cc_err_set(err, CC_ERR_TOOBIG, "reply exceeded the configured ceiling", NULL);
                return CC_ERR_TOOBIG;
            }
            nb = (char *)realloc(buf, ncap);
            if (!nb) { free(buf); cc_err_set(err, CC_ERR_IO, "out of memory", NULL); return CC_ERR_IO; }
            buf = nb; cap = ncap;
        }

        room = cap - len - 1;
        if (len + room > hard) room = hard - len;

#ifdef _WIN32
        n = recv(fd, buf + len, (int)room, 0);
#else
        n = read(fd, buf + len, room);
#endif
        if (n > 0) {
            size_t start = len;
            len += (size_t)n;
            {   /* the terminator can land anywhere in what just arrived */
                size_t i;
                for (i = start; i < len; i++) {
                    if (buf[i] == term) {
                        buf[i] = '\0';
                        *out = buf; *outlen = i;
                        return CC_OK;
                    }
                }
            }
            continue;
        }
        if (n == 0) {
            /* EOF without a terminator. clamd does close after most
             * replies, so a complete-looking reply that simply ended is
             * still a reply; an empty one is not. */
            if (len == 0) {
                free(buf);
                cc_err_set(err, CC_ERR_CLOSED, "peer closed without a reply", NULL);
                return CC_ERR_CLOSED;
            }
            buf[len] = '\0';
            *out = buf; *outlen = len;
            return CC_OK;
        }
#ifndef _WIN32
        if (errno == EINTR) continue;
        if (errno != EAGAIN && errno != EWOULDBLOCK) {
            free(buf);
            cc_err_set(err, CC_ERR_IO, "read", strerror(errno));
            return CC_ERR_IO;
        }
#endif
        w = cc_wait(fd, 0, deadline);
        if (w == 0) {
            free(buf);
            cc_err_set(err, CC_ERR_TIMEOUT, "timed out waiting for a reply", NULL);
            return CC_ERR_TIMEOUT;
        }
        if (w < 0) {
            free(buf);
            cc_err_set(err, CC_ERR_IO, "poll", strerror(errno));
            return CC_ERR_IO;
        }
    }
}

/* connect, send one command, read one reply, close. Phase 0 decided on
 * a connection per command: IDSESSION dies whole when any one command in
 * it fails, taking every outstanding reply with it. */
static int cc_roundtrip(const cc_target *t, const char *cmd,
                        char **out, size_t *outlen, cc_err *err) {
    int fd, rc;
    double deadline;

    err->code = CC_OK; err->msg[0] = '\0';
    fd = cc_connect(t, err);
    if (fd == CC_INVALID_SOCK) return err->code ? err->code : CC_ERR_CONNECT;

    deadline = cc_now() + t->reply_timeout;
    rc = cc_send_command(fd, cmd, t->frame, deadline, err);
    if (rc != CC_OK) { cc_close_sock(fd); return rc; }

    rc = cc_read_reply(fd, t, out, outlen, err);
    cc_close_sock(fd);
    return rc;
}

#endif /* CLAMD_CONN_H */
