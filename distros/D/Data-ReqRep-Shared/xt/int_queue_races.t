use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# Senders and receivers of the Int queue stopped (SIGSTOP) or killed at chosen
# instructions of a copy of reqrep.h.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $root = dirname(dirname(abs_path(__FILE__)));
-f "$root/reqrep.h" or plan skip_all => 'reqrep.h not found';
my $dir = tempdir(CLEANUP => 1);

open my $in, '<', "$root/reqrep.h" or die $!;
my $h = do { local $/; <$in> };
close $in;

# [name, function it must be in, statement, before|after, matches]
my @points = (
    [P_CLAIMED   => 'reqrep_int_try_send', qr/slot->value = value;/, 'before', 1],
    [C_TAKEN     => 'reqrep_int_try_recv', qr/uint64_t published = pos \+ 1;\n(?=\s*__atomic_compare_exchange_n\(&slot->sequence, &published, pos \+ cap)/, 'before', 1],
    [C_READ      => 'reqrep_int_try_recv', qr/uint64_t head = pos;(?=\n\s*if \(__atomic_compare_exchange_n\(&hdr->req_head)/, 'before', 1],
    [SKIP_MARKED => 'reqrep_int_skip_dead_claim', qr/__atomic_add_fetch\(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED\);/, 'before', 1],
    [SKIP_JUDGED => 'reqrep_int_skip_dead_claim', qr/uint64_t expected = pos;/, 'before', 1],
);
for my $p (@points) {
    my ($name, $fn, $re, $where, $want) = @$p;
    my $stall = qq{RR_STALL("$name");};
    my $n = 0;
    $h =~ s{(\n[^\n]*\b\Q$fn\E\([^;]*?\{\n.*?\n\}\n)}{ my $body = $1; $n = $body =~ s{^(\s*)($re)}{$where eq 'before' ? "$1$stall\n$1$2" : "$1$2\n$1$stall"}mge || 0; $body }se;
    BAIL_OUT("stall point $name matched $n, expected $want: update this test") unless $n == $want;
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

static void RR_STALL(const char *name) {
    char var[64];
    snprintf(var, sizeof var, "RR_%s", name);
    if (!getenv(var)) return;
    unsetenv(var);
    raise(SIGSTOP);
}
#include "rr.h"

struct sh { int res[8]; long val[8]; };
static struct sh *sh;
static const char *path;

static ReqRepHandle *at(void) {
    char err[REQREP_ERR_BUFLEN];
    ReqRepHandle *h = reqrep_open(path, REQREP_MODE_INT, err);
    if (!h) { printf("open: %s\n", err); _exit(2); }
    return h;
}
static void stall_at(const char *name) {
    char var[64];
    snprintf(var, sizeof var, "RR_%s", name);
    setenv(var, "1", 1);
}
static double now_ms(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}
static void wait_stop(pid_t p) {
    double t0 = now_ms();
    for (;;) {
        int st;
        pid_t r = waitpid(p, &st, WUNTRACED | WNOHANG);
        if (r == p && WIFSTOPPED(st)) return;
        if (r == p || now_ms() - t0 > 15000) { printf("UNEXPECTED: child never stopped\n"); exit(1); }
        usleep(200);
    }
}
static void reap(pid_t p) { waitpid(p, NULL, 0); }
static void killreap(pid_t p) { kill(p, SIGKILL); waitpid(p, NULL, 0); }
static long recv1(ReqRepHandle *h, double t) {
    int64_t v; uint64_t id;
    return reqrep_int_recv_wait(h, &v, &id, t) == 1 ? (long)v : -1;
}
/* Round trips through every position of several laps; how many completed. */
static int laps(ReqRepHandle *c, ReqRepHandle *s, int n) {
    for (int i = 0; i < n; i++) {
        uint64_t id, rid; int64_t v;
        if (reqrep_int_send_wait(c, 100 + i, &id, 1.0) != 1) return i;
        if (reqrep_int_recv_wait(s, &v, &rid, 1.0) != 1 || v != 100 + i) return i;
        if (reqrep_int_reply(s, rid, v) != 1 || reqrep_int_get_wait(c, id, &v, 1.0) != 1) return i;
    }
    return n;
}

int main(int argc, char **argv) {
    char err[REQREP_ERR_BUFLEN];
    const char *mode = argv[1];
    path = argv[2];
    unlink(path);
    ReqRepHandle *srv = reqrep_create_int(path, 4, 4, 0600, err);
    if (!srv) { printf("create: %s\n", err); return 2; }
    sh = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    ReqRepHandle *cli = at();
    uint64_t id;

    if (!strcmp(mode, "dead_producer")) {
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); reqrep_int_try_send(at(), 1, &id); _exit(0); }
        wait_stop(p);
        killreap(p);
        reqrep_int_try_send(cli, 2, &id);
        reqrep_int_try_send(cli, 3, &id);
        long a = recv1(srv, 3.0), b = recv1(srv, 3.0);
        printf("first=%ld second=%ld laps=%d skipped=%u\n", a, b, laps(cli, srv, 12), srv->hdr->stat_recoveries);
    }
    else if (!strcmp(mode, "stopped_producer")) {
        /* A sender stopped between claiming and publishing holds up the queue, but is not skipped. */
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); reqrep_int_try_send(at(), 1, &id); _exit(0); }
        wait_stop(p);
        reqrep_int_try_send(cli, 2, &id);
        long blocked = recv1(srv, 0.5);
        kill(p, SIGCONT); reap(p);
        long a = recv1(srv, 2.0), b = recv1(srv, 2.0);
        printf("blocked=%ld first=%ld second=%ld laps=%d\n", blocked, a, b, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "parked_then_killed")) {
        /* A receiver parked behind a stopped sender's claim; the sender is then killed and nothing
         * else is sent. The receiver must look again on its own. */
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); reqrep_int_try_send(at(), 1, &id); _exit(0); }
        wait_stop(p);
        reqrep_int_try_send(cli, 2, &id);
        pid_t r = fork();
        if (!r) { sh->val[0] = recv1(at(), 8.0); sh->val[1] = (long)now_ms(); _exit(0); }
        usleep(300000);
        double t = now_ms();
        killreap(p);
        reap(r);
        printf("got=%ld within=%d laps=%d\n", sh->val[0], sh->val[1] - (long)t < 3000, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "skipped_live")) {
        /* A live sender whose claim is skipped anyway (its pid taken for dead) finds out at publish
         * and sends again: the message arrives once. */
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); ReqRepHandle *h = at(); sh->res[0] = reqrep_int_send_wait(h, 1, &id, 5.0); _exit(0); }
        wait_stop(p);
        for (uint32_t i = 0; i < srv->resp_slots; i++) {
            RespSlotHeader *s = reqrep_resp_slot(srv, i);
            uint64_t c = __atomic_load_n(&s->ctl, __ATOMIC_ACQUIRE);
            if (REQREP_CTL_STATE(c) == RESP_ACQUIRED && REQREP_CTL_PID(c) == (uint32_t)p) s->claim_pos = UINT64_MAX;
        }
        reqrep_int_try_send(cli, 2, &id);
        long a = recv1(srv, 3.0);
        kill(p, SIGCONT); reap(p);
        long b = recv1(srv, 3.0), c = recv1(srv, 0.3);
        printf("sent=%d got=%ld,%ld more=%ld laps=%d\n", sh->res[0], a, b, c, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "dead_receiver")) {
        reqrep_int_try_send(cli, 1, &id);
        pid_t r = fork();
        if (!r) { stall_at("C_TAKEN"); recv1(at(), 2.0); _exit(0); }
        wait_stop(r);
        killreap(r);
        reqrep_int_try_send(cli, 2, &id);
        long a = recv1(srv, 2.0);
        printf("got=%ld laps=%d\n", a, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "stopped_receiver")) {
        /* A receiver stopped before moving the head past its message: another moves it for it. */
        reqrep_int_try_send(cli, 1, &id);
        reqrep_int_try_send(cli, 2, &id);
        pid_t r = fork();
        if (!r) { stall_at("C_TAKEN"); sh->val[0] = recv1(at(), 2.0); _exit(0); }
        wait_stop(r);
        long b = recv1(srv, 2.0);
        kill(r, SIGCONT); reap(r);
        long more = recv1(srv, 0.3);
        printf("stopped=%ld other=%ld more=%ld laps=%d\n", sh->val[0], b, more, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "clear_mid_send")) {
        /* clear() runs while a sender has claimed a position but not published it. */
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); sh->res[0] = reqrep_int_send_wait(at(), 1, &id, 5.0); _exit(0); }
        wait_stop(p);
        reqrep_int_clear(srv);
        kill(p, SIGCONT); reap(p);
        long a = recv1(srv, 2.0), more = recv1(srv, 0.3);
        printf("sent=%d got=%ld more=%ld laps=%d\n", sh->res[0], a, more, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "clear_reuse")) {
        /* clear() while a sender has claimed a position, then another sender comes: neither
         * request is lost or delivered twice. */
        sh->res[0] = -100;
        pid_t p = fork();
        if (!p) {
            stall_at("P_CLAIMED");
            ReqRepHandle *h = at();
            uint64_t pid_id; int64_t o = -1;
            int r = reqrep_int_send_wait(h, 1, &pid_id, 5.0);
            __atomic_store_n(&sh->res[0], r, __ATOMIC_RELEASE);
            sh->res[1] = r == 1 ? reqrep_int_get_wait(h, pid_id, &o, 3.0) : -9;
            sh->val[1] = (long)o;
            _exit(0);
        }
        wait_stop(p);
        reqrep_int_clear(srv);
        uint64_t nid; int64_t no = -1;
        int ns = reqrep_int_try_send(cli, 7, &nid);
        kill(p, SIGCONT);
        double t0 = now_ms();
        while (__atomic_load_n(&sh->res[0], __ATOMIC_ACQUIRE) == -100 && now_ms() - t0 < 5000) usleep(200);
        long got[3]; int rep[3];
        for (int i = 0; i < 3; i++) {
            int64_t v; uint64_t rid;
            got[i] = -1; rep[i] = 0;
            if (reqrep_int_recv_wait(srv, &v, &rid, i < 2 ? 2.0 : 0.3) != 1) continue;
            got[i] = (long)v;
            rep[i] = reqrep_int_reply(srv, rid, v + 1);
        }
        int ng = ns == 1 ? reqrep_int_get_wait(cli, nid, &no, 1.0) : -9;
        reap(p);
        printf("got=%ld,%ld,%ld replies=%d,%d P=%d:%ld N=%d:%ld laps=%d\n", got[0], got[1], got[2],
               rep[0], rep[1], sh->res[1], sh->val[1], ng, (long)no, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "clear_mid_take")) {
        /* clear() runs while a receiver has moved the head past a message but not marked it. */
        reqrep_int_try_send(cli, 1, &id);
        pid_t r = fork();
        if (!r) { stall_at("C_TAKEN"); sh->val[0] = recv1(at(), 2.0); _exit(0); }
        wait_stop(r);
        reqrep_int_clear(srv);
        kill(r, SIGCONT); reap(r);
        long more = recv1(srv, 0.3);
        printf("taken=%ld more=%ld laps=%d\n", sh->val[0], more, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "dead_skipper")) {
        /* A receiver killed after marking a dead claim skipped but before moving the head past it. */
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); reqrep_int_try_send(at(), 1, &id); _exit(0); }
        wait_stop(p);
        killreap(p);
        reqrep_int_try_send(cli, 2, &id);
        pid_t a = fork();
        if (!a) { stall_at("SKIP_MARKED"); recv1(at(), 5.0); _exit(0); }
        wait_stop(a);
        killreap(a);
        long got = recv1(srv, 2.0);
        printf("got=%ld laps=%d\n", got, laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "stale_take")) {
        /* A receiver read a message, then another took it and the cell was reused before it could. */
        reqrep_int_try_send(cli, 1, &id);
        pid_t a = fork();
        if (!a) { stall_at("C_READ"); sh->val[0] = recv1(at(), 3.0); _exit(0); }
        wait_stop(a);
        long got = recv1(srv, 2.0);
        int before = laps(cli, srv, 8);
        kill(a, SIGCONT);
        usleep(200000);
        reqrep_int_try_send(cli, 9, &id);
        reap(a);
        printf("got=%ld laps=%d A=%ld after=%d\n", got, before, sh->val[0], laps(cli, srv, 12));
    }
    else if (!strcmp(mode, "stale_skip")) {
        /* A receiver that judged a claim dead resumes after the cell was skipped and reused. */
        pid_t p = fork();
        if (!p) { stall_at("P_CLAIMED"); reqrep_int_try_send(at(), 1, &id); _exit(0); }
        wait_stop(p);
        killreap(p);
        reqrep_int_try_send(cli, 2, &id);
        pid_t a = fork();
        if (!a) { stall_at("SKIP_JUDGED"); sh->val[0] = recv1(at(), 5.0); _exit(0); }
        wait_stop(a);
        long got = recv1(srv, 2.0);
        int before = laps(cli, srv, 8);
        kill(a, SIGCONT);
        usleep(200000);
        reqrep_int_try_send(cli, 9, &id);
        reap(a);
        printf("got=%ld laps=%d A=%ld after=%d\n", got, before, sh->val[0], laps(cli, srv, 12));
    }
    unlink(path);
    return 0;
}
C
close $fh;

system($cc, '-O2', "-I$dir", '-o', "$dir/races", "$dir/races.c", '-lpthread') == 0
    or BAIL_OUT("cannot build the harness with $cc");

my @rows = (
    [dead_producer    => qr/^first=2 second=3 laps=12 skipped=[1-9]\d*$/, 'a sender killed between claiming and publishing is skipped, the queue keeps its order'],
    [stopped_producer => qr/^blocked=-1 first=1 second=2 laps=12$/, 'a sender stopped there holds up the queue but is not skipped'],
    [parked_then_killed => qr/^got=2 within=1 laps=12$/, 'a receiver parked behind a claim whose sender is then killed skips it without further sends'],
    [skipped_live     => qr/^sent=1 got=2,1 more=-1 laps=12$/, 'a live sender skipped anyway sends again, and its message arrives once'],
    [dead_receiver    => qr/^got=2 laps=12$/, 'a receiver killed before moving the head past its message does not wedge the queue'],
    [stopped_receiver => qr/^stopped=1 other=2 more=-1 laps=12$/, 'a receiver stopped there still gets its message once, and others get past it'],
    [clear_mid_send   => qr/^sent=1 got=1 more=-1 laps=12$/, 'clear() while a sender has claimed but not published: it publishes and the queue works'],
    [clear_reuse      => qr/^got=1,7,-1 replies=1,1 P=1:2 N=1:8 laps=12$/, 'clear() while a sender has claimed but not published: a later sender takes another position'],
    [clear_mid_take   => qr/^taken=1 more=-1 laps=12$/, 'clear() while a receiver is taking a message leaves the queue working'],
    [dead_skipper     => qr/^got=2 laps=12$/, 'a receiver killed between skipping a claim and moving the head past it does not wedge the queue'],
    [stale_take       => qr/^got=1 laps=8 A=9 after=12$/, 'a receiver resuming a take of a message someone else took gets the next one instead'],
    [stale_skip       => qr/^got=2 laps=8 A=9 after=12$/, 'a receiver resuming a stale skip leaves the reused cell alone'],
);
for my $row (@rows) {
    my ($mode, $want, $name) = @$row;
    my $o = qx{timeout 90 "$dir/races" $mode "$dir/q.shm" 2>&1};
    my ($last) = $o =~ /([^\n]*)\n?\z/;
    like $last, $want, $name or diag $o;
}

done_testing;
