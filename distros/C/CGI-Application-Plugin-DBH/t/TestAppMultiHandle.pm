package TestAppMultiHandle;
 
use strict;
 
use CGI::Application;
use TestAppBasic;
@TestAppMultiHandle::ISA = qw(TestAppBasic);
 
use CGI::Application::Plugin::DBH (qw/dbh_default_name dbh_config dbh/);
 
sub cgiapp_init {
  my $self = shift;
 
  $self->dbh_config('handle1', [ 'DBI:Mock:','','' ]);
  $self->dbh_config('handle2', $self->dbh('handle1'));

  $self->param('orig_name1', $self->dbh_default_name('handle1'));
  $self->dbh_config('handle3', $self->dbh);

  $self->param('orig_name2', $self->dbh_default_name('handle4'));
  $self->dbh_config('DBI:Mock:','','');

  $self->dbh_default_name($self->param('orig_name1'));

}
