use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
plan skip_all => 'radix.h not found' unless -f 'radix.h';
my $dir = tempdir(CLEANUP => 1);
open my $in, '<', 'radix.h' or die $!;
my $hdr = do { local $/; <$in> };
close $in;

my @points = (
    [leaf   => qr/^\s*__atomic_store_n\(&nodes\[cur\]\.children\[b\], leaf, __ATOMIC_RELEASE\);/m, [1], 1],
    [value  => qr/^\s*__atomic_store_n\(&nodes\[cur\]\.has_value, 1, __ATOMIC_RELEASE\);/m, [2], 1],
    [split  => qr/^\s*__atomic_store_n\(&nodes\[cur\]\.children\[b\], mid, __ATOMIC_RELEASE\);/m, [3], 1],
    [delete => qr/^\s*__atomic_store_n\(&nodes\[n\]\.has_value, 0, __ATOMIC_RELEASE\);/m, [4], 1],
    [clear  => qr/^\s*hdr->node_used = 2;/m, [5], 1],
    [record => qr/^\s*hdr->pending_value = value;/m, [1 .. 5], 0],
    [prepare => qr/^\s*__atomic_store_n\(&hdr->pending_kind, kind, __ATOMIC_RELEASE\);/m, [1 .. 5], 0],
    [count => qr/static inline void rdx_finish_mutation\(RdxHandle \*h\) \{/, [1 .. 5], 1],
    [finish => qr/^\s*__atomic_store_n\(&h->hdr->pending_kind, 0, __ATOMIC_RELEASE\);/m, [1 .. 5], 1],
    [recycle => qr/^\s*nodes\[idx\]\.label_off = hdr->free_head;/m, [3], 1],
    [recycled => qr/^\s*__atomic_store_n\(&hdr->free_head, idx, __ATOMIC_RELEASE\);/m, [3], 1],
    [allocate => qr/^\s*hdr->free_head = \(next < h->node_cap\) \? next : 0;/m, [1], 0],
    [root => qr/^\s*nodes\[hdr->root\]\.has_value = 0;/m, [5], 1],
    [arena => qr/^\s*hdr->arena_used = 0;/m, [5], 1],
);
for my $i (0 .. $#points) {
    my $point = $i + 1;
    $hdr =~ s/($points[$i][1])/$1 if (rdx_crash_point == $point) _exit(99);/
        or BAIL_OUT("cannot inject $points[$i][0] crash");
}
$hdr = "extern int rdx_crash_point;\n$hdr";
open my $out, '>', "$dir/patched.h" or die $!;
print {$out} $hdr;
close $out;
open my $c, '>', "$dir/repro.c" or die $!;
print {$c} <<'C';
#define _GNU_SOURCE
#include <sys/wait.h>
#include "patched.h"
int rdx_crash_point;
static void put(RdxHandle *h, const char *key, uint64_t value) {
    rdx_rwlock_wrlock(h);
    if (!rdx_insert_has_room(h, strlen(key))) _exit(10);
    rdx_insert_locked(h, (const uint8_t *)key, strlen(key), value);
    rdx_rwlock_wrunlock(h);
}
int main(int argc, char **argv) {
    char eb[RDX_ERR_BUFLEN];
    int point = atoi(argv[1]), op = atoi(argv[2]), committed = atoi(argv[3]), st;
    RdxHandle *h = rdx_create(NULL, 64, 4096, 0600, eb);
    if (!h) return 2;
    put(h, "abc", 11);
    put(h, "abd", 22);
    pid_t pid = fork();
    if (pid < 0) return 3;
    if (!pid) {
        rdx_crash_point = point;
        rdx_rwlock_wrlock(h);
        if (op == 1) rdx_insert_locked(h, (const uint8_t *)"z", 1, 33);
        if (op == 2) rdx_insert_locked(h, (const uint8_t *)"ab", 2, 33);
        if (op == 3) rdx_insert_locked(h, (const uint8_t *)"ax", 2, 33);
        if (op == 4) rdx_delete_locked(h, (const uint8_t *)"abc", 3);
        if (op == 5) rdx_clear_locked(h);
        _exit(4);
    }
    if (waitpid(pid, &st, 0) != pid || !WIFEXITED(st) || WEXITSTATUS(st) != 99) return 5;
    if (argc > 4) { /* a second death during recovery must remain recoverable */
        pid = fork();
        if (pid < 0) return 3;
        if (!pid) { rdx_crash_point = 8; rdx_rwlock_wrlock(h); _exit(4); }
        if (waitpid(pid, &st, 0) != pid || !WIFEXITED(st) || WEXITSTATUS(st) != 99) return 6;
    }
    rdx_rwlock_wrlock(h);
    rdx_rwlock_wrunlock(h);
    if (op == 5) {
        if (h->hdr->keys != (committed ? 0 : 2)) return 23;
        char key[16];
        for (int i = 0; i < 6; i++) { snprintf(key, sizeof key, "k%d", i); put(h, key, 100 + i); }
        for (int i = 0; i < 6; i++) {
            uint64_t v;
            snprintf(key, sizeof key, "k%d", i);
            if (!rdx_lookup_locked(h, (const uint8_t *)key, strlen(key), &v) || v != 100 + i) return 20;
        }
        if (h->hdr->keys != (committed ? 6 : 8)) return 21;
    } else {
        const char *key = op == 1 ? "z" : op == 2 ? "ab" : op == 3 ? "ax" : "abc";
        uint64_t v;
        int found = rdx_lookup_locked(h, (const uint8_t *)key, strlen(key), &v);
        if (found != (op == 4 ? !committed : committed)) return 22;
        if (found && v != (op == 4 ? 11 : 33)) return 25;
        if (h->hdr->keys != (committed ? (op == 4 ? 1 : 3) : 2)) return 23;
        if (!rdx_lookup_locked(h, (const uint8_t *)"abd", 3, &v) || v != 22) return 24;
    }
    rdx_destroy(h);
    return 0;
}
C
close $c;
my $log = `$cc -O2 -o $dir/repro $dir/repro.c -I$dir -lpthread 2>&1`;
is $?, 0, 'crash harness compiles' or BAIL_OUT($log);
for my $i (0 .. $#points) {
    for my $op (@{$points[$i][2]}) {
        my $committed = $points[$i][3] || ($op == 5 && $points[$i][0] eq 'prepare');
        system("$dir/repro", $i + 1, $op, $committed);
        is $?, 0, "$points[$i][0], operation $op: interrupted mutation is recoverable";
    }
}
system("$dir/repro", 1, 1, 1, 'recover-again');
is $?, 0, 'interrupted recovery preserves the committed count';
done_testing;
