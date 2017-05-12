package # Hide from PAUSE
  TestApp::DBIC::Result::User;

use strict;
use warnings;

use base 'TestApp::DBIC::Result';

__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer', 
        size => '8', 
    },
    email => {
        data_type => 'varchar',
        size => '64',
    },
);
__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->add_unique_constraint([ 'email' ]);
__PACKAGE__->has_many(
    user_roles_rs => 'TestApp::DBIC::Result::UserRole',
    {'foreign.fk_user_id' => 'self.user_id'},
);
__PACKAGE__->many_to_many(roles => 'user_roles_rs', 'role');

1;
