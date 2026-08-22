/* plan_clamav_clamd phase 0 - ground truth for the FILDES handshake.
 *
 * A listener that dumps every byte a real client sends, and says whether
 * an SCM_RIGHTS descriptor arrived with it. Point clamdscan --fdpass at
 * this and it prints the protocol rather than the documentation.
 *
 * cc -o fake_clamd dev/fake_clamd.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>

static void dump(const char *buf, ssize_t n) {
    for (ssize_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)buf[i];
        if (c == 0)                  printf("\\0");
        else if (c == '\n')          printf("\\n");
        else if (c >= 32 && c < 127) putchar(c);
        else                         printf("\\x%02x", c);
    }
}

int main(int argc, char **argv) {
    const char *path  = argc > 1 ? argv[1] : "/tmp/fake-clamd.sock";
    const char *reply = argc > 2 ? argv[2] : "1: /x: OK";
    struct sockaddr_un addr;
    int l, c, step = 0;

    unlink(path);
    l = socket(AF_UNIX, SOCK_STREAM, 0);
    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);
    if (bind(l, (struct sockaddr *)&addr, sizeof addr) < 0) { perror("bind"); return 1; }
    chmod(path, 0666);
    listen(l, 5);
    printf("fake clamd listening on %s\n", path);
    fflush(stdout);

    c = accept(l, NULL, NULL);
    if (c < 0) { perror("accept"); return 1; }
    printf("client connected\n");

    for (;;) {
        char buf[8192];
        union { struct cmsghdr align; char b[CMSG_SPACE(sizeof(int) * 4)]; } ctl;
        struct msghdr msg;
        struct iovec iov;
        struct cmsghdr *cm;
        ssize_t n;
        int nfds = 0;

        memset(&msg, 0, sizeof msg);
        memset(&ctl, 0, sizeof ctl);
        iov.iov_base = buf; iov.iov_len = sizeof buf;
        msg.msg_iov = &iov; msg.msg_iovlen = 1;
        msg.msg_control = ctl.b; msg.msg_controllen = sizeof ctl.b;

        n = recvmsg(c, &msg, 0);
        if (n < 0) { perror("recvmsg"); break; }
        if (n == 0) { printf("[client closed]\n"); break; }

        for (cm = CMSG_FIRSTHDR(&msg); cm; cm = CMSG_NXTHDR(&msg, cm))
            if (cm->cmsg_level == SOL_SOCKET && cm->cmsg_type == SCM_RIGHTS)
                nfds += (int)((cm->cmsg_len - CMSG_LEN(0)) / sizeof(int));

        printf("recv[%d] %zd bytes, fds=%d, flags=0x%x, data=\"",
               step++, n, nfds, msg.msg_flags);
        dump(buf, n);
        printf("\"\n");
        fflush(stdout);

        /* Answer anything that looked like a command so the client
         * carries on and shows us the next step. */
        if (n > 0) {
            char out[512];
            int len = snprintf(out, sizeof out, "%s", reply);
            (void)!write(c, out, len + 1);   /* NUL-terminated, z-style */
        }
    }
    close(c); close(l); unlink(path);
    return 0;
}
