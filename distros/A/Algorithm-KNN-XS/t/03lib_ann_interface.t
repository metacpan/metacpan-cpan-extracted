use strict;
use warnings;
use Data::Dumper;
use Algorithm::KNN::XS;
use Test::More tests => 119;

my @points = (
    [1.1345, 2.657],
    [4.023, 5.2389],
    [7.589, 8.124],
    [6.89, 11.065],
    [8.1954, 12.785],
    [9.723, 13.357],
    [10.285, 14.1435],
);

my $tree_print_header = "ANN Version 1.1.2\n";
my $tree_dump_header  = "#ANN 1.1.2\n";

my $tree_print_points = "    Points:
	0: 1.1345 2.657
	1: 4.023 5.2389
	2: 7.589 8.124
	3: 6.89 11.065
	4: 8.1954 12.785
	5: 9.723 13.357
	6: 10.285 14.1435\n";

my $tree_dump_points = "points 2 7
0 1.1345 2.657
1 4.023 5.2389
2 7.589 8.124
3 6.89 11.065
4 8.1954 12.785
5 9.723 13.357
6 10.285 14.1435\n";

my @tree_print_structure = (
    "    ........Leaf n=1 <6>
    ......Split cd=0 cv=9.723 lbnd=6.89 hbnd=10.285
    ........Leaf n=1 <5>
    ....Split cd=1 cv=12.785 lbnd=8.40025 hbnd=14.1435
    ......Leaf n=1 <4>
    ..Split cd=0 cv=6.89 lbnd=1.1345 hbnd=10.285
    ....Leaf n=1 <3>
    Split cd=1 cv=8.40025 lbnd=2.657 hbnd=14.1435
    ....Leaf n=1 <2>
    ..Split cd=0 cv=5.70975 lbnd=1.1345 hbnd=10.285
    ......Leaf n=1 <1>
    ....Split cd=1 cv=5.2389 lbnd=2.657 hbnd=8.40025
    ......Leaf n=1 <0>\n",
    "    ....Leaf (trivial)
    ..Shrink
        ([0]>=6.89)  ([1]>=11.065)
    ........Leaf (trivial)
    ......Shrink
            ([0]>=9.723)  ([1]>=13.357)
    ..........Leaf n=1 <6>
    ........Split cd=1 cv=13.7502 lbnd=13.357 hbnd=14.1435
    ..........Leaf n=1 <5>
    ....Split cd=0 cv=8.5875 lbnd=6.89 hbnd=10.285
    ........Leaf n=1 <4>
    ......Split cd=1 cv=12.6043 lbnd=11.065 hbnd=14.1435
    ........Leaf n=1 <3>
    Split cd=1 cv=8.40025 lbnd=2.657 hbnd=14.1435
    ....Leaf n=1 <2>
    ..Split cd=0 cv=5.70975 lbnd=1.1345 hbnd=10.285
    ......Leaf (trivial)
    ....Shrink
          ([0]< 4.023)  ([1]< 5.2389)
    ........Leaf n=1 <1>
    ......Split cd=0 cv=2.57875 lbnd=1.1345 hbnd=4.023
    ........Leaf n=1 <0>\n",
);

my @tree_dump_structure = (
    "tree 2 7 1
1.1345 2.657
10.285 14.1435
split 1 8.40025 2.657 14.1435
split 0 5.70975 1.1345 10.285
split 1 5.2389 2.657 8.40025
leaf 1 0
leaf 1 1
leaf 1 2
split 0 6.89 1.1345 10.285
leaf 1 3
split 1 12.785 8.40025 14.1435
leaf 1 4
split 0 9.723 6.89 10.285
leaf 1 5
leaf 1 6\n",
    "tree 2 7 1
1.1345 2.657
10.285 14.1435
split 1 8.40025 2.657 14.1435
split 0 5.70975 1.1345 10.285
shrink 2
0 4.023 -1
1 5.2389 -1
split 0 2.57875 1.1345 4.023
leaf 1 0
leaf 1 1
leaf 0
leaf 1 2
shrink 2
0 6.89 1
1 11.065 1
split 0 8.5875 6.89 10.285
split 1 12.60425 11.065 14.1435
leaf 1 3
leaf 1 4
shrink 2
0 9.723 1
1 13.357 1
split 1 13.75025 13.357 14.1435
leaf 1 5
leaf 1 6
leaf 0
leaf 0\n",
);

my @tree_stats = (
    [
        '2',
        '7',
        '1',
        '7',
        '0',
        '6',
        '0',
        '4',
        '1.61012744903564'
    ],
    [
        '2',
        '7',
        '1',
        '10',
        '3',
        '6',
        '3',
        '5',
        '1.45566558837891'
    ],
);

my $search_result = [
    [
        '1.1345',
        '2.657',
        '0'
    ], [
        '4.023',
        '5.2389',
        '15.00963986'
    ]
];

for my $use_bd_tree (0 .. 1) {
    my ($tree, $result, $tree_name);

    $tree_name = $use_bd_tree ? 'bd_tree: ' : 'kd_tree: ';

    ok(!eval { Algorithm::KNN::XS::LibANNInterface->new(); }, $tree_name . 'new - must be called with the correct amount of parameters');
    ok(!eval { Algorithm::KNN::XS::LibANNInterface->new('', '', $use_bd_tree, 1, 0, 0) }, $tree_name . 'new - points must be an array reference');
    ok(!eval { Algorithm::KNN::XS::LibANNInterface->new([], [], $use_bd_tree, 1, 0, 0) }, $tree_name . 'new - dump must be a string');
    ok(!eval { Algorithm::KNN::XS::LibANNInterface->new([], '', $use_bd_tree, 1, 0, 0) }, $tree_name . 'new - either points or a dump must be specified');
    ok(!eval { Algorithm::KNN::XS::LibANNInterface->new(\@points, '', $use_bd_tree, 0, 0, 0) }, $tree_name . 'new - a bucket_site must be given if points are used');

    # a bd tree should be able to read in both dumps
    if ($use_bd_tree) {
        ok(Algorithm::KNN::XS::LibANNInterface->new([], $tree_dump_header . $tree_dump_points . $tree_dump_structure[0], $use_bd_tree, 0, 0, 0), $tree_name . 'new - created from dump (kd tree dump)');
        ok(Algorithm::KNN::XS::LibANNInterface->new([], $tree_dump_header . $tree_dump_points . $tree_dump_structure[1], $use_bd_tree, 0, 0, 0), $tree_name . 'new - created from dump (bd tree dump)');
    }
    else {
        ok(Algorithm::KNN::XS::LibANNInterface->new([], $tree_dump_header . $tree_dump_points . $tree_dump_structure[$use_bd_tree], $use_bd_tree, 0, 0, 0), $tree_name . 'new - created from dump (kd tree dump)');
    }

    ok(Algorithm::KNN::XS::LibANNInterface->new(\@points, '', $use_bd_tree, 1, 0, 0), $tree_name . 'new - created from points');

    foreach my $split_rule (values %Algorithm::KNN::XS::ANN_SPLIT_RULE) {
        ok(Algorithm::KNN::XS::LibANNInterface->new(\@points, '', $use_bd_tree, 1, $split_rule, 0), $tree_name . 'new - created from points with split rule: ' . $split_rule);

        # a bd tree can also be created with a shrink rule
        if ($use_bd_tree) {
            foreach my $shrink_rule (values %Algorithm::KNN::XS::ANN_SHRINK_RULE) {
                ok(Algorithm::KNN::XS::LibANNInterface->new(\@points, '', $use_bd_tree, 1, $split_rule, $shrink_rule), $tree_name . 'new - created from points with split rule: ' . $split_rule . ' and shrink rule ' . $shrink_rule);
            }
        }
    }

    $tree = Algorithm::KNN::XS::LibANNInterface->new(\@points, '', $use_bd_tree, 1, 0, 0);

    ok(!eval { $tree->annkSearch($points[0], -1, 0) }, $tree_name . 'annkSearch - limit_neighbors must be >= 0');
    ok(!eval { $tree->annkSearch($points[0], scalar @points + 1, 0) }, $tree_name . 'annkSearch - limit_neighbors must be <= points in the current tree');
    ok(!eval { $tree->annkSearch($points[0], 1, -1) }, $tree_name . 'annkSearch - epsilon must be >= 0');
    ok(!eval { $tree->annkSearch([1,2,3], 1, -1) }, $tree_name . 'annkSearch - query_point must have the same dimension as the current tree');

    $result = $tree->annkSearch($points[0], 0, 0);
    ok(scalar @{$result} == scalar @points, $tree_name . 'annkSearch - successfully returned ' . scalar @points . ' points');

    $result = $tree->annkSearch($points[0], 2, 0);
    ok(scalar @{$result} == 2, $tree_name . 'annkSearch - successfully returned 2 points');
    is_deeply($result, $search_result, $tree_name . 'annkSearch - result is correct');

    $tree->set_annMaxPtsVisit(1);

    $result = $tree->annkSearch($points[0], 4, 0);
    ok(scalar @{$result} == 2, $tree_name . 'annkSearch - successfully returned 1 points while set_annMaxPtsVisit is set to 1');
    is_deeply($result, $search_result, $tree_name . 'annkSearch - result is correct while set_annMaxPtsVisit is set to 1');

    $tree->set_annMaxPtsVisit(0);

    ok(!eval { $tree->annkPriSearch($points[0], -1, 0) }, $tree_name . 'annkPriSearch - limit_neighbors must be >= 0');
    ok(!eval { $tree->annkPriSearch($points[0], scalar @points + 1, 0) }, $tree_name . 'annkPriSearch - limit_neighbors must be <= points in the current tree');
    ok(!eval { $tree->annkPriSearch($points[0], 1, -1) }, $tree_name . 'annkPriSearch - epsilon must be >= 0');
    ok(!eval { $tree->annkPriSearch([1,2,3], 1, -1) }, $tree_name . 'annkPriSearch - query_point must have the same dimension as the current tree');

    $result = $tree->annkPriSearch($points[0], 0, 0);
    ok(scalar @{$result} == scalar @points, $tree_name . 'annkPriSearch - successfully returned ' . scalar @points . ' points');

    $result = $tree->annkPriSearch($points[0], 4, 0);
    ok(scalar @{$result} == 4, $tree_name . 'annkPriSearch - successfully returned 4 points');

    $result = $tree->annkPriSearch($points[0], 2, 0);
    ok(scalar @{$result} == 2, $tree_name . 'annkPriSearch - successfully returned 2 points');
    is_deeply($result, $search_result, $tree_name . 'annkPriSearch - result is correct');

    ok(!eval { $tree->annkFRSearch($points[0], -1, 0, 0) }, $tree_name . 'annkFRSearch - limit_neighbors must be >= 0');
    ok(!eval { $tree->annkFRSearch($points[0], scalar @points + 1, 0, 0) }, $tree_name . 'annkFRSearch - limit_neighbors must be <= points in the current tree');
    ok(!eval { $tree->annkFRSearch($points[0], 1, -1, 0) }, $tree_name . 'annkFRSearch - epsilon must be >= 0');
    ok(!eval { $tree->annkFRSearch([1,2,3], 1, -1, 0) }, $tree_name . 'annkFRSearch - query_point must have the same dimension as the current tree');

    $result = $tree->annkFRSearch($points[0], 0, 0, 10);
    ok(scalar @{$result} == 3, $tree_name . 'annkFRSearch - successfully returned 3 points');

    $result = $tree->annkFRSearch($points[0], 2, 0, 10);
    ok(scalar @{$result} == 2, $tree_name . 'annkFRSearch - successfully returned 2 points');
    is_deeply($result, $search_result, $tree_name . 'annkFRSearch - result is correct');

    ok(!eval { $tree->annCntNeighbours($points[0], -1, 0) }, $tree_name . 'annCntNeighbours - epsilon must be >= 0');
    ok(!eval { $tree->annCntNeighbours([1,2,3], 0, 0) }, $tree_name . 'annCntNeighbours - query_point must have the same dimension as the current tree');

    ok($tree->annCntNeighbours($points[0], 0, 10) == 3, $tree_name . 'annCntNeighbours - returned 3 neighbors');
    ok($tree->theDim() == 2, $tree_name . 'theDim - returned 2');
    ok($tree->nPoints() == scalar @points, $tree_name . 'nPoints - returned ' . scalar @points);
    ok($tree->Print(0) eq $tree_print_header . $tree_print_structure[$use_bd_tree], $tree_name . 'Print - printed without points');
    ok($tree->Print(1) eq $tree_print_header . $tree_print_points . $tree_print_structure[$use_bd_tree], $tree_name . 'Print - printed with points');
    ok($tree->Dump(0) eq $tree_dump_header . $tree_dump_structure[$use_bd_tree], $tree_name . 'Dump - dumped without points');
    ok($tree->Dump(1) eq $tree_dump_header . $tree_dump_points . $tree_dump_structure[$use_bd_tree], $tree_name . 'Dump - dumped with points');
    is_deeply($tree->getStats(), $tree_stats[$use_bd_tree], $tree_name . 'getStats - got the tree stats');
}


