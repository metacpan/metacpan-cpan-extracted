package TestApp::Model::DB;

use strict;
use warnings;
use base qw( Catalyst::Model::Jifty::DBI );

__PACKAGE__->config({
  schema_base  => 'TestApp::Schema',
  connect_info => {
    driver   => 'SQLite',
    database => ':memory:',
  },
});

1;
