package
    TimePieceDB::TestUser;

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::TimePiece PK::Auto Core/);
__PACKAGE__->table('test_user');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 0,
    },
    user_name => {
        data_type => 'varchar',
        size      => 45,
    },
    user_nick => {
        inflate_time_piece => 1,
        is_nullable        => 1,
    },
    postcode => {
        is_nullable => 1,
    },
    last_login => {
        data_type          => 'int',
        inflate_time_piece => 1,
        is_nullable        => 1,
    },
    city => {
        data_type          => 'varchar',
        size               => 45,
        inflate_time_piece => 1,
    },
    user_created => {
        data_type          => 'integer',
        inflate_time_piece => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

1;

