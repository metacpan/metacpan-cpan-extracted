package TestApp::Schema::Result::Session;
use warnings;
use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('sessions');
__PACKAGE__->add_columns(qw/ sessions_id session_data /);
__PACKAGE__->set_primary_key('sessions_id');

1;
