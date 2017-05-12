package TestApp::Schema::User;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table( 'user' );
__PACKAGE__->add_columns( qw/id username email password status role_text session_data/ );
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many( 'map_user_role' => 'TestApp::Schema::UserRole' => 'user' );

__PACKAGE__->many_to_many( roles => 'map_user_role', 'role');

1;
