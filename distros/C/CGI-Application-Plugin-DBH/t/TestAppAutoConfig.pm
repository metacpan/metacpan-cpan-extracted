package TestAppAutoConfig;

use strict;

use CGI::Application;
@TestAppAutoConfig::ISA = qw(CGI::Application);

use CGI::Application::Plugin::DBH (qw/dbh dbh_default_name/);

sub cgiapp_init {
  my $self = shift;


}

sub setup {
    my $self = shift;

    $self->start_mode('test_mode');

    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
  my $self = shift;
  return 1;
}

1;
