package CGI::Application::Plugin::AbstractCallback::Test::InitSetter;

use strict;
use warnings;
use base qw|CGI::Application::Plugin::AbstractCallback|;

sub callback {
	my $self = shift;
	
	$self->param('INIT', 1);
}

1;