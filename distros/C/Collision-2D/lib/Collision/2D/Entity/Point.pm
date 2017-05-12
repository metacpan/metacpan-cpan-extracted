package Collision::2D::Entity::Point;
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader Collision::2D::Entity);
bootstrap Collision::2D::Entity::Point;


sub _p{3} #meh priority
use overload '""'  => sub{'point'};
sub typename{'point'}

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
   );
   return $self;
}

#I daresay, 2 points mayn't collide
sub _collide_point{
   return;
}


#Here, $self is assumed to be normalized.

sub _collide_rect{
   my ($self, $rect, %params) = @_;
   #if we start inside rect, return the null collision, so to speak.
   #if ($rect->contains_point($self)){
   #   return $self->null_collision($rect)
   #}
   #this line segment is path of point during this interval
   my $x1 = $self->relative_x;
   my $x2 = $x1 + ($self->relative_xv * $params{interval});
   my $y1 = $self->relative_y;
   my $y2 = $y1 + ($self->relative_yv * $params{interval});
   my $w = $rect->w;
   my $h = $rect->h;
   
   #if it contains point at t=0, relatively...
   if (  $x1>0 and $x1<$w
     and $y1>0 and $y1<$h){
      return $self->null_collision($rect);
   }
   else{
      #start outside box, so return if no relative movement 
      return unless $params{interval} and ($self->relative_x or $self->relative_y);
   }
   unless ($self->relative_xv){ #no horizontal movement. Don't worry about inverting, it's easy.
      return unless ($x1 > 0 and $x1 < $w);
      my $t;
      if ($y1 < 0 and $y2 > 0){
         $t = -$y1 / $self->relative_yv;
      } elsif ($y1 > $h and $y2 < $h){
         $t = ($y1-$h) / -$self->relative_yv;
      }else {
         return
      }
      return Collision::2D::Collision->new(
         time => $t,
         axis => 'y',
         ent1 => $self,
         ent2 => $rect,
      );
   }
   
   #now see if point starts and ends on one of 4 sides of this rect.
   #probably worth it because most things don't collide with each other every frame
   if ($x1 > $w and $x2 > $w ){
      return
   }
   if ($x1 < 0 and $x2 < 0){
      return
   }
   if ($y1 > $h and $y2 > $h ){
      return
   }
   if ($y1 < 0 and $y2 < 0){
      return
   }
   
   #not that simple. either it enters rect, or passes by a corner. check each rect line segment.
   my ($best_time, $best_axis);
   if ($self->relative_xv){
      if ($x1 < 0 and $x2 > 0){ # horizontally pass rect's left side
         my $t = (-$x1) / $self->relative_xv;
         my $y_at_t = $y1 + ($t * $self->relative_yv);
         if ($y_at_t < $h  and  $y_at_t > 0) {
            $best_time = $t;
            $best_axis = 'x';
         }
      }
      elsif ($x1 > $w and $x2 < $w){ #horizontally pass rect's right side
         my $t = ($x1 - $w) / -$self->relative_xv;
         my $y_at_t = $y1 + ($t * $self->relative_yv);
         if ($y_at_t < $h  and  $y_at_t > 0) {
            $best_time = $t;
            $best_axis = 'x';
         }
      }
   }
   if ($self->relative_yv){
      if ($y1 < 0 and $y2 > 0){ #vertically pass rect's lower side
         my $t = (-$y1) / $self->relative_yv;
         if (!defined($best_time) or $t < $best_time){
            my $x_at_t = $x1 + ($t * $self->relative_xv);
            if ($x_at_t < $w  and  $x_at_t > 0) {
               $best_time = $t;
               $best_axis = 'y';
            }
         }
      }
      elsif ($y1 > $h and $y2 < $h){ #vertically pass rect's upper side
         my $t = ($y1 - $h) / -$self->relative_yv;
         if (!defined($best_time) or $t < $best_time){
            my $x_at_t = $x1 + ($t * $self->relative_xv);
            if ($x_at_t < $w  and  $x_at_t > 0) {
               $best_time = $t;
               $best_axis = 'y';
            }
         }
      }
   }
   return unless $best_axis;
   return Collision::2D::Collision->new(
      time => $best_time,
      axis => $best_axis,
      ent1 => $self,
      ent2 => $rect,
   );
}

2

__END__
=head1 NAME

Collision::2D::Entity::Rect - A Point entity.

=head1 DESCRIPTION

This is a point entity.
Attributes (x, y) are the location of this point. See L<Collision::2D::Entity>.

Points can not collide with other points. Use a very small circle instead.

=head1 ATTRIBUTES

Anything in L<Collision::2D::Entity>.

=head1 METHODS

Anything in L<Collision::2D::Entity>.

=head2 collide

See L<< Collision::2D::Entity->collide|Collision::2D::Entity/collide >>

 print 'boom' if $point->collide($rect);
 print 'zing' if $point->collide($circle);
 print 'yotz' if $point->collide($grid);
 
=head2 intersect

See L<< Collision::2D::Entity->intersect|Collision::2D::Entity/intersect >>

 print 'bam' if $point->intersect($rect);
 # etc..
