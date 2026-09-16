use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# A reply carrying a stale id (its request was cancelled and the slot handed to
# a new request) briefly takes the slot to RESP_WRITING before its generation
# check sends it back. The live request's reply, arriving in that instant, used
# to fail its own CAS and report the request gone -- losing roughly half of
# such replies. Two responders are released on one slot together, one holding
# the stale id, one the live id; the live reply must always land and the stale
# one must never be accepted.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $inc = dirname(dirname(abs_path(__FILE__)));
-f "$inc/reqrep.h" or plan skip_all => 'reqrep.h not found';

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/stale.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include "reqrep.h"
#include <sys/wait.h>
struct sh { volatile long round; volatile uint64_t stale_id, fresh_id;
            volatile int r1, r2; volatile long done1, done2; volatile int stop; };
static void responder(struct sh *sh, const char *path, int stale) {
    char err[REQREP_ERR_BUFLEN];
    ReqRepHandle *w = reqrep_open(path, REQREP_MODE_STR, err);
    long seen = 0;
    for (;;) {
        while (sh->round == seen && !sh->stop) reqrep_spin_pause();
        if (sh->stop) _exit(0);
        seen = sh->round;
        if (stale) { sh->r1 = reqrep_reply(w, sh->stale_id, "stale", 5, false);
                     __atomic_store_n(&sh->done1, seen, __ATOMIC_RELEASE); }
        else       { sh->r2 = reqrep_reply(w, sh->fresh_id, "fresh", 5, false);
                     __atomic_store_n(&sh->done2, seen, __ATOMIC_RELEASE); }
    }
}
int main(int argc, char **argv) {
    const char *path = argv[1]; long n = atol(argv[2]);
    char err[REQREP_ERR_BUFLEN];
    unlink(path);
    ReqRepHandle *srv = reqrep_create(path, 64, 1, 64, 0, 0600, err);
    if (!srv) { printf("create: %s\n", err); return 2; }
    struct sh *sh = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
    pid_t a = fork(); if (!a) responder(sh, path, 1);
    pid_t b = fork(); if (!b) responder(sh, path, 0);
    ReqRepHandle *c = reqrep_open(path, REQREP_MODE_STR, err);
    long lost = 0, stale = 0; const char *s; uint32_t l; bool u; uint64_t id;
    for (long t = 1; t <= n; t++) {
        uint64_t ida, idb;
        if (reqrep_try_send(c, "a", 1, false, &ida) != 1) continue;
        reqrep_cancel(c, ida);
        if (reqrep_try_send(c, "b", 1, false, &idb) != 1) continue;
        reqrep_try_recv(srv, &s, &l, &u, &id); reqrep_try_recv(srv, &s, &l, &u, &id);
        sh->stale_id = ida; sh->fresh_id = idb;
        __atomic_store_n(&sh->round, t, __ATOMIC_RELEASE);
        while (__atomic_load_n(&sh->done1, __ATOMIC_ACQUIRE) != t
            || __atomic_load_n(&sh->done2, __ATOMIC_ACQUIRE) != t) reqrep_spin_pause();
        if (sh->r2 == 1) reqrep_try_get(c, idb, &s, &l, &u);
        else { lost++; reqrep_cancel(c, idb); }
        if (sh->r1 == 1) stale++;
    }
    sh->stop = 1; waitpid(a, 0, 0); waitpid(b, 0, 0);
    printf("lost=%ld stale=%ld\n", lost, stale);
    unlink(path);
    return 0;
}
C
close $fh;

system($cc, '-O2', "-I$inc", '-o', "$dir/stale", "$dir/stale.c", '-lpthread') == 0
    or plan skip_all => "cannot build the harness with $cc";

my $out = qx{"$dir/stale" "$dir/stale.shm" 20000};
like $out, qr/^lost=\d+ stale=\d+$/m, 'harness ran' or diag $out;
my ($lost, $stale) = $out =~ /lost=(\d+) stale=(\d+)/;
is $lost,  0, 'a stale reply never makes the live reply fail';
is $stale, 0, 'and is itself never accepted';

done_testing;
