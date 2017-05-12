package TestApp::M::Session;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;
use FindBin;

__PACKAGE__->install_properties({
    columns     => [ 'id', 'session_data', 'expires' ],
    primary_key => [ 'id' ],
    datasource  => 'sessions',
    get_driver  => sub {
        Data::ObjectDriver::Driver::DBI->new(
            dsn => "dbi:SQLite:$FindBin::Bin/tmp/session.db",
        ),
    },
});

1;
