package t::Role::PRNG;

use Moose;
use Method::Signatures;

with 'Bio::Community::Role::PRNG';


# This is simply a test module that consumes the PRNG role.

method get_random_number ($num = 10) {
   # Random integer in the range [1, 10]
   return int( $self->rand($num) ) + 1;
}

__PACKAGE__->meta->make_immutable;

1;
