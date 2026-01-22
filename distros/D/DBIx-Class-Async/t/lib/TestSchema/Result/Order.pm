package TestSchema::Result::Order;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/Async::ResultComponent Core/);
__PACKAGE__->table('orders');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    user_id => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    amount => {
        data_type   => 'decimal',
        size        => [10, 2],
        is_nullable => 0,
    },
    status => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 0,
        default_value => 'pending',
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(user => 'TestSchema::Result::User','user_id');

1;
