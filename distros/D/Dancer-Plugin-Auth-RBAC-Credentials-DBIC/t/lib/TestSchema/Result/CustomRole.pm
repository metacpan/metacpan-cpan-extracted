package TestSchema::Result::CustomRole;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table("custom_role");

__PACKAGE__->add_columns(
    user_id => { data_type => "integer", is_nullable => 0 },
    rolename => { data_type => "varchar", size => 255, is_nullable => 0 },
);
__PACKAGE__->set_primary_key(qw(user_id rolename));

__PACKAGE__->belongs_to(user => 'TestSchema::Result::CustomUser', 'user_id');

sub check_password { $_[0]->passphrase eq $_[1] }

1;
