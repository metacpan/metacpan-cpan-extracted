#!/usr/bin/env perl
# Cross-process, lock-free: build the set once, dump it to a file, then let
# many independent processes mmap the same immutable image and query it in
# parallel -- no locks, no atomics, no shared writer. This is what makes the
# module different from the rest of the family: the image is immutable after
# build, so concurrent readers scale linearly and cannot corrupt each other.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp 'tempdir';
use POSIX qw(_exit);
use Data::PerfectHash::Shared;
$| = 1;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/ids.phs";

# Parent builds the immutable image once.
my @ids = map { $_ * 2 + 1 } 0 .. 99_999;      # 100k odd ids
Data::PerfectHash::Shared->build_int($path, \@ids);
printf "parent: built %d-key set, %d bytes -> %s\n", scalar @ids, -s $path, $path;

# Four workers each mmap the SAME file independently and look up in parallel.
for my $w (1 .. 4) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $set = Data::PerfectHash::Shared->load($path);   # its own read-only mmap
        my ($hit, $miss) = (0, 0);
        for (1 .. 50_000) {
            my $k = int rand 200_000;                        # ~half are members
            $set->has($k) ? $hit++ : $miss++;
        }
        printf "  worker %d: %d hits, %d misses over 50k lookups\n", $w, $hit, $miss;
        _exit(0);
    }
}
waitpid(-1, 0) for 1 .. 4;
print "parent: all workers done -- each had its own lock-free mmap of the shared image\n";
