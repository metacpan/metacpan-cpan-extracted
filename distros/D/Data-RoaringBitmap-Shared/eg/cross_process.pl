#!/usr/bin/env perl
# Cross-process: parent builds the bitmap via memfd, child opens the same fd,
# both add into the one shared id set.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::RoaringBitmap::Shared;
$| = 1;

my $s = Data::RoaringBitmap::Shared->new_memfd('roaring-demo', 256);
my $fd = $s->memfd;

# Parent records a few user ids before the fork.
$s->add_many([10, 20, 30, 70000]);
printf "parent: added 4 ids, cardinality=%d fd=%d\n", $s->cardinality, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec).
    my $c = Data::RoaringBitmap::Shared->new_from_fd($fd);
    printf "child:  sees cardinality=%d from parent (contains 70000? %s)\n",
        $c->cardinality, ($c->contains(70000) ? 'yes' : 'no');
    $c->add_many([40, 50, 99999]);
    printf "child:  added 3 ids, cardinality now=%d\n", $c->cardinality;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, cardinality=%d\n", $s->cardinality;

my $list = $s->to_array;
printf "parent: merged id set = %s\n", join(' ', @$list);
