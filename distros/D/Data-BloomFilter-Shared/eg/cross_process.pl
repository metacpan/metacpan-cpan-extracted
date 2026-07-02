#!/usr/bin/env perl
# Cross-process: parent builds the filter via memfd, child opens the same fd,
# both add into the one shared bit array.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::BloomFilter::Shared;
$| = 1;

my $bf = Data::BloomFilter::Shared->new_memfd('bloom-demo', 1000, 0.01);
my $fd = $bf->memfd;

# Parent adds some names before fork
$bf->add($_) for qw(alice bob carol);
printf "parent: added 3 names, count=%d fd=%d\n", $bf->count, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::BloomFilter::Shared->new_from_fd($fd);
    printf "child:  sees count=%d, contains(alice)=%d from parent\n",
        $c->count, $c->contains("alice");
    $c->add($_) for qw(dave erin);
    printf "child:  added 2 names, count now=%d\n", $c->count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, count=%d\n", $bf->count;

# the child's additions are visible in the parent's mapping -- union across processes
for my $q (qw(alice dave frank)) {
    printf "parent: contains(%-5s) = %s\n", $q,
        $bf->contains($q) ? "probably yes" : "definitely no";
}
