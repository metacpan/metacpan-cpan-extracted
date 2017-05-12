
use strict;
use warnings;

use Collision::2D ':all';
use Test::Number::Delta;

use Test::More tests => 34;

#first, bounce point off rect
{
   my $tallrect = hash2rect {x=>0,y=>-100, h=>200};
   #point from left
   my $px_pt = hash2point {x=>-1,y=>0,xv=>2};
   my $px_collision = dynamic_collision ($px_pt, $tallrect);
  # $px_collision = Collision::2D::Collision->new (time=>1,ent1=>$tallrect,ent2=>$px_pt, axis=>[1,0]);
   is ($px_collision->axis, 'x');
   is ($px_collision->vaxis->[0], 1);
   is ($px_collision->vaxis->[1], 0);
   
   #point from right
   my $nx_pt = hash2point {x=>2,y=>0,xv=>-2};
   my $nx_collision = dynamic_collision ($nx_pt, $tallrect);
   is ($nx_collision->axis, 'x');
   is ($nx_collision->vaxis->[0], -1);
   is ($nx_collision->vaxis->[1], 0);
   
   
   my $widerect = hash2rect {y=>0,x=>-100, w=>200};
   #point from below
   my $py_pt = hash2point {x=>0,y=>-1,yv=>2};
   my $py_collision = dynamic_collision ($py_pt, $widerect);
   is ($py_collision->axis, 'y');
   is ($py_collision->vaxis->[0], 0);
   is ($py_collision->vaxis->[1], 1);
   #from above
   my $ny_pt = hash2point {x=>0,y=>2,yv=>-2};
   my $ny_collision = dynamic_collision ($ny_pt, $widerect);
   
   is ($ny_collision->axis, 'y');
   is ($ny_collision->ent1->typename, 'point', 'ent1 point');
   is ($ny_collision->ent2->typename, 'rect', 'ent2 rect');
   is ($ny_collision->vaxis->[0], 0);
   is ($ny_collision->vaxis->[1], -1);
}

#now axis from point-circ and circ-circ.
{
   my $unitpie = hash2circle {x=>0,y=>0, radius=>1};
   my $pt = hash2point {x=>-1,y=>-1, xv=>1, yv=>1};
   #my $collision = dynamic_collision ($pt, $unitpie);
   $unitpie->normalize($pt);
   my $collision = $unitpie->_collide_point ($pt, interval=>5);
   my $axis = normalize_vec ($collision->axis);
   delta_ok ($axis->[0], -sqrt(2)/2, 'circpt axis x');
   delta_ok ($axis->[1], -sqrt(2)/2, 'circpt axis y');
   
   my $nonpie = hash2circle {x=>-2,y=>-2, xv=>1, yv=>1};
   $nonpie->normalize($unitpie);
   my $collision2 = $nonpie->_collide_circle ($unitpie, interval=>5);
   delta_ok ($collision2->time, 2-sqrt(2));
   my $axis2 = normalize_vec ($collision2->axis);
   delta_ok ($axis2->[0], sqrt(2)/2);
   delta_ok ($axis2->[1], sqrt(2)/2, 'foo?');
   
}

#now do bounce vectors
{
   my $tallrect = hash2rect {x=>0,y=>-100, h=>200};
   #point from left
   my $px_pt = hash2point {x=>-1.222,y=>1.666,xv=>2, yv=>1};
   my $px_collision = dynamic_collision ($px_pt, $tallrect);
   my $bounce_vec = $px_collision->bounce_vector;
   is ($bounce_vec->[0], -2, '1st bouncevec x');
   is ($bounce_vec->[1], 1, '1st bouncevec y');
   
   
   my $widerect = hash2rect {x=>-100, w=>200, y=>0, h=>1};
   #point from above, moving right. hit at y=1.
   my $ny_pt = hash2point {x=>5,y=>8, xv=>.21212, yv=>-2};
   my $ny_collision = dynamic_collision ($ny_pt, $widerect, interval=>20); 
   
   
   
   #now do 2 moving circles  both moving horizontal, but bounce
   # each other into y dimension; "deflection"?
   my $pxcirc = hash2circle {x=>-2, y=>-sqrt(2), xv=> 100, radius=>2 , yv=>.888 };
   my $nxcirc = hash2circle {x=> 2, y=> sqrt(2), xv=>-100, radius=>2 , yv=>.888 };
   
   $pxcirc->normalize($nxcirc);
   my $circ_collision = $pxcirc->_collide_circle ($nxcirc, interval=>1);
   
   my $axis = normalize_vec $circ_collision->axis;
   delta_ok ($axis->[0], sqrt(2)/2, 'circ-circ "deflection" axis of collision(x)');
   delta_ok ($axis->[1], sqrt(2)/2, 'circ-circ "deflection" axis of collision(y)');
   
   my $cbvec = $circ_collision->bounce_vector;
   my $rcbvec = $circ_collision->bounce_vector (relative=>1);
   my $icbvec = $circ_collision->bounce_vector (elasticity=>0, relative=>1);
   delta_ok ($cbvec->[0], -100, 'elastic circle bounce'); #-100
   delta_ok ($cbvec->[1], -200 + .888, 'elastic circle bounce'); #0
   delta_ok ($rcbvec->[0], 0, 'relative circle bounce'); #deflect vertically, relatively
   delta_ok ($rcbvec->[1], -200, 'relative circle bounce'); #rv is initially 200 ->
   delta_ok ($cbvec->[0],  -100, 'inelastic circle bounce'); #-100 
   delta_ok ($cbvec->[1], -200 + .888, 'inelastic circle bounce'); #0
   
}

#now test keep_order parameter
{
   my $rect = hash2rect  {x=>0  ,y=>1,w=>1,h=>1, xv=>-1};
   my $dot  = hash2point {x=>-1.5,y=>1.5,w=>1,h=>1, xv=>1};
   
   my $collision = dynamic_collision ($rect, $dot, keep_order=>1);
   ok ($collision, 'keepordered collision exists');
   delta_ok ($collision->time, 3/4, 'keepordered collision at ~correct time');
   is ($collision->ent1->typename, 'rect', 'keepordered collision preserves order');
   
   my $axis = normalize_vec($collision->vaxis);
   is ($axis->[0], -1, 'keepordered collision axis x is -1, respective of rect');
   is ($axis->[1], 0, 'keepordered collision axis x is 0, of course');
   
}



