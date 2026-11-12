#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Data::Shared qw(shared_set shared_get shared_call);

my $dir = tempdir(CLEANUP => 1);
my $root = Data::Shared->new($dir);
sub mount_or_skip {
    my ($name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    die $@ unless $@ =~ /is not available; install the/;
    print "skip $name: $@";
    return;
}

if (mount_or_skip('routes', 'radixtree', undef, 4096, 65536)) {
    shared_set($root, '/routes/10.0.0.0/8', 100);
    shared_set($root, '/routes/10.0', 200);
    print "route 10.0.0.0/8: ", shared_get($root, '/routes/10.0.0.0/8'), "\n";
    print "longest prefix of 10.0.0.5: ", shared_call($root, '/routes', 'longest_prefix', '10.0.0.5'), "\n";
}
if (mount_or_skip('board', 'sortedset:strings', { max => 1000 })) {
    shared_set($root, '/board/alice', 1500);
    shared_set($root, '/board/bob', 900);
    print "alice score: ", shared_get($root, '/board/alice'), "\n";
    my @top = shared_call($root, '/board', 'rev_range_by_rank', 0, 0);
    print "board leader: $top[0]\n";
}
if (mount_or_skip('ids', 'intern', undef, 1000, 65536)) {
    my $id = shared_set($root, '/ids/alice');
    print "intern alice id=$id string=", shared_call($root, '/ids', 'string', $id), "\n";
}
