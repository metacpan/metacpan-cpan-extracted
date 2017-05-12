#!/usr/bin/perl
###########################################
# Mike Schilli, 2002 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Algorithm::Bucketizer;
use Data::Dumper;

print "$Algorithm::Bucketizer::VERSION\n";

my @items = (
             [2,2],
             [3,3],
             [5,5], [5,5],
             [7,7],
             [8,8],
            );

my $b = Algorithm::Bucketizer->new( bucketsize => 10, algorithm => 'retry' );

for my $pair (@items) {
    my($item, $weight) = @$pair;
    $b->add_item($item, $weight);
}

$b->optimize(algorithm => 'random', maxrounds => '10');

for my $bucket ($b->buckets()) {
    for my $item ($bucket->items()) {
        print "Bucket: ", $bucket->serial(), ": Item $item\n";
    }
}
