package TestApp::UserRole;

use strict;

use base qw(TestApp::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'user_role',

    columns => [
        id     => { type => 'integer' },
        user   => { type => 'integer' },
        roleid => { type => 'integer' },
    ],

    primary_key_columns => [ 'id' ],

    foreign_keys => [
    	user => {
		class => 'TestApp::User',
		key_columns => { user => 'id' },
	},
    	role => {
		class => 'TestApp::Role',
		key_columns => { roleid => 'id' },
	}
    ],
);

1;

