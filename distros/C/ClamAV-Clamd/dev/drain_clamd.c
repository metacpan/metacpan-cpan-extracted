/* plan_clamav_clamd phase 3 - a peer that only drains.
 *
 * Chunk size affects syscall count, not scanning. Measured against a
 * real clamd the scanning cost buries it, so this strips clamd out:
 * accept, read until the stream terminator, reply. What is left is the
 * transfer, which is the thing the chunk size actually decides.
 *
 * cc -O2 -o dev/drain_clamd dev/drain_clamd.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>

int main(int argc, char **argv) {
    const char *path = argc > 1 ? argv[1] : "/tmp/cav/drain.sock";
    struct sockaddr_un addr;
    int l;
    static char buf[1 << 20];

    unlink(path);
    l = socket(AF_UNIX, SOCK_STREAM, 0);
    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);
    if (bind(l, (struct sockaddr *)&addr, sizeof addr) < 0) { perror("bind"); return 1; }
    chmod(path, 0666);
    listen(l, 64);
    printf("draining on %s\n", path); fflush(stdout);

    for (;;) {
        int c = accept(l, NULL, NULL);
        unsigned long long total = 0;
        if (c < 0) break;
        for (;;) {
            ssize_t n = read(c, buf, sizeof buf);
            if (n <= 0) break;
            total += (unsigned long long)n;
            /* The client sends a zero-length chunk to finish. Rather than
             * parse the framing, answer once the writer stops - the
             * measurement is the transfer, not the protocol. */
            if (n >= 4 && buf[n-4] == 0 && buf[n-3] == 0 && buf[n-2] == 0 && buf[n-1] == 0) {
                (void)!write(c, "stream: OK\0", 11);
                break;
            }
        }
        close(c);
    }
    close(l); unlink(path);
    return 0;
}
