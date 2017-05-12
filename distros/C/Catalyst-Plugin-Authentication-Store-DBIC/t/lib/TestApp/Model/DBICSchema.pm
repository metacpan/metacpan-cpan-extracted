package TestApp::Model::DBICSchema;

eval { require Catalyst::Model::DBIC::Schema }; return 1 if $@;
eval { require DBIx::Class }; return 1 if $@;
@ISA = qw/Catalyst::Model::DBIC::Schema/;
use strict;

our $db_file = $ENV{TESTAPP_DB_FILE};

__PACKAGE__->config(
    schema_class => 'TestDB',
    connect_info => [ "dbi:SQLite:$db_file",
              '',
              '',
              { AutoCommit => 1 },
            ],

);

1;
