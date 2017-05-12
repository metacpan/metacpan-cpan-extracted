package TestApp::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table('user');

__PACKAGE__->add_columns(
	id   => { data_type => "integer", is_nullable => 0 },
	name => { data_type => "text",    is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');


1;

