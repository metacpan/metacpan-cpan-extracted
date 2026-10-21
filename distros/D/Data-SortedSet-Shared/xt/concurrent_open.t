use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Config;
use POSIX qw(_exit);
use Data::SortedSet::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

# Many processes race to create/open the same backing file at once; the
# flock-serialized create path must let every opener succeed.
my $N     = 8;
my $ITERS = 20;
my $dir = tempdir(CLEANUP => 1);
for my $iter (1 .. $ITERS) {
    my $path = "$dir/set.$iter";
    my @pids;
    for (1 .. $N) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $ok = eval {
                my $z = Data::SortedSet::Shared->new($path, 1000);
                $z->add(int(rand(1000)), rand());
                1;
            };
            _exit($ok ? 0 : 1);
        }
        push @pids, $pid;
    }
    my @fails;
    for my $pid (@pids) { waitpid $pid, 0; push @fails, $pid if $? != 0 }
    unlink $path;
    is scalar(@fails), 0, "iter $iter: $N procs race open, all succeed"
        or diag "failed pids: @fails";
}

open my $c, '>', "$dir/attach.c" or die $!;
print $c <<'C';
#include <stdio.h>
#include <poll.h>
#include <sys/wait.h>
#include "sortedset.h"
int main(int argc, char **argv) {
    char err[SS_ERR_BUFLEN];
    int by_fd = argc > 2, p[2], status;
    SsHandle *z = by_fd ? ss_create_memfd("attach", 10, err) : ss_create(argv[1], 10, 0600, err);
    if (!z) return 2;
    ss_rwlock_wrlock(z);
    ss_add_locked(z, 5, 7.5);
    ss_wphase(z, SS_WP_TREE);
    z->hdr->count = 0;  /* root published before the first insert's count */
    if (pipe(p)) return 2;
    pid_t child = fork();
    if (child < 0) return 2;
    if (!child) {
        close(p[0]);
        if (write(p[1], "R", 1) != 1) _exit(2);
        SsHandle *h = by_fd ? ss_open_fd(z->backing_fd, err) : ss_create(argv[1], 10, 0600, err);
        char result = h && h->hdr->count == 1 ? 'Y' : 'N';
        if (h) ss_destroy(h);
        if (write(p[1], &result, 1) != 1) _exit(2);
        _exit(result == 'Y' ? 0 : 1);
    }
    close(p[1]);
    char result;
    if (read(p[0], &result, 1) != 1 || result != 'R') return 2;
    struct pollfd ready = { p[0], POLLIN, 0 };
    int premature = poll(&ready, 1, 200) != 0;
    z->hdr->count = 1;
    ss_wphase(z, SS_WP_NONE);
    ss_rwlock_wrunlock(z);
    int good = read(p[0], &result, 1) == 1 && result == 'Y';
    waitpid(child, &status, 0);
    close(p[0]);
    ss_destroy(z);
    return premature || !good || status ? 1 : 0;
}
C
close $c;
my $cc = $Config{cc};
my $build = `$cc -O2 -D_GNU_SOURCE -I. $dir/attach.c -o $dir/attach -lpthread 2>&1`;
is $?, 0, 'live-writer attach harness compiles' or BAIL_OUT($build);
for my $by_fd (0, 1) {
    my $rc = system('timeout', '10', "$dir/attach", "$dir/live.$by_fd", ($by_fd ? 'fd' : ()));
    is $rc, 0, ($by_fd ? 'fd' : 'path') . ' attach waits for a live writer before checking tree state';
}

done_testing;
