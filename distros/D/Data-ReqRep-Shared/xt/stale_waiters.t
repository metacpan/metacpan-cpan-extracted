use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# A process killed while parked leaves its registration behind.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $inc = dirname(dirname(abs_path(__FILE__)));
-f "$inc/reqrep.h" or plan skip_all => 'reqrep.h not found';
my $dir = tempdir(CLEANUP => 1);

open my $fh, '>', "$dir/stale.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <signal.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <linux/futex.h>
static long wakes;
static long counted_syscall(long nr, ...) {
    va_list ap; va_start(ap, nr);
    long a[6];
    for (int i = 0; i < 6; i++) a[i] = va_arg(ap, long);
    va_end(ap);
    if (nr == SYS_futex && (a[1] & 127) == FUTEX_WAKE) wakes++;
    return syscall(nr, a[0], a[1], a[2], a[3], a[4], a[5]);
}
#define syscall counted_syscall
#include "reqrep.h"
#undef syscall

static void lock_mutex(ReqRepHandle *h) { while (reqrep_mutex_lock_until(h, NULL, -1) != 1) {} }

static int is_int;
static const char *path;
static ReqRepHandle *at(void) {
    char err[REQREP_ERR_BUFLEN];
    ReqRepHandle *h = reqrep_open(path, is_int ? REQREP_MODE_INT : REQREP_MODE_STR, err);
    if (!h) { printf("open: %s\n", err); exit(2); }
    return h;
}
static int send1(ReqRepHandle *h, uint64_t *id) {
    return is_int ? reqrep_int_try_send(h, 1, id) : reqrep_try_send(h, "x", 1, false, id);
}
static int recv1(ReqRepHandle *h, uint64_t *id, double t) {
    int64_t v; const char *s; uint32_t l; bool u;
    return is_int ? reqrep_int_recv_wait(h, &v, id, t) : reqrep_recv_wait(h, &s, &l, &u, id, t);
}
static int reply1(ReqRepHandle *h, uint64_t id) {
    return is_int ? reqrep_int_reply(h, id, 2) : reqrep_reply(h, id, "y", 1, false);
}
static int get1(ReqRepHandle *h, uint64_t id, double t) {
    int64_t v; const char *s; uint32_t l; bool u;
    return is_int ? reqrep_int_get_wait(h, id, &v, t) : reqrep_get_wait(h, id, &s, &l, &u, t);
}
/* Round trips on one process; returns FUTEX_WAKE calls made by the last half. */
static long trips(ReqRepHandle *c, ReqRepHandle *s, int n) {
    long before = 0;
    for (int i = 0; i < n; i++) {
        if (i == n / 2) before = wakes;
        uint64_t id, rid;
        if (send1(c, &id) != 1 || recv1(s, &rid, 1.0) != 1 || reply1(s, rid) != 1 || get1(c, id, 1.0) != 1) {
            printf("round trip %d failed\n", i); exit(1);
        }
    }
    return wakes - before;
}
static void settle(void) { usleep(200000); }
static pid_t park(int (*fn)(void)) {
    pid_t p = fork();
    if (!p) _exit(fn());
    settle();
    return p;
}
static void kill_parked(pid_t p) { kill(p, SIGKILL); waitpid(p, NULL, 0); }

static uint64_t parked_id;
static int park_recv(void) { uint64_t id; return recv1(at(), &id, -1.0); }
static int park_send(void) { uint64_t id; ReqRepHandle *h = at();
    return is_int ? reqrep_int_send_wait(h, 1, &id, -1.0) : reqrep_send_wait(h, "x", 1, false, &id, -1.0); }
static int park_get(void) { return get1(at(), parked_id, -1.0); }
static int park_lock(void) { ReqRepHandle *h = at(); uint64_t id; return is_int ? 0 : reqrep_try_recv(h, &(const char *){0}, &(uint32_t){0}, &(bool){0}, &id); }

int main(int argc, char **argv) {
    char err[REQREP_ERR_BUFLEN];
    is_int = !strcmp(argv[1], "int");
    const char *mode = argv[2];
    path = argv[3];
    unlink(path);
    ReqRepHandle *srv = is_int ? reqrep_create_int(path, 2, 3, 0600, err) : reqrep_create(path, 2, 3, 64, 0, 0600, err);
    if (!srv) { printf("create: %s\n", err); return 2; }
    ReqRepHandle *cli = at();
    uint64_t ids[3], rids[3];
    pid_t p;
    if (!strcmp(mode, "recv")) {
        p = park(park_recv);
    } else if (!strcmp(mode, "send")) {
        send1(cli, &ids[0]); send1(cli, &ids[1]);
        p = park(park_send);
    } else if (!strcmp(mode, "slot")) {
        for (int i = 0; i < 3; i++) { send1(cli, &ids[i]); recv1(srv, &rids[i], 1.0); }
        p = park(park_send);
    } else if (!strcmp(mode, "reply")) {
        send1(cli, &parked_id);
        p = park(park_get);
    } else if (!strcmp(mode, "mutex")) {
        if (is_int) { printf("wakes=0\n"); return 0; }
        lock_mutex(srv);
        p = park(park_lock);
    } else return 2;
    kill_parked(p);
    if (!strcmp(mode, "send")) for (int i = 0; i < 2; i++) { recv1(srv, &rids[i], 1.0); reply1(srv, rids[i]); get1(cli, ids[i], 1.0); }
    if (!strcmp(mode, "slot")) for (int i = 0; i < 3; i++) { reply1(srv, rids[i]); get1(cli, ids[i], 1.0); }
    if (!strcmp(mode, "reply")) { uint64_t rid; recv1(srv, &rid, 1.0); reply1(srv, rid); get1(cli, parked_id, 1.0); }
    if (!strcmp(mode, "mutex")) reqrep_mutex_unlock(srv);
    printf("wakes=%ld\n", trips(cli, srv, 64));
    unlink(path);
    return 0;
}
C
close $fh;

system($cc, '-O2', "-I$inc", '-o', "$dir/stale", "$dir/stale.c", '-lpthread') == 0
    or BAIL_OUT("cannot build the harness with $cc");

my %what = (
    recv  => 'a receiver',
    send  => 'a sender parked for queue room',
    slot  => 'a sender parked for a slot',
    reply => 'a client parked for its reply',
    mutex => 'a caller parked on the queue mutex',
);
for my $m (qw(str int)) {
    for my $mode (qw(recv send slot reply mutex)) {
        next if $m eq 'int' && $mode eq 'mutex';
        my $out = qx{timeout 60 "$dir/stale" $m $mode "$dir/s.shm" 2>&1};
        like $out, qr/^wakes=0$/m, "$m: round trips after $what{$mode} was killed make no wake calls" or diag $out;
    }
}

done_testing;
