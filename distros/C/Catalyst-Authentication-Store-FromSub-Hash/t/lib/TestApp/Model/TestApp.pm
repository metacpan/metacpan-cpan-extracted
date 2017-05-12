package TestApp::Model::TestApp;

use base qw/Catalyst::Model::DBIC::Schema/;
use strict;


our $db_file = $ENV{TESTAPP_DB_FILE};

__PACKAGE__->config(
    schema_class => 'TestApp::Schema',
    connect_info => [ "dbi:SQLite:$db_file",
              '',
              '',
              { AutoCommit => 1 },
            ],

);

# Load all of the classes
#__PACKAGE__->load_classes(qw/Role User UserRole/);


1;
