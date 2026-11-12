#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_set shared_get shared_call);

my $root = Data::Shared->new;
sub mount_or_skip {
    my ($name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    die $@ unless $@ =~ /is not available; install the/;
    print "skip $name: $@";
    return;
}

if (mount_or_skip('visitors', 'hyperloglog', undef, 14)) {
    shared_call($root, '/visitors', 'add', $_) for qw(alice bob alice carol);
    printf "distinct visitors ~ %.0f\n", shared_call($root, '/visitors', 'count');
}
if (mount_or_skip('freq', 'countminsketch', undef, 0.001, 0.001)) {
    shared_set($root, '/freq/alice', 5);
    shared_set($root, '/freq/bob');
    print "freq alice >= ", shared_get($root, '/freq/alice'), "\n";
}
if (mount_or_skip('hitters', 'topk', undef, 100)) {
    shared_set($root, '/hitters/popular') for 1 .. 3;
    shared_set($root, '/hitters/rare');
    my @top = shared_call($root, '/hitters', 'top', 1);
    print "top hitter: $top[0]{key} ~$top[0]{count}\n";
}
if (mount_or_skip('latency', 'ddsketch', undef, 0.01)) {
    shared_call($root, '/latency', 'add', $_) for 10, 20, 30, 40, 100;
    printf "p50 ~ %.0f\n", shared_call($root, '/latency', 'quantile', 0.5);
}
if (mount_or_skip('sample', 'reservoir', undef, 5)) {
    shared_call($root, '/sample', 'add', $_) for 1 .. 100;
    print "reservoir seen: ", shared_call($root, '/sample', 'seen'),
          " held: ", shared_call($root, '/sample', 'count'), "\n";
}
