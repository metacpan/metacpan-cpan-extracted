package TestApp::Action::Test_Inherit;

use strict;
use warnings;
use utf8;

sub main {
	my ($self) = @_;

	return { result => $self->params->{x} };
}

1;
