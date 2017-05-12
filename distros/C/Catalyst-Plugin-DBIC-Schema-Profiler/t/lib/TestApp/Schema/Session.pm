package TestApp::Schema::Session;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('sessions');
__PACKAGE__->add_columns(
    id => {
    },
    data => {
        size => 200,
    },
    expires => {
    },
);
__PACKAGE__->set_primary_key('id');

1;
