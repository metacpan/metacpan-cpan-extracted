use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# Processes descheduled at the wrong instruction, forced by stalls injected into
# a copy of reqrep.h. The client's deadline must hold, no slot may leak or sit
# idle, and no reply may be lost or delivered to the wrong request.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $inc = dirname(dirname(abs_path(__FILE__)));
-f "$inc/reqrep.h" or plan skip_all => 'reqrep.h not found';

my $dir = tempdir(CLEANUP => 1);
open my $in, '<', "$inc/reqrep.h" or die $!;
my $h = do { local $/; <$in> };
close $in;

# [name, matches expected, function to confine it to, statement, stall before or after it]
my @points = (
    # a responder after taking RESP_WRITING, before storing its pid
    [window   => 2, undef, qr/__atomic_store_n\(&slot->writer_pid, \(uint32_t\)getpid\(\), __ATOMIC_RELAXED\);/, 'before'],
    # a responder after its generation check, before the payload lands
    [copy     => 2, undef, qr/if \(len > 0\) memcpy\(data, str, len\);|\*\(int64_t \*\)\(\(uint8_t \*\)slot \+ sizeof\(RespSlotHeader\)\) = value;/, 'before'],
    # a stale responder handing the slot back, after clearing writer_pid
    [restore  => 2, undef, qr/uint32_t expected_writing = RESP_WRITING;/, 'before'],
    # a responder checking whether the one holding RESP_WRITING is alive
    [live     => 1, 'reqrep_writer_is_live', qr/reqrep_spin_pause\(\);/, 'before'],
    # an acquirer between taking the slot and bumping its generation
    [acquire  => 1, 'reqrep_slot_acquire', qr/__atomic_add_fetch\(&slot->generation, 1, __ATOMIC_RELEASE\);(?=\n\s*__atomic_store_n\(&h->hdr->resp_hint)/, 'before'],
    # a recoverer between reading a slot and claiming it
    [recovery => 1, undef, qr/uint32_t pid = __atomic_load_n\(&slot->owner_pid, __ATOMIC_ACQUIRE\);/, 'after'],
    # a recoverer right after claiming a slot
    [claimed  => 1, 'reqrep_slot_acquire', qr/if \(!__atomic_compare_exchange_n\(&slot->owner_pid, &expected_pid, \w+,\n\s*0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED\)\)\n\s*continue;/, 'after'],
    # a cancel right after clearing owner_pid
    [unowned  => 1, 'reqrep_cancel', qr/__atomic_store_n\(&slot->owner_pid, 0, __ATOMIC_RELAXED\);/, 'after'],
    # the release after reading a reply, before it bumps the generation
    [release  => 1, 'reqrep_slot_release_from', qr/__atomic_add_fetch\(&slot->generation, 1, __ATOMIC_RELEASE\);/, 'before'],
);
for my $p (@points) {
    my ($name, $want, $fn, $re, $where) = @$p;
    my $stall = 'RR_STALL("RR_STALL_' . uc($name) . '_MS");';
    my $inject = sub {
        $_[0] =~ s{^(\s*)($re)}{$where eq 'before' ? "$1$stall\n$1$2" : "$1$2\n$1$stall"}mge || 0;
    };
    my $n = 0;
    if ($fn) { $h =~ s{(\n[^\n]*\b\Q$fn\E\([^;]*?\{\n.*?\n\}\n)}{ my $body = $1; $n = $inject->($body); $body }se }
    else     { $n = $inject->($h) }
    BAIL_OUT("stall point '$name' matched $n, expected $want: update this test") unless $n == $want;
}
open my $out, '>', "$dir/rr.h" or die $!;
print {$out} $h;
close $out;

open my $fh, '>', "$dir/stall.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
static void RR_STALL(const char *var) {
    const char *v = getenv(var);
    if (!v) return;
    long ms = atol(v);
    struct timespec ts = { ms / 1000, (ms % 1000) * 1000000L };
    nanosleep(&ts, NULL);
}
#include "rr.h"
#include <signal.h>
#include <sys/wait.h>

struct sh { int got, go, goy, goz, ra, rb, ry; long oy; };
static struct sh *sh;
static int is_int;
static const char *path;

static ReqRepHandle *at(void) {
    char err[REQREP_ERR_BUFLEN];
    ReqRepHandle *h = reqrep_open(path, is_int ? REQREP_MODE_INT : REQREP_MODE_STR, err);
    if (!h) { printf("open: %s\n", err); _exit(2); }
    return h;
}
/* Single digits, so both modes carry the same values. */
static int send1(ReqRepHandle *h, long v, uint64_t *id) {
    if (is_int) return reqrep_int_try_send(h, v, id);
    char c = '0' + v;
    return reqrep_try_send(h, &c, 1, false, id);
}
static int send_wait1(ReqRepHandle *h, long v, uint64_t *id, double timeout) {
    if (is_int) return reqrep_int_send_wait(h, v, id, timeout);
    char c = '0' + v;
    return reqrep_send_wait(h, &c, 1, false, id, timeout);
}
static int reply1(ReqRepHandle *h, uint64_t id, long v) {
    if (is_int) return reqrep_int_reply(h, id, v);
    char c = '0' + v;
    return reqrep_reply(h, id, &c, 1, false);
}
static int get1(ReqRepHandle *h, uint64_t id, double timeout) {
    int64_t o; const char *s; uint32_t l; bool u;
    return is_int ? reqrep_int_get_wait(h, id, &o, timeout)
                  : reqrep_get_wait(h, id, &s, &l, &u, timeout);
}
static void drain1(ReqRepHandle *h, uint64_t id) {
    int64_t o; const char *s; uint32_t l; bool u;
    if (is_int) reqrep_int_try_get(h, id, &o); else reqrep_try_get(h, id, &s, &l, &u);
}
static int request1(ReqRepHandle *h, long v, long *out, double timeout) {
    if (is_int) {
        int64_t o; int r = reqrep_int_request(h, v, &o, timeout);
        if (r == 1) *out = o;
        return r;
    }
    char c = '0' + v; const char *s; uint32_t l; bool u;
    int r = reqrep_request(h, &c, 1, false, &s, &l, &u, timeout);
    if (r == 1) *out = l == 1 ? s[0] - '0' : -1;
    return r;
}
static void clear1(ReqRepHandle *h) { if (is_int) reqrep_int_clear(h); else reqrep_clear(h); }
static int busy(ReqRepHandle *h) {
    int n = 0;
    for (uint32_t i = 0; i < h->resp_slots; i++)
        if (__atomic_load_n(&reqrep_resp_slot(h, i)->state, __ATOMIC_ACQUIRE) != RESP_FREE) n++;
    return n;
}
static void await(int *flag) { while (!__atomic_load_n(flag, __ATOMIC_ACQUIRE)) usleep(100); }
static void raise1(int *flag) { __atomic_store_n(flag, 1, __ATOMIC_RELEASE); }
static uint64_t hold_slot(ReqRepHandle *h) {
    int32_t s = reqrep_slot_acquire(h);
    return REQREP_MAKE_ID((uint32_t)s,
        __atomic_load_n(&reqrep_resp_slot(h, (uint32_t)s)->generation, __ATOMIC_ACQUIRE));
}

/* Take one request and reply v to it, stalled at `var` if given. */
static pid_t responder(const char *var, const char *ms, int wait_go, long v, int *res) {
    pid_t p = fork();
    if (p) return p;
    if (var) setenv(var, ms, 1);
    ReqRepHandle *h = at();
    uint64_t id; int64_t iv; const char *s; uint32_t l; bool u;
    int r = is_int ? reqrep_int_recv_wait(h, &iv, &id, 5.0)
                   : reqrep_recv_wait(h, &s, &l, &u, &id, 5.0);
    if (r != 1) _exit(3);
    raise1(&sh->got);
    if (wait_go) { await(&sh->go); usleep(50000); }
    r = reply1(h, id, v);
    if (res) *res = r;
    _exit(0);
}

/* Another client: once *flag is up and delay_ms has passed, request v and
 * record the outcome in ry/oy. */
static pid_t client(int *flag, int delay_ms, long v) {
    pid_t p = fork();
    if (p) return p;
    ReqRepHandle *h = at();
    await(flag);
    usleep(delay_ms * 1000);
    long out = -1;
    sh->ry = request1(h, v, &out, 3.0);
    sh->oy = out;
    _exit(0);
}

static double now_ms(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

int main(int argc, char **argv) {
    char err[REQREP_ERR_BUFLEN];
    is_int = !strcmp(argv[1], "int");
    const char *mode = argv[2];
    path = argv[3];
    unlink(path);
    uint32_t nslots = strcmp(mode, "deadline") ? 1 : 4;
    ReqRepHandle *srv = is_int ? reqrep_create_int(path, 16, nslots, 0600, err)
                               : reqrep_create(path, 16, nslots, 64, 0, 0600, err);
    if (!srv) { printf("create: %s\n", err); return 2; }
    sh = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    ReqRepHandle *cli = at();
    long out = -1;

    if (!strcmp(mode, "deadline")) {
        /* argv[4]: where the responder stalls for 300ms; the deadline is 50ms. */
        char var[64]; snprintf(var, sizeof var, "RR_STALL_%s_MS", argv[4]);
        pid_t a = responder(var, "300", 0, 7, NULL);
        double t0 = now_ms();
        int r = request1(cli, 1, &out, 0.05);
        double el = now_ms() - t0;
        waitpid(a, NULL, 0);
        printf("r=%d ms=%.0f pending=%u busy=%d\n", r, el, reqrep_pending(cli), busy(cli));
    }
    else if (!strcmp(mode, "done") || !strcmp(mode, "restore")) {
        /* Leave the pid of an exited responder in the only slot: one that
         * finished the slot's previous reply, or one whose stale id took and
         * restored the slot of the request we are about to time out. */
        uint64_t id0, id1;
        if (!strcmp(mode, "done")) {
            send1(cli, 1, &id0);
            waitpid(responder(NULL, NULL, 0, 1, NULL), NULL, 0);
            get1(cli, id0, 1.0);
            send1(cli, 2, &id1);
        } else {
            send1(cli, 1, &id0);
            reqrep_cancel(cli, id0);
            send1(cli, 2, &id1);
            waitpid(responder(NULL, NULL, 0, 1, NULL), NULL, 0);
        }
        __atomic_store_n(&sh->got, 0, __ATOMIC_RELEASE);
        pid_t a = responder("RR_STALL_WINDOW_MS", "300", 0, 3, &sh->ra);
        await(&sh->got);
        usleep(20000);
        int r1 = get1(cli, id1, 0.03);
        reqrep_cancel(cli, id1);
        drain1(cli, id1);
        pid_t b = responder("RR_STALL_COPY_MS", "400", 0, 4, &sh->rb);
        int r2 = request1(cli, 5, &out, 3.0);
        waitpid(a, NULL, 0); waitpid(b, NULL, 0);
        printf("r1=%d r2=%d out=%ld ra=%d rb=%d busy=%d\n", r1, r2, out, sh->ra, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "dead_owner")) {
        /* The only slot: its owner died and a reply to it is still being
         * copied in. A client waiting for a slot must get it once that copy
         * ends, not at its own deadline. */
        pid_t c1 = fork();
        if (!c1) { uint64_t id; send1(at(), 1, &id); _exit(0); }
        waitpid(c1, NULL, 0);
        pid_t a = responder("RR_STALL_COPY_MS", "300", 0, 3, &sh->ra);
        await(&sh->got);
        usleep(20000);
        pid_t b = responder(NULL, NULL, 0, 4, &sh->rb);
        double t0 = now_ms();
        int r2 = request1(cli, 5, &out, 3.0);
        double el = now_ms() - t0;
        waitpid(a, NULL, 0); waitpid(b, NULL, 0);
        printf("r2=%d out=%ld ms=%.0f ra=%d rb=%d busy=%d\n", r2, out, el, sh->ra, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "recovery")) {
        /* The only slot belongs to a client that died after sending. A reply
         * to it starts while a recoverer is between reading and claiming it. */
        pid_t c1 = fork();
        if (!c1) { uint64_t id; send1(at(), 1, &id); _exit(0); }
        waitpid(c1, NULL, 0);
        pid_t a = responder("RR_STALL_COPY_MS", "400", 1, 3, &sh->ra);
        await(&sh->got);
        pid_t b = responder("RR_STALL_COPY_MS", "600", 0, 4, &sh->rb);
        setenv("RR_STALL_RECOVERY_MS", "200", 1);
        raise1(&sh->go);
        int r2 = request1(cli, 5, &out, 3.0);
        unsetenv("RR_STALL_RECOVERY_MS");
        waitpid(a, NULL, 0); waitpid(b, NULL, 0);
        printf("r2=%d out=%ld ra=%d rb=%d busy=%d\n", r2, out, sh->ra, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "live_check")) {
        /* A stale reply parks the slot in WRITING and hands it back while the
         * live reply is checking on it: the live one must take its turn. */
        uint64_t id0, id1;
        send1(cli, 1, &id0);
        reqrep_cancel(cli, id0);
        send1(cli, 2, &id1);
        pid_t a = responder("RR_STALL_RESTORE_MS", "100", 0, 3, &sh->ra);
        await(&sh->got);
        usleep(20000);
        pid_t b = responder("RR_STALL_LIVE_MS", "200", 0, 4, &sh->rb);
        int g = get1(cli, id1, 2.0);
        if (g != 1) { reqrep_cancel(cli, id1); drain1(cli, id1); }
        waitpid(a, NULL, 0); waitpid(b, NULL, 0);
        printf("g=%d ra=%d rb=%d busy=%d\n", g, sh->ra, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "get_then_cancel")) {
        /* cancel on an id whose reply was already read, while another client
         * is part-way through acquiring the slot. */
        uint64_t id1;
        send1(cli, 1, &id1);
        waitpid(responder(NULL, NULL, 0, 3, NULL), NULL, 0);
        get1(cli, id1, 1.0);
        pid_t b = responder(NULL, NULL, 0, 4, &sh->rb);
        setenv("RR_STALL_ACQUIRE_MS", "300", 1);
        pid_t y = client(&sh->goy, 0, 5);
        unsetenv("RR_STALL_ACQUIRE_MS");
        raise1(&sh->goy);
        usleep(100000);
        reqrep_cancel(cli, id1);
        waitpid(y, NULL, 0); waitpid(b, NULL, 0);
        printf("ry=%d oy=%ld rb=%d busy=%d\n", sh->ry, sh->oy, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "orphan_cancel") || !strcmp(mode, "orphan_get")) {
        /* A release descheduled part-way -- a cancel, or the release after
         * reading a reply -- while another client recovers the slot: the rest
         * of the release must not touch the slot's new owner. */
        uint64_t id1;
        int get = !strcmp(mode, "orphan_get");
        if (get) {
            send1(cli, 1, &id1);
            waitpid(responder(NULL, NULL, 0, 3, NULL), NULL, 0);
        } else {
            id1 = hold_slot(cli);
        }
        pid_t b = responder(NULL, NULL, 1, 4, &sh->rb);
        pid_t y = client(&sh->goy, 50, 5);
        raise1(&sh->goy);
        const char *var = get ? "RR_STALL_RELEASE_MS" : "RR_STALL_UNOWNED_MS";
        setenv(var, "300", 1);
        if (get) get1(cli, id1, 1.0); else reqrep_cancel(cli, id1);
        unsetenv(var);
        raise1(&sh->go);
        waitpid(y, NULL, 0); waitpid(b, NULL, 0);
        printf("ry=%d oy=%ld rb=%d busy=%d\n", sh->ry, sh->oy, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "orphan_race")) {
        /* A recoverer that saw a cancel part-way and was descheduled must not
         * take the slot from whoever acquired it once the cancel finished. */
        uint64_t id1 = hold_slot(cli);
        pid_t b = responder(NULL, NULL, 1, 4, &sh->rb);
        pid_t r = fork();
        if (!r) {
            ReqRepHandle *h = at();
            uint64_t id;
            await(&sh->goy);
            usleep(20000);
            setenv("RR_STALL_RECOVERY_MS", "400", 1);
            send_wait1(h, 9, &id, 3.0);
            _exit(0);
        }
        pid_t y = client(&sh->goz, 0, 5);
        raise1(&sh->goy);
        setenv("RR_STALL_UNOWNED_MS", "100", 1);
        reqrep_cancel(cli, id1);
        unsetenv("RR_STALL_UNOWNED_MS");
        raise1(&sh->goz);
        usleep(500000);
        raise1(&sh->go);
        waitpid(y, NULL, 0); waitpid(b, NULL, 0); waitpid(r, NULL, 0);
        printf("ry=%d oy=%ld rb=%d\n", sh->ry, sh->oy, sh->rb);
    }
    else if (!strcmp(mode, "dead_recoverer")) {
        /* A recoverer killed right after claiming a dead owner's slot must
         * leave it to the next one. */
        pid_t c1 = fork();
        if (!c1) { hold_slot(at()); _exit(0); }
        waitpid(c1, NULL, 0);
        pid_t r = fork();
        if (!r) {
            setenv("RR_STALL_CLAIMED_MS", "5000", 1);
            uint64_t id;
            send_wait1(at(), 9, &id, 3.0);
            _exit(0);
        }
        usleep(200000);
        kill(r, SIGKILL);
        waitpid(r, NULL, 0);
        pid_t b = responder(NULL, NULL, 0, 4, &sh->rb);
        int r2 = request1(cli, 5, &out, 3.0);
        waitpid(b, NULL, 0);
        printf("r2=%d out=%ld rb=%d busy=%d\n", r2, out, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "clear_live")) {
        /* clear() while a reply is being copied in must not hand the slot on
         * under that copy. */
        uint64_t id1;
        send1(cli, 1, &id1);
        pid_t a = responder("RR_STALL_COPY_MS", "400", 0, 3, &sh->ra);
        await(&sh->got);
        usleep(50000);
        clear1(srv);
        pid_t b = responder("RR_STALL_COPY_MS", "600", 0, 4, &sh->rb);
        int r2 = request1(cli, 5, &out, 3.0);
        waitpid(a, NULL, 0); waitpid(b, NULL, 0);
        printf("r2=%d out=%ld ra=%d rb=%d busy=%d\n", r2, out, sh->ra, sh->rb, busy(cli));
    }
    else if (!strcmp(mode, "clear_dead")) {
        /* A responder killed before storing its pid strands its slot for cancel
         * and recovery alike; clear() is the documented way back. */
        uint64_t id1;
        send1(cli, 1, &id1);
        pid_t a = responder("RR_STALL_WINDOW_MS", "5000", 0, 3, NULL);
        await(&sh->got);
        usleep(50000);
        kill(a, SIGKILL);
        waitpid(a, NULL, 0);
        get1(cli, id1, 0.05);
        reqrep_cancel(cli, id1);
        drain1(cli, id1);
        clear1(srv);
        pid_t b = responder(NULL, NULL, 0, 4, &sh->rb);
        int r2 = request1(cli, 5, &out, 3.0);
        waitpid(b, NULL, 0);
        printf("r2=%d out=%ld rb=%d busy=%d\n", r2, out, sh->rb, busy(cli));
    }
    unlink(path);
    return 0;
}
C
close $fh;

system($cc, '-O2', "-I$dir", '-o', "$dir/stall", "$dir/stall.c", '-lpthread') == 0
    or plan skip_all => "cannot build the harness with $cc";

sub run { my ($m, $mode, @rest) = @_; my $o = qx{"$dir/stall" $m $mode "$dir/s.shm" @rest}; chomp $o; return $o }

my @rows = (
    [done            => qr/^r1=0 r2=1 out=4 ra=-2 rb=1 busy=0$/,
        "an exited responder's pid does not let cancel take the slot from a live one"],
    [restore         => qr/^r1=0 r2=1 out=4 ra=-2 rb=1 busy=0$/,
        "nor does the pid of one that handed the slot back and exited"],
    [recovery        => qr/^r2=1 out=4 ra=-2 rb=1 busy=0$/,
        "recovery leaves a slot to a reply that started after its check"],
    [live_check      => qr/^g=1 ra=-2 rb=1 busy=0$/,
        "a reply waiting out a stale one takes its turn when the slot is handed back"],
    [get_then_cancel => qr/^ry=1 oy=4 rb=1 busy=0$/,
        "cancel on an id already read leaves the slot's next owner alone"],
    [orphan_cancel   => qr/^ry=1 oy=4 rb=1 busy=0$/,
        "a cancel descheduled mid-release leaves the slot's next owner alone"],
    [orphan_get      => qr/^ry=1 oy=4 rb=1 busy=0$/,
        "so does the release after reading a reply"],
    [orphan_race     => qr/^ry=1 oy=4 rb=1$/,
        "a recoverer descheduled mid-scan leaves the slot's next owner alone"],
    [dead_recoverer  => qr/^r2=1 out=4 rb=1 busy=0$/,
        "a recoverer killed mid-recovery leaves the slot recoverable"],
    [clear_live      => qr/^r2=1 out=4 ra=-2 rb=1 busy=0$/,
        "clear() leaves a slot to the reply being copied into it"],
    [clear_dead      => qr/^r2=1 out=4 rb=1 busy=0$/,
        "clear() frees a slot whose responder died before storing its pid"],
);

for my $m (qw(str int)) {
    for my $at (qw(WINDOW COPY)) {
        my $o = run($m, 'deadline', $at);
        my ($r, $ms, $pend, $busy) = $o =~ /r=(-?\d+) ms=(\d+) pending=(\d+) busy=(\d+)/
            or do { fail("$m deadline $at: $o"); next };
        ok $r == 0 && $ms < 150 && $pend == 0 && $busy == 0,
            "$m: a responder stalled at $at neither holds the client past its deadline nor leaks the slot"
            or diag $o;
    }
    my $d = run($m, 'dead_owner');
    my ($ms) = $d =~ /ms=(\d+)/;
    ok $d =~ /^r2=1 out=4 ms=\d+ ra=-2 rb=1 busy=0$/ && $ms < 1000,
        "$m: a slot whose owner died mid-reply is handed on when the copy ends" or diag $d;
    like run($m, $_->[0]), $_->[1], "$m: $_->[2]" for @rows;
}

done_testing;
