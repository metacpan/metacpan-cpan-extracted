package TestAppSessionDelete;

use strict;

use CGI::Application;
use CGI::Application::Plugin::Session;
@TestAppSessionDelete::ISA = qw(CGI::Application);

sub cgiapp_init {
  my $self = shift;

  $self->session_config({
                        CGI_SESSION_OPTIONS => [ "driver:File", $self->query ],
                        SEND_COOKIE         => 1,
                        DEFAULT_EXPIRY      => '+1h',
                        COOKIE_PARAMS       => {
                                                 -path    => '/testpath',
                                                 -domain  => 'mydomain.com',
                                                 -expires => '+3M',
                                               },
  });
}

sub setup {
    my $self = shift;

    $self->start_mode('start');

    $self->run_modes( [ qw( start logout ) ] );
}

sub start {
  my $self = shift;
  my $output = '';

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub logout {
  my $self = shift;
  my $query = $self->query;
  if ( ! $query->cookie( 'CGISESSID' ) ) {
      return "didn't get session passed in!";
  } else {
      $self->session_delete;
      return "logout finished";
  }
}


1;
