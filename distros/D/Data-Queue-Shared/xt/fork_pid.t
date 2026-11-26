use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

# The lock word names its holder; a forked child must not inherit the parent's cached PID.

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/forkpid.c" or die $!;
print {$out} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <sys/wait.h>
#include "queue.h"

int main(void) {
    char err[QUEUE_ERR_BUFLEN];
    QueueHandle *q = queue_create(NULL, 16, QUEUE_MODE_STR, 4096, 0600, err);
    if (!q) { fprintf(stderr, "%s\n", err); return 2; }
    queue_str_lock(q);
    queue_mutex_unlock(q->hdr);
    pid_t kid = fork();
    if (kid < 0) return 2;
    if (!kid) {
        queue_str_lock(q);
        uint32_t word = __atomic_load_n(&q->hdr->mutex, __ATOMIC_RELAXED);
        queue_mutex_unlock(q->hdr);
        _exit(word == QUEUE_MUTEX_VAL(getpid()) ? 0 : 1);
    }
    int status;
    waitpid(kid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 2;
}
C
close $out;

my @cc = shellwords($Config{cc});
is system(@cc, '-O2', "-I$root", '-o', "$dir/forkpid", "$dir/forkpid.c"), 0, 'harness builds';
is system("$dir/forkpid") >> 8, 0, 'a forked child holds the lock under its own PID';

done_testing;
