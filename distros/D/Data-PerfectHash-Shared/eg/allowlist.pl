#!/usr/bin/env perl
# Allow-list: build a static set of permitted integer IDs, dump it to a file,
# then load it (here or in any other process) for fast, exact membership.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/allow.phs";

# A fixed set of allowed account IDs. Built once; duplicates are deduped.
my @allowed = (1001, 1002, 2048, 4096, 4096, 65_537, 1_000_003);
Data::PerfectHash::Shared->build_int($path, \@allowed);

my %uniq; @uniq{@allowed} = ();
printf "built %s: %d unique ids, %d bytes on disk\n",
    $path, scalar(keys %uniq), -s $path;

# Load (read-only mmap) and check membership: O(1) worst case, exact, zero
# false positives (the full keys are stored).
my $set = Data::PerfectHash::Shared->load($path);
printf "count=%d type=%s\n", $set->count, $set->type;
for my $id (1002, 4096, 1003, 65_537, 999) {
    printf "  has(%7d) = %s\n", $id, $set->has($id) ? 'yes' : 'no';
}
