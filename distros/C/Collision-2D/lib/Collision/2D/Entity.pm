package Collision::2D::Entity;
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader);
bootstrap Collision::2D::Entity;

sub typename{'entity'}


#an actual collision at t=0; 
sub null_collision{
   my $self = shift;
   my $other = shift;
   return Collision::2D::Collision->new(
      time => 0,
      ent1 => $self,
      ent2 => $other,
   );
}

sub intersect{
   my ($self, @others) = @_;
   for (@others){
      return 1 if Collision::2D::intersection ($self, $_);
   }
   return 0;
}

sub collide{
   my ($self, $other, %params) = @_;
   $params{keep_order} = 1;
   return Collision::2D::dynamic_collision ($self, $other, %params);
}

sub new{die}
1

__END__
=head1 NAME

Collision::2D::Entity - A moving entity. Don't use this directly.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 x,y,xv,yv

Absolute position and velocity in space.
These are necessary if you want to do collisions through 
L<dynamic_collision|Collision::2D/dynamic_collision>

 dynamic_collision($circ1, $circ2);

=head2 relative_x, relative_y, relative_xv, relative_yv

You shouldn't worry about these. Move along now.

Relative position and velocity in space.
these are necessary if you want to do collisions directly through entity methods,

 $circ1->_collide_circle($circ2);

In this case, both the absolute and relative position and velocity of $circ2
is not used. The relative attributes of $circ1 are assumed to be relative to $circ2.


=head1 METHODS

=head2 collide

 my $collision = $self->collide ($other_entity, interval=>4);

Detect collision with another entity. $self must be normalized to $other.
Takes interval as a parameter. Returns a collision if there is a collision.
Returns undef if there is no collision.

With the collide method, the entity order is preserved.
Consider this example:

 my $collision1 = $panel->collide($droplet);
 my $collision2 = $droplet->collide($panel);

If these objects collide, then its C<$collision1->ent1> will be C<$panel>, and
C<$collision2->ent1> will be C<$droplet>.

=head2 intersect

 my $t_or_f = $self->intersect ($other_entity, interval=>2.5);

Detect intersection (overlapping) with another entity.
Takes interval as a parameter. Returns a collision if there is a collision.
Returns undef if there is no collision.

C<interval> is optional. C<interval> is 1 by default.

Relative vectors and velocity are not considered for intersection.

=head2 normalize

You probably shouldn't use this directly. At all. 
Relative vectors are handled automatically
in C<dynamic_collision> and in  C<$ent1->collide($ent2)>

 $self->normalize($other); # $other isa entity

This compares the absolute attributes of $self and $other.
It only sets the relative attributes of $self.
This is necessary to call _collide_*($other) methods on $self.
