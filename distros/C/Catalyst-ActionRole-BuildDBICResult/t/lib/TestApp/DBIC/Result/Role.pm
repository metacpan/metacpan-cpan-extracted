package # Hide from PAUSE
  TestApp::DBIC::Result::Role;

use strict;
use warnings;

use base 'TestApp::DBIC::Result';

__PACKAGE__->table('role');
__PACKAGE__->add_columns(
    role_id => {
        data_type => 'integer', 
        size => 8,
    },
    name => {
        data_type => 'varchar',
        size => '24',
    },
);
__PACKAGE__->set_primary_key('role_id');
__PACKAGE__->add_unique_constraint(unique_role_name => ['name']);
__PACKAGE__->has_many(
    role_users_rs => 'TestApp::DBIC::Result::UserRole',
    {'foreign.fk_role_id' => 'self.role_id'},
);
__PACKAGE__->many_to_many(users => 'role_users_rs', 'user');


