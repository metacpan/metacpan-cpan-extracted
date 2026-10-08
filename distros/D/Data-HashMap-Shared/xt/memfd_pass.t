use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::HashMap::Shared::II;

# A memfd map passed to a forked child via new_from_fd shares state both ways.

plan skip_all => "memfd requires Linux" if $^O ne "linux";

my $parent_map = eval { Data::HashMap::Shared::II->new_memfd("test", 1024, 0, 30) };
plan skip_all => "memfd_create not supported: $@" if !$parent_map;

$parent_map->put(42, 100);
$parent_map->put_ttl(7, 7777, 90);
my $fd = $parent_map->memfd;
ok($fd >= 0, "memfd: parent has valid fd ($fd)");

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $shared = Data::HashMap::Shared::II->new_from_fd($fd);
    my $ok = ($shared->get(42) == 100 && $shared->get(7) == 7777) ? 0 : 1;
    $shared->put(99, 999);
    _exit($ok);
}
waitpid($pid, 0);
is($? >> 8, 0, "memfd: child read shared values via new_from_fd");
is($parent_map->get(99), 999, "memfd: parent sees child's write");

my (undef, $rem) = $parent_map->get_with_ttl(7);
ok($rem > 30 && $rem <= 90, "memfd: TTL preserved across handoff (rem=$rem)");

done_testing;
