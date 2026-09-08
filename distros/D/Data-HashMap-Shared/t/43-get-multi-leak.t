use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::II;

plan skip_all => 'needs /proc/self/status' unless -r '/proc/self/status';
# ASan's free quarantine and valgrind's replacement malloc hold freed buffers,
# so memory is not flat even when every result is correctly freed
if (open my $maps, '<', '/proc/self/maps') {
    local $/; my $m = <$maps>;
    plan skip_all => 'memory is not a leak signal under an intercepting allocator'
        if $m =~ /libasan|libtsan|vgpreload/;
}

plan skip_all => 'no VmRSS in /proc/self/status' unless defined rss_kb();

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, $_[0]) }

sub rss_kb {
    open my $f, '<', '/proc/self/status' or die $!;
    while (<$f>) { return $1 if /^VmRSS:\s+(\d+)/ }
    return undef;
}

# A result pushed without being mortalised is never freed: 1.6M leaked
# scalars are well over 100MB, while a clean run stays flat after warm-up.
my $calls = 50_000;
for my $shape (['SS', 0], ['II', 0], ['SS', 4], ['II', 4]) {
    my ($class, $shards) = @$shape;
    my $pkg  = "Data::HashMap::Shared::$class";
    my $map  = $shards ? $pkg->new_sharded(path("$class-s"), $shards, 1000)
                       : $pkg->new(path("$class.shm"), 1000);
    my @keys = $class eq 'SS' ? (map { "key-$_" } 1 .. 32) : (1 .. 32);
    $map->put($_, $class eq 'SS' ? "value-$_-" x 3 : $_ * 10) for @keys;
    my @r = $map->get_multi(@keys);
    is scalar(grep { defined } @r), 32, "$class" . ($shards ? " sharded" : "") . ": all 32 keys found";

    $map->get_multi(@keys) for 1 .. 2000;
    my $before = rss_kb();
    $map->get_multi(@keys) for 1 .. $calls;
    my $growth = rss_kb() - $before;
    cmp_ok $growth, '<', 16_384,
        "$class" . ($shards ? " sharded" : "") . ": $calls get_multi calls free their results (RSS +${growth}KB)";
}

done_testing;
