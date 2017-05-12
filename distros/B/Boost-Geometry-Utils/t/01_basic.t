#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 36;
use Boost::Geometry::Utils qw(polygon_multi_linestring_intersection
                              multi_polygon_multi_linestring_intersection
                              point_within_polygon point_covered_by_polygon
                              point_within_multi_polygon point_covered_by_multi_polygon
                              linestring_simplify multi_linestring_simplify
                              linestring_length polygon_centroid linestring_centroid
                              multi_linestring_centroid correct_polygon
                              correct_multi_polygon polygon_area
                              multi_linestring_multi_polygon_difference);

{
    my $square = [  # ccw
        [10, 10],
        [20, 10],
        [20, 20],
        [10, 20],
    ];
    my $hole_in_square = [  # cw
        [14, 14],
        [14, 16],
        [16, 16],
        [16, 14],
    ];
    my $polygon = [$square, $hole_in_square];
    my $linestring = [ [5, 15], [30, 15] ];
    my $linestring2 = [ [40, 15], [50, 15] ];  # external
    my $multilinestring = [ [ [5, 15], [30, 15] ], [ [40, 15], [50, 15] ] ];
    
    {
        is polygon_area([$square, $hole_in_square]), 10*10 - 2*2, 'polygon area';
    }
    {
        my $intersection =
            polygon_multi_linestring_intersection($polygon, [$linestring]);
        is_deeply $intersection, [
            [ [10, 15], [14, 15] ],
            [ [16, 15], [20, 15] ],
        ], 'line is clipped to square with hole';
    }
    {
        my $intersection =
            polygon_multi_linestring_intersection($polygon, [$linestring2]);
        is_deeply $intersection, [], 'external line produces no intersections';
    }
    {
        my $expected = [
            [ [10, 15], [14, 15] ],
            [ [16, 15], [20, 15] ],
        ];
        my $expected_noholes = [
            [ [10, 15], [20, 15] ],
        ];
        is_deeply polygon_multi_linestring_intersection([$square], $multilinestring),
            $expected_noholes, 'multiple linestring clipping against polygon with no holes';
        is_deeply polygon_multi_linestring_intersection($polygon, $multilinestring),
            $expected, 'multiple linestring clipping';
        is_deeply multi_polygon_multi_linestring_intersection([[$square]], $multilinestring),
            $expected_noholes, 'multiple linestring clipping against multiple polygons with no holes';
        is_deeply multi_polygon_multi_linestring_intersection([$polygon], $multilinestring),
            $expected, 'multiple linestring clipping against multiple polygons';
    }
    {
        ok !eval { polygon_multi_linestring_intersection([$square], [[]]); 1 },
            "croak on reading empty linestring";
        is_deeply multi_polygon_multi_linestring_intersection([], []),
            [], 'emtpy array of linestrings clipping against empty array of polygons';
    }
    {
        my $expected = [
            [ [5,  15], [10, 15] ],
            [ [14, 15], [16, 15] ],
            [ [20, 15], [30, 15] ],
            [ [40, 15], [50, 15] ],
        ];
        is_deeply multi_linestring_multi_polygon_difference($multilinestring, [$polygon]),
            $expected, 'difference between multiple linestrings and multiple polygons';
    }
    
    for my $factor (10, 100, 1000, 10000) {
        my $polygon = [
            [ [50000000,85355480], [14644519,50000000], [50000000,14644519], [85355480,50000000] ],
        ];
        my $line = [ [16369660,85355339], [16369660,14644660] ];
        @$_ = (int $_->[0]/$factor, int $_->[1]/$factor) for @{$polygon->[0]}, @$line;
        
        my $intersection = polygon_multi_linestring_intersection($polygon, [$line]);
        isnt linestring_length($line), linestring_length($intersection->[0]),
            "linestring clipping with large coordinates";
    }

    {
        my $point_in = [11,11];
        my $point_out = [8,8];
        my $point_in_hole = [15,15];
        my $point_on_edge = [10,15];
        my $point_on_hole_edge = [14,15];
        ok point_within_polygon($point_in, $polygon), 'point in polygon';
        ok point_within_multi_polygon($point_in, [$polygon]), 'point in multipolygon';
        ok !point_within_polygon($point_out, $polygon), 'point outside polygon';
        ok !point_within_polygon($point_in_hole, $polygon),
            'point in hole in polygon';
        my $hole = [$hole_in_square];
        ok point_within_polygon($point_in_hole, $hole), 'point in hole';
        ok !point_within_polygon($point_on_edge, $polygon),
            'point on polygon edge';
        ok !point_within_polygon($point_on_hole_edge, $polygon),
            'point on hole edge';

        ok point_covered_by_polygon($point_in, $polygon), 'point in polygon';
        ok point_covered_by_multi_polygon($point_in, [$polygon]), 'point in multipolygon';
        ok !point_covered_by_polygon($point_out, $polygon),
            'point outside polygon';
        ok !point_covered_by_polygon($point_in_hole, $polygon),
            'point in hole in polygon';
        ok point_covered_by_polygon($point_in_hole, $hole), 'point in hole';
        ok point_covered_by_polygon($point_on_edge, $polygon),
            'point on polygon edge';
        ok point_covered_by_polygon($point_on_hole_edge, $polygon),
            'point on hole edge';
    }

    {
        my $line = [[11, 11], [25, 21], [31, 31], [49, 11], [31, 19]];
        is_deeply linestring_simplify($line, 5),
            [ [11, 11], [31, 31], [49, 11], [31, 19] ],
            'linestring simplification';
        is_deeply multi_linestring_simplify([$line], 5),
            [[ [11, 11], [31, 31], [49, 11], [31, 19] ]],
            'multi_linestring simplification';
    }

    {
        my $line = [[10, 10], [10, 20]];
        is linestring_length($line), 10, 'linestring simplification';
    }

    {
        my $square = [  # ccw
            [10, 10],
            [20, 10],
            [20, 20],
            [10, 20],
        ];
        is_deeply polygon_centroid([$square]), [15, 15], 'polygon_centroid';
    }

    {
        my $line = [ [10, 10], [20, 10] ];
        is_deeply linestring_centroid($line), [15, 10], 'linestring_centroid';
        is_deeply multi_linestring_centroid([$line]), [15, 10], 'multi_linestring_centroid';
    }
}

{
    my $square = [  # cw
        [10, 20],
        [20, 20],
        [20, 10],
        [10, 10],
    ];
    my $hole_in_square = [  # cw
        [14, 14],
        [14, 16],
        [16, 16],
        [16, 14],
    ];
    my $polygon = [$square, $hole_in_square];
    my $expected = [ [reverse @$square], $hole_in_square ];
    is_deeply correct_polygon($polygon), $expected, 'correct_polygon';
    is_deeply correct_multi_polygon([$polygon]), [$expected], 'correct_multi_polygon';
}

__END__
