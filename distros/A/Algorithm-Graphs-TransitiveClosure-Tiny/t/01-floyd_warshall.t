use strict;
use warnings;

use Test::More;

use Storable qw(dclone);

use Algorithm::Graphs::TransitiveClosure::Tiny qw(floyd_warshall);

{
  note "taken from original (basically)";
  my $graph = {
               0 => {0 => undef},
               1 => {1 => undef, 2 => undef, 3 => undef},
               2 => {1 => undef, 2 => undef},
               3 => {0 => undef, 2 => undef, 3 => undef},
              };

  is(floyd_warshall($graph, 4),
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
  floyd_warshall($clone, 4);
  is_deeply($clone, $graph, "calling floyd_warshall a second time won't change anything");
}


{
  note("Empty input");
  my $g = {};
  floyd_warshall($g, 27);
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
  floyd_warshall($graph, 5);

  is_deeply($graph, { 1 => { 0 => undef },
                      2 => { 0 => undef },
                      3 => { 0 => undef, 1 => undef, 2 => undef },
                      4 => { 0 => undef }
                    },
            "bugfix ok");
}


#-----------------------------------------------------------------------------
done_testing();

#############################################################################

