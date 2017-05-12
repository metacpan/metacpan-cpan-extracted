package TestAppRunmode;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestAppRunmode::ISA = qw(CGI::Application);

sub runmode_rm : Runmode {
	my $self = shift;
	return "Runmode: runmode_rm\n";
}

1;
