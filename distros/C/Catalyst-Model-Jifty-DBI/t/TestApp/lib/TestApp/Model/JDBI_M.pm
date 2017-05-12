package TestApp::Model::JDBI_M;

use strict;
use warnings;
use base qw( Catalyst::Model::Jifty::DBI );

__PACKAGE__->config(
  schema_base  => 'TestApp::Schema',
  databases => [
    {
      name => 'db1',
      connect_info => {
        driver   => 'SQLite',
        database => $ENV{CM_JDBI_MEMORY} ? ':memory:' : 'testdb1',
      },
    },
    {
      name => 'db2',
      connect_info => {
        driver   => 'SQLite',
        database => $ENV{CM_JDBI_MEMORY} ? ':memory:' : 'testdb2',
      },
    },
  ],
);

1;
