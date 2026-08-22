/* clamd_compat.h - the platform bits, probed rather than assumed.
 *
 * The rule here is the one the FreeBSD 9 / gcc 4.2.1 smoker taught:
 * test for the feature, never for the compiler or its version.
 */
#ifndef CLAMD_COMPAT_H
#define CLAMD_COMPAT_H

#ifdef _WIN32
#  include <winsock2.h>
#  include <ws2tcpip.h>
   typedef int cc_socklen_t;
#  define CC_INVALID_SOCK   INVALID_SOCKET
#  define cc_close_sock(s)  closesocket(s)
#  define cc_sock_errno()   WSAGetLastError()
   /* Windows has AF_UNIX from Win10 1803, but it has no SCM_RIGHTS and
    * no descriptor passing at all - so FILDES can never work there. That
    * is a phase 2 decision; what matters here is that it is a platform
    * fact and not a build accident. */
#  define CC_HAVE_FD_PASSING 0
#else
#  include <sys/types.h>
#  include <sys/socket.h>
#  include <sys/un.h>
#  include <netinet/in.h>
#  include <netinet/tcp.h>
#  include <arpa/inet.h>
#  include <netdb.h>
#  include <unistd.h>
#  include <fcntl.h>
#  include <errno.h>
   typedef socklen_t cc_socklen_t;
#  define CC_INVALID_SOCK   (-1)
#  define cc_close_sock(s)  close(s)
#  define cc_sock_errno()   errno
#  define CC_HAVE_FD_PASSING 1
#endif

#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

#ifdef HAVE_POLL_H
#  include <poll.h>
#endif
#ifndef _WIN32
#  include <poll.h>
#endif

/* Writing to a socket the peer has closed raises SIGPIPE, whose default
 * disposition kills the process. A library that takes down its caller
 * because clamd hung up is not usable inside a server, and clamd hangs
 * up routinely - it does exactly that when a stream exceeds
 * StreamMaxLength.
 *
 * There is no single portable answer, so both are used:
 *   MSG_NOSIGNAL   per-call, Linux and modern POSIX
 *   SO_NOSIGPIPE   per-socket, macOS and the BSDs
 * Neither exists everywhere; where neither does, every send still
 * reports EPIPE and the caller's own disposition governs.
 *
 * This is also why nothing below uses write() or writev(): they take no
 * flags. sendmsg() carries an iovec and takes flags, so it does both
 * jobs at once.
 */
#ifdef MSG_NOSIGNAL
#  define CC_MSG_NOSIGNAL MSG_NOSIGNAL
#else
#  define CC_MSG_NOSIGNAL 0
#endif

/* "The peer has gone" is spelled differently per platform, and getting
 * the set wrong turns a stream clamd deliberately closed into a generic
 * IO error - which loses the distinction between "no verdict" and
 * "something broke". macOS in particular answers ENOTCONN where Linux
 * answers EPIPE. */
static int cc_errno_is_closed(int e) {
#ifdef _WIN32
    return e == WSAECONNRESET || e == WSAECONNABORTED || e == WSAENOTCONN
        || e == WSAESHUTDOWN;
#else
    if (e == EPIPE || e == ECONNRESET || e == ENOTCONN) return 1;
#  ifdef ESHUTDOWN
    if (e == ESHUTDOWN) return 1;
#  endif
#  ifdef ECONNABORTED
    if (e == ECONNABORTED) return 1;
#  endif
    return 0;
#endif
}

static void cc_suppress_sigpipe(int fd) {
#ifdef SO_NOSIGPIPE
    int one = 1;
    (void)setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&one, sizeof one);
#else
    (void)fd;
#endif
}

/* Monotonic where it exists, wall clock where it does not. A deadline
 * computed off a clock that can step backwards is a timeout that can
 * fail to fire, so prefer CLOCK_MONOTONIC and say so. */
static double cc_now(void) {
#if defined(CLOCK_MONOTONIC)
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0)
        return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
#endif
    {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
    }
}

/* The largest path a UNIX socket address can hold, including its NUL.
 * 104 on the BSDs and macOS, 108 on Linux. This is not a suggestion:
 * the kernel copies a fixed-size array, so anything longer is silently
 * truncated by whoever writes it. */
#ifndef _WIN32
#  define CC_SUN_PATH_MAX (sizeof(((struct sockaddr_un *)0)->sun_path))
#endif

static int cc_set_nonblock(int fd, int on) {
#ifdef _WIN32
    u_long v = on ? 1 : 0;
    return ioctlsocket(fd, FIONBIO, &v) == 0 ? 0 : -1;
#else
    int fl = fcntl(fd, F_GETFL, 0);
    if (fl < 0) return -1;
    fl = on ? (fl | O_NONBLOCK) : (fl & ~O_NONBLOCK);
    return fcntl(fd, F_SETFL, fl) == 0 ? 0 : -1;
#endif
}

/* Wait for readiness with a deadline. Returns 1 ready, 0 timed out,
 * -1 error. EINTR restarts against the deadline rather than the original
 * timeout, or a stream of signals turns a 2 second wait into forever. */
static int cc_wait(int fd, int for_write, double deadline) {
    for (;;) {
        struct pollfd p;
        int ms, r;
        double left = deadline - cc_now();
        if (left <= 0) return 0;
        ms = (int)(left * 1000);
        if (ms < 1) ms = 1;
        p.fd = fd;
        p.events = for_write ? POLLOUT : POLLIN;
        p.revents = 0;
        r = poll(&p, 1, ms);
        if (r > 0) return 1;
        if (r == 0) return 0;
#ifndef _WIN32
        if (errno == EINTR) continue;
#endif
        return -1;
    }
}

#endif /* CLAMD_COMPAT_H */
