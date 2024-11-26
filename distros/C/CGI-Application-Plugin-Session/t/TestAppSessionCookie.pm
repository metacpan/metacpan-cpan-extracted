package TestAppSessionCookie;

use strict;

use CGI::Application;
use CGI::Application::Plugin::Session;
@TestAppSessionCookie::ISA = qw(CGI::Application);

sub cgiapp_init {
  my $self = shift;

  $self->session_config({
                        CGI_SESSION_OPTIONS => [ "driver:File", $self->query ],
                        SEND_COOKIE         => 1,
                        DEFAULT_EXPIRY      => '+1h',
                        COOKIE_PARAMS       => {
                                                 -name    => CGI::Session->name,
                                                 -value   => '1111',
                                                 -path    => '/testpath',
                                                 -domain  => 'mydomain.com',
                                                 -expires => '',
                                               },
  });
}

sub setup {
    my $self = shift;

    $self->start_mode('test_mode');

    $self->run_modes([qw(test_mode existing_session_cookie existing_session_cookie_plus_extra_cookie existing_extra_cookie)]);
}

sub test_mode {
  my $self = shift;
  my $output = '';

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub existing_session_cookie {
  my $self = shift;
  my $output = '';

  $self->header_add(-cookie => 
      $self->query->cookie(-name => 'CGISESSID', -value => 'test'),
  );

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub existing_session_cookie_plus_extra_cookie {
  my $self = shift;
  my $output = '';

  $self->header_add(-cookie => [
      $self->query->cookie(-name => 'CGISESSID', -value => 'test'),
      $self->query->cookie(-name => 'TESTCOOKIE', -value => 'testvalue'),
  ]);

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub existing_extra_cookie {
  my $self = shift;
  my $output = '';

  $self->header_add(-cookie => 
      $self->query->cookie(-name => 'TESTCOOKIE', -value => 'testvalue'),
  );

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}


1;
