#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

# A durable spatial index: build it, sync to a file, then reopen it in a fresh
# handle (as a later process would) and query -- the data survives.

my $path = "/tmp/sph-eg-persist-$$.bin";
{
    my $s = Data::SpatialHash::Shared->new($path, 10_000, 0, 1.0);
    $s->insert(rand()*1000, rand()*1000, $_) for 1 .. 1000;
    $s->sync;
    printf "built and synced %d points to %s\n", $s->count, $path;
}
{
    my $s = Data::SpatialHash::Shared->new($path, 10_000, 0, 1.0);
    my @near = $s->query_radius(500, 500, 50);
    printf "reopened: %d points survived, %d near (500,500)\n", $s->count, scalar @near;
    $s->unlink;
}
