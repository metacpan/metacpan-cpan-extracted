#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_set shared_get shared_exists shared_delete shared_call);

my $root = Data::Shared->new;
sub mount_or_skip {
    my ($name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    die $@ unless $@ =~ /is not available; install the/;
    print "skip $name: $@";
    return;
}

if (mount_or_skip('seen', 'bloomfilter', undef, 10_000, 0.01)) {
    shared_set($root, '/seen/event-42', 1);
    print "bloom event-42: ", shared_exists($root, '/seen/event-42'), "\n";
    print "bloom event-99: ", shared_exists($root, '/seen/event-99'), "\n";
}
if (mount_or_skip('bits', 'bitset', undef, 256)) {
    shared_set($root, '/bits/10', 1);
    shared_set($root, '/bits/42', 1);
    print "bit 10: ", shared_get($root, '/bits/10'), " count: ", shared_call($root, '/bits', 'count'), "\n";
    shared_delete($root, '/bits/10');
    print "bit 10 after delete: ", shared_get($root, '/bits/10'), "\n";
}
if (mount_or_skip('members', 'roaringbitmap', undef, 256)) {
    shared_set($root, '/members/70000', 1);
    print "roaring 70000: ", shared_exists($root, '/members/70000'), "\n";
}
if (mount_or_skip('board', 'sortedset', undef, 1000)) {
    shared_set($root, '/board/42', 1500);
    shared_set($root, '/board/7', 900);
    print "score 42: ", shared_get($root, '/board/42'), "\n";
    my @top = shared_call($root, '/board', 'rev_range_by_rank', 0, 0);
    print "top member: $top[0]\n";
}
if (mount_or_skip('ds', 'disjointset', undef, 100)) {
    shared_set($root, '/ds/0', 1);
    print "disjoint connected 0-1: ", shared_call($root, '/ds', 'connected', 0, 1), "\n";
}
