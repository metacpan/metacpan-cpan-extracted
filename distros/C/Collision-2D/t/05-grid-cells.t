
use strict;
use warnings;
no warnings 'qw';

use Collision::2D ':all';

use Test::More  tests => 84;

#motionless circle with rects on grids
# the rects represent cells

#cell (0,0) to (1,1) is center cell
#put a rect in this grid at specified coordinates
sub grid_3x3{
   my ($x,$y) = @_;
   my $grid = hash2grid {x=>-1,y=>-1, w=>3,h=>3, cell_size => 1};
   if (defined $x){
      #be a good citizen and don't touch your neighbors.
      my $rect = hash2rect {x=>$x+.0001, y=>$y+.0001, w=>.9998, h=>.9998};
      is ($grid->cells_intersect_rect ($rect), 1, "rect representing single(!) cell at x: $x y: $y");
      $grid->add_rect ($rect);
   }
   return $grid;
}

#not an acronym. the animal. provides test names..
my @COW = qw|(-1,-1) (0,-1) (1,-1)  (-1,0) (0,0) (1,0)  (-1,1) (0,1) (1,1) |;

my @grids; #[4] at center, [3..5] is center row, [6..8] is top row..
for my $y(-1..1){
   for my $x(-1..1){
      push @grids, grid_3x3 ($x, $y);
   }
}

is (ref $grids[4]->table->[1][1][0], 'Collision::2D::Entity::Rect', 'rect in center cell of its rep. grid');


#start with a circle vs. 9-celled grids
{
   my $smallest_circle = hash2circle {x=>.5, y=>.5, radius=>.49}; #1 cell
   my $corner_circle = hash2circle {x=>-.5, y=>-.5, radius=>.49}; #1 cell
   my $small_circle = hash2circle {x=>.5, y=>.5, radius=>.51}; #5 cells
   my $med_circle = hash2circle {x=>.5, y=>.5, radius=> sqrt(2)/2 - .01}; #5 cells
   my $large_circle = hash2circle {x=>.5, y=>.5, radius=> sqrt(2)/2 + .01}; #9 cells
   my $huge_circle = hash2circle {x=>.5, y=>.5, radius=> 5555555}; #9 cells
   
   
   is ( grid_3x3()->cells_intersect_circle($smallest_circle), 1,
         'smallest_circle intersects 1 cell');
   ok ($smallest_circle->intersect($grids[4]), 'smallest vs. center square');
   ok (!$smallest_circle->intersect($grids[$_]), 'smallest_circle vs. grid '.$COW[$_])
         for (0..3,5..8);
   
   is ( grid_3x3()->cells_intersect_circle($corner_circle), 1,
         'corner intersects 1 cell');
   ok ($corner_circle->intersect($grids[0]), 'corner_circle vs. corner square');
   ok (!$corner_circle->intersect($grids[$_]), 'corner_circle vs. grid '.$COW[$_])
         for (1..8);
   
   is ( grid_3x3()->cells_intersect_circle($small_circle), 5,
         'corner intersects 1 cell');
   #die join ',',map {'('.$_->[0].','.$_->[1].')'} grid_3x3()->cells_intersect_circle($small_circle);
   ok ($small_circle->intersect($grids[$_]), "small_circle vs. $COW[$_] square")
      for (4,3,5,1,7);
   ok (!$small_circle->intersect($grids[$_]), 'small_circle vs. grid '.$COW[$_])
         for (0,2,6,8);
         
   is ( grid_3x3()->cells_intersect_circle($med_circle), 5,
         'corner intersects 1 cell');
   ok ($med_circle->intersect($grids[$_]), "med_circle vs. $COW[$_] square")
      for (4,3,5,1,7);
   ok (!$med_circle->intersect($grids[$_]), 'med_circle vs. grid '.$COW[$_])
         for (0,2,6,8);
   
   is ( grid_3x3()->cells_intersect_circle($large_circle), 9,
         'corner intersects 1 cell');
   ok ($large_circle->intersect($grids[$_]), "large_circle vs. $COW[$_] square")
      for (0..8);
   #ok (!$corner_circle->intersect($grids[$_]), 'med_circle vs. grid '.$COW[$_])
   #      for (0,2,6,8);
   
   is ( grid_3x3()->cells_intersect_circle($huge_circle), 9,
         'corner intersects 1 cell');
   ok ($huge_circle->intersect($grids[$_]), "huge_circle vs. $COW[$_] square")
      for (0..8);
   #ok (!$corner_circle->intersect($grids[$_]), 'med_circle vs. grid '.$COW[$_])
   #      for (0,2,6,8);
   
}

#test cells_intersect_rect
{
   my $empty_grid = grid_3x3();
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>-.9995, y=>-.9995, h=>.999, w=>.999}),
      1,
      '1 cell intersects lil\' rect at ~(-1,-1)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>.0005, y=>.0005, h=>.999, w=>.999}),
      1,
      '1 cell intersects lil\' rect at ~(0,0)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>1.0005, y=>1.0005, h=>.999, w=>.999}),
      1,
      '1 cell intersects lil\' rect at ~(1,1)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>2.0005, y=>1.0005, h=>.999, w=>.999}),
      0,
      '0 cells intersect lil\' rect at ~(2,1)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>1.0005, y=>2.0005, h=>.999, w=>.999}),
      0,
      '0 cells intersect lil\' rect at ~(1,2)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>-1.9995, y=>-1.9995, h=>.999, w=>.999}),
      0,
      '0 cells intersect lil\' rect at ~(-2,-2)'
   );
   
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>-1.9995, y=>-1.9995, h=>1.999, w=>1.999}),
      1,
      '1 cell intersect big\' rect at ~(-2,-2)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>-0.9995, y=>-0.9995, h=>1.999, w=>1.999}),
      4,
      '4 cells intersect big rect at ~(-1,-1)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>.0005, y=>.0005, h=>1.999, w=>1.999}),
      4,
      '4 cells intersect big rect at ~(0,0)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>.0005, y=>1.0005, h=>1.999, w=>1.999}),
      2,
      '2 cells intersect big rect at ~(0,1)'
   );
   is ($empty_grid->cells_intersect_rect (
      hash2rect {x=>1.0005, y=>1.0005, h=>1.999, w=>1.999}),
      1,
      '1 cells intersect big rect at ~(1,1)'
   );
}

#now with a dense grid
{
   my $dense_grid = hash2grid {x=>0, y=>0, cell_size => .01, w=>1, h=>1};
   is ($dense_grid->cells_intersect_rect (
      hash2rect {x=>0.8, y=>0.5, h=>1.999, w=>1.999}),
      1000,
      '1000 dense cells intersect some rect at (.8,.5)'
   );
   is ($dense_grid->cells_intersect_circle (
      hash2circle {x=>0.8, y=>0.5, r=>.0099 }),
      4,
      '4 dense cells intersect some rect with radius=.099'
   );
   is ($dense_grid->cells_intersect_circle (
      hash2circle {x=>0.8, y=>0.5, r=>.0101 }),
      12,
      '12 dense cells intersect some rect with radius=.101'
   );
   
}



