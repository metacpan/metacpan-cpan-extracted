/* plan_clamav_clamd phase 0 - does FILDES work, and what does it reply?
 *
 * Core Perl cannot send an SCM_RIGHTS control message and Socket::MsgHdr
 * is not installed, so this is C - which is where the real client is
 * going to live anyway. This file is the phase 2 descriptor pass in
 * miniature.
 *
 * cc -o fildes_probe dev/fildes_probe.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/un.h>

static int clamd_connect(const char *path) {
    struct sockaddr_un addr;
    int s = socket(AF_UNIX, SOCK_STREAM, 0);
    if (s < 0) { perror("socket"); return -1; }
    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);
    if (connect(s, (struct sockaddr *)&addr, sizeof addr) < 0) {
        perror("connect"); close(s); return -1;
    }
    return s;
}

/* Send "zFILDES\0" with exactly one descriptor attached. Every offset
 * goes through the CMSG_* macros - the alignment rules are the kind of
 * thing that works by accident on one platform and not the next. */
/* Which framing does FILDES actually want? Set by FILDES_FRAMING. */
static const char *framing(size_t *len) {
    const char *f = getenv("FILDES_FRAMING");
    if (!f) f = "z";
    if (!strcmp(f, "z"))    { *len = 8; return "zFILDES\0"; }
    if (!strcmp(f, "n"))    { *len = 8; return "nFILDES\n"; }
    if (!strcmp(f, "bare")) { *len = 7; return "FILDES";   }
    if (!strcmp(f, "barenl")){ *len = 7; return "FILDES\n"; }
    *len = 8; return "zFILDES\0";
}

/* THE HANDSHAKE, as captured from clamdscan --fdpass against a listener
 * that dumps what it receives:
 *
 *   write   "zFILDES\0"   -- the command, ALONE, no ancillary data
 *   sendmsg "\0" + fd     -- one NUL byte carrying SCM_RIGHTS
 *
 * Attaching the descriptor to the command itself - the obvious reading -
 * gets "PROTOCOL ERROR: ancillary data sent without FILDES", because
 * clamd sees the control message on a read where the command has not
 * been dispatched yet. Two messages, in this order. */
static int send_fildes(int sock, int fd) {
    struct msghdr msg;
    struct iovec iov;
    union {
        struct cmsghdr align;
        char buf[CMSG_SPACE(sizeof(int))];
    } control;
    struct cmsghdr *cmsg;
    size_t cmdlen;
    const char *cmd = framing(&cmdlen);
    char pad = '\0';

    if (write(sock, cmd, cmdlen) != (ssize_t)cmdlen) return -1;

    memset(&msg, 0, sizeof msg);
    memset(&control, 0, sizeof control);

    iov.iov_base = &pad;
    iov.iov_len  = 1;

    msg.msg_iov        = &iov;
    msg.msg_iovlen     = 1;
    msg.msg_control    = control.buf;
    msg.msg_controllen = CMSG_SPACE(sizeof(int));

    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type  = SCM_RIGHTS;
    cmsg->cmsg_len   = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(cmsg), &fd, sizeof(int));

    return sendmsg(sock, &msg, 0) < 0 ? -1 : 0;
}

static void show(const char *label, const char *buf, ssize_t n) {
    printf("%-28s reply=", label);
    if (n <= 0) { printf("<no reply, n=%zd>\n", n); return; }
    for (ssize_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)buf[i];
        if (c == 0)            printf("\\0");
        else if (c == '\n')    printf("\\n");
        else if (c >= 32 && c < 127) putchar(c);
        else                   printf("\\x%02x", c);
    }
    putchar('\n');
}

static void scan_path(const char *sockpath, const char *label, const char *file) {
    char buf[4096];
    ssize_t n;
    int s, fd;

    fd = open(file, O_RDONLY);
    if (fd < 0) { printf("%-28s open failed: %s\n", label, strerror(errno)); return; }

    s = clamd_connect(sockpath);
    if (s < 0) { close(fd); return; }

    /* clamdscan --fdpass wraps FILDES in a session; test whether that is
     * decoration or a requirement. */
    if (getenv("FILDES_SESSION")) (void)!write(s, "zIDSESSION\0", 11);

    if (send_fildes(s, fd) < 0) {
        printf("%-28s sendmsg failed: %s\n", label, strerror(errno));
        close(fd); close(s); return;
    }
    close(fd);                        /* clamd has its own reference now */

    n = read(s, buf, sizeof buf);
    show(label, buf, n);
    if (getenv("FILDES_SESSION")) (void)!write(s, "zEND\0", 5);
    close(s);
}

/* Hand over a descriptor already read from, to see whether clamd honours
 * the inherited file offset - if it does, a caller that peeked at the
 * file first gets a scan of the remainder and a clean verdict on a file
 * whose signature was in the part already consumed. */
static void scan_at_offset(const char *sockpath, const char *label,
                           const char *file, off_t off) {
    char buf[4096];
    ssize_t n;
    int s, fd;

    fd = open(file, O_RDONLY);
    if (fd < 0) { printf("%-28s open failed\n", label); return; }
    if (lseek(fd, off, SEEK_SET) == (off_t)-1) { printf("seek failed\n"); close(fd); return; }

    s = clamd_connect(sockpath);
    if (s < 0) { close(fd); return; }
    if (send_fildes(s, fd) < 0) { printf("%-28s sendmsg failed\n", label); close(fd); close(s); return; }
    close(fd);

    n = read(s, buf, sizeof buf);
    show(label, buf, n);
    close(s);
}

int main(int argc, char **argv) {
    const char *sock = getenv("CLAMD_SOCK");
    if (!sock) sock = "/opt/homebrew/var/run/clamav/clamd.sock";

    if (argc > 2 && strcmp(argv[1], "--offset") == 0) {
        scan_at_offset(sock, "fd at offset", argv[2], atol(argv[3]));
        return 0;
    }
    for (int i = 1; i < argc; i++) scan_path(sock, argv[i], argv[i]);
    return 0;
}
