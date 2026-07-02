#!/usr/bin/env perl
# Cross-process: parent builds the filter via memfd, child opens the same fd,
# both add into the one shared Cuckoo filter.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::CuckooFilter::Shared;
$| = 1;

my $cf = Data::CuckooFilter::Shared->new_memfd('cuckoo-demo', 100_000);
my $fd = $cf->memfd;

# Parent records a few "seen" items before fork
$cf->add($_) for qw(alice bob carol);
printf "parent: added 3 items, count=%d fd=%d\n", $cf->count, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::CuckooFilter::Shared->new_from_fd($fd);
    printf "child:  sees alice=%d carol=%d (added by parent)\n",
        $c->contains("alice"), $c->contains("carol");
    $c->add($_) for qw(dave erin);
    printf "child:  added 2 items, count now=%d\n", $c->count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, count=%d\n", $cf->count;

# the child's additions are visible in the parent's view of the shared filter
printf "parent: contains dave=%d erin=%d (added by child), frank=%d (never added)\n",
    $cf->contains("dave"), $cf->contains("erin"), $cf->contains("frank");
