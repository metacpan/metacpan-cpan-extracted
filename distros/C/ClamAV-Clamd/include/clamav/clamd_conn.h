/* clamd_conn.h - a target, an error, and a connection to clamd.
 *
 * Phase 1 of plan_clamav_clamd. Everything here is deliberately
 * transport-only: no verdicts, no scanning, no interpretation of what
 * came back. The framed command and the bounded reply used to live here
 * too, as a blocking loop of their own; they are now the state machine
 * in clamd_async.h with nothing to stream, so there is one
 * implementation of the wire protocol and not two.
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
#define CC_ERR_NOTREG    -7   /* not a regular file */
#define CC_ERR_NOFDPASS  -8   /* this transport or platform cannot pass one */
/* -9 and -10 live in clamd_stream.h */
#define CC_ERR_UNAVAILABLE -11  /* clamd has this command switched off (Enable*Command no) */

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

/* "what: detail", or "what" alone, cut to fit. A detail is as often a
 * path from the configuration as a strerror, so the cut is not academic. */
static void cc_err_set(cc_err *e, int code, const char *what, const char *detail) {
    e->code = code;
    if (detail) snprintf(e->msg, sizeof e->msg, "%s: %s", what, detail);
    else        snprintf(e->msg, sizeof e->msg, "%s", what);
}

/* Did a non-blocking connect that returned -1 begin at all? */
static int cc_connect_started(void) {
#ifdef _WIN32
    return cc_sock_errno() == WSAEWOULDBLOCK;
#else
    return errno == EINPROGRESS;
#endif
}

/* The second half of a non-blocking connect, given what the first half
 * returned. A UNIX connect completes or fails at once on every platform
 * this has met and a TCP one is still in flight, so the wait here is the
 * same code for both and is exercised by TCP. */
static int cc_finish_connect(int fd, int r, double deadline, const char *name, cc_err *err) {
    int w, soerr = 0;
    cc_socklen_t sl = sizeof soerr;

    if (r == 0) return CC_OK;
    if (!cc_connect_started()) {
        cc_err_set(err, CC_ERR_CONNECT, "connect", strerror(errno));
        return CC_ERR_CONNECT;
    }
    w = cc_wait(fd, 1, deadline);
    if (w == 0) {
        cc_err_set(err, CC_ERR_TIMEOUT, "connect timed out", name);
        return CC_ERR_TIMEOUT;
    }
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (w < 0) {
        cc_err_set(err, CC_ERR_CONNECT, "poll", strerror(errno)); /* # uncoverable statement */
        return CC_ERR_CONNECT; /* # uncoverable statement */
    }
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (getsockopt(fd, SOL_SOCKET, SO_ERROR, (void *)&soerr, &sl) < 0) soerr = errno;
    if (soerr) {
        cc_err_set(err, CC_ERR_CONNECT, "connect", strerror(soerr));
        return CC_ERR_CONNECT;
    }
    return CC_OK;
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

    if (len >= CC_SUN_PATH_MAX) {
        cc_err_set(err, CC_ERR_CONFIG,
                   "socket path too long for this platform's sockaddr_un",
                   t->path);
        return CC_INVALID_SOCK;
    }

    fd = socket(AF_UNIX, SOCK_STREAM, 0);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (fd < 0) { cc_err_set(err, CC_ERR_CONNECT, "socket", strerror(errno)); return CC_INVALID_SOCK; }
    cc_suppress_sigpipe(fd);

    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    memcpy(addr.sun_path, t->path, len);
    addr.sun_path[len] = '\0';

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (cc_set_nonblock(fd) < 0) {
        cc_err_set(err, CC_ERR_CONNECT, "fcntl", strerror(errno)); /* # uncoverable statement */
        cc_close_sock(fd); return CC_INVALID_SOCK; /* # uncoverable statement */
    }

    r = connect(fd, (struct sockaddr *)&addr, (cc_socklen_t)sizeof addr);
    if (cc_finish_connect(fd, r, cc_now() + t->connect_timeout, t->path, err) != CC_OK) {
        cc_close_sock(fd);
        return CC_INVALID_SOCK;
    }
    return fd;
}
#endif

static int cc_connect_tcp(const cc_target *t, cc_err *err) {
    struct addrinfo hints, *res = NULL, *ai;
    char portbuf[16];
    int fd = CC_INVALID_SOCK, gai;
    double deadline = cc_now() + t->connect_timeout;

    if (cc_net_init() < 0) {
        cc_err_set(err, CC_ERR_CONNECT, "WSAStartup failed", NULL);
        return CC_INVALID_SOCK;
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    snprintf(portbuf, sizeof portbuf, "%d", t->port);
    gai = getaddrinfo(t->host, portbuf, &hints, &res);
    if (gai != 0) {
        cc_err_set(err, CC_ERR_CONNECT, "resolve", gai_strerror(gai));
        return CC_INVALID_SOCK;
    }

    for (ai = res; ai; ai = ai->ai_next) {
        int r, rc;
        fd = (int)socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 */
        if (fd < 0) continue;
        cc_suppress_sigpipe(fd);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 */
        if (cc_set_nonblock(fd) < 0) { cc_close_sock(fd); fd = CC_INVALID_SOCK; continue; }

#ifdef _WIN32
        r = connect((SOCKET)fd, ai->ai_addr, (cc_socklen_t)ai->ai_addrlen);
#else
        r = connect(fd, ai->ai_addr, (cc_socklen_t)ai->ai_addrlen);
#endif
        rc = cc_finish_connect(fd, r, deadline, t->host, err);
        if (rc == CC_OK) break;
        cc_close_sock(fd);
        fd = CC_INVALID_SOCK;
        /* A timeout is the deadline for the whole attempt, not for one
         * address; a refusal leaves the next address its turn. */
        if (rc == CC_ERR_TIMEOUT) break;
    }
    freeaddrinfo(res);

    if (fd == CC_INVALID_SOCK) {
        if (err->code != CC_ERR_TIMEOUT)
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

#endif /* CLAMD_CONN_H */
