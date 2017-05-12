package MyApp::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'MyApp::Schema',
    
    connect_info => {
	    dsn => 'dbi:SQLite:t/var/myapp.db',
	     user => '',
	    password => '',
	       on_connect_do => q{PRAGMA foreign_keys = ON},
	    },
);
1;
