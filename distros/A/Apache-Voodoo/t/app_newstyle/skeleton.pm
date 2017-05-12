package app_newstyle::skeleton;

use strict;
use warnings;

use base("Apache::Voodoo");

sub handle {
	my $self = shift;
	my $p    = shift;

	return {
		SKELETON => 'skeleton'
	};
}

1;
