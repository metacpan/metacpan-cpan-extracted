use strict;
use warnings;
use Test::More;

# /proc/self/maps inspection: verify the module's mmap region is
# present with expected PROT_READ|PROT_WRITE and MAP_SHARED flags.
# Catches accidental PROT_READ downgrade or MAP_PRIVATE regression.

plan skip_all => "needs /proc/self/maps" unless -r '/proc/self/maps';

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("maps-test", 32);

open my $mf, '<', '/proc/self/maps' or die;
my @lines = <$mf>;
close $mf;

# Our memfd's label is "/memfd:maps-test (deleted)" or "/memfd:maps-test"
my @our = grep /\bmemfd:maps-test/, @lines;
cmp_ok scalar(@our), '>=', 1, "our memfd region visible in /proc/self/maps";

for my $line (@our) {
    # Format: start-end perms offset dev inode pathname
    #         0002a000-0002b000 rw-s 00000000 00:01 12345 /memfd:maps-test
    my @parts = split /\s+/, $line, 6;
    my ($perms) = $parts[1];
    like $perms, qr/^rw/,  "mapping has read+write: $perms ($line)";
    like $perms, qr/s$/,   "mapping is MAP_SHARED (not private)";
}

done_testing;
