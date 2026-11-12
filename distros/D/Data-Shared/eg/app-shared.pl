#!/usr/bin/env perl
# Producer creates a file-backed namespace; consumer reopens it from the directory alone.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_call);

my $dir = @ARGV ? $ARGV[0] : tempdir(CLEANUP => 1);
print "dir: $dir\n";

{
    my $root = Data::Shared->new($dir);
    $root->mount('cache', 'hashmap:ii', undef, 100_000) unless $root->mount_info('cache');
    $root->mount('visitors', 'hyperloglog', undef, 14) unless $root->mount_info('visitors');
    shared_set($root, '/cache/42', 100);
    shared_call($root, '/visitors', 'add', 'alice');
    print "producer: cache/42=", shared_get($root, '/cache/42'), "\n";
}

{
    my $root = Data::Shared->open($dir);
    print "consumer mounts: ", join(', ', $root->mounts), "\n";
    print "consumer: cache/42=", shared_get($root, '/cache/42'),
          " visitors~", shared_call($root, '/visitors', 'count'), "\n";
}
