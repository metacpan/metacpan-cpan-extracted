package TestSchema::User;

use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
        default_value     => undef,
        size              => 10,
    },
    login => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many( user_role => 'TestSchema::UserRole', 'user_id' );
__PACKAGE__->many_to_many( roles => 'user_role', 'role' );
__PACKAGE__->resultset_class('DBIx::Class::ResultSet::HashRef');

1;
