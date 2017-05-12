#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Boost::Geometry::Utils qw(polygon_medial_axis);

use constant SOURCE_INDEX => 0;
use constant VERTEX0  => 1;
use constant TWIN     => 2;
use constant NEXT     => 3;
use constant PREV     => 4;
use constant THETA    => 5;
use constant PHI      => 6;
use constant CURVED   => 7;
use constant PRIMARY  => 8;
use constant INTERNAL => 9;
use constant FOOT     => 10;
use constant VISITED  => 11;

{
    # This polygon includes and hole and a deep concavity
    # and happens to trigger several special cases (though not all) that
    # medial_axis.hpp needs to handle.
    my @expoly = (
        [
          [-182.85714,446.6479],
          [-260,603.79075],
          [8.7692453,559.2707],
          [42.984311,535.98704],
          [77.351978,547.91037],
          [205.71429,526.6479],
          [648.57143,558.07647],
          [632.62232,466.55294],
          [586.18633,452.35022],
          [527.66215,446.38339],
          [479.69269,472.14026],
          [422.48205,469.05075],
          [421.86286,437.5833],
          [459.53403,440.19799],
          [498.13387,402.18796],
          [549.57083,398.3973],
          [591.75,398.35323],
          [625.24287,413.3201],
          [628.57143,306.6479],
        ],
        [
          [-140,483.79075],
          [-22.857143,489.50504],
          [-165.71429,540.93361],
          [-122.85714,506.6479],
        ],
        [
          [94.285714,446.6479],
          [137.14286,438.07647],
          [214.28571,429.50504],
          [274.28571,420.93361],
          [337.14286,412.36218],
          [340,435.21933],
          [325.71429,455.21933],
          [280,455.21933],
          [248.57143,452.36218],
          [211.42857,449.50504],
          [202.85714,466.6479],
          [228.57143,469.50504],
          [271.42857,472.36218],
          [300,478.07647],
          [320,472.36218],
          [348.57143,478.07647],
          [348.57143,506.6479],
          [100,483.79075],
        ]
    );
           
    # Get most of the digits in the above coordinates on the left side
    # of the decimal point. These numbers will be truncated to 32 bit integers,
    # since that's what Boost::Polygon::Voronoi expects by default.
    my $scale = 10000;
    for my $pl (@expoly) { for my $po (@$pl) {$_*=$scale for @$po}}
    
    # Basic tests for the presence of results, and absence of edges the 
    # voronoi to medial code should have eliminated.

    my $ma = polygon_medial_axis(\@expoly);

    ok($ma->{edges} && ref($ma->{edges}) =~ 'ARRAY' && @{$ma->{edges}},
      "medial axis has edges: ".ref($ma->{edges})   . " len: ".scalar(@{$ma->{edges}}));
    ok($ma->{vertices} && ref($ma->{vertices}) =~ 'ARRAY' && @{$ma->{vertices}},
      "medial axis has vertices: ".ref($ma->{vertices}). " len: ".scalar(@{$ma->{edges}}));

    my @internal_primary_edges    = map [$_->[VERTEX0]//undef,$_->[TWIN]->[VERTEX0]//undef], grep  $_->[INTERNAL] &&  $_->[PRIMARY], @{$ma->{edges}};
    my @internal_nonprimary_edges = map [$_->[VERTEX0]//undef,$_->[TWIN]->[VERTEX0]//undef], grep  $_->[INTERNAL] && !$_->[PRIMARY], @{$ma->{edges}};
    my @external_primary_edges    = map [$_->[VERTEX0]//undef,$_->[TWIN]->[VERTEX0]//undef], grep !$_->[INTERNAL] &&  $_->[PRIMARY], @{$ma->{edges}};
    my @external_nonprimary_edges = map [$_->[VERTEX0]//undef,$_->[TWIN]->[VERTEX0]//undef], grep !$_->[INTERNAL] && !$_->[PRIMARY], @{$ma->{edges}};
    my @degen_int_prim_edges    = ((map $_->[1], grep !$_->[0], @internal_primary_edges),
                                   (map $_->[0], grep !$_->[1], @internal_primary_edges)
                                  );
    my @degen_int_nonprim_edges = ((map $_->[1], grep !$_->[0], @internal_nonprimary_edges),
                                   (map $_->[0], grep !$_->[1], @internal_nonprimary_edges)
                                  );
    my @degen_ext_prim_edges    = ((map $_->[1], grep !$_->[0], @external_primary_edges),
                                   (map $_->[0], grep !$_->[1], @external_primary_edges)
                                  );
    my @degen_ext_nonprim_edges = ((map $_->[1], grep !$_->[0], @external_nonprimary_edges),
                                   (map $_->[0], grep !$_->[1], @external_nonprimary_edges)
                                  );
    @internal_primary_edges    = grep $_->[0] && $_->[1], @internal_primary_edges;
    @internal_nonprimary_edges = grep $_->[0] && $_->[1], @internal_nonprimary_edges;
    @external_primary_edges    = grep $_->[0] && $_->[1], @external_primary_edges;
    @external_nonprimary_edges = grep $_->[0] && $_->[1], @external_nonprimary_edges;

    my $expected_edge_count = 170;
    
    # the edges we want - primary edges within the polygon
    ok(scalar(@internal_primary_edges)    == $expected_edge_count,
      "internal primary edges accounted for");
    
    # right now we don't want primary edges outside of the polygon
    # or within holes - though we may want those as a future option
    ok(scalar(@external_primary_edges)    == 0, 
      "external primary edges removed");
    
    # We eliminate the need for non-primary edges by instead providing an 
    # initial trajectory angle for all edges, and a "foot" point on the polygon
    # for each edge. This is enough information to replace the utility of 
    # non-primary edges. So no non-primaries should have slipped through.
    ok(scalar(@internal_nonprimary_edges) == 0, 
      "no internal non-primary edges present");
    ok(scalar(@external_nonprimary_edges) == 0, 
      "no external non-primary edges");
    
    # Degenerate edges are missing an end vertex, generally because it's at 
    # infinity. We may want some of these in future, if we allow optional 
    # external edges. But for now these should be filtered out.
    ok(scalar(@degen_ext_nonprim_edges)   == 0, 
      "no degenerate external non-primary edges");
    ok(scalar(@degen_ext_prim_edges )     == 0, 
      "no degenerate external primary edges");
    
    # These shouldn't be possible
    ok(scalar(@degen_int_prim_edges)      == 0, 
      "no degenerate internal primary edges");
    ok(scalar(@degen_int_nonprim_edges)   == 0, 
      "no degenerate internal non-primary edges");

    # check integrity of the half-edge graph
    ok((grep defined($_->[TWIN]), @{$ma->{edges}})      == $expected_edge_count,
      "all edges have a twin reference");
    ok((grep defined($_->[NEXT]), @{$ma->{edges}})      == $expected_edge_count,
      "all edges have a next reference");
    ok((grep defined($_->[PREV]), @{$ma->{edges}})      == $expected_edge_count,
      "all edges have a prev reference");
    ok((grep $_->[TWIN]->[TWIN] == $_, @{$ma->{edges}}) == $expected_edge_count,
      "all twins refer to each other");
    ok((grep $_->[NEXT]->[PREV] == $_, @{$ma->{edges}}) == $expected_edge_count,
      "all next->prev references are valid");
    ok((grep $_->[PREV]->[NEXT] == $_, @{$ma->{edges}}) == $expected_edge_count,
      "all prev->next references are valid");
}

__END__
