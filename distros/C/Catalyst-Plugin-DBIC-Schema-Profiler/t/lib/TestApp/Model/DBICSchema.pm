package TestApp::Model::DBICSchema;

eval { require Catalyst::Model::DBIC::Schema }; return 1 if $@;
@ISA = qw/Catalyst::Model::DBIC::Schema/;

use strict;
use warnings;

our $db_file = $ENV{TESTAPP_DB_FILE};

__PACKAGE__->config(
    schema_class => 'TestApp::Schema',
    connect_info => [
        "dbi:SQLite:$db_file",
        '',
        '',
        { AutoCommit => 1 },
    ],
);

1;
