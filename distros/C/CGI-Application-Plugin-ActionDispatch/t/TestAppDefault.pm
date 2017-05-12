package TestAppDefault;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestAppDefault::ISA = qw(CGI::Application);

sub setup {
	my $self = shift;
	$self->run_modes({ home => 'home' });
}

sub home {
	return "Runmode: home\n";
}

sub default_rm : Default {
	my $self = shift;
	return "Runmode: default_rm\n";
}

1;
