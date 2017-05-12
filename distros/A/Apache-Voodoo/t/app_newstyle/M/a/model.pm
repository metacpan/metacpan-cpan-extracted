package app_newstyle::M::a::model;

use strict;
use warnings;

use base("Apache::Voodoo");

sub get_foo {
	my $self = shift;
	my $p    = shift;

	return "foo";
}

1;
