#!/usr/bin/env perl 
use strict;
use Test::More;
use Algorithm::DistanceMatrix;
my $objects = [qw/alpha beta gamma delta epsilon/];


my $expect_lower = 
[
[],
[1],
[0,1],
[0,1,0],
[2,3,2,2],
];

my $expect_upper = 
[
[undef,1,0,0,2],
[(undef)x2,1,1,3],
[(undef)x3,0,2],
[(undef)x4,2],
[(undef)x5],
];

my $expect_full = 
[
[0,1,0,0,2],
[1,0,1,1,3],
[0,1,0,0,2],
[0,1,0,0,2],
[2,3,2,2,0],
];


sub _test {
    my ($mode, $expect, $metric) = @_;

    my $dm = Algorithm::DistanceMatrix->new(
        mode=>$mode, objects=>$objects, metric=>$metric);
    my $distmat = $dm->distancematrix;

    is(scalar @$distmat, scalar @$objects, 'matrix length');

    is_deeply($distmat, $expect, "$mode");
    return $distmat;
}

sub _metric {
    return abs(length($_[0])-length($_[1]));
}

_test('lower',$expect_lower,sub{abs(length($_[0])-length($_[1]))});
_test('upper',$expect_upper,sub{abs(length($_[0])-length($_[1]))});
_test('full',$expect_full,sub{abs(length($_[0])-length($_[1]))});

# And test alternate callback syntax
my $result = _test('lower',$expect_lower,\&_metric);


# Feed matrix to Algorithm::Cluster::treecluster, if installed
SKIP: {
    eval { require Algorithm::Cluster; };
    skip "Algorithm::Cluster not intalled", 1 if $@;
    
    my $msg = Algorithm::Cluster::check_distance_matrix($result);
    is ($msg, 'OK', 'check_distance_matrix');
    
    my $tree = Algorithm::Cluster::treecluster(data=>$result, method=>'a');
    my $clusterids = $tree->cut(3);
    # Really, I figured this out in my head:
    my $expect_clusters = [2,1,2,2,0];
    is_deeply($clusterids,$expect_clusters, "tree->cut");
}

done_testing;
