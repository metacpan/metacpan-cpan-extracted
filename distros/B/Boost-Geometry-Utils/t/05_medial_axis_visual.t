#!/usr/bin/perl

use strict;
use warnings;

my $svg;

BEGIN {
  # Slic4rt.pm available here:
  # https://gist.github.com/mesheldrake/5479337/download
  eval("require '../Slic4rt.pm';");
  if ($@) {
    require Test::More;
    Test::More::plan(skip_all => 'author tests');
  } else {
    $DB::svg = SVGAppend->new('05_medial_axis_visual.t.svg',{style=>'background-color:#000000;'},'clobber');
    $svg = $DB::svg;
  }
}

use Boost::Geometry::Utils qw(polygon_medial_axis);
use List::Util qw(first);
use Test::More tests => 1;

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
        
    # The point of this "test" is to output various geometry related to
    # producing the medial axis to an SVG file for visual inspection.
    
    my $ma = polygon_medial_axis(\@expoly);
        
    # these style class names are used in the debug code in
    # medial_axis.hpp
    # Pixel dimensions here are appropriate for the test polygon above.
    $svg->appendStyle('.ine1linearprimary circle {fill:green;}'.
    '.ine1linearprimary line {stroke:purple;stroke-width:15000;}'.
    '.ine1linearsecondary circle {fill:lightgreen;}'.
    '.ine1linearsecondary line {stroke:purple;stroke-dasharray:3000 3000;stroke-width:15000;}'.
    '.cirevtpt {fill:white;}'.
    '.cirevtcir {fill:none;stroke:gray;stroke-width:10000}'.
    '.edge12 {stroke:green;stroke-width:7000;stroke-dasharray:2000 2000;}'.
    '.edge23 {stroke:lightgreen;stroke-width:7000;stroke-dasharray:2000 2000;}'.
    '.siteseg1 {stroke:brown;stroke-width:40000;opacity:0.4;stroke-dasharray:5000 5000;}'.
    '.siteseg3 {stroke:orange;stroke-width:40000;opacity:0.4;stroke-dasharray:5000 5000;}'.
    '.sitept1 {fill:brown;opacity:0.4;}'.
    '.sitept3 {fill:orange;opacity:0.4;}'.
    '.evtfoot  {fill:red;stroke:white;stroke-width:20000;}'.
    '.evtfoot2 {fill:red;stroke:blue;stroke-width:20000;}'.
    '.evtfoot3 {fill:gray;stroke:red;stroke-width:20000;}'.
    '.evtfootc {fill:pink;stroke:blue;stroke-width:20000;}'.
    '.evtfootworking {fill:yellow;stroke:green;stroke-width:20000;}'.
    '.edge_missing_foot {stroke:yellow;stroke-width:230000;opacity:0.5;stroke-dasharray:8000 8000;}'
    );

    $svg->appendRaw($ma->{events});
    
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


    # Collect a path of primary edges that doesn't leave the polygon
    my @path_loops;
    if (1) {
    
    # note: An expanded version of the edge graph walking done below is now done
    # upstream in medial_axis.hpp, so the following isn't necessary, but
    # should still work if all the medial axis edges have been properly linked.
    
    # Sorting on source segment should make the first result loop
    # be the one for the polygon contour, and the rest for the holes.
    # This is probably also preseving opposite winding for countour vs holes
    # but currently the winding convention comes out opposite of the polygon 
    # input winding convention.
    my @source_sorted_edges = sort {$a->[SOURCE_INDEX] <=> $b->[SOURCE_INDEX]} @{$ma->{edges}};
    while (my $start_edge = first { $_->[PRIMARY] and $_->[INTERNAL] and not $_->[VISITED] } @source_sorted_edges) {
       push @path_loops, [];
       my $edge = $start_edge;
       do {
         # collect whatever representation of the edge we want
         # - just points here, but it would be more useful to
         # collect a list of these edge structs.
         push @{$path_loops[-1]}, $edge->[VERTEX0] if $edge->[VERTEX0];
         ++$edge->[VISITED];
         if (!defined $edge->[NEXT]) {diag("SAW UNDEF EDGE->NEXT\n");next;}
         if ($edge->[NEXT]->[INTERNAL]) {
           if ($edge->[NEXT]->[PRIMARY]) { # goto next edge within same cell 
             $edge = $edge->[NEXT];
           } else { # skip over a non-primary edge before a curved primary edge
             $edge = $edge->[NEXT]->[TWIN]->[NEXT];
             fail("non-primary edge escaped processing"); 
           }
         } else { # corner - end touches polygon, so turn around
           $edge = $edge->[TWIN];                      
           fail("corner edge escaped processing"); 
         }
       } while (defined $edge->[NEXT] && $edge != $start_edge && not $edge->[VISITED]);
       # Since here we're just collecting points,
       # close the loop with second point of last edge.
       push @{$path_loops[-1]}, $edge->[VERTEX0] if $edge->[VERTEX0];
     }
     }
    
    my @poly = @{$ma->{vertices}};
    
    $svg->appendPolygons({style=>"stroke-width:".($scale).";stroke:blue;fill:none;"},\@expoly);
    $svg->appendPolylines({style=>"stroke-width:".($scale*2).";opacity:0.7;stroke-linecap:round;stroke-linejoin:round;stroke:orange;fill:none;"},
       @path_loops);
    #$svg->appendCircles({style=>"stroke-width:".($scale*0.05).";stroke:yellow;fill:none;"},
    #   grep defined($_) && defined($_->[0]) && defined($_->[1] && defined($_->[2])), @poly);
    
    if (1) {
    # These voronoi relics shouldn't appear for inside-edges-only medial axis.
    $svg->appendLines({style=>"stroke-width:".($scale*5).";stroke:#0000FF;fill:none;"},
        @external_primary_edges);
    $svg->appendLines({style=>"stroke-width:".($scale*5).";stroke:aqua;fill:none;"},
        @external_nonprimary_edges);
    $svg->appendPoints({r=>($scale*9),style=>"stroke-width:".($scale*0.5).";stroke:#0000FF;fill:none;"},
       map [$_->[0],$_->[1]], @degen_ext_prim_edges);
    $svg->appendPoints({r=>($scale*9),style=>"stroke-width:".($scale*0.5).";stroke:aqua;fill:none;"},
       map [$_->[0],$_->[1]], @degen_ext_nonprim_edges);
    
    $svg->appendLines({style=>"stroke-width:".($scale*5).";stroke:#666666;fill:none;"},
        @internal_primary_edges);
    $svg->appendLines({style=>"stroke-width:".($scale*5).";stroke:#AAAAAA;fill:none;"},
        @internal_nonprimary_edges);
    $svg->appendPoints({r=>($scale*9),style=>"stroke-width:".($scale*0.5).";stroke:#666666;fill:none;"},
       map [$_->[0],$_->[1]], @degen_int_prim_edges);
    $svg->appendPoints({r=>($scale*9),style=>"stroke-width:".($scale*0.5).";stroke:#AAAAAA;fill:none;"},
       map [$_->[0],$_->[1]], @degen_int_nonprim_edges);
    }
   
    # circle zero-radius vertices that we expect to appear at the polygon's
    # convex corners.
    $svg->appendPoints({r=>(6.3*$scale),style=>"stroke-width:".($scale*2).";stroke:#AAAAAA;fill:none;"},
       map [$_->[0],$_->[1]], grep $_->[2] == 0, @{$ma->{vertices}});

    #$svg->appendPoints({r=>($scale*3),style=>"stroke-width:".($scale*0.5).";fill:blue;"},
    #   map [$_->[FOOT]->[0],$_->[FOOT]->[1]], @{$ma->{edges}});
    
    #$svg->appendLines({style=>"stroke-width:".($scale*5).";stroke:#666666;fill:none;"},
    #    map [$_->[VERTEX0VERTEX0],$_->[NEXT]->[VERTEX0]], grep $_->[NEXT] == $_->[TWIN], @{$ma->{edges}});

    #$svg->appendLines({style=>"stroke-width:".($scale*5).";stroke:green;fill:none;"},
    #    map [$_->[VERTEX0],$_->[NEXT]->[VERTEX0]], grep $_->[VERTEX0]->[2] == 0, @{$ma->{edges}});
        
    #$svg->appendLines({style=>"stroke-width:".($scale*3).";stroke:blue;fill:none;"},
    #   map [$_->[VERTEX0],$_->[FOOT]] , @{$ma->{edges}});
          
    # should maybe calculate curved edge bezier point in C so you can do this:
    if (1) {
    # update/reduce redundancy here    
    $svg->appendCurves({style=>"stroke-width:".($scale*2.7).";opacity:0.6;stroke:white;stroke-linecap:round;stroke-linejoin:round;fill:none;"},
    [ [ [$ma->{edges}->[0]->[VERTEX0]->[0], $ma->{edges}->[0]->[VERTEX0]->[1]], 
        [$ma->{edges}->[0]->[NEXT]->[VERTEX0]->[0], $ma->{edges}->[0]->[NEXT]->[VERTEX0]->[1]]
      ],
     
      map  {
            ref($ma->{edges}->[$_]->[CURVED]) ?
             [  [$ma->{edges}->[$_]->[VERTEX0]->[0]  , $ma->{edges}->[$_]->[VERTEX0]->[1]],
                [$ma->{edges}->[$_]->[CURVED]->[0] , $ma->{edges}->[$_]->[CURVED]->[1], 
                 $ma->{edges}->[$_]->[NEXT]->[VERTEX0]->[0], $ma->{edges}->[$_]->[NEXT]->[VERTEX0]->[1]]
              ]
            : [ [$ma->{edges}->[$_]->[VERTEX0]->[0]  , $ma->{edges}->[$_]->[VERTEX0]->[1]],
                [$ma->{edges}->[$_]->[NEXT]->[VERTEX0]->[0], $ma->{edges}->[$_]->[NEXT]->[VERTEX0]->[1]] ]
          } (0 .. $#{$ma->{edges}} - 1)
      
    ]);

    $svg->appendPoints({r=>($scale*3),style=>"stroke-width:".($scale*0.7).";fill:green;"},
       map [$_->[CURVED]->[0],$_->[CURVED]->[1]], grep {ref $_->[CURVED]} @{$ma->{edges}});
    }
     
}

ok($DB::svg);

__END__
