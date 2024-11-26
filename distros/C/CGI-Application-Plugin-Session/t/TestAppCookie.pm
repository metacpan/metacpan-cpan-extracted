package TestAppCookie;

use strict;

use CGI::Application;
use CGI::Application::Plugin::Session;
@TestAppCookie::ISA = qw(CGI::Application);

sub cgiapp_init {
  my $self = shift;

  $self->session_config({
                        CGI_SESSION_OPTIONS => [ "driver:File", $self->query ],
                        SEND_COOKIE         => 0,
                        COOKIE_PARAMS       => {
                                                 -name    => CGI::Session->name,
                                                 -value   => '1111',
                                                 -path    => '/testpath',
                                                 -domain  => 'mydomain.com',
                                                 -expires => '+24h',
                                               },
  });
}

sub setup {
    my $self = shift;

    $self->start_mode('test_mode');

    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
	my $self = shift;
  my $output = '';

  $self->session_cookie;
  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}


1;
