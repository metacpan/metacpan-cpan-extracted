use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# File-backed pool on multiple filesystems. Certain FS (overlayfs on old
# kernels, some NFS) reject mmap flags or flock semantics.

use Data::Pool::Shared;

my %fs_points = (
    tmp  => '/tmp',
    vdtmp => '/var/tmp',
);
$fs_points{dev_shm} = '/dev/shm' if -d '/dev/shm' && -w _;

for my $name (sort keys %fs_points) {
    my $root = $fs_points{$name};
    next unless -w $root;
    my $dir = tempdir(DIR => $root, CLEANUP => 1);
    my $path = "$dir/pool";

    subtest "fs=$name ($root)" => sub {
        my $p = eval { Data::Pool::Shared::I64->new($path, 16) };
        unless ($p) {
            fail "new on $name failed: $@";
            return;
        }
        ok $p, "created on $name";

        for my $i (0..7) {
            my $s = $p->alloc;
            $p->set($s, $i);
        }

        $p->sync;
        undef $p;

        # Reopen
        my $p2 = Data::Pool::Shared::I64->new($path, 16);
        is $p2->used, 8, "used count survives reopen on $name";
    };
}

done_testing;
