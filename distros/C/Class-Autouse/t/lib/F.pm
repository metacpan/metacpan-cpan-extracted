package F;

use strict;
use base 'E';

sub foo {
	my $class = shift;
	return $class->SUPER::foo(@_);
}

1;

