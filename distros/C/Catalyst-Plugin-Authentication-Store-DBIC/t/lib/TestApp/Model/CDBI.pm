package TestApp::Model::CDBI;

eval { require Class::DBI }; return 1 if $@;
@ISA = qw/Class::DBI/;
use strict;

our $db_file = $ENV{TESTAPP_DB_FILE};

#unlink '/tmp/andy.trace';
#DBI->trace( 1, '/tmp/andy.trace' );

__PACKAGE__->connection(
    "dbi:SQLite:$db_file",
);

1;
