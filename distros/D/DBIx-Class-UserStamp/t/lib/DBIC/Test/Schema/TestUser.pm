package #
    DBIC::Test::Schema::TestUser;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/UserStamp PK::Auto Core/);
__PACKAGE__->table('test_user');

__PACKAGE__->add_columns(
    'pk1' => {
        data_type => 'integer', is_nullable => 0, is_auto_increment => 1
    },
    display_name => { data_type => 'varchar', size => 128, is_nullable => 0 },
    u_created => {
        data_type => 'integer', is_nullable => 0,
        store_user_on_create => 1
    },
    u_updated => {
        data_type => 'integer', is_nullable => 0,
        store_user_on_create => 1, store_user_on_update => 1
    },
);

__PACKAGE__->set_primary_key('pk1');

1;
