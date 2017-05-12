package #
    DBIC::Test::Schema::TestTime;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/TimeStamp PK::Auto Core/);
__PACKAGE__->table('test_time');

__PACKAGE__->add_columns(
    'pk1' => {
        data_type => 'integer', is_nullable => 0, is_auto_increment => 1
    },
    display_name => { data_type => 'varchar', size => 128, is_nullable => 0 },
    t_created => {
        data_type => 'timestamp', is_nullable => 0,
        set_on_create => 1
    },
    t_updated => {
        data_type => 'timestamp', is_nullable => 0,
        set_on_create => 1, set_on_update => 1
    },
);

__PACKAGE__->set_primary_key('pk1');

1;
