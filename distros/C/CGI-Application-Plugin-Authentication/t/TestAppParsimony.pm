package TestAppParsimony;

use strict;
use warnings;
use Carp;
use base qw(CGI::Application);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;

sub setup {
        my $self = shift;
        $self->start_mode('unprotected');
        #$self->mode_param('rm');
        $self->run_modes(
                'unprotected' => sub {return "<html><head/><body>This is public.</body></html>";},
                'protected' => sub {return "<html><head/><body>This is private.</body></html>";}
        );
	$self->authen->config(
        	DRIVER => [ 'Generic', { 'test' => '123' } ],
        	STORE  => [ 'Session' ],
        	CREDENTIALS => [qw(auth_username auth_password)],
	);
	$self->authen->protected_runmodes('protected');
}

1
