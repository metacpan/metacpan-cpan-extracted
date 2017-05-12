package #
    DBIC::Test::Schema::Test;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/Tokenize Core/);
__PACKAGE__->table('test');

__PACKAGE__->add_columns(
    'pk1' => {
        data_type => 'integer', is_nullable => 0, is_auto_increment => 1
    },
    'name' => { 
        data_type   => 'varchar', 
        size        => 128, 
        is_nullable => 0,
        token_field => 'token'
    },
    'token' => {
        data_type   => 'varchar',
        size        => 128,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('pk1');

1;
