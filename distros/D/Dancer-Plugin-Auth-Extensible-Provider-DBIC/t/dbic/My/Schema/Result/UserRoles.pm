package My::Schema::Result::UserRoles;

use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

__PACKAGE__->table('UserRoles');

__PACKAGE__->add_columns(
    user_id => {
        data_type => 'INTEGER',
        is_foreign_key => 1,
        is_nullable => 0,
    },
    role_id => {
        data_type => 'INTEGER',
        is_foreign_key => 1,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key( 'user_id', 'role_id' );

__PACKAGE__->belongs_to( 
    user => 'My::Schema::Result::Users', 'user_id' 
);
__PACKAGE__->belongs_to( 
    role => 'My::Schema::Result::Roles', 'role_id' 
);

1;

