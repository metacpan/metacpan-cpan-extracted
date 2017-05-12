package TestApp::User;

use strict;

use base qw(TestApp::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'user',

    columns => [
        id           => { type => 'integer' },
        username     => { type => 'text' },
        email        => { type => 'text' },
        password     => { type => 'text' },
        status       => { type => 'text' },
        role_text    => { type => 'text' },
        session_data => { type => 'text' },
    ],

    primary_key_columns => [ 'id' ],

    relationships => [
    	roles => {
		type => 'many to many',
		map_class => 'TestApp::UserRole',
	}
    ],
);

__PACKAGE__->meta->make_manager_class();

1;

