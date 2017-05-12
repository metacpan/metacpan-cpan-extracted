package TestSchema::UserRole;

use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
    user_id => {
        data_type     => "INT",
        default_value => undef,
        is_nullable   => 0,
        size          => 10
    },
    role_id => {
        data_type     => "INT",
        default_value => undef,
        is_nullable   => 0,
        size          => 10
    },
);
__PACKAGE__->set_primary_key(qw/user_id role_id/);
__PACKAGE__->belongs_to( user => 'TestSchema::User', { id => "user_id" } );
__PACKAGE__->belongs_to( role => 'TestSchema::Role', { id => "role_id" } );
