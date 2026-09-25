use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);

open my $fh, '>', "$dir/sig.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <signal.h>
#include <sys/time.h>
#include "reqrep.h"
static void tick(int s) { (void)s; }
static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec / 1e9; }
int main(int argc, char **argv) {
    char err[REQREP_ERR_BUFLEN];
    int is_int = !strcmp(argv[1], "int");
    ReqRepHandle *h = is_int ? reqrep_create_int(NULL, 16, 1, 0600, err) : reqrep_create(NULL, 16, 1, 64, 0, 0600, err);
    if (!h) { printf("create: %s\n", err); return 2; }
    struct sigaction sa = { 0 };
    sa.sa_handler = tick;
    sigaction(SIGALRM, &sa, NULL);
    struct itimerval it = { { 0, 300000 }, { 0, 300000 } };
    setitimer(ITIMER_REAL, &it, NULL);
    double t0 = now();
    int r;
    if (is_int) { int64_t o; r = reqrep_int_request(h, 1, &o, 1.0); }
    else { const char *s; uint32_t l; bool u; r = reqrep_request(h, "x", 1, false, &s, &l, &u, 1.0); }
    printf("r=%d secs=%.1f\n", r, now() - t0);
    return 0;
}
C
close $fh;
system($cc, '-O2', "-I$root", '-o', "$dir/sig", "$dir/sig.c", '-lpthread') == 0
    or plan skip_all => "cannot build with $cc";

for my $m (qw(str int)) {
    my $out = qx{timeout 10 "$dir/sig" $m 2>&1};
    like $out, qr/^r=0 secs=1\.\d$/, "$m: a 1 s request under a 0.3 s signal times out at its deadline" or diag $out || 'no output: still waiting after 10 s';
}

done_testing;
