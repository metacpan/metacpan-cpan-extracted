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
#  include <windows.h>
#  include <io.h>
#  include <fcntl.h>
#  include <errno.h>
#  include <sys/types.h>
#  include <sys/stat.h>
   typedef int cc_socklen_t;
   /* A socket is held in an int everywhere in this dist, so the invalid
    * one is -1 here as well and not INVALID_SOCKET, which is unsigned and
    * 64 bits wide. Kernel handles fit in 32 bits on Win64. */
#  define CC_INVALID_SOCK   (-1)
#  define cc_close_sock(s)  closesocket((SOCKET)(s))
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
   /* Descriptor passing is a fact about the headers in front of us, not
    * about the operating system. Solaris and illumos keep the 4.3BSD
    * msghdr - the one with msg_accrights and no msg_control - and hide
    * the CMSG_* macros until _XPG4_2 is defined, and perl.h has already
    * included <sys/socket.h> by the time this file is read, so the define
    * has to arrive on the command line. Makefile.PL probes for the
    * spelling that works there.
    *
    * Where the macros stay hidden, SCM_RIGHTS cannot be spoken at all:
    * FILDES compiles out and cc_scan_fd falls back to INSTREAM, which is
    * slower and correct. Testing the macros rather than the platform is
    * also what catches the case where the probe never ran.
    */
#  if defined(CC_NO_FD_PASSING) || !defined(SCM_RIGHTS) \
   || !defined(CMSG_SPACE) || !defined(CMSG_LEN) \
   || !defined(CMSG_FIRSTHDR) || !defined(CMSG_DATA)
#    define CC_HAVE_FD_PASSING 0
#  else
#    define CC_HAVE_FD_PASSING 1
#  endif
#endif

#include <string.h>
#include <stdlib.h>
#include <time.h>

#ifndef _WIN32
#  include <sys/time.h>
#  include <sys/stat.h>
#  include <poll.h>
#endif

/* The file side. The underscore names on Windows are deliberate: perl
 * renames the plain ones (read, open, close, fstat) there, and its fstat
 * wants perl's own stat struct. The descriptor is opened binary, or the
 * C runtime rewrites line endings and stops at ^Z - in a scanner, that
 * is a file clamd never saw the whole of. */
#ifdef _WIN32
   typedef struct _stat64 cc_stat_t;
#  define cc_fstat(fd, st)   _fstat64((fd), (st))
#  define cc_open_ro(path)   _open((path), _O_RDONLY | _O_BINARY)
#  define cc_read_fd(fd, b, n) _read((fd), (b), (unsigned int)(n))
#  define cc_close_fd(fd)    _close(fd)
#  define CC_S_ISREG(m)      (((m) & _S_IFMT) == _S_IFREG)
#else
   typedef struct stat cc_stat_t;
#  define cc_fstat(fd, st)   fstat((fd), (st))
#  define cc_open_ro(path)   open((path), O_RDONLY)
#  define cc_read_fd(fd, b, n) read((fd), (b), (n))
#  define cc_close_fd(fd)    close(fd)
#  define CC_S_ISREG(m)      S_ISREG(m)
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
    return e == EPIPE;
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

/* Winsock reports through WSAGetLastError and never touches errno, and
 * every caller below reads errno. So the socket calls go through these,
 * which translate once: would-block to EAGAIN, every spelling of "the
 * peer has gone" to EPIPE, the rest to EIO. Elsewhere they are the plain
 * calls. */
#ifdef _WIN32
static void cc_wsa_to_errno(void) {
    switch (WSAGetLastError()) {
    case WSAEWOULDBLOCK:
    case WSAEINPROGRESS:
    case WSAEALREADY:      errno = EAGAIN; break;
    case WSAEINTR:         errno = EINTR;  break;
    case WSAECONNRESET:
    case WSAECONNABORTED:
    case WSAENOTCONN:
    case WSAESHUTDOWN:
    case WSAENETRESET:     errno = EPIPE;  break;
    default:               errno = EIO;    break;
    }
}

static ssize_t cc_send(int fd, const char *buf, size_t len, int flags) {
    int n = send((SOCKET)fd, buf, (int)len, flags);
    if (n == SOCKET_ERROR) { cc_wsa_to_errno(); return -1; }
    return (ssize_t)n;
}

static ssize_t cc_recv(int fd, char *buf, size_t len) {
    int n = recv((SOCKET)fd, buf, (int)len, 0);
    if (n == SOCKET_ERROR) { cc_wsa_to_errno(); return -1; }
    return (ssize_t)n;
}

/* Winsock has to be started before the first call into it. perl starts
 * it lazily inside its own socket wrappers, which this dist does not go
 * through, so it cannot be assumed. WSAStartup is counted, and the one
 * reference taken here is held for the life of the process. */
static int cc_net_init(void) {
    static int started = 0;
    WSADATA wsa;
    if (started) return 0;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) return -1;
    started = 1;
    return 0;
}
#else
#  define cc_send(fd, buf, len, flags) send((fd), (buf), (len), (flags))
#  define cc_recv(fd, buf, len)        recv((fd), (buf), (len), 0)
#  define cc_net_init()                0
#endif

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
#ifdef _WIN32
    LARGE_INTEGER freq, count;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&count);
    return (double)count.QuadPart / (double)freq.QuadPart;
#else
#  if defined(CLOCK_MONOTONIC)
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0)
        return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
#  endif
    {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
    }
#endif
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
    return ioctlsocket((SOCKET)fd, FIONBIO, &v) == 0 ? 0 : -1;
#else
    int fl = fcntl(fd, F_GETFL, 0);
    if (fl < 0) return -1;
    fl = on ? (fl | O_NONBLOCK) : (fl & ~O_NONBLOCK);
    return fcntl(fd, F_SETFL, fl) == 0 ? 0 : -1;
#endif
}

/* Wait for readiness with a deadline. Returns 1 ready, 0 timed out,
 * -1 error. EINTR restarts against the deadline rather than the original
 * timeout, or a stream of signals turns a 2 second wait into forever.
 *
 * Windows waits with select() and not WSAPoll(): before Windows 10 2004
 * WSAPoll never reports a connect that failed, so a refused connection
 * sat there until the timeout. select() reports it in the except set,
 * which counts as ready here - the caller's SO_ERROR or next call then
 * says what happened. */
#ifdef _WIN32
static int cc_select(int fd, int for_write, long sec, long usec) {
    fd_set rd, wr, ex;
    struct timeval tv;
    int r;
    FD_ZERO(&rd); FD_ZERO(&wr); FD_ZERO(&ex);
    if (for_write) FD_SET((SOCKET)fd, &wr); else FD_SET((SOCKET)fd, &rd);
    FD_SET((SOCKET)fd, &ex);
    tv.tv_sec = sec; tv.tv_usec = usec;
    r = select(0, &rd, &wr, &ex, &tv);
    if (r == SOCKET_ERROR) { cc_wsa_to_errno(); return -1; }
    return r > 0 ? 1 : 0;
}
#endif

static int cc_wait(int fd, int for_write, double deadline) {
    for (;;) {
        int ms, r;
        double left = deadline - cc_now();
        if (left <= 0) return 0;
        ms = (int)(left * 1000);
        if (ms < 1) ms = 1;
#ifdef _WIN32
        r = cc_select(fd, for_write, ms / 1000, (ms % 1000) * 1000);
#else
        {
            struct pollfd p;
            p.fd = fd;
            p.events = for_write ? POLLOUT : POLLIN;
            p.revents = 0;
            r = poll(&p, 1, ms);
        }
#endif
        if (r > 0) return 1;
        if (r == 0) return 0;
        if (errno == EINTR) continue;
        return -1;
    }
}

/* Is there something to read right now? Never waits. A hangup or an
 * error counts: either way the next read has an answer. */
static int cc_readable_now(int fd) {
#ifdef _WIN32
    return cc_select(fd, 0, 0, 0) > 0 ? 1 : 0;
#else
    struct pollfd p;
    p.fd = fd; p.events = POLLIN; p.revents = 0;
    return poll(&p, 1, 0) > 0 && (p.revents & (POLLIN | POLLHUP | POLLERR)) ? 1 : 0;
#endif
}

#endif /* CLAMD_COMPAT_H */
