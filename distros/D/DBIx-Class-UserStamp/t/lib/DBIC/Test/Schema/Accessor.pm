package #
    DBIC::Test::Schema::Accessor;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/UserStamp PK::Auto Core/);
__PACKAGE__->table('test_accessor');

__PACKAGE__->add_columns(
    'pk1' => {
        data_type => 'integer', is_nullable => 0, is_auto_increment => 1
    },
    display_name => { data_type => 'varchar', size => 128, is_nullable => 0 },
    u_created => {
        data_type => 'integer', is_nullable => 0,
        store_user_on_create => 1, accessor => 'u_created_accessor',
    },
    u_updated => {
        data_type => 'integer', is_nullable => 0,
        store_user_on_create => 1, store_user_on_update => 1, accessor => 'u_updated_accessor',
    },
);

__PACKAGE__->set_primary_key('pk1');

no warnings 'redefine';

sub u_created {
    my $self = shift;
    croak('Shouldnt be trying to update through u_created - should use accessor') if shift;

    return $self->u_created_accessor();
}

sub u_updated {
    my $self = shift;
    croak('Shouldnt be trying to update through u_updated - should use accessor') if shift;

    return $self->u_updated_accessor();
}


1;
