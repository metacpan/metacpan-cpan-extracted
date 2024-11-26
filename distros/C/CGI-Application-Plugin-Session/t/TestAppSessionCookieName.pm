package TestAppSessionCookieName;

use warnings;
use strict;

use CGI::Application;
use CGI::Application::Plugin::Session;

@TestAppSessionCookieName::ISA = qw(CGI::Application);

sub cgiapp_init {
    my $self = shift;

    $self->session_config(
        {   CGI_SESSION_OPTIONS =>
                [ "driver:File", $self->query, {},
            { name => 'foobar' }
            ],
            SEND_COOKIE    => 1,
            DEFAULT_EXPIRY => '+1h'
        }
    );
}

sub setup {
   my $self = shift;
   $self->start_mode( 'test_mode' );
   $self->run_modes(
      [ qw( test_mode ) ]
   );
}

sub test_mode {
   my $self    = shift;
   my $session = $self->session;

   return "session: " . $session->id . "\n";
}

1;

