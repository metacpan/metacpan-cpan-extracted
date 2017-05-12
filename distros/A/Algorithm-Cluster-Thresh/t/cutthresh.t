#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Algorithm::Cluster::Thresh;

# Copied partially from Algorithm::Cluster t/12-treecluster.t

# treecluster on a lower diagonal (column major) distance matrix

my $matrix   =  [
        [],
        [ 3.4],
        [ 4.3, 10.1],
        [ 3.7, 11.5,  1.0],
        [ 1.6,  4.1,  3.4,  3.4],
        [10.1, 20.5,  2.5,  2.7,  9.8],
        [ 2.5,  3.7,  3.1,  3.6,  1.1, 10.1],
        [ 3.4,  2.2,  8.8,  8.7,  3.3, 16.6,  2.7],
        [ 2.1,  7.7,  2.7,  1.9,  1.8,  5.7,  3.4,  5.2],
        [ 1.4,  1.7,  9.2,  8.7,  3.4, 16.8,  4.2,  1.3,  5.0],
        [ 2.7,  3.7,  5.5,  5.5,  1.9, 11.5,  2.0,  1.5,  2.1,  3.1],
        [10.0, 19.3,  2.2,  3.7,  9.1,  1.2,  9.3, 15.7,  6.3, 16.0, 11.5]
];


# Index into data matrix, regardless of order
sub dist {
    my ($i,$j) = @_;
    $matrix->[$i][$j] || $matrix->[$j][$i];
}
# Test dist() first
# 7,3 and 3,7 are the same: 8.7
is (dist(7,3), 8.7, 'dist row major');
is (dist(3,7), 8.7, 'dist col major');

# Basic clustering test, inter-cluster distance > 1.5 (depending on method)
my $thresh = 1.5;

# Linkage methods
# http://en.wikipedia.org/wiki/Hierarchical_clustering#Linkage_criteria

# distance between clusters, according to single linkage (mimimum linkage)
# Distance is the min distance between any two cluster elementes
sub minlinkage {
    my ($icluster, $jcluster) = @_;
    my $min;
    foreach my $i (@$icluster) {
        foreach my $j (@$jcluster) {
            my $dist = dist($i,$j);
            if (!defined($min) || $dist < $min) { $min = $dist }
        }
    }
    $min;
}
is(minlinkage([0..5],[6..11]), 1.1, 'minlinkage');

# distance between clusters, according to complete linkage (maximum linkage)
# Distance is the max distance between any two cluster elementes
sub avglinkage { 
    my ($icluster, $jcluster) = @_;
    my $sum = 0;
    foreach my $i (@$icluster) {
        foreach my $j (@$jcluster) {
            my $dist = dist($i,$j);
            $sum += $dist;
        }
    }
    $sum / (@$icluster * @$jcluster);    
}
ok(avglinkage([0..5],[6..11]) > 5.7361, 'avglinkage');
ok(avglinkage([0..5],[6..11]) < 5.7362, 'avglinkage');


# distance between clusters, according to complete linkage (maximum linkage)
# Distance is the max distance between any two cluster elementes
sub maxlinkage {
    my ($icluster, $jcluster) = @_;
    my $max;
    foreach my $i (@$icluster) {
        foreach my $j (@$jcluster) {
            my $dist = dist($i,$j);
            if (!defined($max) || $dist > $max) { $max = $dist }
        }
    }
    $max;
}
is(maxlinkage([0..5],[6..11]), 19.3, 'maxlinkage');

# single, average (UPGMA), and maximum (complete) linkage
my %dispatch = ('s'=>\&minlinkage,'a'=>\&avglinkage,'m'=>\&maxlinkage);
foreach my $method (keys %dispatch) {
    my $tree = Algorithm::Cluster::treecluster(data=>$matrix,method=>$method);
    # Test that all data is in the tree
    is (scalar(@$matrix) - 1, $tree->length, "tree size ($method)");

    # According to current $method
    my $clusters = $tree->cutthresh($thresh);
    # Tree cointains only internal nodes
    # Num of internal nodes is one less than leaf nodes
    is (scalar(@$clusters) - 1, $tree->length, "num clusters ($method)");

    # Given a cluster id, what data indexes are in it, i.e. reverse map
    my @clustermap;
    for (my $i = 0; $i < @$clusters; $i++) {
        my $cluster = $clusters->[$i];
        push @{$clustermap[$cluster]}, $i;
    }
    
    # For every pair of clusters, 
    # verify that inter-cluster distance (given $method) doesn't exceed $thresh
    for (my $i = 0; $i < @clustermap - 1; $i++) {
        for (my $j = $i+1; $j < @clustermap; $j++) {
            # Dispatch table to call appropriate metric, i.e. minlinkage when 's'            
            my $dist = $dispatch{$method}->($clustermap[$i],$clustermap[$j]);     
            ok $dist > $thresh, 
                sprintf "%5.2f < %5.2f for clusters %2d and %2d ($method)", 
                    $dist, $thresh, $i, $j;
        }
    }
}

done_testing;
    
