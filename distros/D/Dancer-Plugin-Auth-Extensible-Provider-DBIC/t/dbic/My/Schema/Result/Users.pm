package My::Schema::Result::Users;

use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('Users');

__PACKAGE__->add_columns(
    user_id => {
        data_type => 'INTEGER',
        is_auto_increment => 1,
        is_nullable => 0,
    },
    username => {
        data_type => 'VARCHAR',
        size => 32,
        is_nullable => 0,
    },
    secret => {
        data_type => 'VARCHAR',
        size => 40,
        is_nullable => 0,
        encode_column => 1,
        encode_class  => 'Digest',
        encode_args   => { 
            algorithm => 'SHA-1', 
            format => 'hex',
        },
    },
);

sub check_secret {
    my( $self, $password ) = @_;
    return $self->secret eq $password;
}

__PACKAGE__->set_primary_key( 'user_id' );
__PACKAGE__->add_unique_constraint( 'username' => [ 'username' ] );

__PACKAGE__->has_many( 
    user_roles => 'My::Schema::Result::UserRoles', 'user_id' 
);

__PACKAGE__->many_to_many( 
    roles => 'user_roles', 'role'
);

1;
