package TestApp::Model::DM;
use strict;
use base qw/ Catalyst::Model::DBIDM /;

use TestApp::Schema;

__PACKAGE__->config(
    schema_class => 'TestApp::DM',
    connect_info => [
        'dbi:Mock:',
        '',
        '',
        { RaiseError => 1 },
    ],
);

1;
