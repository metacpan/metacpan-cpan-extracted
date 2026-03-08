use strict;
use warnings;

package Data::ZPath::_ScalarProxy;

our $VERSION = '0.001000';

sub TIESCALAR { bless { slot => $_[1] }, $_[0] }
sub FETCH     { $_[0]->{slot}->() }
sub STORE     { $_[0]->{slot}->($_[1]) }

1;
