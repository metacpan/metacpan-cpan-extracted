use strict;
use warnings;

use Test::More;

use Storable qw(dclone);

use Algorithm::Graphs::TransitiveClosure::Tiny qw(floyd_warshall);

{
  note "Taken from original but with integers as keys";
  my $graph = {
               0 => {0 => undef},
               1 => {1 => undef, 2 => undef, 3 => undef},
               2 => {1 => undef, 2 => undef},
               3 => {0 => undef, 2 => undef, 3 => undef},
              };

  is(floyd_warshall($graph),
     $graph, 'floyd_warshall($graph) returns $graph'
    );

  #
  # This test is a modified copie of the 'hash' part of 000_tests.t contained in
  # Algorithm::Graphs::TransitiveClosure distribution.
  #
  ok(1 == keys %{$graph -> {0}}   && exists($graph -> {0}   -> {0}) &&
     4 == keys %{$graph -> {1}}   && exists($graph -> {1}   -> {0}) &&
     exists($graph -> {1} -> {1}) &&
     exists($graph -> {1} -> {2}) &&
     exists($graph -> {1} -> {3}) &&
     4 == keys %{$graph -> {2}} && exists($graph -> {2} -> {0}) &&
     exists($graph -> {2} -> {1}) &&
     exists($graph -> {2} -> {2}) &&
     exists($graph -> {2} -> {3}) &&
     4 == keys %{$graph -> {3}}   && exists($graph -> {3}  -> {0}) &&
     exists($graph -> {3}  -> {1}) &&
     exists($graph -> {3}  -> {2}) &&
     exists($graph -> {3}  -> {3}),
     "check result of floyd_warshall()");

  my $clone = dclone($graph);
  floyd_warshall($clone);
  is_deeply($clone, $graph, "calling floyd_warshall a second time won't change anything");
}


{
  note("Empty input");
  my $g = {};
  floyd_warshall($g);
  is_deeply($g, {}, "empty result");
}


{
  note("Example for fixed problem (->POD)");
  my $g = {
           0 => { 2 => 1},
           1 => { 0 => 1},
          };
  floyd_warshall($g, 3);
  is_deeply($g,
            {
             0 => { 2 => 1},
             1 => { 0 => 1,
                    2 => undef},
            },
            "Vertice from 1 to 2 has been added"
           );
}


{
  note "Bugfix";
  my $graph = { 1 => { 0 => undef },
                2 => { 0 => undef },
                3 => { 1 => undef, 2 => undef },
                4 => { 0 => undef }
              };
  floyd_warshall($graph);

  is_deeply($graph, { 1 => { 0 => undef },
                      2 => { 0 => undef },
                      3 => { 0 => undef, 1 => undef, 2 => undef },
                      4 => { 0 => undef }
                    },
            "bugfix ok");
}


note "With strings as keys";
{
  note("Test from Algorithm::Graphs::TransitiveClosure (using 1 as value)");
  my $graph = {
               one   => {one => 1},
               two   => {two => 1, three => 1, four => 1},
               three => {two => 1, three => 1},
               four  => {one => 1, three => 1, four => 1},
              };
  floyd_warshall $graph;
  is_deeply($graph,
            {
             one   => {one => 1},
             two   => {one => undef, two => 1,     three => 1, four => 1},
             three => {one => undef, two => 1,     three => 1, four => undef},
             four  => {one => 1,     two => undef, three => 1, four => 1},
            },
            "TransitiveClosure ok"
           );
}

{
  note("Test from Algorithm::Graphs::TransitiveClosure (using undef as value)");
  my $graph = {
               one   => {one => undef},
               two   => {two => undef, three => undef, four => undef},
               three => {two => undef, three => undef},
               four  => {one => undef, three => undef, four => undef},
              };
  floyd_warshall $graph;
  is_deeply($graph,
            {
             one   => {one => undef},
             two   => {one => undef, two => undef, three => undef, four => undef},
             three => {one => undef, two => undef, three => undef, four => undef},
             four  => {one => undef, two => undef, three => undef, four => undef},
            },
            "TransitiveClosure ok"
           );
}

note "keep and don't keep";
{
  {
    note "Keep";
    my $graph = {
                 this => {that => undef},
                 that => {}
                };
    floyd_warshall($graph, 1);
    is_deeply($graph, {
                       this => {that => undef},
                       that => {}
                      },
              "Keep ok");
  }
  {
    note "Don't keep";
    my $graph = {
                 this => {that => undef},
                 that => {}
                };
    floyd_warshall($graph);
    is_deeply($graph, {
                       this => {that => undef}
                      },
              "Don't keep (default) ok");
  }
}

#-----------------------------------------------------------------------------
done_testing();

#############################################################################

