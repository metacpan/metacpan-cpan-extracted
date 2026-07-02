#!/usr/bin/env perl
# Cross-process: parent builds the radix tree via memfd, child opens the same fd,
# both insert into the one shared mapping.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::RadixTree::Shared;
$| = 1;

my $t = Data::RadixTree::Shared->new_memfd('radix-demo', 4096, 65536);
my $fd = $t->memfd;

# Parent inserts a few keys before the fork ("apple"/"apricot" share the "ap"
# edge, so the radix tree stores them as one compressed branch).
$t->insert("apple",   1);
$t->insert("apricot", 2);
$t->insert("banana",  3);
printf "parent: inserted 3 keys, count=%d fd=%d\n", $t->count, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::RadixTree::Shared->new_from_fd($fd);
    printf "child:  sees count=%d from parent (apple=%d)\n", $c->count, $c->lookup("apple");
    $c->insert("cherry",    4);
    $c->insert("cranberry", 5);
    printf "child:  added 2 keys, count now=%d\n", $c->count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, count=%d\n", $t->count;

# The parent now sees the child's keys in the one shared tree.
printf "parent: child's cherry=%d cranberry=%d\n",
    $t->lookup("cherry"), $t->lookup("cranberry");

# longest_prefix: the longest stored key that is a prefix of the query.
printf "parent: longest_prefix('applesauce')=%d (value of stored 'apple')\n",
    $t->longest_prefix("applesauce");
