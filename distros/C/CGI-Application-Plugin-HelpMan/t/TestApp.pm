package TestApp;
use strict;
use warnings;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use base 'CGI::Application::Plugin::HelpMan';
#use CGI::Application::Plugin::HelpMan qw(man help);

$CGI::Application::Plugin::HelpMan::DEBUG = 1;

sub setup {
   my $self = shift;
	$self->mode_param('rm');
   $self->start_mode('help');   
}






1;
