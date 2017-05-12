package TestSchema::Result::CustomUser;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table("custom_user");

__PACKAGE__->add_columns(
    uid => { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    nickname => { data_type => "varchar", size => 255 },
    username => { data_type => "varchar", size => 32, is_nullable => 0 },
    passphrase => { data_type => "varchar", size => 32 },
);
__PACKAGE__->set_primary_key("uid");
__PACKAGE__->add_unique_constraint("username", ["username"]);

__PACKAGE__->has_many(roles => "TestSchema::Result::CustomRole", "user_id");

sub check_password { $_[0]->passphrase eq $_[1] }

1;
