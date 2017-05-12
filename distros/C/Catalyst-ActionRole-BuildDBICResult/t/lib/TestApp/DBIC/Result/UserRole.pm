package # Hide from PAUSE
  TestApp::DBIC::Result::UserRole;

use strict;
use warnings;

use base 'TestApp::DBIC::Result';

__PACKAGE__->table('user_role');
__PACKAGE__->add_columns(
    fk_user_id => {
        data_type => 'integer', 
        size => '8', 
    },
    fk_role_id => {
        data_type => 'integer', 
        size => '8', 
    },
);
__PACKAGE__->set_primary_key('fk_user_id','fk_role_id');
__PACKAGE__->belongs_to(
    user => 'TestApp::DBIC::Result::User',
    {'foreign.user_id' => 'self.fk_user_id'},
);

__PACKAGE__->belongs_to(
    role => 'TestApp::DBIC::Result::Role',
    {'foreign.role_id' => 'self.fk_role_id'},
);

