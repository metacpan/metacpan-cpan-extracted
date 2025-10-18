use strict;
use warnings;

package CoffeeSize;

# On purpose do not use Class::Enumeration::Builder
use parent 'Class::Enumeration';

my @values;

sub values { ## no critic ( ProhibitBuiltinHomonyms )
  unless ( @values ) {
    my $ordinal = 0;
    my @tmp     = ( BIG => { ounces => 8 }, HUGE => { ounces => 10 }, OVERWHELMING => { ounces => 16 } );
    while ( my ( $name, $attributes ) = splice @tmp, 0, 2 ) {
      push @values, __PACKAGE__->_new( $ordinal++, $name, $attributes )
    }
  }
  @values
}

sub ounces {
  my ( $self ) = @_;

  $self->{ ounces }
}

1
