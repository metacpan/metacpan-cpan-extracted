use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# Processes stopped (SIGSTOP) at chosen instructions of a copy of reqrep.h while
# other processes change the slot under them.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $root = dirname(dirname(abs_path(__FILE__)));
-f "$root/reqrep.h" or plan skip_all => 'reqrep.h not found';
my $dir = tempdir(CLEANUP => 1);

open my $in, '<', "$root/reqrep.h" or die $!;
my $h = do { local $/; <$in> };
close $in;

# [name, function it must be in (undef: anywhere), statement, before|after, matches]
my @points = (
    [ACQ_LOADED    => 'reqrep_slot_acquire', qr/uint32_t gen = reqrep_next_gen\(REQREP_CTL_GEN\(c\)\);/, 'after', 1],
    [ACQ_TAKEN     => 'reqrep_slot_acquire', qr/__atomic_store_n\(&slot->owner, mypid, __ATOMIC_RELAXED\);(?=\n\s*__atomic_store_n\(&slot->owner_tag, tag, __ATOMIC_RELAXED\);\n\s*h->inflight\+\+;\n\s*__atomic_store_n\(&h->hdr->resp_hint)/, 'before', 1],
    [REC_JUDGED    => 'reqrep_slot_acquire', qr/if \(taken < 0\) \{/, 'before', 1],
    [CAN_LOADED    => 'reqrep_cancel', qr/if \(REQREP_CTL_GEN\(c\) != gen\) return;/, 'before', 1],
    [CAN_JUDGED    => 'reqrep_cancel', qr/if \(reqrep_ctl_cas\(slot, c, want\)\) \{/, 'before', 1],
    [CLR_LOADED    => 'reqrep_clear_slots', qr/uint32_t state = REQREP_CTL_STATE\(c\);/, 'before', 1],
    [DISP_LOADED   => 'reqrep_slot_dispatch', qr/if \(reqrep_ctl_cas\(slot, c, REQREP_CTL\(gen, mypid, RESP_DISPATCHED\)\)\) return;/, 'before', 1],
    [TW_LOADED     => 'reqrep_slot_take_write', qr/\*owner = __atomic_load_n\(&slot->owner, __ATOMIC_RELAXED\);/, 'before', 1],
    [PUBLISH       => 'reqrep_slot_publish', qr/if \(reqrep_ctl_cas\(slot, REQREP_CTL\(gen, mypid, RESP_WRITING\)/, 'before', 1],
    [COPY          => undef, qr/if \(len > 0\) memcpy\(data, str, len\);|\*\(int64_t \*\)\(\(uint8_t \*\)slot \+ sizeof\(RespSlotHeader\)\) = value;/, 'before', 2],
    [TG_COPIED     => undef, qr/if \(!reqrep_slot_take_reply\(h, slot, c\)\) return -4;/, 'before', 2],
    [AW_WAIT       => 'reqrep_await_reply', qr/long rc = reqrep_futex_wait\(reqrep_slot_futex\(slot\), \(uint32_t\)c, pts\);/, 'before', 1],
    [AW_LOADED     => 'reqrep_await_reply', qr/if \(\(REQREP_CTL_STATE\(c\) == RESP_DISPATCHED \|\| REQREP_CTL_STATE\(c\) == RESP_WRITING\)/, 'before', 1],
    [SW_PARK       => 'reqrep_send_wait_reserving', qr/uint32_t fseq = __atomic_load_n\(futex_word, __ATOMIC_ACQUIRE\);/, 'after', 1],
    [SW_PARK       => 'reqrep_int_send_wait', qr/uint32_t fseq = __atomic_load_n\(futex_word, __ATOMIC_ACQUIRE\);/, 'after', 1],
    [SEND_ACQUIRED => 'reqrep_send_attempt', qr/int r = reqrep_mutex_lock_until\(h, deadline, timeout\);/, 'before', 1],
    [SEND_ACQUIRED => 'reqrep_int_try_send', qr/ReqRepHeader \*hdr = h->hdr;/, 'before', 1],
    [RECV_UNMARKED => 'reqrep_recv_attempt', qr/reqrep_slot_dispatch\(h, \*out_id\);/, 'before', 1],
    [RECV_UNMARKED => 'reqrep_int_try_recv', qr/reqrep_slot_dispatch\(h, \*out_id\);/, 'before', 1],
    [RW_PARK       => 'reqrep_recv_wait', qr/long rc = reqrep_futex_wait\(&hdr->recv_futex, fseq, pts\);/, 'before', 1],
    [RW_PARK       => 'reqrep_int_recv_wait', qr/long rc = reqrep_futex_wait\(&hdr->recv_futex, fseq, pts\);/, 'before', 1],
    [RW_WOKEN      => 'reqrep_recv_wait', qr/long rc = reqrep_futex_wait\(&hdr->recv_futex, fseq, pts\);/, 'after', 1],
    [RW_WOKEN      => 'reqrep_int_recv_wait', qr/long rc = reqrep_futex_wait\(&hdr->recv_futex, fseq, pts\);/, 'after', 1],
    [WAKE_MISSED   => 'reqrep_wake', qr/reqrep_waiters_forget\(futex_word, waiters, w\);/, 'before', 1],
    [MX_PARK       => 'reqrep_mutex_lock_until', qr/long rc = reqrep_futex_wait\(&hdr->mutex_futex, fseq, pts\);/, 'before', 1],
    [SWA_LOADED    => 'reqrep_slot_waiters_add', qr/if \(__atomic_compare_exchange_n\(&slot->waiters, &w,/, 'before', 1],
    [REG_EVICTED   => 'reqrep_proc_register', qr/if \(r\.pid\) reqrep_proc_release\(h, r\.pid\);/, 'before', 1],
    [NOTIFY_LOST   => 'reqrep_notify_owner', qr/__atomic_add_fetch\(reqrep_lost_counter\(h, pid, tag\), 1, __ATOMIC_RELEASE\);/, 'before', 1],
    [REG_WALK      => 'reqrep_proc_register', qr/uint32_t mask = REQREP_PROC_SLOTS - 1;/, 'before', 1],
    [REG_RECLAIM   => 'reqrep_proc_register', qr/if \((?:!reqrep_proc_cas\(e, r, pid, r\.start \? REQREP_START_RELEASING : start\)\) continue;|known && __atomic_compare_exchange_n\(&e->start, &known, 0, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE\)\) \{)/, 'before', 1],
);
for my $p (@points) {
    my ($name, $fn, $re, $where, $want) = @$p;
    my $stall = qq{RR_STALL("$name");};
    my $inject = sub { $_[0] =~ s{^(\s*)($re)}{$where eq 'before' ? "$1$stall\n$1$2" : "$1$2\n$1$stall"}mge || 0 };
    my $n = 0;
    if ($fn) { $h =~ s{(\n[^\n]*\b\Q$fn\E\([^;]*?\{\n.*?\n\}\n)}{ my $body = $1; $n = $inject->($body); $body }se }
    else     { $n = $inject->($h) }
    BAIL_OUT("stall point $name matched $n, expected $want: update this test") unless $n == $want;
}
my @lines = split /\n/, $h;
for my $i (grep { $lines[$_] =~ /RR_STALL\("/ } 0 .. $#lines) {
    my $j = $i - 1;
    $j-- while $j > 0 && ($lines[$j] =~ /^\s*$/ || $lines[$j] =~ /RR_STALL\("/);
    BAIL_OUT("stall point would change the code it tests, after: $lines[$j]")
        unless $lines[$j] =~ m{(?:[;{}]|\*/)\s*$};
}
open my $out, '>', "$dir/rr.h" or die $!;
print {$out} $h;
close $out;

open my $fh, '>', "$dir/races.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <poll.h>
#include <pthread.h>

/* One-shot: RR_<NAME>=stop raises SIGSTOP, =<ms> sleeps. */
static void RR_STALL(const char *name) {
    char var[64];
    snprintf(var, sizeof var, "RR_%s", name);
    const char *v = getenv(var);
    if (!v) return;
    char buf[64];
    snprintf(buf, sizeof buf, "%s", v);
    unsetenv(var);
    if (!strcmp(buf, "stop")) { raise(SIGSTOP); return; }
    long ms = atol(buf);
    struct timespec ts = { ms / 1000, (ms % 1000) * 1000000L };
    nanosleep(&ts, NULL);
}
#include "rr.h"

static void lock_mutex(ReqRepHandle *h) { while (reqrep_mutex_lock_until(h, NULL, -1) != 1) {} }

enum { F_A, F_B, F_C, F_D, NF };
struct sh { int flag[NF]; int res[8]; long val[8]; uint64_t id[8]; };
static struct sh *sh;
static int is_int;
static const char *path;

static ReqRepHandle *at(void) {
    char err[REQREP_ERR_BUFLEN];
    ReqRepHandle *h = reqrep_open(path, is_int ? REQREP_MODE_INT : REQREP_MODE_STR, err);
    if (!h) { printf("open: %s\n", err); _exit(2); }
    return h;
}
/* Single digits, so both variants carry the same values. */
static int send1(ReqRepHandle *h, long v, uint64_t *id) {
    if (is_int) return reqrep_int_try_send(h, v, id);
    char c = '0' + v;
    return reqrep_try_send(h, &c, 1, false, id);
}
static int reply1(ReqRepHandle *h, uint64_t id, long v) {
    if (is_int) return reqrep_int_reply(h, id, v);
    char c = '0' + v;
    return reqrep_reply(h, id, &c, 1, false);
}
static int recv1(ReqRepHandle *h, long *v, uint64_t *id, double t) {
    int64_t iv; const char *s; uint32_t l; bool u;
    int r = is_int ? reqrep_int_recv_wait(h, &iv, id, t) : reqrep_recv_wait(h, &s, &l, &u, id, t);
    if (r == 1) *v = is_int ? (long)iv : (l == 1 ? s[0] - '0' : -1);
    return r;
}
static int getv(ReqRepHandle *h, uint64_t id, double t, long *out) {
    int64_t o; const char *s; uint32_t l; bool u;
    int r = is_int ? reqrep_int_get_wait(h, id, &o, t) : reqrep_get_wait(h, id, &s, &l, &u, t);
    *out = r != 1 ? -1 : is_int ? (long)o : (l == 1 ? s[0] - '0' : -1);
    return r;
}
static int request1(ReqRepHandle *h, long v, long *out, double t) {
    if (is_int) {
        int64_t o; int r = reqrep_int_request(h, v, &o, t);
        *out = r == 1 ? (long)o : -1;
        return r;
    }
    char c = '0' + v; const char *s; uint32_t l; bool u;
    int r = reqrep_request(h, &c, 1, false, &s, &l, &u, t);
    *out = r == 1 ? (l == 1 ? s[0] - '0' : -1) : -1;
    return r;
}
static void clear1(ReqRepHandle *h) { if (is_int) reqrep_int_clear(h); else reqrep_clear(h); }
static int busy(ReqRepHandle *h) {
    int n = 0;
    for (uint32_t i = 0; i < h->resp_slots; i++)
        if (REQREP_CTL_STATE(__atomic_load_n(&reqrep_resp_slot(h, i)->ctl, __ATOMIC_ACQUIRE)) != RESP_FREE) n++;
    return n;
}
static double now_ms(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}
static void await(int f) {
    double t0 = now_ms();
    while (!__atomic_load_n(&sh->flag[f], __ATOMIC_ACQUIRE)) {
        if (now_ms() - t0 > 20000) { printf("TIMEOUT awaiting flag %d\n", f); exit(1); }
        usleep(200);
    }
}
static void raise1(int f) { __atomic_store_n(&sh->flag[f], 1, __ATOMIC_RELEASE); }
static void wait_stop(pid_t p, const char *what) {
    double t0 = now_ms();
    for (;;) {
        int st;
        pid_t r = waitpid(p, &st, WUNTRACED | WNOHANG);
        if (r == p && WIFSTOPPED(st)) return;
        if (r == p) { printf("UNEXPECTED: %s exited instead of stopping\n", what); exit(1); }
        if (now_ms() - t0 > 15000) { printf("UNEXPECTED: %s never stopped\n", what); exit(1); }
        usleep(200);
    }
}
static int reap(pid_t p) {
    double t0 = now_ms();
    for (;;) {
        int st;
        pid_t r = waitpid(p, &st, WNOHANG);
        if (r == p) return WIFEXITED(st) ? WEXITSTATUS(st) : -WTERMSIG(st);
        if (now_ms() - t0 > 30000) { kill(p, SIGKILL); waitpid(p, NULL, 0); return -98; }
        usleep(500);
    }
}
static void killreap(pid_t p) { kill(p, SIGKILL); waitpid(p, NULL, 0); }
static void resume(pid_t p) { kill(p, SIGCONT); }
static void noop_handler(int sig) { (void)sig; }
static void alarm_again(int sig) { (void)sig; alarm(1); }
static void *open_in_thread(void *unused) { (void)unused; at(); return NULL; }
static void stall_at(const char *name) {
    char var[64];
    snprintf(var, sizeof var, "RR_%s", name);
    setenv(var, "stop", 1);
}
/* Every process record names this live process except the one where q looks first, which names q
 * with a start it never had: q's pid, left by a process that died. Returns that record's index. */
static uint32_t fill_registry(ReqRepHandle *h, pid_t q) {
    uint32_t me = (uint32_t)getpid(), start = 0;
    reqrep_proc_stat(me, &start);
    uint32_t home = (uint32_t)q & (REQREP_PROC_SLOTS - 1);
    for (uint32_t i = 0; i < REQREP_PROC_SLOTS; i++)
        h->procs[i] = i == home ? (ReqRepProc){ (uint32_t)q, 12345 } : (ReqRepProc){ me, start };
    return home;
}

/* Reply v+1 to up to n requests. */
static pid_t server(int n) {
    pid_t p = fork();
    if (p) return p;
    ReqRepHandle *h = at();
    for (int i = 0; i < n; i++) {
        long v; uint64_t id;
        if (recv1(h, &v, &id, 10.0) != 1) break;
        reply1(h, id, v + 1);
    }
    _exit(0);
}
/* Take one request and reply v+1 into res[k], stopping at `stall` if given. */
static pid_t responder(const char *stall, int k) {
    pid_t p = fork();
    if (p) return p;
    ReqRepHandle *h = at();
    long v; uint64_t id;
    if (recv1(h, &v, &id, 10.0) != 1) _exit(3);
    sh->id[k] = id;
    if (stall) stall_at(stall);
    sh->res[k] = reply1(h, id, v + 1);
    _exit(0);
}
/* A client that sends v, raises F_A, and records get_wait(t) in res[k]/val[k]. */
static pid_t waiter(long v, double t, const char *stall, int k) {
    pid_t p = fork();
    if (p) return p;
    ReqRepHandle *h = at();
    uint64_t id; long out = -1;
    sh->res[k] = send1(h, v, &id);
    sh->id[k] = id;
    raise1(F_A);
    if (stall) { await(F_B); stall_at(stall); }
    double t0 = now_ms();
    sh->res[k] = getv(h, id, t, &out);
    sh->val[k] = out;
    sh->id[7] = (uint64_t)(now_ms() - t0);
    sh->val[7] = (long)now_ms();
    _exit(0);
}

int main(int argc, char **argv) {
    char err[REQREP_ERR_BUFLEN];
    setvbuf(stdout, NULL, _IOLBF, 0);
    is_int = !strcmp(argv[1], "int");
    const char *mode = argv[2];
    path = argv[3];
    unlink(path);
    int two = !strcmp(mode, "sw_park") || !strcmp(mode, "mutex_two_parked") || !strcmp(mode, "epoch_reset_parking")
              || !strcmp(mode, "unmarked_pair") || !strcmp(mode, "send_clear") || !strcmp(mode, "clear_mid_acquire")
              || !strcmp(mode, "cancel_abandoned_twice");
    int room = !strcmp(mode, "room_taker_dies") || !strcmp(mode, "zombie_receiver_pair");
    uint32_t caps = two || room ? 2 : 16, slots = room ? 4 : two ? 2 : 1;
    ReqRepHandle *srv = is_int ? reqrep_create_int(path, caps, slots, 0600, err)
                               : reqrep_create(path, caps, slots, 64, 0, 0600, err);
    if (!srv) { printf("create: %s\n", err); return 2; }
    sh = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    long o = -1, o2 = -1, v;
    uint64_t id;
    int r = -9, r2 = -9;

    if (!strcmp(mode, "stale_acquire")) {
        /* Read FREE, then the slot served a whole request before the CAS. */
        pid_t x = fork();
        if (!x) { stall_at("ACQ_LOADED"); sh->res[0] = request1(at(), 1, &o, 5.0); sh->val[0] = o; _exit(0); }
        wait_stop(x, "X");
        pid_t sv = server(2);
        r = request1(at(), 5, &o, 3.0);
        resume(x); reap(x); reap(sv);
        printf("R=%d:%ld X=%d:%ld busy=%d\n", r, o, sh->res[0], sh->val[0], busy(srv));
    }
    else if (!strcmp(mode, "stale_recover") || !strcmp(mode, "rec_clear")) {
        /* Judged a dead owner, then another request (after clear(), for rec_clear) recovered and
         * used the slot. Its old id must not reach the slot the late recoverer takes. */
        pid_t x = fork();
        if (!x) { send1(at(), 1, &id); _exit(0); }
        reap(x);
        uint64_t xid = 0;
        recv1(srv, &v, &xid, 5.0);
        pid_t rr = fork();
        if (!rr) { stall_at("REC_JUDGED"); sh->res[0] = request1(at(), 5, &o, 8.0); sh->val[0] = o; _exit(0); }
        wait_stop(rr, "R");
        if (!strcmp(mode, "rec_clear")) clear1(srv);
        ReqRepHandle *y = at();
        uint64_t yid;
        pid_t sv = server(1);
        r = send1(y, 3, &yid) == 1 ? getv(y, yid, 3.0, &o) : -9;
        reap(sv);
        resume(rr);
        if (recv1(srv, &v, &id, 5.0) == 1) {
            reqrep_cancel(y, yid);
            sh->res[2] = reply1(srv, xid, 9);
            sh->res[1] = reply1(srv, id, v + 1);
        }
        reap(rr);
        printf("Y=%d:%ld R=%d:%ld reply=%d xreply=%d busy=%d\n", r, o, sh->res[0], sh->val[0], sh->res[1], sh->res[2], busy(srv));
    }
    else if (!strcmp(mode, "stale_release")) {
        /* Copied a reply, then clear() and a new request passed before the slot was taken back. */
        pid_t oo = waiter(1, 5.0, "TG_COPIED", 0);
        await(F_A);
        raise1(F_B);
        if (recv1(srv, &v, &id, 5.0) == 1) reply1(srv, id, v + 1);
        wait_stop(oo, "O");
        clear1(srv);
        pid_t sv = server(1);
        r = request1(at(), 5, &o, 3.0);
        resume(oo); reap(oo); reap(sv);
        printf("O=%d N=%d:%ld busy=%d\n", sh->res[0], r, o, busy(srv));
    }
    else if (!strcmp(mode, "stale_cancel")) {
        /* Loaded its own ACQUIRED slot, then clear() and a new request passed. */
        pid_t oo = fork();
        if (!oo) { ReqRepHandle *h = at(); send1(h, 1, &id); stall_at("CAN_JUDGED"); reqrep_cancel(h, id); _exit(0); }
        wait_stop(oo, "O");
        recv1(srv, &v, &id, 5.0);
        clear1(srv);
        pid_t n = waiter(5, 5.0, NULL, 1);
        await(F_A);
        resume(oo); reap(oo);
        if (recv1(srv, &v, &id, 5.0) == 1) sh->res[2] = reply1(srv, id, v + 1);
        reap(n);
        printf("N=%d:%ld reply=%d busy=%d\n", sh->res[1], sh->val[1], sh->res[2], busy(srv));
    }
    else if (!strcmp(mode, "send_clear")) {
        /* Took a slot for a send, then clear() gave it to another sender first. */
        pid_t x = fork();
        if (!x) {
            ReqRepHandle *h = at();
            stall_at("SEND_ACQUIRED");
            send1(h, 1, &sh->id[0]);
            raise1(F_B);
            sh->res[0] = getv(h, sh->id[0], 3.0, &sh->val[0]);
            _exit(0);
        }
        wait_stop(x, "X");
        clear1(srv);
        pid_t n = waiter(5, 5.0, NULL, 1);
        await(F_A);
        resume(x);
        await(F_B);
        for (int i = 0; i < 2; i++) if (recv1(srv, &v, &id, 5.0) == 1) sh->res[2 + i] = reply1(srv, id, v + 1);
        reap(x); reap(n);
        printf("same_id=%d X=%d N=%d:%ld replies=%d,%d busy=%d\n", sh->id[0] == sh->id[1],
               sh->res[0], sh->res[1], sh->val[1], sh->res[2], sh->res[3], busy(srv));
    }
    else if (!strcmp(mode, "rec_abandoned")) {
        /* Judged an abandoned slot's writer dead, then another process recovered and used it. */
        ReqRepHandle *cli = at();
        send1(cli, 1, &id);
        pid_t w = responder("COPY", 0);
        wait_stop(w, "W");
        reqrep_cancel(cli, sh->id[0]);
        killreap(w);
        pid_t rr = fork();
        if (!rr) { stall_at("REC_JUDGED"); sh->res[1] = request1(at(), 5, &o, 8.0); sh->val[1] = o; _exit(0); }
        wait_stop(rr, "R");
        pid_t sv = server(2);
        r = request1(at(), 3, &o, 3.0);
        resume(rr); reap(rr); reap(sv);
        printf("N=%d:%ld R=%d:%ld busy=%d\n", r, o, sh->res[1], sh->val[1], busy(srv));
    }
    else if (!strcmp(mode, "await_stale")) {
        /* Saw the writer mid-copy, then it published and exited. */
        pid_t oo = waiter(1, -1.0, "AW_LOADED", 0);
        await(F_A);
        pid_t w = responder("PUBLISH", 1);
        wait_stop(w, "W");
        raise1(F_B);
        wait_stop(oo, "O");
        resume(w); reap(w);
        resume(oo); reap(oo);
        printf("O=%d:%ld W=%d busy=%d\n", sh->res[0], sh->val[0], sh->res[1], busy(srv));
    }
    else if (!strcmp(mode, "cancel_stale")) {
        /* cancel loaded the slot mid-copy, then the writer published and exited. */
        pid_t oo = fork();
        if (!oo) {
            ReqRepHandle *h = at();
            send1(h, 1, &id);
            raise1(F_A);
            await(F_B);
            stall_at("CAN_LOADED");
            reqrep_cancel(h, id);
            sh->res[0] = getv(h, id, 1.0, &sh->val[0]);
            _exit(0);
        }
        await(F_A);
        pid_t w = responder("PUBLISH", 1);
        wait_stop(w, "W");
        raise1(F_B);
        wait_stop(oo, "O");
        resume(w); reap(w);
        resume(oo); reap(oo);
        pid_t sv = server(1);
        r = request1(at(), 5, &o, 3.0);
        reap(sv);
        printf("O=%d:%ld N=%d:%ld busy=%d\n", sh->res[0], sh->val[0], r, o, busy(srv));
    }
    else if (!strcmp(mode, "clear_stale")) {
        /* clear() loaded one reply's slot, then that reply was read and another request started. */
        pid_t oo = waiter(1, 5.0, NULL, 0);
        await(F_A);
        pid_t w1 = responder("PUBLISH", 1);
        wait_stop(w1, "W1");
        pid_t c = fork();
        if (!c) { stall_at("CLR_LOADED"); clear1(at()); _exit(0); }
        wait_stop(c, "clear");
        resume(w1); reap(w1); reap(oo);
        pid_t n = waiter(5, 5.0, NULL, 2);
        pid_t w2 = responder("COPY", 3);
        wait_stop(w2, "W2");
        resume(c); reap(c);
        pid_t sv = server(2);
        r2 = request1(at(), 3, &o2, 1.0);
        resume(w2); reap(w2);
        reap(n);
        r = request1(at(), 7, &o, 3.0);
        reap(sv);
        printf("O=%d:%ld W2=%d N=%d N2=%d N3=%d:%ld busy=%d\n", sh->res[0], sh->val[0], sh->res[3],
               sh->res[2], r2, r, o, busy(srv));
    }
    else if (!strcmp(mode, "futex_aba")) {
        /* A waiter about to sleep on the slot futex while its reply lands, clear() runs and the same
         * responder starts another request's reply on the slot: the futex word must have changed. */
        pid_t oo = waiter(1, -1.0, "AW_WAIT", 0);
        await(F_A);
        pid_t w = fork();
        if (!w) {
            ReqRepHandle *h = at();
            for (int i = 0; i < 2; i++) {
                if (recv1(h, &v, &id, 10.0) != 1) _exit(3);
                stall_at("COPY");
                sh->res[1 + i] = reply1(h, id, v + 1);
            }
            _exit(0);
        }
        wait_stop(w, "W");
        raise1(F_B);
        wait_stop(oo, "O");
        resume(w);
        while (REQREP_CTL_STATE(__atomic_load_n(&reqrep_resp_slot(srv, 0)->ctl, __ATOMIC_ACQUIRE)) != RESP_READY)
            usleep(100);
        clear1(srv);
        pid_t b = waiter(5, 5.0, NULL, 3);
        wait_stop(w, "W again");
        double t = now_ms();
        resume(oo); reap(oo);
        long slept = sh->val[7] - (long)t;
        resume(w); reap(w); reap(b);
        printf("O=%d slept_long=%d W=%d,%d B=%d:%ld busy=%d\n", sh->res[0], slept > 1000,
               sh->res[1], sh->res[2], sh->res[3], sh->val[3], busy(srv));
    }
    else if (!strcmp(mode, "sw_park")) {
        /* The queue is full with one slot free, so X's send parks for the queue; the queue then
         * drains and the last slot is taken before X re-checks. X must end up woken by slots. */
        ReqRepHandle *c1 = at(), *c2 = at(), *c3 = at();
        uint64_t id1, id2, id3, rid2 = 0, rid3 = 0;
        send1(c1, 1, &id1);
        reqrep_cancel(c1, id1);
        send1(c2, 2, &id2);
        pid_t x = fork();
        if (!x) {
            ReqRepHandle *h = at();
            uint64_t xid;
            stall_at("SW_PARK");
            if (is_int) sh->res[0] = reqrep_int_send_wait(h, 3, &xid, -1.0);
            else { char ch = '3'; sh->res[0] = reqrep_send_wait(h, &ch, 1, false, &xid, -1.0); }
            sh->val[0] = (long)now_ms();
            raise1(F_C);
            _exit(0);
        }
        wait_stop(x, "X");
        for (int i = 0; i < 2; i++)
            if (recv1(srv, &v, &id, 1.0) == 1 && v == 2) rid2 = id;
        send1(c3, 4, &id3);
        if (recv1(srv, &v, &id, 1.0) == 1) rid3 = id;
        resume(x);
        usleep(300000);
        reply1(srv, rid2, 3);
        reply1(srv, rid3, 5);
        getv(c2, id2, 1.0, &o);
        getv(c3, id3, 1.0, &o2);
        double t_free = now_ms();
        while (!__atomic_load_n(&sh->flag[F_C], __ATOMIC_ACQUIRE) && now_ms() - t_free < 6000) usleep(1000);
        int sent = __atomic_load_n(&sh->flag[F_C], __ATOMIC_ACQUIRE);
        if (sent) reap(x); else killreap(x);
        printf("X=%d woke=%d replies=%ld,%ld\n", sent ? sh->res[0] : -99,
               sent && sh->val[0] - (long)t_free < 1500, o, o2);
    }
    else if (!strcmp(mode, "stale_acquire_reply")) {
        /* X read FREE(g); R then cycled the slot 32 times, so FREE(g+32) has the same low half,
         * and R's last request is still queued. X must not take generation g+32. */
        pid_t x = fork();
        if (!x) {
            ReqRepHandle *h = at();
            stall_at("ACQ_LOADED");
            sh->res[0] = send1(h, 1, &sh->id[0]);
            raise1(F_A);
            sh->res[1] = getv(h, sh->id[0], 3.0, &sh->val[1]);
            _exit(0);
        }
        wait_stop(x, "X");
        ReqRepHandle *rh = at();
        uint32_t low0 = (uint32_t)__atomic_load_n(&reqrep_resp_slot(srv, 0)->ctl, __ATOMIC_ACQUIRE);
        uint32_t g;
        for (int i = 0; i < 31; i++) { reqrep_slot_acquire(rh, &g); reqrep_cancel(rh, REQREP_MAKE_ID(0, g)); }
        send1(rh, 5, &id);
        reqrep_cancel(rh, id);
        uint32_t low1 = (uint32_t)__atomic_load_n(&reqrep_resp_slot(srv, 0)->ctl, __ATOMIC_ACQUIRE);
        resume(x);
        await(F_A);
        int stale = -9, late = -9;
        if (recv1(srv, &v, &id, 2.0) == 1) stale = reply1(srv, id, v + 1);
        if (recv1(srv, &v, &id, 2.0) == 1) late = reply1(srv, id, v + 1);
        reap(x);
        printf("same_low=%d stale_reply=%d X=%d:%ld x_reply=%d busy=%d\n", low0 == low1, stale,
               sh->res[1], sh->val[1], late, busy(srv));
    }
    else if (!strcmp(mode, "stale_writer_inflight") || !strcmp(mode, "stale_writer_entry")) {
        /* V received (g, V, DISPATCHED); C cancelled and cycled the slot to g+32 with a new request,
         * which then reads as received by V, the same low half. Whether V stopped after loading
         * the slot or only starts its reply now, it must not take it. */
        int entry = !strcmp(mode, "stale_writer_entry");
        ReqRepHandle *cli = at();
        RespSlotHeader *s0 = reqrep_resp_slot(srv, 0);
        send1(cli, 1, &id);
        pid_t w;
        if (entry) {
            w = fork();
            if (!w) {
                ReqRepHandle *h = at();
                if (recv1(h, &v, &sh->id[0], 5.0) != 1) _exit(3);
                raise1(F_A);
                await(F_B);
                sh->res[0] = reply1(h, sh->id[0], v + 1);
                _exit(0);
            }
            await(F_A);
        } else {
            w = responder("TW_LOADED", 0);
            wait_stop(w, "V");
        }
        uint64_t c0 = __atomic_load_n(&s0->ctl, __ATOMIC_ACQUIRE), as_v = 0;
        reqrep_cancel(cli, sh->id[0]);
        uint32_t g;
        for (int i = 0; i < 31; i++) { reqrep_slot_acquire(cli, &g); reqrep_cancel(cli, REQREP_MAKE_ID(0, g)); }
        uint64_t nid;
        send1(cli, 5, &nid);
        int nr = -9;
        if (recv1(srv, &v, &id, 2.0) == 1) {
            uint64_t mine = __atomic_load_n(&s0->ctl, __ATOMIC_ACQUIRE);
            as_v = REQREP_CTL(REQREP_CTL_GEN(mine), REQREP_CTL_PID(c0), RESP_DISPATCHED);
            __atomic_store_n(&s0->ctl, as_v, __ATOMIC_RELEASE);
            if (entry) raise1(F_B); else resume(w);
            reap(w);
            reqrep_ctl_cas(s0, as_v, mine);
            nr = reply1(srv, id, v + 1);
        }
        int ng = getv(cli, nid, 1.0, &o);
        printf("same_low=%d V=%d reply=%d N=%d:%ld busy=%d\n", (uint32_t)c0 == (uint32_t)as_v, sh->res[0],
               nr, ng, o, busy(srv));
    }
    else if (!strcmp(mode, "stale_dispatch")) {
        /* R loaded (g, C, ACQUIRED) to mark it received; C cancelled and took the slot again at g+32. */
        ReqRepHandle *cli = at();
        RespSlotHeader *s0 = reqrep_resp_slot(srv, 0);
        send1(cli, 1, &id);
        pid_t rv = fork();
        if (!rv) {
            ReqRepHandle *h = at();
            stall_at("DISP_LOADED");
            if (recv1(h, &v, &sh->id[0], 5.0) != 1) _exit(3);
            sh->res[0] = reply1(h, sh->id[0], v + 1);
            _exit(0);
        }
        wait_stop(rv, "R");
        uint64_t c0 = __atomic_load_n(&s0->ctl, __ATOMIC_ACQUIRE);
        reqrep_cancel(cli, id);
        uint32_t g;
        for (int i = 0; i < 31; i++) { reqrep_slot_acquire(cli, &g); reqrep_cancel(cli, REQREP_MAKE_ID(0, g)); }
        reqrep_slot_acquire(cli, &g);
        uint64_t c1 = __atomic_load_n(&s0->ctl, __ATOMIC_ACQUIRE);
        resume(rv); reap(rv);
        int kept = __atomic_load_n(&s0->ctl, __ATOMIC_ACQUIRE) == c1;
        reqrep_cancel(cli, REQREP_MAKE_ID(0, g));
        printf("same_low=%d R=%d kept=%d busy=%d\n", (uint32_t)c0 == (uint32_t)c1, sh->res[0], kept, busy(srv));
    }
    else if (!strcmp(mode, "dead_taker")) {
        /* A receiver killed after taking the request off the queue, before marking it received. */
        pid_t oo = waiter(1, -1.0, NULL, 0);
        await(F_A);
        pid_t w = fork();
        if (!w) { ReqRepHandle *h = at(); stall_at("RECV_UNMARKED"); recv1(h, &v, &id, 5.0); _exit(0); }
        wait_stop(w, "W");
        killreap(w);
        reap(oo);
        printf("O=%d within=%d busy=%d\n", sh->res[0], sh->id[7] < 8000, busy(srv));
    }
    else if (!strcmp(mode, "dead_receiver")) {
        pid_t oo = waiter(1, -1.0, NULL, 0);
        await(F_A);
        pid_t w = responder("TW_LOADED", 1);
        wait_stop(w, "W");
        killreap(w);
        reap(oo);
        printf("O=%d within=%d busy=%d\n", sh->res[0], sh->id[7] < 3000, busy(srv));
    }
    else if (!strcmp(mode, "dead_owner_dispatched")) {
        /* The owner died after its request was received; nobody replies, yet the slot comes back. */
        pid_t x = fork();
        if (!x) { send1(at(), 1, &id); _exit(0); }
        reap(x);
        uint64_t xid = 0;
        recv1(srv, &v, &xid, 5.0);
        pid_t sv = server(1);
        r = request1(at(), 5, &o, 3.0);
        reap(sv);
        printf("R=%d:%ld stale=%d busy=%d\n", r, o, reply1(srv, xid, 9), busy(srv));
    }
    else if (!strcmp(mode, "stale_writer")) {
        /* A responder loaded its request's slot, then the owner cancelled and a new request was answered. */
        ReqRepHandle *cli = at();
        send1(cli, 1, &id);
        pid_t w = responder("TW_LOADED", 0);
        wait_stop(w, "V");
        reqrep_cancel(cli, sh->id[0]);
        pid_t sv = server(1);
        r = request1(cli, 5, &o, 3.0);
        reap(sv);
        resume(w); reap(w);
        printf("V=%d N=%d:%ld busy=%d\n", sh->res[0], r, o, busy(srv));
    }
    else if (!strcmp(mode, "dup_writer")) {
        /* Two responders reply to the same request. */
        pid_t oo = waiter(1, 5.0, NULL, 0);
        await(F_A);
        pid_t w1 = responder("COPY", 1);
        wait_stop(w1, "W1");
        r = reply1(at(), sh->id[1], 8);
        resume(w1); reap(w1); reap(oo);
        printf("W2=%d W1=%d O=%d:%ld busy=%d\n", r, sh->res[1], sh->res[0], sh->val[0], busy(srv));
    }
    else if (!strcmp(mode, "dead_acquirer")) {
        pid_t x = fork();
        if (!x) { stall_at("ACQ_TAKEN"); send1(at(), 1, &id); _exit(0); }
        wait_stop(x, "X");
        killreap(x);
        pid_t sv = server(1);
        r = request1(at(), 5, &o, 3.0);
        reap(sv);
        printf("R=%d:%ld busy=%d\n", r, o, busy(srv));
    }
    else if (!strcmp(mode, "stopped_acquirer")) {
        /* Stopped for longer than any timeout while taking a slot: still alive. */
        pid_t x = fork();
        if (!x) { stall_at("ACQ_TAKEN"); sh->res[0] = request1(at(), 1, &o, 10.0); sh->val[0] = o; _exit(0); }
        wait_stop(x, "X");
        pid_t sv = server(2);
        r = request1(at(), 5, &o, 2.5);
        resume(x); reap(x);
        r2 = request1(at(), 7, &o2, 3.0);
        reap(sv);
        printf("R=%d X=%d:%ld R2=%d:%ld busy=%d\n", r, sh->res[0], sh->val[0], r2, o2, busy(srv));
    }
    else if (!strcmp(mode, "clear_mid_acquire")) {
        /* clear() while a sender has taken a slot but not yet named itself its owner. */
        pid_t x = fork();
        if (!x) { stall_at("ACQ_TAKEN"); sh->res[0] = request1(at(), 1, &o, 5.0); sh->val[0] = o; _exit(0); }
        wait_stop(x, "X");
        clear1(srv);
        pid_t n = waiter(5, 5.0, NULL, 1);
        await(F_A);
        resume(x);
        pid_t sv = server(2);
        reap(x); reap(n); reap(sv);
        uint32_t ns = REQREP_ID_SLOT(sh->id[1]);
        int owner_n = ns < srv->resp_slots
                      && __atomic_load_n(&reqrep_resp_slot(srv, ns)->owner, __ATOMIC_ACQUIRE) == (uint32_t)n;
        printf("X=%d:%ld N=%d:%ld owner_N=%d busy=%d\n", sh->res[0], sh->val[0], sh->res[1], sh->val[1],
               owner_n, busy(srv));
    }
    else if (!strcmp(mode, "room_taker_dies")) {
        /* Receivers killed after taking every request, before waking a sender parked for room
         * (Str: a full arena; Int: a full queue). */
        static char big[4000];
        memset(big, 'x', sizeof big);
        ReqRepHandle *c = at();
        int fill = is_int ? 2 : 1;
        for (int i = 0; i < fill; i++)
            if ((is_int ? reqrep_int_try_send(c, 1, &id) : reqrep_try_send(c, big, sizeof big, false, &id)) != 1)
                printf("UNEXPECTED: fill %d\n", i);
        sh->res[0] = -9;
        pid_t s = fork();
        if (!s) {
            ReqRepHandle *h = at();
            sh->res[0] = is_int ? reqrep_int_send_wait(h, 2, &id, -1)
                                : reqrep_send_wait(h, big, sizeof big, false, &id, -1);
            _exit(0);
        }
        double t0 = now_ms();
        while (!REQREP_WAITERS(__atomic_load_n(&srv->hdr->send_waiters, __ATOMIC_ACQUIRE)) && now_ms() - t0 < 5000)
            usleep(200);
        for (int i = 0; i < fill; i++) {
            pid_t w = fork();
            if (!w) { ReqRepHandle *h = at(); stall_at("RECV_UNMARKED"); recv1(h, &v, &id, 5.0); _exit(0); }
            wait_stop(w, "W");
            killreap(w);
        }
        pid_t sv = server(1);
        t0 = now_ms();
        int ended = 1;
        while (waitpid(s, NULL, WNOHANG) != s) {
            if (now_ms() - t0 > 6000) { killreap(s); ended = 0; break; }
            usleep(1000);
        }
        reap(sv);
        printf("S=%d ended=%d\n", sh->res[0], ended);
    }
    else if (!strcmp(mode, "cancel_abandoned_twice")) {
        /* A cancel leaves a reply being written ABANDONED, its writer is killed and the owner cancels
         * again: the owner's destroy must still give back its other request. */
        ReqRepHandle *c = at();
        uint64_t a, b;
        send1(c, 1, &a);
        send1(c, 2, &b);
        pid_t w = fork();
        if (!w) {
            ReqRepHandle *h = at();
            uint64_t rid;
            uint32_t owner;
            if (recv1(h, &v, &rid, 5.0) == 1)
                reqrep_slot_take_write(reqrep_resp_slot(h, REQREP_ID_SLOT(rid)), REQREP_ID_GEN(rid), reqrep_self_pid(), &owner);
            raise(SIGSTOP);
            _exit(0);
        }
        wait_stop(w, "W");
        reqrep_cancel(c, a);
        killreap(w);
        reqrep_cancel(c, a);
        reqrep_destroy(c);
        printf("busy=%d\n", busy(srv));
    }
    else if (!strcmp(mode, "cancel_raced_by_reply")) {
        /* A cancel stopped just before its compare-and-swap while the reply lands: the owner's
         * destroy must still give back the slot the reply now sits in. */
        pid_t oo = fork();
        if (!oo) {
            ReqRepHandle *c = at();
            uint64_t a;
            send1(c, 1, &a);
            raise1(F_A);
            await(F_B);
            stall_at("CAN_JUDGED");
            reqrep_cancel(c, a);
            reqrep_destroy(c);
            raise1(F_C);
            pause();
            _exit(0);
        }
        await(F_A);
        recv1(srv, &v, &id, 5.0);
        raise1(F_B);
        wait_stop(oo, "O");
        r = reply1(srv, id, v + 1);
        resume(oo);
        await(F_C);
        printf("reply=%d busy=%d\n", r, busy(srv));
        killreap(oo);
    }
    else if (!strcmp(mode, "pending_signal")) {
        /* A signal Perl has taken but not yet run ends a wait before it parks, and never a call
         * that does not wait. */
        int pend = 1;
        ReqRepHandle *c = at(), *s = at();
        c->sig_pending = s->sig_pending = &pend;
        double t0 = now_ms();
        int r0 = recv1(s, &v, &id, 0.0);
        int r1 = recv1(s, &v, &id, 5.0);
        int sn = send1(c, 1, &id);
        int g0 = getv(c, id, 0.0, &o);
        int g1 = getv(c, id, 5.0, &o);
        int fast = now_ms() - t0 < 1000;
        pend = 0;
        int r2 = recv1(s, &v, &id, 1.0);
        printf("recv0=%d recv5=%d send=%d get0=%d get5=%d fast=%d then=%d\n", r0, r1, sn, g0, g1, fast, r2);
    }
    else if (!strcmp(mode, "mutex_dead_signals")) {
        /* A process killed holding the Str mutex is recovered while signals a tick apart keep
         * interrupting the waits behind it. */
        if (is_int) { printf("recovered=1\n"); unlink(path); return 0; }
        pid_t hd = fork();
        if (!hd) { lock_mutex(at()); raise(SIGSTOP); _exit(0); }
        wait_stop(hd, "H");
        kill(hd, SIGKILL);
        siginfo_t si;
        waitid(P_PID, hd, &si, WEXITED | WNOWAIT);   /* dead, left unreaped: only /proc tells */
        pid_t r = fork();
        if (!r) {
            struct sigaction sa;
            memset(&sa, 0, sizeof sa);
            sa.sa_handler = alarm_again;
            sigaction(SIGALRM, &sa, NULL);
            alarm(1);
            ReqRepHandle *h = at();
            while (recv1(h, &v, &id, -1.0) == REQREP_EINTR) {}
            _exit(0);
        }
        double t0 = now_ms();
        while (__atomic_load_n(&srv->hdr->mutex, __ATOMIC_ACQUIRE) && now_ms() - t0 < 6000) usleep(1000);
        int recovered = !__atomic_load_n(&srv->hdr->mutex, __ATOMIC_ACQUIRE);
        killreap(r);
        waitpid(hd, NULL, 0);
        printf("recovered=%d\n", recovered);
    }
    else if (!strcmp(mode, "zombie_receiver_pair")) {
        /* Two requests a receiver marked, then it died unreaped: waiting for them in turn, the
         * second ends as soon as the first. */
        ReqRepHandle *c = at();
        uint64_t ids[2];
        for (int i = 0; i < 2; i++) send1(c, i + 1, &ids[i]);
        pid_t w = fork();
        if (!w) { ReqRepHandle *h = at(); for (int i = 0; i < 2; i++) recv1(h, &v, &id, 1.0); _exit(0); }
        usleep(300000);
        int g1 = getv(c, ids[0], 10.0, &o);
        double t1 = now_ms();
        int g2 = getv(c, ids[1], 10.0, &o);
        long second = (long)(now_ms() - t1);
        reap(w);
        printf("gets=%d,%d second_at_once=%d\n", g1, g2, second < 500);
    }
    else if (!strcmp(mode, "woken_receiver_dies")) {
        /* The one wake a send gives goes to a receiver killed before it takes the request: another
         * parked receiver still serves it. */
        pid_t r1 = fork();
        if (!r1) { stall_at("RW_WOKEN"); recv1(at(), &v, &id, -1.0); _exit(0); }
        double t0 = now_ms();
        while (REQREP_WAITERS(__atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE)) < 1 && now_ms() - t0 < 5000)
            usleep(200);
        pid_t r2 = fork();
        if (!r2) { ReqRepHandle *h = at(); if (recv1(h, &v, &id, -1.0) == 1) reply1(h, id, v + 1); _exit(0); }
        while (REQREP_WAITERS(__atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE)) < 2 && now_ms() - t0 < 5000)
            usleep(200);
        pid_t c = waiter(1, 8.0, NULL, 0);
        wait_stop(r1, "R1");
        killreap(r1);
        reap(c);
        killreap(r2);
        printf("O=%d:%ld within=%d\n", sh->res[0], sh->val[0], sh->id[7] < 5000);
    }
    else if (!strcmp(mode, "dead_taker_clear")) {
        /* A receiver killed between taking a request and marking it, then clear(): the untimed
         * waiter still learns that no reply will come. */
        pid_t oo = waiter(1, -1.0, NULL, 0);
        await(F_A);
        pid_t w = fork();
        if (!w) { ReqRepHandle *h = at(); stall_at("RECV_UNMARKED"); recv1(h, &v, &id, 5.0); _exit(0); }
        wait_stop(w, "W");
        killreap(w);
        clear1(srv);
        double t0 = now_ms();
        int ended = 1;
        while (waitpid(oo, NULL, WNOHANG) != oo) {
            if (now_ms() - t0 > 10000) { killreap(oo); ended = 0; break; }
            usleep(1000);
        }
        printf("O=%d ended=%d busy=%d\n", sh->res[0], ended, busy(srv));
    }
    else if (!strcmp(mode, "stopped_reader")) {
        /* Stopped between copying its reply and taking the slot back. */
        pid_t oo = waiter(1, 5.0, "TG_COPIED", 0);
        await(F_A);
        raise1(F_B);
        if (recv1(srv, &v, &id, 5.0) == 1) reply1(srv, id, v + 1);
        wait_stop(oo, "O");
        pid_t sv = server(2);
        r = request1(at(), 5, &o, 2.5);
        resume(oo); reap(oo);
        r2 = request1(at(), 7, &o2, 3.0);
        reap(sv);
        printf("R=%d O=%d:%ld R2=%d:%ld busy=%d\n", r, sh->res[0], sh->val[0], r2, o2, busy(srv));
    }
    else if (!strcmp(mode, "stopped_writer")) {
        /* A responder stopped mid-copy for longer than the tick: a wait with no deadline keeps waiting. */
        pid_t oo = waiter(1, -1.0, NULL, 0);
        await(F_A);
        pid_t w = responder("COPY", 1);
        wait_stop(w, "W");
        usleep(2600000);
        int st, done = waitpid(oo, &st, WNOHANG) == oo;
        resume(w); reap(w);
        if (!done) reap(oo);
        printf("gave_up_early=%d O=%d:%ld W=%d busy=%d\n", done, sh->res[0], sh->val[0], sh->res[1], busy(srv));
    }
    else if (!strcmp(mode, "dead_writer") || !strcmp(mode, "dead_writer_deadline")) {
        pid_t oo = waiter(1, strcmp(mode, "dead_writer") ? 15.0 : -1.0, NULL, 0);
        await(F_A);
        pid_t w = responder("COPY", 1);
        wait_stop(w, "W");
        killreap(w);
        reap(oo);
        printf("O=%d within=%d busy=%d\n", sh->res[0], sh->id[7] < 3000, busy(srv));
    }
    else if (!strcmp(mode, "dead_owner_mid_reply")) {
        pid_t oo = fork();
        if (!oo) { send1(at(), 1, &id); raise1(F_A); await(F_B); _exit(0); }
        await(F_A);
        pid_t w = responder("COPY", 0);
        wait_stop(w, "W");
        raise1(F_B); reap(oo);
        pid_t rr = fork();
        if (!rr) { sh->res[1] = request1(at(), 5, &o, 8.0); sh->val[1] = o; _exit(0); }
        usleep(300000);
        resume(w); reap(w);
        pid_t sv = server(1);
        reap(rr); reap(sv);
        printf("W=%d R=%d:%ld busy=%d\n", sh->res[0], sh->res[1], sh->val[1], busy(srv));
    }
    else if (!strcmp(mode, "clear_live")) {
        /* clear() while a reply is copied in: the copy is not handed to anyone else. */
        pid_t oo = waiter(1, 5.0, NULL, 0);
        await(F_A);
        pid_t w = responder("COPY", 1);
        wait_stop(w, "W");
        clear1(srv);
        pid_t n = fork();
        if (!n) { sh->res[2] = request1(at(), 5, &o, 5.0); sh->val[2] = o; _exit(0); }
        usleep(200000);
        resume(w); reap(w);
        pid_t sv = server(1);
        reap(n); reap(oo); reap(sv);
        printf("W=%d O=%d N=%d:%ld busy=%d\n", sh->res[1], sh->res[0], sh->res[2], sh->val[2], busy(srv));
    }
    else if (!strcmp(mode, "clear_writer_dies")) {
        pid_t oo = waiter(1, -1.0, NULL, 0);
        await(F_A);
        pid_t w = responder("COPY", 1);
        wait_stop(w, "W");
        clear1(srv);
        killreap(w);
        reap(oo);
        pid_t sv = server(1);
        r = request1(at(), 5, &o, 5.0);
        reap(sv);
        printf("O=%d N=%d:%ld busy=%d\n", sh->res[0], r, o, busy(srv));
    }
    else if (!strcmp(mode, "epoch_reset_parking")) {
        /* A receiver registered but not yet parked while wakes keep missing it and the count is reset;
         * another parks in the new epoch before the first leaves, and must stay counted. */
        pid_t a = fork();
        if (!a) { stall_at("RW_PARK"); sh->res[0] = recv1(at(), &v, &id, 5.0); sh->val[0] = v; sh->val[6] = (long)now_ms(); _exit(0); }
        wait_stop(a, "A");
        ReqRepHandle *c = at();
        c->recv_wake.seen = __atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE);
        c->recv_wake.misses = REQREP_STALE_WAKES - 1;
        uint64_t first;
        send1(c, 1, &first);
        uint64_t w = __atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE);
        recv1(srv, &v, &id, 1.0);
        reqrep_cancel(c, first);
        pid_t b = fork();
        if (!b) { sh->res[1] = recv1(at(), &v, &id, 5.0); sh->val[1] = v; sh->val[7] = (long)now_ms(); _exit(0); }
        while (REQREP_WAITERS(__atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE)) != 1) usleep(1000);
        usleep(100000);
        resume(a);
        double t0 = now_ms();
        while (REQREP_WAITERS(__atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE)) != 2 && now_ms() - t0 < 2000) usleep(1000);
        usleep(100000);
        double t = now_ms();
        send1(c, 2, &id);
        usleep(50000);
        send1(c, 3, &id);
        reap(a); reap(b);
        long last = sh->val[6] > sh->val[7] ? sh->val[6] : sh->val[7];
        printf("A=%d B=%d sum=%ld fast=%d epoch=%u count=%u\n", sh->res[0], sh->res[1], sh->val[0] + sh->val[1],
               last - (long)t < 1000, (unsigned)(w >> 32),
               REQREP_WAITERS(__atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE)));
    }
    else if (!strcmp(mode, "epoch_reset_aba")) {
        /* Between a waker reading the count and resetting it, one receiver leaves and another parks:
         * the count reads the same, yet the new receiver must still be woken. */
        pid_t a = fork();
        if (!a) { stall_at("RW_PARK"); sh->res[0] = recv1(at(), &v, &id, 5.0); _exit(0); }
        wait_stop(a, "A");
        pid_t s = fork();
        if (!s) { ReqRepHandle *c = at(); c->recv_wake.seen = __atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE); c->recv_wake.misses = REQREP_STALE_WAKES - 1; stall_at("WAKE_MISSED"); send1(c, 1, &id); _exit(0); }
        wait_stop(s, "S");
        resume(a); reap(a);
        pid_t b = fork();
        if (!b) { sh->res[1] = recv1(at(), &v, &id, 5.0); sh->val[1] = v; sh->val[7] = (long)now_ms(); _exit(0); }
        while (REQREP_WAITERS(__atomic_load_n(&srv->hdr->recv_waiters, __ATOMIC_ACQUIRE)) != 1) usleep(1000);
        usleep(100000);
        resume(s); reap(s);
        usleep(100000);
        double t = now_ms();
        send1(at(), 3, &id);
        reap(b);
        printf("A=%d B=%d:%ld fast=%d\n", sh->res[0], sh->res[1], sh->val[1], sh->val[7] - (long)t < 1000);
    }
    else if (!strcmp(mode, "slot_tag_stale")) {
        /* A waiter for an old generation resumes registering after the slot's next owner registered
         * for its own reply: that registration must survive, so the next reply wakes at once. */
        ReqRepHandle *c = at();
        send1(c, 1, &id);
        sh->id[0] = id;
        pid_t x = fork();
        if (!x) { stall_at("SWA_LOADED"); sh->res[0] = getv(at(), sh->id[0], 5.0, &o); _exit(0); }
        wait_stop(x, "X");
        reqrep_cancel(c, id);
        recv1(srv, &v, &id, 1.0);
        pid_t y = waiter(5, 5.0, NULL, 1);
        await(F_A);
        while (REQREP_WAITERS(__atomic_load_n(&reqrep_resp_slot(srv, 0)->waiters, __ATOMIC_ACQUIRE)) != 1) usleep(1000);
        usleep(100000);
        resume(x); reap(x);
        double t = now_ms();
        if (recv1(srv, &v, &id, 1.0) == 1) reply1(srv, id, v + 1);
        reap(y);
        printf("X=%d Y=%d:%ld fast=%d busy=%d\n", sh->res[0], sh->res[1], sh->val[1], sh->val[7] - (long)t < 1000, busy(srv));
    }
    else if (!strcmp(mode, "stopped_holder")) {
        /* A process stopped while holding the queue mutex: timed calls keep their deadline, a
         * non-blocking call gives up after the lock timeout, and a signal ends an untimed wait. */
        if (is_int) { printf("send_wait=0 recv_wait=0 on_time=1 recv=0 bounded=1 eintr=1\n"); unlink(path); return 0; }
        pid_t p = fork();
        if (!p) { lock_mutex(at()); raise(SIGSTOP); _exit(0); }
        wait_stop(p, "holder");
        pid_t c = fork();
        if (!c) {
            ReqRepHandle *h = at();
            const char *s; uint32_t l; bool u; uint64_t cid;
            double t0 = now_ms();
            int sw = reqrep_send_wait(h, "x", 1, false, &cid, 0.5);
            double t1 = now_ms();
            int rw = reqrep_recv_wait(h, &s, &l, &u, &cid, 0.5);
            int on_time = t1 - t0 < 850 && now_ms() - t1 < 850;
            t0 = now_ms();
            int rn = reqrep_try_recv(h, &s, &l, &u, &cid);
            int bounded = now_ms() - t0 < 4000;
            signal(SIGALRM, noop_handler);
            alarm(1);
            int ri = reqrep_recv_wait(h, &s, &l, &u, &cid, -1.0);
            printf("send_wait=%d recv_wait=%d on_time=%d recv=%d bounded=%d eintr=%d\n", sw, rw, on_time, rn, bounded, ri == REQREP_EINTR);
            fflush(stdout);
            _exit(0);
        }
        int st;
        double t0 = now_ms();
        while (waitpid(c, &st, WNOHANG) != c) {
            if (now_ms() - t0 > 15000) { kill(c, SIGKILL); waitpid(c, NULL, 0); printf("HUNG\n"); break; }
            usleep(1000);
        }
        resume(p); reap(p);
    }
    else if (!strcmp(mode, "mutex_reset_parking")) {
        /* A locker registered but not yet parked while the holder unlocks and relocks until the
         * count is reset: once parked it must still be woken at the next unlock. */
        if (is_int) { printf("X=1 reset=1 fast=1\n"); unlink(path); return 0; }
        lock_mutex(srv);
        pid_t x = fork();
        if (!x) { uint64_t xid; stall_at("MX_PARK"); sh->res[0] = send1(at(), 1, &xid); sh->val[7] = (long)now_ms(); _exit(0); }
        wait_stop(x, "X");
        uint32_t e0 = (uint32_t)(__atomic_load_n(&srv->hdr->mutex_waiters, __ATOMIC_ACQUIRE) >> 32);
        for (int i = 0; i < 2 * REQREP_STALE_WAKES; i++) { reqrep_mutex_unlock(srv); lock_mutex(srv); }
        uint32_t e1 = (uint32_t)(__atomic_load_n(&srv->hdr->mutex_waiters, __ATOMIC_ACQUIRE) >> 32);
        resume(x);
        while (!REQREP_WAITERS(__atomic_load_n(&srv->hdr->mutex_waiters, __ATOMIC_ACQUIRE))) usleep(1000);
        usleep(100000);
        double t = now_ms();
        reqrep_mutex_unlock(srv);
        reap(x);
        printf("X=%d reset=%d fast=%d\n", sh->res[0], e1 != e0, sh->val[7] - (long)t < 1000);
    }
    else if (!strcmp(mode, "mutex_two_parked")) {
        if (is_int) { printf("W=1,1 fast=1\n"); unlink(path); return 0; }
        lock_mutex(srv);
        pid_t w[2];
        for (int i = 0; i < 2; i++) {
            w[i] = fork();
            if (!w[i]) { uint64_t wid; sh->res[i] = send1(at(), 1 + i, &wid); sh->val[i] = (long)now_ms(); _exit(0); }
        }
        usleep(300000);
        double t = now_ms();
        reqrep_mutex_unlock(srv);
        reap(w[0]); reap(w[1]);
        long last = sh->val[0] > sh->val[1] ? sh->val[0] : sh->val[1];
        printf("W=%d,%d fast=%d\n", sh->res[0], sh->res[1], last - (long)t < 1000);
    }
    else if (!strcmp(mode, "mutex_steal")) {
        /* A caller parked on the queue mutex loses the race to a fast locker when woken: it must be
         * woken again at that locker's unlock, not by its lock timeout. */
        if (is_int) { printf("W=1 fast=1\n"); unlink(path); return 0; }
        lock_mutex(srv);
        pid_t w = fork();
        if (!w) { uint64_t wid; sh->res[0] = send1(at(), 1, &wid); sh->val[7] = (long)now_ms(); _exit(0); }
        while (!REQREP_WAITERS(__atomic_load_n(&srv->hdr->mutex_waiters, __ATOMIC_ACQUIRE))) usleep(1000);
        usleep(50000);
        reqrep_mutex_unlock(srv);
        lock_mutex(srv);
        usleep(100000);
        double t = now_ms();
        reqrep_mutex_unlock(srv);
        reap(w);
        printf("W=%d fast=%d\n", sh->res[0], sh->val[7] - (long)t < 1000);
    }
    else if (!strcmp(mode, "deadline")) {
        /* The client's 50 ms deadline holds while its responder is mid-copy. */
        pid_t w = fork();
        if (!w) {
            ReqRepHandle *h = at();
            if (recv1(h, &v, &id, 5.0) != 1) _exit(3);
            setenv("RR_COPY", "300", 1);
            reply1(h, id, v + 1);
            _exit(0);
        }
        ReqRepHandle *cli = at();
        double t0 = now_ms();
        r = request1(cli, 1, &o, 0.05);
        double el = now_ms() - t0;
        reap(w);
        printf("r=%d fast=%d pending=%u busy=%d\n", r, el < 150, reqrep_pending(cli), busy(srv));
    }
    else if (!strcmp(mode, "reg_evict_release") || !strcmp(mode, "reg_evict_mutex")) {
        /* The registry is full. An evictor takes a record and stops before releasing what its pid
         * held; q, a live process with the pid of another stale record, registers and takes a slot
         * or the mutex; the evictor resumes. Only a record whose pid is gone may be evicted, so
         * what q holds must survive. */
        int mutex = !strcmp(mode, "reg_evict_mutex");
        pid_t d = fork();
        if (!d) _exit(0);
        reap(d);
        pid_t e = fork();
        if (!e) { await(F_A); stall_at("REG_EVICTED"); at(); _exit(0); }
        pid_t q = fork();
        if (!q) {
            await(F_B);
            ReqRepHandle *h = at();
            if (mutex) lock_mutex(h);
            else { sh->res[0] = send1(h, 1, &id); sh->id[0] = id; }
            raise1(F_C);
            await(F_D);
            if (mutex) reqrep_mutex_unlock(h);
            _exit(0);
        }
        uint32_t home = fill_registry(srv, q);
        srv->procs[(home + 1) & (REQREP_PROC_SLOTS - 1)] = (ReqRepProc){ (uint32_t)d, 1 };
        raise1(F_A);
        wait_stop(e, "evictor");
        raise1(F_B);
        await(F_C);
        uint32_t before = __atomic_load_n(&srv->hdr->mutex, __ATOMIC_ACQUIRE);
        resume(e);
        reap(e);
        if (mutex) {
            uint32_t after = __atomic_load_n(&srv->hdr->mutex, __ATOMIC_ACQUIRE);
            printf("q_held=%d still_held=%d\n", before == REQREP_MUTEX_VAL(q), after == REQREP_MUTEX_VAL(q));
        } else {
            uint64_t c = __atomic_load_n(&reqrep_resp_slot(srv, REQREP_ID_SLOT(sh->id[0]))->ctl, __ATOMIC_ACQUIRE);
            printf("Q=%d held=%d\n", sh->res[0], REQREP_CTL_STATE(c) == RESP_ACQUIRED && REQREP_CTL_PID(c) == (uint32_t)q);
        }
        raise1(F_D);
        reap(q);
    }
    else if (!strcmp(mode, "reg_reclaim_stale")) {
        /* q finds its pid's record left by a dead process and stops before reclaiming it; another
         * process registers and takes a slot; q resumes. The record names a live pid, so it stays
         * q's to reclaim. */
        pid_t q = fork();
        if (!q) { await(F_A); stall_at("REG_RECLAIM"); at(); raise1(F_B); await(F_C); _exit(0); }
        uint32_t home = fill_registry(srv, q);
        raise1(F_A);
        wait_stop(q, "reclaimer");
        usleep(30000);   /* start times count in clock ticks: give the evictor one q never had */
        pid_t e = fork();
        if (!e) {
            ReqRepHandle *h = at();
            sh->res[0] = send1(h, 1, &id);
            raise1(F_D);
            await(F_C);
            _exit(0);
        }
        await(F_D);
        resume(q);
        await(F_B);
        uint32_t qstart = 0;
        reqrep_proc_stat((uint32_t)q, &qstart);
        ReqRepProc rec = srv->procs[home];
        printf("R=%d kept=%d\n", sh->res[0], rec.pid == (uint32_t)q && rec.start == qstart);
        raise1(F_C);
        reap(q);
        reap(e);
    }
    else if (!strcmp(mode, "image_first_threads")) {
        /* Two threads of a fresh program open the channel at once. The one that finds the record
         * the other made must not take it for a record left from before an exec, and release it. */
        pid_t k = fork();
        if (!k) {
            memset(reqrep_image_channels, 0, sizeof reqrep_image_channels);   /* a fresh image */
            setenv("RR_REG_WALK", "300", 1);   /* the first to register sleeps before its walk */
            pthread_t a;
            pthread_create(&a, NULL, open_in_thread, NULL);
            usleep(50000);
            ReqRepHandle *b = at();
            int sent = send1(b, 1, &id) == 1;
            pthread_join(a, NULL);
            uint64_t c = __atomic_load_n(&reqrep_resp_slot(b, REQREP_ID_SLOT(id))->ctl, __ATOMIC_ACQUIRE);
            printf("B=%d held=%d\n", sent, REQREP_CTL_STATE(c) == RESP_ACQUIRED && REQREP_CTL_PID(c) == ((uint32_t)getpid() & 0xFFFFFFU));
            fflush(stdout);
            _exit(0);
        }
        reap(k);
    }
    else if (!strcmp(mode, "unmarked_pair")) {
        /* Two requests taken off the queue and never marked received: a client waiting for them
         * in turn must still give up on one. */
        ReqRepHandle *cli = at();
        uint64_t ids[2];
        for (int i = 0; i < 2; i++) send1(cli, i + 1, &ids[i]);
        for (int i = 0; i < 2; i++) {
            pid_t t = fork();
            if (!t) { ReqRepHandle *h = at(); stall_at("RECV_UNMARKED"); recv1(h, &v, &id, 5.0); _exit(0); }
            wait_stop(t, "taker");
            killreap(t);
        }
        double t0 = now_ms();
        int gave_up = 0;
        while (!gave_up && now_ms() - t0 < 12000)
            for (int i = 0; i < 2 && !gave_up; i++) gave_up = getv(cli, ids[i], 0.3, &o) == -4;
        printf("gave_up=%d within=%d\n", gave_up, now_ms() - t0 < 10000);
    }
    else if (!strcmp(mode, "notify_counted_late")) {
        /* The replier stops between a notification the client's full queue refused and counting
         * it, while the client drains its queue and finds nothing counted; once the count moves,
         * the client must still be woken for that reply. */
        int qlen = 0;
        FILE *q = fopen("/proc/sys/net/unix/max_dgram_qlen", "r");
        if (!q || fscanf(q, "%d", &qlen) != 1 || qlen < 1 || qlen > 4000) { printf("woke=1 listed=1\n"); return 0; }
        fclose(q);
        uint32_t n = (uint32_t)qlen + 2;   /* a queue holds one more than max_dgram_qlen */
        char path2[4096];
        snprintf(path2, sizeof path2, "%s.2", path);
        unlink(path2);
        ReqRepHandle *s2 = is_int ? reqrep_create_int(path2, 8192, n, 0600, err) : reqrep_create(path2, 8192, n, 64, 0, 0600, err);
        ReqRepHandle *cli = s2 ? reqrep_open(path2, is_int ? REQREP_MODE_INT : REQREP_MODE_STR, err) : NULL;
        if (!cli) { printf("open: %s\n", err); return 2; }
        int fd = reqrep_ready_fd(cli);
        for (uint32_t i = 0; i < n; i++) send1(cli, 1, &id);
        pid_t w = fork();
        if (!w) {
            ReqRepHandle *h = reqrep_open(path2, is_int ? REQREP_MODE_INT : REQREP_MODE_STR, err);
            stall_at("NOTIFY_LOST");
            for (uint32_t i = 0; i < n && recv1(h, &v, &id, 5.0) == 1; i++) reply1(h, id, v + 1);
            _exit(0);
        }
        wait_stop(w, "replier");
        uint64_t *ids = malloc(n * sizeof *ids);
        while (reqrep_ready_ids(cli, ids, n) > 0) {}
        resume(w);
        reap(w);
        struct pollfd pfd = { fd, POLLIN, 0 };
        int woke = poll(&pfd, 1, 1000) == 1;
        printf("woke=%d listed=%d\n", woke, reqrep_ready_ids(cli, ids, n) > 0);
        unlink(path2);
    }
    unlink(path);
    return 0;
}
C
close $fh;

system($cc, '-O2', "-I$dir", '-o', "$dir/races", "$dir/races.c", '-lpthread') == 0
    or BAIL_OUT("cannot build the harness with $cc");

my @rows = (
    [stale_acquire        => qr/^R=1:6 X=1:2 busy=0$/, 'an acquirer acting on a stale FREE takes nothing from the next owner'],
    [stale_recover        => qr/^Y=1:4 R=1:6 reply=1 xreply=-2 busy=0$/, 'a recoverer acting on a stale dead owner takes a fresh generation'],
    [stale_release        => qr/^O=-4 N=1:6 busy=0$/, 'a reader resuming after clear() takes nothing from the next request'],
    [stale_cancel         => qr/^N=1:6 reply=1 busy=0$/, 'a cancel resuming after clear() leaves the next owner alone'],
    [send_clear           => qr/^same_id=0 X=1 N=1:6 replies=1,1 busy=0$/, 'a send resuming after clear() keeps its slot, and the next sender takes another'],
    [rec_clear            => qr/^Y=1:4 R=1:6 reply=1 xreply=-2 busy=0$/, 'so does one resuming after clear()'],
    [rec_abandoned        => qr/^N=1:4 R=1:6 busy=0$/, 'a recoverer of an abandoned slot resuming late leaves it alone'],
    [await_stale          => qr/^O=1:2 W=1 busy=0$/, 'a waiter that saw a writer which then published and exited gets the reply'],
    [cancel_stale         => qr/^O=1:2 N=1:6 busy=0$/, 'a cancel that saw a writer which then published and exited frees nothing under it'],
    [clear_stale          => qr/^O=1:2 W2=-2 N=-4 N2=(?:0|-3) N3=1:8 busy=0$/, 'clear() resuming late leaves a live copy to its responder'],
    [futex_aba            => qr/^O=-4 slept_long=0 W=1,1 B=1:6 busy=0$/, 'a waiter about to sleep across clear() and a new reply by the same responder is not left asleep'],
    [sw_park              => qr/^X=1 woke=1 replies=3,5$/, 'a sender that parked for the queue while slots ran out is woken when slots free'],
    [stale_acquire_reply  => qr/^same_low=1 stale_reply=-2 X=1:2 x_reply=1 busy=0$/, 'an acquirer acting on a stale FREE never takes a generation with the same low half'],
    [stale_writer_inflight => qr/^same_low=1 V=-2 reply=1 N=1:6 busy=0$/, 'a stale responder never takes a slot whose word differs only in its generation'],
    [stale_writer_entry   => qr/^same_low=1 V=-2 reply=1 N=1:6 busy=0$/, 'nor one that only starts replying then'],
    [stale_dispatch       => qr/^same_low=1 R=-2 kept=1 busy=0$/, 'a receiver resuming after its request was cancelled marks nothing under the next owner'],
    [stale_writer         => qr/^V=-2 N=1:6 busy=0$/, 'a responder resuming after its request was cancelled writes nothing'],
    [dup_writer           => qr/^W2=-2 W1=1 O=1:2 busy=0$/, 'a second reply to the same request is refused at once'],
    [dead_acquirer        => qr/^R=1:6 busy=0$/, 'a client killed while taking a slot leaves it recoverable'],
    [stopped_acquirer     => qr/^R=(?:0|-3) X=1:2 R2=1:8 busy=0$/, 'a client stopped while taking a slot is not taken for dead'],
    [clear_mid_acquire    => qr/^X=1:2 N=1:6 owner_N=1 busy=0$/, 'clear() leaves a slot being taken to its taker, so the next sender names only itself'],
    [room_taker_dies      => qr/^S=1 ended=1$/, 'a sender parked for room gets in after the receivers that made it died before waking it'],
    [cancel_abandoned_twice => qr/^busy=0$/, 'cancelling an abandoned reply again after its writer died leaves destroy to free the rest'],
    [cancel_raced_by_reply  => qr/^reply=1 busy=0$/, 'a cancel that loses its race to the reply leaves destroy to free that slot'],
    [pending_signal       => qr/^recv0=0 recv5=-7 send=1 get0=0 get5=-7 fast=1 then=1$/, 'a pending Perl signal ends a wait before it parks, but not a call that does not wait'],
    [mutex_dead_signals   => qr/^recovered=1$/, 'a mutex holder dead unreaped is recovered while signals keep interrupting the waits behind it'],
    [zombie_receiver_pair => qr/^gets=-4,-4 second_at_once=1$/, 'requests an unreaped dead receiver marked end one after another at once'],
    [woken_receiver_dies  => qr/^O=1:2 within=1$/, 'a request whose wake went to a receiver killed as it came is served by another parked receiver'],
    [dead_taker_clear     => qr/^O=-4 ended=1 busy=0$/, 'a request taken by a receiver killed before marking it still times out after clear()'],
    [stopped_reader       => qr/^R=(?:0|-3) O=1:2 R2=1:8 busy=0$/, 'nor is a client stopped with its reply unread'],
    [stopped_writer       => qr/^gave_up_early=0 O=1:2 W=1 busy=0$/, 'nor is a responder stopped mid-copy'],
    [dead_writer          => qr/^O=-4 within=1 busy=0$/, 'a wait with no deadline gives up on a responder killed mid-copy and frees the slot'],
    [dead_writer_deadline => qr/^O=-4 within=1 busy=0$/, 'so does a wait with a long deadline, within one tick'],
    [dead_taker           => qr/^O=-4 within=1 busy=0$/, 'and one whose receiver was killed after taking the request but before marking it received'],
    [dead_receiver        => qr/^O=-4 within=1 busy=0$/, 'and one whose receiver was killed before replying'],
    [dead_owner_dispatched => qr/^R=1:6 stale=-2 busy=0$/, 'a received request whose owner died is recovered without a reply'],
    [dead_owner_mid_reply => qr/^W=1 R=1:6 busy=0$/, 'a slot whose owner died mid-reply is recovered once the reply lands'],
    [clear_live           => qr/^W=-2 O=-4 N=1:6 busy=0$/, 'clear() leaves a reply being copied to its responder, which frees the slot'],
    [clear_writer_dies    => qr/^O=-4 N=1:6 busy=0$/, 'a responder killed after clear() abandoned its reply neither hangs a waiter nor holds the slot'],
    [epoch_reset_parking  => qr/^A=1 B=1 sum=5 fast=1 epoch=1 count=0$/, 'a receiver about to park when wakes reset the count takes the message and leaves the new count alone'],
    [stopped_holder       => qr/^send_wait=0 recv_wait=0 on_time=1 recv=0 bounded=1 eintr=1$/, 'calls waiting behind a stopped mutex holder keep their deadlines, and signals end untimed ones'],
    [mutex_reset_parking  => qr/^X=1 reset=1 fast=1$/, 'a locker about to park while the holder relocks past a count reset is woken at the next unlock'],
    [mutex_two_parked     => qr/^W=1,1 fast=1$/, 'the first of two callers parked on the mutex wakes the second at its unlock'],
    [epoch_reset_aba      => qr/^A=1 B=1:3 fast=1$/, 'a receiver that parked while a reset raced it is still woken'],
    [slot_tag_stale       => qr/^X=-4 Y=1:6 fast=1 busy=0$/, 'a waiter for an old generation leaves the next owner\'s registration counted'],
    [mutex_steal          => qr/^W=1 fast=1$/, 'a caller parked on the mutex and beaten to it is woken at the next unlock'],
    [deadline             => qr/^r=0 fast=1 pending=0 busy=0$/, 'a request\'s deadline holds while its responder is mid-copy'],
    [reg_evict_release    => qr/^Q=1 held=1$/, 'an evictor releasing a dead pid\'s holdings leaves the slot a live process took meanwhile'],
    [reg_evict_mutex      => qr/^q_held=1 still_held=1$/, '  and the mutex it holds'],
    [reg_reclaim_stale    => qr/^R=1 kept=1$/, 'a reclaimer resuming late keeps its record, which names a live pid'],
    [image_first_threads  => qr/^B=1 held=1$/, 'two threads opening the channel at once in a fresh program release nothing of each other'],
    [notify_counted_late  => qr/^woke=1 listed=1$/, 'a client that drained its queue before a refused notification was counted is still woken'],
    [unmarked_pair        => qr/^gave_up=1 within=1$/, 'a client waiting in turn for two requests taken but never marked gives up on one'],
);

for my $m (qw(str int)) {
    for my $row (@rows) {
        my ($mode, $want, $name) = @$row;
        my $o = qx{timeout 90 "$dir/races" $m $mode "$dir/s.shm" 2>&1};
        my ($last) = $o =~ /([^\n]*)\n?\z/;
        like $last, $want, "$m: $name" or diag $o;
    }
}

done_testing;
