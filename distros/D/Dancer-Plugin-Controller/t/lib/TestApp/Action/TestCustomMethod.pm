package TestApp::Action::TestCustomMethod;

use strict;
use warnings;
use utf8;

use base 'TestApp::Action';

sub main {
	my ($self) = @_;

	return { result => $self->custom_method };
}

1;
