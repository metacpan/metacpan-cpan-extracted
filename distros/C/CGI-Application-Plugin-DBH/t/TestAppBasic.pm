package TestAppBasic;

use strict;

use CGI::Application;
@TestAppBasic::ISA = qw(CGI::Application);

use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);

sub cgiapp_init {
  my $self = shift;

  $self->dbh_config('DBI:Mock:','','');

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
