package app_newstyle::C::a::controller;

use strict;
use warnings;

use base("Apache::Voodoo");

sub init {
	my $self = shift;

	$self->{'c'} = 'a controller';
}

sub handle {
	my $self = shift;
	my $p    = shift;

	return {
		'a_controller' => $self->{'c'}
	};
}

1;
