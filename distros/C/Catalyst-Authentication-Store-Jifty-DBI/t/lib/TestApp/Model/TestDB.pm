package TestApp::Model::TestDB;

use strict;
use warnings;
use base qw( Catalyst::Model::Jifty::DBI );

__PACKAGE__->config(
  schema_base  => 'TestApp::Schema',
  connect_info => {
    driver   => 'SQLite',
    database => ':memory:', # $ENV{TESTAPP_DB_FILE},
  },
);

1;
