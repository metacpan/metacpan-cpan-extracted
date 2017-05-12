package Collision::2D::Collision;

use strict;
use warnings;
use Carp qw/carp croak confess/;
require DynaLoader;
our @ISA = qw(DynaLoader);
bootstrap Collision::2D::Collision;

#this might be of use for calculating bounce vectors based on axes of collision. 
# http://www.members.shaw.ca/mathematica/ahabTutorials/2dCollision.html

sub new{
   my ($package,%params) = @_;
   return __PACKAGE__->_new (@params{qw/ent1 ent2 time axis/})
}


sub does_mario_defeat_goomba{}

#unless 'elasticity' is a param, assume it's totally elastic
#This just adds a negatively scaled axis of collision
# to the relative velocity
#  (The scalar depends on elasticity and some trig.)
# If 'relative' is param, return that.
# Else use it & ent2 to find the resulting absolute velocity.

#Also, for now we assume that ent2 has infinite mass.
use Math::Trig qw/acos/;

sub bounce_vector{ 
   my ($self,%params) = @_;
   my $elasticity = $params{elasticity} // 1;
   my $axis = $self->vaxis;
   unless ($axis){
      confess 'no bounce vector because no axis.';
      return [0,0];
   }
   
   my $axis_len = sqrt($axis->[0]**2 + $axis->[1]**2);
   my $rxv = $self->ent1->xv - $self->ent2->xv;
   my $ryv = $self->ent1->yv - $self->ent2->yv;
   my $rv_len = sqrt($rxv**2 + $ryv**2);
   my $dot = $rxv*$axis->[0] + $ryv*$axis->[1];
   unless ($rv_len){
      #warn "FOO FOO ". $self->time;
      #warn $rv_len;
      return [0,0];
   }
   my $angle = acos($dot / ($axis_len * $rv_len));
   
   my $axis_scalar = $rv_len * cos($angle) / $axis_len;
   $axis_scalar *= -1 * (1+$elasticity);
   
   my $r_bounce_xv = $rxv + ($axis_scalar * $axis->[0]);
   my $r_bounce_yv = $ryv + ($axis_scalar * $axis->[1]);
   
   if ($params{relative}){
      return [$r_bounce_xv, $r_bounce_yv]
   }
   
   return [$r_bounce_xv + $self->ent2->xv, $r_bounce_yv + $self->ent2->yv]
}

sub invert{
   my $self = shift;
   my $axis = $self->axis;
   if (ref($axis) eq 'ARRAY'){
      $axis = [-$axis->[0], -$axis->[1]]
   }
   else{ #x or y
      $self->ent2->normalize($self->ent1);
   }
   return Collision::2D::Collision->new(
      ent1=>$self->ent2,
      ent2=>$self->ent1,
      time=>$self->time,
      axis => $axis,
   )
   
}

__END__
=head1 NAME

Collision::2D::Collision - An object representing a collision betwixt 2 entities

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over

=item time

The time of collision. For example, consider a point-circle collision,
where the point is moving towards the circle. 
$collision->time is the B<exact> moment of collision between the two.

=item axis

The axis of collision. Basically a vector from one entity to the other.
It depends entirely on how they collide.

If the collision involves a vertical or horizontal line, the axis will be
'x' or 'y'. If it's between a point or corner and a circle, it will be
an arrayref, of the form [$x,$y].

This vector will not be normal (normal means of length 1).
L<Collision::2D::normalize_vec($v)|Collision::2D/normalize_vec>
is provided for that purpose.

=item vaxis

Again, the axis of collision. If you call this, it will always return the vector
form [$x,$y]. If the axis existed as 'x' or 'y', it is translated to [$x,$y].

This vector will not be normal (normal means of length 1).
L<Collision::2D::normalize_vec($v)|Collision::2D/normalize_vec>
is provided for that purpose.

=item ent1, ent2

 $collision->ent1

This is to provide some context for L</axis>. This is useful because
dynamic_collision doesn't preserve the order of your entities. If you would
like for the order to be preserved, use the C<< entity->collide($ent2) >> method,
or use the keep_order parameter in C<dynamic_collision>.

=back

=head1 METHODS

=over

=item bounce_vector

 my $bouncevec = $co->bounce_vector (elasticity => .8);

Assuming that C<< $co->ent2 >> has infinite mass, the C<< $co->bounce_vector >> is
the resulting velocity of C<< $co->ent1 >>. The elasticity parameter is 1 by default.

=item invert

my $other_collision = $self->invert();

This returns the inverse of this collision. That is, the time remains,
but ent1 and ent2 are swapped, and the axis is inversed. This does not effect $self.

