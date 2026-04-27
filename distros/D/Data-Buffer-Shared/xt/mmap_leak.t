use strict;
use warnings;
use Test::More;
use Data::Buffer::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'requires /proc/self/maps' unless -r '/proc/self/maps';

sub maps_count {
    open my $fh, '<', '/proc/self/maps' or die $!;
    my $n = 0;
    $n++ while <$fh>;
    close $fh;
    $n;
}

my $baseline = maps_count();

# Create + destroy 50 handles. Each handle does 1 mmap; all should be
# released on DESTROY. Use new_anon to avoid filesystem side-effects
# (the file-backed new() with O_CREAT|O_EXCL would leave temp files behind).
for (1..50) {
    my $h = Data::Buffer::Shared::I64->new_anon(64);
    undef $h;
}

# Fudge ± 3 lines (other mmap churn: malloc arenas, thread stacks, etc).
my $after = maps_count();
my $delta = $after - $baseline;
cmp_ok abs($delta), '<=', 3,
    "maps count stable after create/destroy cycle (baseline=$baseline, after=$after, delta=$delta)";

done_testing;
