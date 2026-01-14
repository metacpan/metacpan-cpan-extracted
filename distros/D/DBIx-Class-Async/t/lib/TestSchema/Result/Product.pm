package TestSchema::Result::Product;
use base 'DBIx::Class::Core';

__PACKAGE__->table('products');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'text',
    },
    sku => {
        data_type => 'text',
    },
    price => {
        data_type => 'real',
        is_nullable => 1,
    },
    description => {
        data_type => 'text',
        is_nullable => 1,
    },
    active => {
        data_type => 'integer',
        default_value => 1,
    },
);
__PACKAGE__->set_primary_key('id');

1;
