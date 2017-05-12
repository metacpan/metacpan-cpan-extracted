package Collision::2D::Entity::Circle;
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader Collision::2D::Entity);
bootstrap Collision::2D::Entity::Circle;

#in a circle, x and y denote center. 

sub _p{2} #highish priority
use overload '""'  => sub{'circle'};
sub typename{'circle'}


sub new{
   my ($package, %params) = @_;
   my $self = __PACKAGE__->_new (
      $params{x} || 0,
      $params{y} || 0,
      $params{xv} || 0,
      $params{yv} || 0,
      $params{relative_x} || 0,
      $params{relative_y} || 0,
      $params{relative_xv} || 0,
      $params{relative_yv} || 0,
      $params{radius},
   );
   return $self;
}


sub intersect_circle{
   my ($self, $other) = @_;

   #sqrt is more expensive than square
   return  ($self->radius + $other->radius)**2 > 
         ($self->x - $other->x)**2 + 
         ($self->y - $other->y)**2;
}


sub intersect_point{
   my ($self, $point) = @_;
   return   $self->radius**2 >
         ($self->x - $point->x)**2 + 
         ($self->y - $point->y)**2;
}

#both stationary
sub intersect_rect{
   my ($self, $rect) = @_;
   my $r = $self->radius;
   my $w = $rect->w;
   my $h = $rect->h;
   my $x = $self->x - $rect->x; #of self, relative to rect!
   my $y = $self->y - $rect->y; #of self, relative to rect!
   
   
   if   ($x-$r > $w
      or $y-$r > $h
      or $x+$r < 0
      or $y+$r < 0){
         #warn "$x $y   w: $w, h: $h, r: $r";
         return 0
   }
   return 1 if ($x**2 + $y**2) < $r**2;
   return 1 if (($x-$w)**2 + $y**2) < $r**2;
   return 1 if (($x-$w)**2 + ($y-$h)**2) < $r**2;
   return 1 if ($x**2 + ($y-$h)**2) < $r**2;
   #detect 'imposition', whereall corner+side points are outside the other entity
   return 1 if (($x-$w/2)**2 + ($y-$h/2)**2) < $r**2;
   
   for ([$x,$y-$r], [$x-$r,$y], [$x,$y+$r], [$x+$r,$y]){
      my ($x,$y) = @$_;
      return 1 if $x>0 and $y>0
              and $x<$w and $y<$h;
   }
   return 0;
}

sub _collide_rect{
   my ($self, $rect, %params) = @_;
   my @collisions;
   
   #my doing this we can consider $self to be stationary and $rect to be moving.
   #this line segment is path of rect during this interval
   my $r = $self->radius;
   my $w = $rect->w;
   my $h = $rect->h;
   my $x1 = -$self->relative_x; #of rect!
   my $x2 = $x1 - ($self->relative_xv * $params{interval});
   my $y1 = -$self->relative_y;
   my $y2 = $y1 - ($self->relative_yv * $params{interval});
   
   #now see if point starts and ends on one of 4 sides of this rect.
   #probably worth it because most things don't collide with each other every frame
   if ($x1 > $r and $x2 > $r ){
      return
   }
   if ($x1+$w < -$r and $x2+$w < -$r){
      return
   }
   if ($y1 > $r and $y2 > $r ){
      return
   }
   if ($y1+$h < -$r and $y2+$h < -$r){
      return
   }
   if (($x1+$w/2)**2 + ($y1+$h/2)**2 < $r**2) { #imposition?
      return $self->null_collision($rect);
   }
   
   #which of rect's 4 points should I consider?
 #  my @start_pts = ([$x1, $y1], [$x1+$w, $y1], [$x1+$w, $y1+$h], [$x1, $y1+$h]);
 #  my @end_pts = ([$x2, $y2], [$x2+$w, $y2], [$x2+$w, $y2+$h], [$x2, $y2+$h]);
   my @pts = (
      {x1 => $x1,    y1 => $y1},
      {x1 => $x1+$w, y1 => $y1},
      {x1 => $x1+$w, y1 => $y1+$h},
      {x1 => $x1,    y1 => $y1+$h},
   );
   for (@pts){ #calc initial distance from center of circle
      $_->{dist} = sqrt($_->{x1}**2 + $_->{y1}**2);
   }
   my $origin_point = Collision::2D::Entity::Point->new(
     # x => 0,y => 0, #actually not used, since circle is normalized with respect to the point
   );
   @pts = sort {$a->{dist} <=> $b->{dist}} @pts;
   #now detect null collision of closest rect corner
   if (0 and $pts[0]{dist} < $r){
      return $self->null_collision($rect)
   }
   for (@pts[0,1,2]){ #do this for 3 initially closest rect corners
      my $new_relative_circle = Collision::2D::Entity::Circle->new(
        # x => 0,y => 0, # used
         relative_x =>  $_->{x1},
         relative_y =>  $_->{y1},
         relative_xv => -$self->relative_xv,
         relative_yv => -$self->relative_yv,
         radius => $self->radius,
      );
      my $collision = $new_relative_circle->_collide_point ($origin_point, interval=>$params{interval});
      next unless $collision;
      #$_->{collision} = 
      push @collisions, Collision::2D::Collision->new(
         axis => $collision->axis,
         time => $collision->time,
         ent1 => $self,
         ent2 => $rect,
      );
   }
   #return unless @collisions;
   #@collisions = sort {$a->time <=> $b->time} @collisions;
   #return $collisions[0] if defined $collisions[0];
   
   # that looked at the rect corners. that was half of it. 
   # now look for collisions between a side of the circle
   #  and a side of the rect
   my @circ_points; #these are relative coordinates to rect
   if ($x1+$w < -$r  and  $x2+$w > -$r){
      #add circle's left point
      push @circ_points, [-$x1-$r,-$y1];
   }
   if ($x1 > $r  and  $x2 < $r){
      #add circle's right point
      push @circ_points, [-$x1+$r,-$y1];
   }
   if ($y1+$h < -$r  and  $y2+$h > -$r ){
      #add circle's bottom point
      push @circ_points, [-$x1,-$y1-$r];
   }
   if ($y1 > $r  and  $y2 < $r){
      #add circle's top point
      push @circ_points, [-$x1,-$y1+$r];
   }   #   warn @{$circ_points[0]};
   for (@circ_points){
      my $rpt = Collision::2D::Entity::Point->new(
         relative_x => $_->[0],
         relative_y => $_->[1],
         relative_xv => $self->relative_xv,
         relative_yv => $self->relative_yv,
      );
      my $collision = $rpt->_collide_rect($rect, interval=>$params{interval});
      next unless $collision;
      push @collisions, new Collision::2D::Collision(
         time => $collision->time,
         axis => $collision->axis,
         ent1 => $self,
         ent2 => $rect,
      );
   }
   return unless @collisions;
   @collisions = sort {$a->time <=> $b->time} @collisions;
   #warn join ',', @collisions;
   return $collisions[0]
}




#ok, so normal circle is sqrt(x**2+y**2)=r
#and line is y=mx+b (invert line if line is vertical)
#to find their intersection on the x axis,
# sqrt(x**2 + (mx+b)**2) = r
#  x**2 + (mx)**2 + mxb + b**2 = r**2
#   (m**2+1)x**2 + (2mb)x + (b**2-r**2) = 0.
#solve using quadratic equation
# A=m**2+1
# B=2mb
# C=b**2-r**2
# roots (where circle intersects on the x axis) are at
# ( -B ± sqrt(B**2 - 4AC) ) / 2A
#Then, see which intercept, if any, is the closest after starting point
sub _collide_point{
   my ($self, $point, %params) = @_;
   #x1,etc. is the path of the point, relative to $self.
   #it's probably easier to consider the point as stationary.
   my $x1 = -$self->relative_x;
   my $y1 = -$self->relative_y;
   my $x2 = $x1 - $self->relative_xv * $params{interval};
   my $y2 = $y1 - $self->relative_yv * $params{interval};
   
   if (($x1**2 + $y1**2) < $self->radius**2) {
      return $self->null_collision($point);
   }
   
   if ($x2-$x1 == 0  or  abs(($y2-$y1)/($x2-$x1)) > 100) { #a bit too vertical for my liking. so invert.
      if ($y2-$y1 == 0){ #relatively motionless.
         return
      }
      ($x1, $y1) = ($y1,$x1);
      ($x2, $y2) = ($y2,$x2);
   }
   
   #now do quadratic
   my $slope = ($y2-$y1)/($x2-$x1);
   my $y_intercept = $y1 - $slope*$x1;
   my $A = $slope**2 + 1; #really?
   my $B = 2 * $slope*$y_intercept;
   my $C = $y_intercept**2 - $self->radius**2;
   my @xi; #x component of intersections.
   my $blah = $B**2 - 4*$A*$C;
   return unless $blah>0;
   $blah = sqrt($blah);
   push @xi, (-$B + $blah ) / (2*$A);
   push @xi, (-$B - $blah ) / (2*$A);
   #keep intersections within segment
   @xi = grep {($_>=$x1 and $_<=$x2) or ($_<=$x1 and $_>=$x2)} @xi;
   #sort based on closeness to starting point.
   @xi = sort {abs($a-$x1) <=> abs($b-$x1)} @xi;
   return unless defined $xi[0];
   
   #get away from invertedness
   my $time = $params{interval} * ($xi[0]-$x1) / ($x2-$x1);
   my $x_at_t = $self->relative_x + $self->relative_xv*$time;
   my $y_at_t = $self->relative_y + $self->relative_yv*$time;
   my $axis = [-$x_at_t, -$y_at_t]; #vector from self to point
   
   my $collision = Collision::2D::Collision->new(
      time => $time, axis => $axis,
      ent1 => $self,
      ent2 => $point,
   );
   return $collision;
}

#Say, can't we just use the point algorithm by transferring the radius of one circle to the other?
sub _collide_circle{
   my ($self, $other, %params) = @_;
   my $double_trouble = Collision::2D::Entity::Circle->new(
      relative_x => $self->relative_x,
      relative_y => $self->relative_y,
      relative_xv => $self->relative_xv,
      relative_yv => $self->relative_yv,
      radius => $self->radius + $other->radius,
      #y=>0,x=>0, #these will not be used, as we're doing all relative calculations
   );
   
   my $pt = Collision::2D::Entity::Point->new(
      #y=>44,x=>44, #these willn't be used, as we're doing all relative calculations
   );
   my $collision = $double_trouble->_collide_point($pt, %params);
   return unless $collision;
   
   return Collision::2D::Collision->new(
      ent1 => $self,
      ent2 => $other,
      time => $collision->time,
      axis => $collision->axis,
      #axis => [-$collision->axis->[0], -$collision->axis->[1]],
   );
}

1

__END__
=head1 NAME

Collision::2D::Entity::Circle - A circle entity.

=head1 DESCRIPTION

This is an entity with a radius.
Attributes x and y point to the center of the circle.

=head1 ATTRIBUTES

=head2 radius

Each point on the circle is this distance from the center, at C<< ($circ->x, $circ->y) >>

=head1 METHODS

Anything in L<Collision::2D::Entity>.

=head2 collide

See L<< Collision::2D::Entity->collide|Collision::2D::Entity/collide >>

 print 'boom' if $circle->collide($rect);
 print 'zing' if $circle->collide($circle);
 print 'yotz' if $circle->collide($grid);
 
=head2 intersect

See L<< Collision::2D::Entity->intersect|Collision::2D::Entity/intersect >>

 print 'bam' if $circle->intersect($rect);
 # etc..



