package TestApp::Role;

use strict;

use base qw(TestApp::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'role',

    columns => [
        id   => { type => 'integer' },
        role => { type => 'text' },
    ],

    primary_key_columns => [ 'id' ],
);

1;

