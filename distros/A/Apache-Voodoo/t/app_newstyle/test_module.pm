package app_newstyle::test_module;

use strict;
use warnings;

use base("Apache::Voodoo");

sub handle {
	my $self = shift;
	my $p    = shift;

	return {
		test_module => 'test_module'
	};
}

1;
