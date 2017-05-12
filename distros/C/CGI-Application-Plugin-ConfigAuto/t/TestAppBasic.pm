package TestAppBasic;

use strict;

use CGI::Application;
@TestAppBasic::ISA = qw(CGI::Application);

use CGI::Application::Plugin::ConfigAuto (qw/cfg cfg_file/);

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
