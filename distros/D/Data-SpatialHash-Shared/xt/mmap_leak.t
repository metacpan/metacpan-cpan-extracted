use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux /proc required' unless -e '/proc/self/maps';
use Data::SpatialHash::Shared;

# Creating and destroying many maps must not leak mappings (complements fd_leak,
# which only counts file descriptors).

sub vma_count { open my $m, '<', '/proc/self/maps' or return -1; my $n = () = <$m>; close $m; $n }

{ my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0); $s->insert(1, 1, 1); }   # warm up
my $before = vma_count();
for (1 .. 500) {
    my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);
    $s->insert(rand()*100, rand()*100, $_);
    $s->query_radius(50, 50, 10);
    # $s leaves scope -> DESTROY -> munmap
}
my $after = vma_count();
cmp_ok $after - $before, '<', 10, "VMA count stable across 500 create/destroy cycles ($before -> $after)";

done_testing;
