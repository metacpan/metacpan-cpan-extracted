package Collision::2D;
use 5.010_000;
use warnings;
use strict;

use Collision::2D::Collision;
use Collision::2D::Entity;
use Collision::2D::Entity::Point;
use Collision::2D::Entity::Rect;
use Collision::2D::Entity::Circle;
use Collision::2D::Entity::Grid;

BEGIN {
   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT_OK = qw( 
      dynamic_collision
      intersection
      hash2point hash2rect
      obj2point  obj2rect
      hash2circle obj2circle
      normalize_vec
      hash2grid
   );
   our %EXPORT_TAGS = (
      all => \@EXPORT_OK,
      #std => [qw( check_contains check_collision )],
   );
}

our $VERSION = '0.07';

sub dynamic_collision{
   my ($ent1, $ent2, %params) = @_;
   $params{interval} //= 1;
   
   #if $obj2 is an arrayref, do this for each thing in @$obj
   # and return all collisions, starting with the closest
   if (ref $ent2 eq 'ARRAY'){
      my @collisions = map {dynamic_collision($ent1,$_,%params)} @$ent2;
      return sort{$a->time <=> $b->time} grep{defined$_} @collisions;
   }
   
   #now, we sort by package name. This is so we can find specific routine in predictable namespace.
   #for example, p comes before r, so point-rect collisions are at $point->_collide_rect
   my $swapped;
   if  ($ent1->_p > $ent2->_p ){
      ($ent1, $ent2) =  ($ent2, $ent1);
      $swapped=1
   }
   my $method = "_collide_$ent2";
   
   $ent1->normalize($ent2);
   my $collision = $ent1->$method($ent2, %params);
   return unless $collision;
   if ($params{keep_order} and $swapped){
      #original ent1 needs to be ent1 in collision
      return $collision->invert;
   }
   return $collision;
}

sub intersection{
   my ($ent1, $ent2) = @_;
   if (ref $ent2 eq 'ARRAY'){
      for (@$ent2){
         return 1 if intersection($ent1, $_);
      }
      return 0;
   }
   ($ent1, $ent2) =  ($ent2, $ent1)  if  ($ent1->_p > $ent2->_p );
   my $method = "intersect_$ent2";
   
   return 1 if $ent1->$method($ent2);
   return 0;
}

sub normalize_vec{
   my ($x,$y) = @{shift()};
   my $r = sqrt($x**2+$y**2);
   return [$x/$r, $y/$r]
}

sub hash2point{
   my $hash = shift;
   return Collision::2D::Entity::Point->new (
      x=>$hash->{x},
      y=>$hash->{y},
      xv=>$hash->{xv},
      yv=>$hash->{yv},
   );
}
sub hash2rect{
   my $hash = shift;
   return Collision::2D::Entity::Rect->new (
      x=>$hash->{x},
      y=>$hash->{y},
      xv=>$hash->{xv},
      yv=>$hash->{yv},
      h=>$hash->{h} || 1,
      w=>$hash->{w} || 1,
   )
}
sub obj2point{
   my $obj = shift;
   return Collision::2D::Entity::Point->new (
      x=>$obj->x,
      y=>$obj->y,
      xv=>$obj->xv,
      yv=>$obj->yv,
   )
}
sub obj2rect{
   my $obj = shift;
   return Collision::2D::Entity::Rect->new (
      x=>$obj->x,
      y=>$obj->y,
      xv=>$obj->xv,
      yv=>$obj->yv,
      h=>$obj->h || 1,
      w=>$obj->w || 1,
   )
}

sub hash2circle{
   my $hash = shift;
   return Collision::2D::Entity::Circle->new (
      x=>$hash->{x},
      y=>$hash->{y},
      xv=>$hash->{xv},
      yv=>$hash->{yv},
      radius => $hash->{radius} || $hash->{r} || 1,
   )
}

sub obj2circle{
   my $obj = shift;
   return Collision::2D::Entity::Circle->new (
      x=>$obj->x,
      y=>$obj->y,
      xv=>$obj->xv,
      yv=>$obj->yv,
      radius => $obj->radius || 1,
   )
   
}

# x and y are be derivable from specified number of $cells?
#w < cell_size * cells_w
#cells_w > cell_size / w
#cells: both cells_x and cells_y. this means that you want this grid to be square.

# do what? do + dimensions even need to be constrained?
sub hash2grid{
   my $hash = shift;
   my ($cell_size, $w, $h, $x, $y, $cells, $cells_x, $cells_y) 
      = @{$hash}{qw/cell_size w h x y cells cells_x cells_y/};
   die 'where?' unless defined $y and defined $x;
   die 'require cell_size' unless $cell_size;
   
   if ($cells) {
      $w = $cell_size * $cells_x;
      $h = $cell_size * $cells_y;
   }
   else{
      if ($cells_x) {
         $w = $cell_size * $cells_x;
      }
      if ($cells_y){
         $h = $cell_size * $cells_y;
      }
   }
   die 'require some form of w and h' unless $w and $h;
   
   return Collision::2D::Entity::Grid->new (
      x=>$x,
      y=>$y,
      w=>$w,
      h=>$h,
      cell_size => $cell_size,
   );
}


q|positively|
__END__
=head1 NAME

Collision::2D - Continuous 2d collision detection

=head1 SYNOPSIS

  use Collision::2D ':all';
  my $rect = hash2rect ({x=>0, y=>0, h=>1, w=>1});
  my $circle = hash2circle ({x=>0, y=>0, radius => 1});
  my $collision = dynamic_collision ($rect, $circle);
  
  #When your geometric objects do not move, it is static.
  #Collision::2D is also capable of dynamic collisions, eith moving entities.
  my $roach = hash2circle ({x=>-1, y=>-12, radius => .08, xv = 3, yv => 22});
  my $food = hash2circle ({x=>0, y=>3, radius => .08, xv=>-6});
  my $co2 = dynamic_collision ($roach, $food);
  if ($co2){
     print "collision is at t=" . $co2->time . "\n"
     print "axis of collision is (" . join(',', @{$co2->axis}) .")\n";
  }
  
  #we can also detect whether points collide with circles and rects. 
  #these entities collide at around y=20000, x=10000, t=100:
  my $tiny_rect = hash2rect {x=>15000-.00005, y=>30000-.00005, h=>.0001, w=>.0001, xv=>-50, yv=>-100};
  my $accurate_bullet = hash2point { x=>-40000, y=>80100, xv=>500, yv=> -601};
  my $strange_collision = dynamic_collision ($accurate_bullet, $tiny_rect, interval=>400);

=head1 DESCRIPTION

Collision::2D contains sets of several geometrical classes to help you model dynamic (continuous)
collisions in your programs. It is targeted for any game or other application that requires
dynamic collision detection between moving circles, rectangles, and points.

=head2 WHY

Typically, collision detection in games and game libraries tends to be static. 
That is, they only detect overlap of motionless polygons.  
This is somewhat simple, but naive, because often the developer may want a
description of the
collision, so that he may implement a response.

Supply Collision::2D with any 2 moving entities
(L<rects|Collision::2D::Entity::Rect>, 
L<circles|Collision::2D::Entity::Circle>, and 
L<points|Collision::2D::Entity::Point>)
and an interval of time and it will return a Collision::2D::Collision object.
This $collision has attributes ->time and ->axis, which describe when and how the collision took place.

=head2 HOW

Initially, I implemented point-rect and point-circle. I used these to compose the other types of detection.

Circle-circle is just an extension of point-circle, and it reduces to a single 
point-circle detection.

Circle-rect and may use a bunch of calls to point-collision routines. This is a worst case, though.
If both entities stay entirely separate on either dimension, no such calculation is required.
If they intersect at t=0, it returns the null collision, with no axis involved.

Rect-rect operates independently of point operations.

In any case, if one entity is observed to remain on one side of the other, then
we can be certain that they don't collide.

=head1 FUNCTIONS

=over

=item dynamic_collision

Detects collisions between 2 entities. The entities may be any combination
of rects, circles, and points. You may specify a time interval as an keyed parameter.
By default, the interval is 1.

 my $circle = hash2circle ({x=>0, y=>0, yv => 1, radius => 1});
 my $point = hash2point ({x=>0, y=>-2, yv => 2});
 my $collision = dynamic_collision ($circle, $point, interval => 4);
 #$collision->time == 1. More on that in L<Collision::2D::Collision>.
 #$collision->axis ~~ [0,1] or [0,-1]. More on that in L<Collision::2D::Collision>.

=item intersection

 print 'whoops' unless intersection ($table, $pie);

Detects overlap between 2 entities. This is similar to dynamic_collision,
except that time and motion is not considered. intersection() does not return a
L<Collision::2D::Collision>, but instead true or false values.

=item hash2circle, hash2point, hash2rect

 my $circle = hash2circle ({x=>0, y=>0, yv => 1, radius => 1});

These takes a hash reference, and return the appropriate entity.
The hash typically includes absolute coordinates and velocities.
For hash2circle, it takes radius.
For hash2rect, it takes h and w.

=item obj2circle, obj2point, obj2rect

 my $circle = hash2circle ($game_sprite);

These takes an object with the appropriate methods and return the appropriate entity.
C<< ->x(), ->y(), ->xv(), and ->yv() >> must be callable methods of the $object.
For C<obj2circle>, it takes radius.
For C<obj2rect>, it takes h and w.

=item normalize_vec

Normalize your 2d vectors

 my $vec = [3,4];
 my $nvec = normalize_vec($vec);
 # $nvec is now [3/5, 4/5]

=back

=head1 EXPORTABLE SYMBOLS

Collision::2D doesn't export anything by default. You have to explicitly 
define function names or use the :all tag.

=head1 TODO

 *point-point collisions? Don't expect much if you try it now.
 *either triangles or line segments (or both!) to model slopes.
 *Something that can model walking on mario-style platformers.
 **maybe entities should be linked to whatever entities they stand/walk on?
 **How should entities fit into 'gaps' in the floor that are their exact size?

=head1 CONTRIBUTORS

Zach P. Morgan, C<< <zpmorgan at cpan.org> >>

Stefan Petrea C<< <stefan.petrea@gmail.com> >>

Kartik Thakore C<< <kthakore@cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Many thanks to Breno G. de Oliveira and Kartik Thakore for their help and insights.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
