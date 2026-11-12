#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_exists);

my $dir = @ARGV ? $ARGV[0] : tempdir(CLEANUP => 1);
print "dir: $dir\n";
# A frozen store cannot be opened writable, so a re-run skips the producer.
if (my $root = eval { Data::Shared->new($dir) }) {
    $root->mount('seen', 'bloomfilter', undef, 10_000, 0.01) unless $root->mount_info('seen');
    $root->mount('cache', 'hashmap:ii', undef, 1000) unless $root->mount_info('cache');
    shared_set($root, '/seen/event-42', 1);
    shared_set($root, '/cache/42', 100);
    $root->freeze_all;
    print "producer: frozen and shipped\n";
} else {
    die $@ unless $@ =~ /is frozen/;
    print "producer: already frozen, skipping\n";
}
{
    my $ro = Data::Shared->open_readonly($dir, strict => 1);
    print "consumer readonly=", $ro->readonly,
          " seen/event-42=", shared_exists($ro, '/seen/event-42'),
          " cache/42=", shared_get($ro, '/cache/42'), "\n";
    my $ok = eval { shared_set($ro, '/cache/43', 1); 1 };
    print "consumer write blocked: ", ($ok ? "no" : "yes"), "\n";
}
