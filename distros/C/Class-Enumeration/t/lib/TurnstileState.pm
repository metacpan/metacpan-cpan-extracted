use strict;
use warnings;

package TurnstileState;

# On purpose do not use Class::Enumeration::Builder
use parent 'Class::Enumeration';

my @values;

sub _values { ## no critic ( ProhibitUnusedPrivateSubroutines )
  unless ( @values ) {
    my $ordinal = 0;
    @values = map { __PACKAGE__->_new( $ordinal++, $_ ) } qw( Locked Unlocked )
  }
  @values
}

1
