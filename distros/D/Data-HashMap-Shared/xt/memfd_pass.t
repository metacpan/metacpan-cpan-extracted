use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::HashMap::Shared::II;

# Verify memfd-backed map survives fd inheritance across fork+exec-style
# handoff: parent creates a memfd map, exposes the fd, child reopens via
# new_from_fd and observes shared state.

plan skip_all => "memfd requires Linux" if $^O ne "linux";

my $parent_map = eval { Data::HashMap::Shared::II->new_memfd("test", 1024, 0, 30) };
plan skip_all => "memfd_create not supported: $@" if !$parent_map;

$parent_map->put(42, 100);
$parent_map->put_ttl(7, 7777, 90);
my $fd = $parent_map->memfd;
ok($fd >= 0, "memfd: parent has valid fd ($fd)");

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child reopens via fd inheritance
    my $shared = Data::HashMap::Shared::II->new_from_fd($fd);
    my $ok = ($shared->get(42) == 100 && $shared->get(7) == 7777) ? 0 : 1;
    # Mutate from child — parent should see it
    $shared->put(99, 999);
    _exit($ok);
}
waitpid($pid, 0);
is($? >> 8, 0, "memfd: child read shared values via new_from_fd");
is($parent_map->get(99), 999, "memfd: parent sees child's write");

# TTL survives across handoff
my (undef, $rem) = $parent_map->get_with_ttl(7);
ok($rem > 30 && $rem <= 90, "memfd: TTL preserved across handoff (rem=$rem)");

done_testing;
