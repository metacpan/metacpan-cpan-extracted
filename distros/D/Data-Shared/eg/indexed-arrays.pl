#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_set shared_get shared_incr shared_call);

my $root = Data::Shared->new;
sub mount_or_skip {
    my ($name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    die $@ unless $@ =~ /is not available; install the/;
    print "skip $name: $@";
    return;
}

if (mount_or_skip('lat', 'ndarray', undef, 'f64', 2, 3)) {
    shared_set($root, '/lat/0/1', 1.5);
    shared_set($root, '/lat/1/2', 9);
    print "ndarray [0][1]=", shared_get($root, '/lat/0/1'),
          " sum=", shared_call($root, '/lat', 'sum'), "\n";
}
if (mount_or_skip('counts', 'fenwick', undef, 100)) {
    shared_incr($root, '/counts/5', 3);
    shared_incr($root, '/counts/9', 7);
    print "fenwick prefix(9)=", shared_call($root, '/counts', 'prefix', 9), "\n";
}
if (mount_or_skip('arr', 'segmenttree', undef, 100)) {
    shared_set($root, '/arr/10', 42);
    shared_incr($root, '/arr/10', 5);
    print "segtree sum(0,99)=", shared_call($root, '/arr', 'sum', 0, 99), "\n";
}
if (mount_or_skip('cities', 'kdtree', undef, 2, 1000)) {
    shared_call($root, '/cities', 'add', [10.5, 20.5], 42);
    shared_call($root, '/cities', 'add', [30.0, 40.0], 7);
    my $near = shared_call($root, '/cities', 'nearest', [10.0, 20.0]);
    print "nearest city id: $near->{id}\n";
}
if (mount_or_skip('bookings', 'intervaltree', undef, 1000)) {
    shared_call($root, '/bookings', 'add', 10, 20, 42);
    my @at = shared_call($root, '/bookings', 'stab', 15);
    print "booking at 15: id $at[0]{id} [$at[0]{lo},$at[0]{hi}]\n";
}
