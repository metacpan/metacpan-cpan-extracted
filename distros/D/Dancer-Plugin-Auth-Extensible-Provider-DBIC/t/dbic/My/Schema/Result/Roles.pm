package My::Schema::Result::Roles;

use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

__PACKAGE__->table('Roles');

__PACKAGE__->add_columns(
    role_id => {
        data_type => 'INTEGER',
        is_auto_increment => 1,
        is_nullable => 0,
    },
    role => {
        data_type => 'VARCHAR',
        size => 32,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key( 'role_id' );
__PACKAGE__->add_unique_constraint( 'role' => [ 'role' ] );

__PACKAGE__->has_many( 
    user_roles => 'My::Schema::Result::UserRoles', 'role_id' 
);

__PACKAGE__->many_to_many( 
    users => 'user_roles', 'user'
);

1;


