use strict;
use warnings;

package TurnstileState;

# On purpose do not use Class::Enumeration::Builder
use parent 'Class::Enumeration';

my @values;

sub values { ## no critic ( ProhibitBuiltinHomonyms )
  unless ( @values ) {
    my $ordinal = 0;
    @values = map { __PACKAGE__->_new( $ordinal++, $_ ) } qw( Locked Unlocked )
  }
  @values
}

1
