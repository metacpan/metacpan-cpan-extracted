package Collision::2D::Entity::Rect;
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader Collision::2D::Entity);
bootstrap Collision::2D::Entity::Rect;

sub _p{4} #low priority
use overload '""'  => sub{'rect'};
sub typename{'rect'}

sub new{
   my ($package, %params) = @_;
   my $self = __PACKAGE__->_new (
      @params{qw/x y/},
      $params{xv} || 0,
      $params{yv} || 0,
      $params{relative_x} || 0,
      $params{relative_y} || 0,
      $params{relative_xv} || 0,
      $params{relative_yv} || 0,
      @params{qw/w h/},
   );
   return $self;
}

sub intersect_rect{
   my ($self, $other) = @_;
   return (
               ($self->x < $other->x + $other->w) 
            && ($self->y < $other->y + $other->h) 
            && ($self->x + $self->w > $other->x) 
            && ($self->y + $self->h > $other->y));
}

sub _collide_rect{
   my ($self, $other, %params) = @_;
   my $xv = $self->relative_xv;
   my $yv = $self->relative_yv;
   my $x1 = $self->relative_x;
   my $y1 = $self->relative_y;
   my $x2 = $x1 + ($xv * $params{interval});
   my $y2 = $y1 + ($yv * $params{interval});
   my $sw = $self->w;
   my $sh = $self->h;
   my $ow = $other->w;
   my $oh = $other->h;
   
   #start intersected?
   return $self->null_collision($other) if (
      $y1+$sh > 0 and 
      $x1+$sw > 0 and
      $x1 < $ow and
      $y1 < $oh
   );
   #miss entirely?
   return if ( $x1+$sw < 0 and $x2+$sw < 0
            or $x1 > $ow and $x2 > $ow
            or $y1+$sh < 0 and $y2+$sh < 0
            or $y1 > $oh and $y2 > $oh
   );
   my $best_time = $params{interval}+1;
   my $best_axis;
   
   if ($x1+$sw < 0){ #hit on left of $other
      my $time = -($x1+$sw)/$xv;
      my $yatt = $y1+$yv*$time;
      if ($yatt + $sh > 0 and $yatt < $oh){
         $best_time = $time;
         $best_axis = 'x';
      }
   }
   if ($y1+$sh < 0){ #hit on bottom of $other
      my $time = -($y1+$sh)/$yv;
      if ($time<$best_time){
         my $xatt = $x1+$xv*$time;
         if ($xatt + $sw > 0 and $xatt < $ow){
            $best_time = $time;
            $best_axis = 'y';
         }
      }
   }
   if ($x1 > $ow){ #hit on right of $other
      my $time = -($x1 - $ow)/$xv;
      if ($time<$best_time){
         my $yatt = $y1+$yv*$time;
         if ($yatt + $sh > 0 and $yatt < $oh){
            $best_time = $time;
            $best_axis = 'x';
         }
      }
   }
   if ($y1 > $oh){ #hit on right of $top
      my $time = -($y1 - $oh)/$yv;
      if ($time<$best_time){
         my $xatt = $x1+$xv*$time;
         if ($xatt + $sw > 0 and $xatt < $ow){
            $best_time = $time;
            $best_axis = 'y';
         }
      }
   }
   
   if ($best_time <= $params{interval}){
      return Collision::2D::Collision->new(
         axis => $best_axis,
         time => $best_time,
         ent1 => $self,
         ent2 => $other,
      );
   }
   return;
}

sub contains_point{
   my ($self, $point) = @_;
   return ($point->x > $self->x
      and  $point->y > $self->y
      and  $point->x < $self->x + $self->w
      and  $point->y < $self->y + $self->h);
}

3

__END__
=head1 NAME

Collision::2D::Entity::Rect - A rectangle entity.

=head1 DESCRIPTION

This is an entity with height and width.
Attributes (x, y) is one corner of the rect, whereas (x+w,y+h)
is the opposite corner.

=head1 ATTRIBUTES

=head2 w, h

Width and height of the rectangle.

=head1 METHODS

Anything in L<Collision::2D::Entity>.

=head2 collide

See L<< Collision::2D::Entity->collide|Collision::2D::Entity/collide >>

 print 'boom' if $rect->collide($rect);
 print 'zing' if $rect->collide($circle);
 print 'yotz' if $rect->collide($grid);
 
=head2 intersect

See L<< Collision::2D::Entity->intersect|Collision::2D::Entity/intersect >>

 print 'bam' if $rect->intersect($rect);
 # etc..


