package CAPDBICTest::CGIApp;
use strict;
use warnings;

use parent 'CGI::Application';

use CAPDBICTest::Schema;
use CGI::Application::Plugin::DBIx::Class ':all';

our $DBFILE = 'test.db';
our $CONNECT_STR = "dbi:SQLite:dbname=$DBFILE";

sub cgiapp_init {
  my $self = shift;

  $self->dbic_config({
     schema => 'CAPDBICTest::Schema',
     connect_info => "dbi:SQLite:dbname=$DBFILE",
  });
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

