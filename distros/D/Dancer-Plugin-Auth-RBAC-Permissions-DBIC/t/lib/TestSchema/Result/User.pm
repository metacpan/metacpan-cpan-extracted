package TestSchema::Result::User;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table("user");

__PACKAGE__->add_columns(
    id => { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => "varchar", size => 255 },
    login => { data_type => "varchar", size => 32, is_nullable => 0 },
    password => { data_type => "varchar", size => 32 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("login", ["login"]);

__PACKAGE__->has_many(roles => "TestSchema::Result::Role", {"foreign.user" => "self.id"});

sub check_password { $_[0]->password eq $_[1] }

1;
