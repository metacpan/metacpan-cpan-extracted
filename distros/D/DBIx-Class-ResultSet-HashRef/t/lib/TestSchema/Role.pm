package TestSchema::Role;

use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('role');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
        default_value     => undef,
        size              => 10,
    },
    name => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many( user_role => 'TestSchema::UserRole', 'role_id' );
__PACKAGE__->many_to_many( users => 'user_role', 'user' );

1;
