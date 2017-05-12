package CAPExtTest::CGIApp;
use strict;
use warnings;

use parent 'CGI::Application';

use Readonly;
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CAPExtTest::Schema;
use CGI::Application::Plugin::DBIx::Class ':all';
use CGI::Application::Plugin::ExtJS ':all';

Readonly our $DBFILE => 'test.db';
Readonly our $CONNECT_STR => "dbi:SQLite:dbname=$DBFILE";

sub cgiapp_init {
  my $self = shift;

  $self->dbh_config( $CONNECT_STR );

  $self->dbic_config({
     schema => 'CAPExtTest::Schema',
  });
}

sub setup {
    my $self = shift;

    $self->start_mode('test_mode');

    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
   return 1;
}

1;

