package TestApp::Model::DB;

use Moose;
extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    {   schema_class => 'TestApp::Schema',
        connect_info => 'dbi:SQLite:dbname=:memory:',
    },
);

1;
