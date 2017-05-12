package TestAppErrorRunmode;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestAppErrorRunmode::ISA = qw(CGI::Application);

sub setup {
	my $self = shift;
	$self->run_modes({ home => 'home' });
}

sub home : Default {
	die "Call error runmode";
	return "Runmode: home\n";
}

sub error_rm : ErrorRunmode {
	my $self = shift;
	return "Runmode: error_rm\n";
}

1;
