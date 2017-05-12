package MyDBIC::Schema::Goo;

use strict;
use warnings;

use base 'MyDBIC::Base::DBIC';

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('goos');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    name => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( foo_goo => 'MyDBIC::Schema::FooGoo', 'goo_id' );
__PACKAGE__->many_to_many( foogoos => 'foo_goo' => 'foo' );

1;
