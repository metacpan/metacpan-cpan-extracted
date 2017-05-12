
use strict;
use warnings;

use Collision::2D ':all';

use Test::More  tests => 98;

#grids are an optimization, but here I suppose we'll just test function rather than performance

#motionless circle with points on grid
{
   my $pie = hash2circle {x=>1.8888, y=>-1.1234, radius=>2}; #motionless
   my @points_in = (
      hash2point ({x=>1.8887 + sqrt(2), y=>-1.1234 + sqrt(2)}),
      hash2point ({x=>1.8887 + sqrt(2), y=>-1.1234 - sqrt(2)}),
      hash2point ({x=>1.8889 - sqrt(2), y=>-1.1234 - sqrt(2)}),
      hash2point ({x=>1.8889 - sqrt(2), y=>-1.1234 + sqrt(2)}),
      hash2point ({x=>1.8887 + sqrt(2), y=>-1.1234}), #E, very in
   );
   my @points_out = (
      hash2point ({x=>1.8887 - sqrt(2), y=>-1.1234 - sqrt(2)}),
      hash2point ({x=>1.8887 - sqrt(2), y=>-1.1234 + sqrt(2)}),
      hash2point ({x=>1.8889 + sqrt(2), y=>-1.1234 + sqrt(2)}),
      hash2point ({x=>1.8889 + sqrt(2), y=>-1.1234 - sqrt(2)}),
   );
   #$grid->add_point ($_) for (@points_in, @points_out);
   
   for my $s (.444,.543,.642,.741,.84,.949,1.048){
      my $grid = hash2grid {x=>-15, y=>-15, w=>30, h=>30,  cell_size => $s };
      $grid->add_circle($pie);

      ok (intersection ($grid, $points_in[0]), 'NE collision');
      ok (intersection ($grid, $points_in[1]), 'SE collision');
      ok (intersection ($grid, $points_in[2]), 'SW collision');
      ok (intersection ($grid, $points_in[3]), 'NW collision');
      ok (intersection ($grid, $points_in[4]), 'E collision');
      ok (!intersection ($grid, $points_out[0]), 'NE non-collision');
      ok (!intersection ($grid, $points_out[1]), 'SE non-collision');
      ok (!intersection ($grid, $points_out[2]), 'SW non-collision');
      ok (!intersection ($grid, $points_out[3]), 'NW non-collision');
   }
}

# just a circle on grid. make sure it's not in cells that the circle doesn't intersect
{
   my $pie = hash2circle {x=>.5, y=>.5, radius=>.51}; #motionless
   my $grid = hash2grid {x=>-1, y=>-1, w=>4, h=>4,  cell_size => 1 };
   $grid->add_circle ($pie);
   
   ok ($grid->table->[1][1], 'circle is primarily here');
   ok ($grid->table->[1][2], 'cell clips right of circle');
   ok ($grid->table->[1][0], 'cell clips left of circle');
   ok ($grid->table->[2][1], 'cell clips top of circle');
   ok ($grid->table->[0][1], 'cell clips bottom of circle');
   ok (!$grid->table->[2][2], 'circle is not in top-right');
   ok (!$grid->table->[2][0], 'circle is not in top-left');
   ok (!$grid->table->[0][0], 'circle is not in bottom-left');
   ok (!$grid->table->[0][0], 'circle is not in bottom-right');
}

#now do some rect-rect via grid
{
   my $grid = hash2grid {x=>0, y=>0, w=>4, h=>4,  cell_size => 1 };
   $grid->add (hash2rect {x=>.0005, y=>.0005, h=>1, w=>1});
   ok ($grid->intersect (hash2rect {x=>1,      y=>1,      h=>1, w=>1}));
   ok ($grid->intersect (hash2rect {x=>1,      y=>-.9994, h=>1, w=>1}));
   ok ($grid->intersect (hash2rect {x=>-.9994, y=>1,      h=>1, w=>1}));
   ok ($grid->intersect (hash2rect {x=>-.9994, y=>-.9994, h=>1, w=>1}));
   ok ($grid->collide (hash2rect {x=>1,      y=>1,      h=>1, w=>1}));
   ok ($grid->collide (hash2rect {x=>1,      y=>-.9994, h=>1, w=>1}));
   ok ($grid->collide (hash2rect {x=>-.9994, y=>1,      h=>1, w=>1}));
   ok ($grid->collide (hash2rect {x=>-.9994, y=>-.9994, h=>1, w=>1}));
   
   #now in srsly motion
   ok ($grid->collide (hash2rect {x=>1+5,      y=>1-5,      h=>1, w=>1, xv=>-5, yv=>5}), 'RR, NE corner from SE');
   ok ($grid->collide (hash2rect {x=>1-5,      y=>1+5,      h=>1, w=>1, xv=>5, yv=>-5}), 'RR, NE corner from NW');
   ok ($grid->collide (hash2rect {x=>1+5,      y=>-.9994+5, h=>1, w=>1, xv=>-5, yv=>-5}), 'RR, SE corner from SW');
   ok ($grid->collide (hash2rect {x=>1-5,      y=>-.9994-5, h=>1, w=>1, xv=>5, yv=>5}), 'RR, SE corner from NE');
   ok ($grid->collide (hash2rect {x=>-.9994+5, y=>1+5,          h=>1, w=>1, xv=>-5, yv=>-5}));
   ok ($grid->collide (hash2rect {x=>-.9994-5, y=>1-5,          h=>1, w=>1, xv=>5, yv=>5}));
   ok ($grid->collide (hash2rect {x=>-.9994+5, y=>-.9994-5,     h=>1, w=>1, xv=>-5, yv=>5}));
   ok ($grid->collide (hash2rect {x=>-.9994-5, y=>-.9994+5,     h=>1, w=>1, xv=>5, yv=>-5}));
}

#circle-grid collisions
{
   #south circle, moving northeast
   my $s_circ = hash2circle {x=>0,y=>-5, xv=>5, yv=>5, radius=>1};
   #north circle, moving southeast
   my $n_circ = hash2circle {x=>0,y=>5, xv=>5, yv=>-5, radius=>1};
   my $both_grid1 = hash2grid {x=>0.54, y=>-3, h=>6, w=>9, cell_size=>1};
   $both_grid1->add(hash2point({x=>4.52,y=>0}));
   my $both_grid2 = hash2grid {x=>0.46, y=>-3, h=>6, w=>9, cell_size=>1};
   $both_grid2->add(hash2point({x=>5.48,y=>0}));
   
   my $s_grid = hash2grid {x=>-2, y=>-6, h=>6, w=>9, cell_size=>1};
   my $n_grid = hash2grid {x=>-2, y=>3,  h=>6, w=>9, cell_size=>1};
   $s_grid->add(hash2point({x=>0,y=>-5}));
   $n_grid->add(hash2point({x=>0,y=>5}));
   
   ok (dynamic_collision($s_circ, $both_grid1));
   ok (dynamic_collision($n_circ, $both_grid1));
   ok (dynamic_collision($s_circ, $both_grid2));
   ok (dynamic_collision($n_circ, $both_grid2));
   
   ok (dynamic_collision($s_circ, $s_grid));
   ok (dynamic_collision($n_circ, $n_grid));
   
   ok (!dynamic_collision($s_circ, $n_grid), 's. circle misses far point');
   ok (!dynamic_collision($n_circ, $s_grid), 'n. circle misses far point');
   
   my $miss_grid = $s_grid = hash2grid {x=>-2.634154315345, y=>-3.21314324, h=>6, w=>9, cell_size=>1};
   $miss_grid->add(hash2point({x=>3,y=>0}));
   $miss_grid->add(hash2point({x=>6.01,y=>0}));
   $miss_grid->add(hash2point({x=>5,y=>3}));
   $miss_grid->add(hash2point({x=>5,y=>-3}));
   ok (!dynamic_collision($s_circ, $miss_grid), 's. circle misses a bunch of points');
   ok (!dynamic_collision($n_circ, $miss_grid), 'n. circle misses a bunch of points');
   
}





