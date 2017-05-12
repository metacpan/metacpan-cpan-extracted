#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 3;
use TestUtils;

my $p = new_backpan();

my $dists = $p->dists;
cmp_ok $dists->count, '>=', 20_000;

ok $p->dist("Acme-Pony");

# Pick a distribution at random, it should have releases.
{
    my $dist = $dists->search( undef, { order_by => 'random()' } )->first;
    my $releases = $dist->releases;
    is $releases->first->dist, $dist->name, "found releases for ".$dist->name;
}

1;
