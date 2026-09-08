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

plan skip_all => 'no VmPeak in /proc/self/status' unless defined vmpeak_kb();

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, $_[0]) }

sub vmpeak_kb {
    open my $f, '<', '/proc/self/status' or die $!;
    while (<$f>) { return $1 if /^VmPeak:\s+(\d+)/ }
    return undef;
}

# drain reserves only what the map can yield: a limit far above the entry
# count must not reserve the limit (20M entries is several hundred MB).
# VmPeak is a high-water mark: one baseline before the loop, or every shape
# after the first measures nothing
my $peak0 = vmpeak_kb();
for my $shape (['SS', 0], ['II', 0], ['SS', 4], ['II', 4]) {
    my ($class, $shards) = @$shape;
    my $name = $class . ($shards ? ' sharded' : '');
    my $pkg  = "Data::HashMap::Shared::$class";
    my $map  = $shards ? $pkg->new_sharded(path("$class-s"), $shards, 1000)
                       : $pkg->new(path("$class.shm"), 1000);
    my %want = $class eq 'SS' ? (a => 'x', b => 'y', c => 'z') : (1 => 10, 2 => 20, 3 => 30);
    $map->put($_, $want{$_}) for keys %want;

    my @got = $map->drain(20_000_000);
    my $delta = vmpeak_kb() - $peak0;
    is_deeply { @got }, \%want, "$name: drain(20_000_000) yields exactly the 3 entries";
    is $map->size, 0, "$name: map drained";
    cmp_ok $delta, '<', 65_536, "$name: reserved only what it could yield (VmPeak +${delta}KB)";

    $map->put($_, $want{$_}) for keys %want;
    my @again = eval { $map->drain(~0) };
    is $@, '', "$name: drain(UV max) does not die";
    is scalar(@again), 6, "$name: drain(UV max) yields the 3 entries";
}

done_testing;
