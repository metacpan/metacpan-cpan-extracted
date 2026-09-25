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
-f "$root/reqrep.h" or plan skip_all => 'reqrep.h not found';
my $dir = tempdir(CLEANUP => 1);

open my $fh, '>', "$dir/pass_wake.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include "reqrep.h"

int main(int argc, char **argv) {
    char err[REQREP_ERR_BUFLEN];
    ReqRepHandle *h = reqrep_create(NULL, 16, 2, 64, 0, 0600, err);
    if (!h) { printf("create: %s\n", err); return 2; }

    ReqRepHeader *hdr = h->hdr;
    hdr->send_waiters = 1;
    hdr->arena_used = 0;

    const char *mode = argv[1];
    if (!strcmp(mode, "control")) {
        hdr->req_tail = 6;
        hdr->req_head = 5;
    } else if (!strcmp(mode, "underflow")) {
        hdr->req_tail = 5;
        hdr->req_head = 6;
    } else {
        return 3;
    }

    uint32_t f0 = hdr->send_futex;
    reqrep_pass_send_wake(h);
    uint32_t f1 = hdr->send_futex;

    printf("woken=%d\n", f1 > f0);
    return 0;
}
C
close $fh;

system($cc, '-O2', "-I$root", '-o', "$dir/pass_wake", "$dir/pass_wake.c", '-lpthread') == 0
    or plan skip_all => "cannot build with $cc";

my $ctrl = qx{"$dir/pass_wake" control 2>&1};
like $ctrl, qr/^woken=1$/, 'control: normal queue size wakes waiting sender';

my $out = qx{"$dir/pass_wake" underflow 2>&1};
like $out, qr/^woken=1$/, 'pass_send_wake wakes waiting sender when req_tail < req_head (monotonic wrap guard)'
    or diag $out;

done_testing;
