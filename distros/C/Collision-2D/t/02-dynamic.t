
use strict;
use warnings;

use Collision::2D ':all';

use Test::More tests => 145;
use Test::Number::Delta;

#First do rect-point collisions. the method is $point->_collide_rect($rect,...)
{
   my $andy = hash2rect {x=>-1, y=>-1, h=>2, w=>2};
   my $bullet1 = hash2point { x=>-51, y=>0, xv=>100, yv=>16 }; #wild miss
   my $bullet2 = hash2point { x=>-51, y=>0, xv=>100, yv=>0 }; #hit
   my $meteorite = hash2point { x=>0, y=>80001, xv=>0, yv=>-200000 }; #hit
   #Bless you, Andy. Blandy.

   my $collision1 = dynamic_collision ($bullet1, $andy, interval=>1);
   my $collision2 = dynamic_collision ($bullet2, $andy, interval=>1);
   my $collision3 = dynamic_collision ($meteorite, $andy, interval=>1);

   ok (!defined $collision1);
   isa_ok ($collision2, 'Collision::2D::Collision');
   is ($collision2->axis, 'x', 'horizontal collision.');
   delta_ok ($collision2->time, .5, 'bullet hits andy in half of a time unit');
   isa_ok ($collision3, 'Collision::2D::Collision');
   is ($collision3->axis, 'y', 'vert collision.');
   delta_ok ($collision3->time, 8/20, 'meteorite hits andy at right time');

   #test the corners
   ok (!dynamic_collision ($andy, hash2point { x=>-2, y=>0, xv=>2, yv=>2.02 }));
   ok (dynamic_collision ($andy, hash2point { x=>-2, y=>0, xv=>2, yv=>1.98 }));
   ok (!dynamic_collision ($andy, hash2point { x=>-2, y=>0, xv=>2, yv=>-2.02 }));
   ok (dynamic_collision ($andy, hash2point { x=>-2, y=>0, xv=>2, yv=>-1.98 }));
   #right
   ok (!dynamic_collision ($andy, hash2point { x=>2, y=>0, xv=>-2, yv=>2.02 }));
   ok (dynamic_collision ($andy, hash2point { x=>2, y=>0, xv=>-2, yv=>1.98 }));
   ok (!dynamic_collision ($andy, hash2point { x=>2, y=>0, xv=>-2, yv=>-2.02 }));
   ok (dynamic_collision ($andy, hash2point { x=>2, y=>0, xv=>-2, yv=>-1.98 }));
   #top
   ok (!dynamic_collision ($andy, hash2point { x=>0, y=>2, xv=>2.01, yv=>-2 }));
   ok (dynamic_collision ($andy, hash2point { x=>0, y=>2, xv=>1.99, yv=>-2 }));
   ok (!dynamic_collision ($andy, hash2point { x=>0, y=>2, xv=>-2.01, yv=>-2 }));
   ok (dynamic_collision ($andy, hash2point { x=>0, y=>2, xv=>-1.99, yv=>-2 }));
   #ass
   ok (!dynamic_collision ($andy, hash2point { x=>0, y=>-2, xv=>2.01, yv=>2 }));
   ok (dynamic_collision ($andy, hash2point { x=>0, y=>-2, xv=>1.99, yv=>2 }));
   ok (!dynamic_collision ($andy, hash2point { x=>0, y=>-2, xv=>-2.01, yv=>2 }));
   ok (dynamic_collision ($andy, hash2point { x=>0, y=>-2, xv=>-1.99, yv=>2 }));
   
   #How about where both things are moving?
   #This stuff may look failure-prone, but it actually passes when made orders of magnitude more precise
   #attempt to hit at y=20000, x=10000, t=100
   my $tiny_rect = hash2rect {x=>15000-.0025, y=>30000-.0045, h=>.005, w=>.005, xv=>-50, yv=>-100};
   my $accurate_bullet = hash2point { x=>-40000, y=>80100, xv=>500, yv=> -601};
   my $strange_collision = dynamic_collision ($accurate_bullet, $tiny_rect, interval=>400);
   ok($strange_collision, 'small object at long distance');
   #is ($strange_collision->axis, 'y');
   SKIP: {
      skip 'strange collision didn\'t happen', 1 unless $strange_collision;
      delta_ok ($strange_collision->time, 100, 'time ~ 100');
   }
   
   my $widerect = hash2rect {x=>-100, w=>200, y=>0, h=>1};
   #point from above, moving right. hit at y=1.
   my $ny_pt = hash2point {x=>6,y=>2, xv=>.21212, yv=>-1};
   my $ny_collision = dynamic_collision ($ny_pt, $widerect, interval=>20);
   ok ($ny_collision, 'some now-passing point-rect test');
   is ($ny_collision->time, 1, 'time for now-passing point-rect test');
   
}

#now circle-point collisions. The method is $circle->_collide_point($point,...)
{
   my $pie = hash2circle { x=>0, y=>0, radius=>1 };#the unit pie
   my $raisinH = hash2point { x=>-2, y=>0, xv=>1 };
   my $raisin_collisionH = dynamic_collision($raisinH,$pie, interval=>3);
   delta_ok ($raisin_collisionH->time, 1, 'raisinH hits left side of pie at t=1');
   
   my $raisinV = hash2point { x=>0, y=>5, yv=>-2 };
   my $raisin_collisionV = dynamic_collision($raisinV,$pie, interval=>188);
   delta_ok ($raisin_collisionV->time, 2, 'raisinV hits top side of unit pie at t=2');
   
   my $raisin2 = hash2point { x=>-1, y=>sqrt(3)/2, xv=>1 };
   my $raisin_collision2 = dynamic_collision($raisin2,$pie);
   delta_ok ($raisin_collision2->time, .5, 'raisin hits y=sqrt(3)/2, upper left quadrant of unit pie moving horizontally at t=1/2');
   
   #test points stopping short of hitting unit pie directly, coming from around 5*pi/4 rad
   ok (dynamic_collision ($pie, hash2point { x=>-2, y=>-2, xv=>2.01-sqrt(2)/2, yv=>2.01-sqrt(2)/2 }), 'stop right after collision');
   ok (!dynamic_collision ($pie, hash2point { x=>-2, y=>-2, xv=>1.99-sqrt(2)/2, yv=>1.99-sqrt(2)/2 }), 'stop right before collision');
   
   #test points moving up & to the right
   ok (dynamic_collision ($pie, hash2point { x=>-sqrt(1.99), y=>0, xv=>10, yv=>10 }), 'up&right');
   ok (!dynamic_collision ($pie, hash2point { x=>-sqrt(2.01), y=>0, xv=>10, yv=>10 }));
   ok (dynamic_collision ($pie, hash2point { y=>-sqrt(1.99), x=>0, xv=>10, yv=>10 }));
   ok (!dynamic_collision ($pie, hash2point { y=>-sqrt(2.01), x=>0, xv=>10, yv=>10 }));
   #test points moving up & to the left
   ok (dynamic_collision ($pie, hash2point { x=>sqrt(1.99), y=>0, xv=>-10, yv=>10 }), 'up&left');
   ok (!dynamic_collision ($pie, hash2point { x=>sqrt(2.01), y=>0, xv=>-10, yv=>10 }));
   ok (dynamic_collision ($pie, hash2point { y=>-sqrt(1.99), x=>0, xv=>-10, yv=>10 }));
   ok (!dynamic_collision ($pie, hash2point { y=>-sqrt(2.01), x=>0, xv=>-10, yv=>10 }));
   #test points moving down & to the right
   ok (dynamic_collision ($pie, hash2point { x=>-sqrt(1.99), y=>0, xv=>10, yv=>-10 }), 'down&right');
   ok (!dynamic_collision ($pie, hash2point { x=>-sqrt(2.01), y=>0, xv=>10, yv=>-10 }));
   ok (dynamic_collision ($pie, hash2point { y=>sqrt(1.99), x=>0, xv=>10, yv=>-10 }));
   ok (!dynamic_collision ($pie, hash2point { y=>sqrt(2.01), x=>0, xv=>10, yv=>-10 }));
   #test points moving down & to the left
   ok (dynamic_collision ($pie, hash2point { x=>sqrt(1.99), y=>0, xv=>-10, yv=>-10 }), 'down&left');
   ok (!dynamic_collision ($pie, hash2point { x=>sqrt(2.01), y=>0, xv=>-10, yv=>-10 }));
   ok (dynamic_collision ($pie, hash2point { y=>sqrt(1.99), x=>0, xv=>-10, yv=>-10 }));
   ok (!dynamic_collision ($pie, hash2point { y=>sqrt(2.01), x=>0, xv=>-10, yv=>-10 }));
}

#Now do circle collisions!
{
   my $unitpie = hash2circle {x=>0, y=>0, };
   my $doomdisk = hash2circle {x=>-12, y=>0, xv=>5};
   my $collision = dynamic_collision($unitpie, $doomdisk, interval=>3);
   ok ($collision, 'unitpie hits doomdisk'); 
   my $rv_collision = dynamic_collision($doomdisk, $unitpie, interval=>3);
   ok($rv_collision, 'doomdisk hits unitpie');
   delta_ok ($collision->time, 2);
   delta_ok ($rv_collision->time, 2);
   ok ($collision->axis->[0] < 0);
   ok ($rv_collision->axis->[0] > 0);
   is ($collision->axis->[1], 0);
   is ($rv_collision->axis->[1], 0);
   
   #again, barely hit pie, and then barely stop short. from upper left.
   my $collisionX = dynamic_collision ($unitpie, hash2circle({ x=>-10, y=>10, xv=>1, yv=>-1}), interval=>10-sqrt(1.99));
   ok($collisionX, 'stop right after collision');
   delta_ok ($collisionX->time, 10-sqrt(2));
   ok (!dynamic_collision ($unitpie, hash2circle({ x=>-10, y=>10, xv=>1, yv=>-1}), interval=>10-sqrt(2.01)),
      'stop right before collision');
   
}

#now do circle-rect collisions!
{
   my $cannonball = hash2circle {x=>-5.5, y=>0, xv=>16, radius=>.5};
   my $unit_toast = hash2rect { x=>-1, y=>-1, w=>2,h=>2 };
   my $collision = dynamic_collision ($cannonball, $unit_toast, interval=>100);
   ok($collision, 'cannontoast collision exists');
   delta_ok ($collision->time, 1/4);
   is ($collision->axis, 'x', 'horizontal collision');
   #is_deeply (normalize_vec $collision->axis, [0,1]);
   
   # top directly
   my $ball2 = hash2circle {x=>0, y=>5.5, yv=>-16, radius=>.5};
   my $collision2 = dynamic_collision ($ball2, $unit_toast, interval=>100);
   ok($collision2);
   delta_ok ($collision2->time, 1/4);
   is ($collision2->axis, 'y', 'vertical collision');
   # right directly
   my $ball3 = hash2circle {x=>5.5, y=>0, xv=>-16, radius=>.5};
   my $collision3 = dynamic_collision ($ball3, $unit_toast, interval=>100);
   ok($collision3);
   delta_ok ($collision3->time, 1/4);
   is ($collision3->axis, 'x', 'h collision');
   # bottom directly
   my $ball4 = hash2circle {x=>0, y=>-5.5, yv=>16, radius=>.5};
   my $collision4 = dynamic_collision ($ball4, $unit_toast, interval=>100);
   ok($collision4);
   delta_ok ($collision4->time, 1/4);
   is ($collision4->axis, 'y', 'vertical collision');
}
   #those didn't test the corners of the square with diagonal parts of the circle. these do:
{
   my $unitpie = hash2circle {x=>0, y=>0};
   my $money = hash2rect {x=> (sqrt(2)/2 + 3), y=> (sqrt(2)/2 + 3),   xv=>-1, yv=>-1, w=>2, h=>2};
   my $collision = dynamic_collision ($unitpie, $money, interval=>3.01);
   ok ($collision, 'rect (0,0) point collides with circle');
   delta_ok ($collision->time, 3, 'at right time');
   delta_ok (normalize_vec($collision->axis)->[0], -sqrt(2)/2,  'collision vector x ok');
   delta_ok (normalize_vec($collision->axis)->[1], -sqrt(2)/2,  'collision vector y ok');
   
   my $rect2 = hash2rect {x=> -(sqrt(2)/2 + 3), y=> -(sqrt(2)/2 + 3),   xv=>1, yv=>1, w=>2, h=>2};
   $collision = dynamic_collision ($unitpie, $rect2, interval=>1.01);
   ok ($collision, 'rect (2,2) point collides with circle');
   delta_ok ($collision->time, 1, 'at right time');
   
   my $rect3 = hash2rect {x=> (sqrt(2)/2 + 1), y=> -(sqrt(2)/2 + 3),   xv=>-1, yv=>1, w=>2, h=>2};
   $collision = dynamic_collision ($unitpie, $rect3, interval=>2);
   ok ($collision, 'rect (2,0) point (lower-right) collides with circle');
   delta_ok ($collision->time, 1, 'at right time');
   
   my $rect4 = hash2rect {x=> -(sqrt(2)/2 + 3), y=> (sqrt(2)/2 + 1),   xv=>1, yv=>-1, w=>2, h=>2};
   $collision = dynamic_collision ($unitpie, $rect3, interval=>2);
   ok ($collision, 'rect (0,2) point (upper left-right) collides with circle');
   delta_ok ($collision->time, 1, 'at right time');
}

{ #null collisions anyone?
   my $unitpie = hash2circle { x=>0, y=>0, radius=>1 };#the unit pie
   
   #barely touching at start; using this to test null collision of rect corner
   my $touching = hash2rect {x=> (sqrt(2)/2 - .01), y=> (sqrt(2)/2 - .01),   xv=>-1, yv=>-1, w=>2, h=>2};
   my $null_c = dynamic_collision ($unitpie, $touching, interval=>4444);
   ok ($null_c, 'rect(corner)-circle null collision');
   is ($null_c->time, 0, 'null collision at t=0');
   #not touching
   my $not_touching = hash2rect {x=> (sqrt(2)/2 + .01), y=> (sqrt(2)/2 + .01),   xv=>1, yv=>1, w=>2, h=>2};
   ok(!dynamic_collision ($unitpie, $not_touching, interval=>1.01));
   
   #barely touching again; now test null collision of rect side
   my $touching2 = hash2rect {x=> 0, y=> -1.99,   xv=>1, yv=>1};
   my $null_c2 = dynamic_collision ($unitpie, $touching2, interval=>4444);
   ok ($null_c2, 'rect(side)-circle null collision');
   is ($null_c2->time, 0, 'null collision at t=0');
   #not touching
   my $not_touching2 = hash2rect {x=> 0, y=> 1.01,   xv=>1, yv=>1};
   ok(!dynamic_collision ($unitpie, $not_touching2, interval=>1.01));
   
   #where no corner/side points are inside the other!
   my $imposition = hash2rect {x=> -.99, y=>-.99, h=>1.98, w=>1.98};
   ok(dynamic_collision ($unitpie, $imposition));
   ok ($unitpie->intersect_rect($imposition));
}

#rect-rect collisions anyone?
{
   my $square1 = hash2rect {x=>-1, y=>-1, h=>2,w=>2};
   my $square2 = hash2rect {x=>-4, y=>0, h=>2,w=>2, xv=>1};
   $square2->normalize($square1);
   $square1->normalize($square2);
   #horizontal:
   my $collision = $square1->_collide_rect($square2, interval=>2);
   ok($collision, 'squares collide h1');
   delta_ok($collision->time, 1, 'squares collide at t=1');
   is($collision->axis, 'x', 'vcollide axis is x');
   $collision = $square2->_collide_rect($square1, interval=>2);
   ok($collision, 'squares collide h2');
   delta_ok($collision->time, 1, 'squares collide at t=1');
   is($collision->axis, 'x', 'vcollide axis is x');
   
   #vertical:
   my $square3 = hash2rect {x=>0, y=>-4, h=>2,w=>2, yv=>2};
   $square3->normalize($square1);
   $square1->normalize($square3);
   $collision = $square1->_collide_rect($square3, interval=>2);
   ok($collision, 'squares collide v1');
   delta_ok($collision->time, .5, 'squares vcollide at t=.5');
   is($collision->axis, 'y', 'vcollide axis is y');
   $collision = $square3->_collide_rect($square1, interval=>2);
   ok($collision, 'squares collide v2');
   delta_ok($collision->time, .5, 'squares vcollide at t=.5');
   is($collision->axis, 'y', 'vcollide axis is y');
   
   my $foomiss = hash2rect {x=>-3.1+6, y=>-3-6, h=>2,w=>2, xv=>-6, yv=>6};
   my $foohit = hash2rect {x=>-2.9+6, y=>-3-6, h=>2,w=>2, xv=>-6, yv=>6};
   my $barmiss = hash2rect {y=>-3.1+6, x=>-3-6, h=>2,w=>2, yv=>-6, xv=>6};
   my $barhit = hash2rect {y=>-2.9+6, x=>-3-6, h=>2,w=>2, yv=>-6, xv=>6};
   #diagonally passing and/or colliding
   ok (dynamic_collision ($square1, $foohit), 'rectrect diag hit');
   ok (!dynamic_collision ($square1, $foomiss), 'rectrect diag miss');
   ok (dynamic_collision ($square1, $barhit), 'rectrect diag hit');
   ok (!dynamic_collision ($square1, $barmiss), 'rectrect diag miss');
}

#bad circle-rect behavior is apparent in marble.pl
#it looks like corner points interfere when they shouldn't,
#  when circle is near corner
{
   my $rect = hash2rect {x=>200, y=>200, w=>150, h=>70};
   
   for (1..20){
      my $circ = hash2circle {x=>200+$_, y=>155, radius=>30, yv=>15};
      my $collision = dynamic_collision ($rect, $circ, interval=>2);
      #warn ("x=".(200+$_));
      delta_ok ($collision->time, 1);
      #warn join ',',@{normalize_vec($collision->vaxis)};
      is_deeply (normalize_vec($collision->vaxis), [0,1]);
   }
}


#my $grid_environment = Collision::Util::Grid->new (stuff=>things);

#let's say myrtle doesn't intersect any blocks in this environment.
#ok (!dynamic_collision($myrtle, $grid_environment));

#but this bullet hits a block in 1st frame or second.
#my $collision3 = dynamic_collision ($extreme_bullet, $grid_environment, interval=>1);

