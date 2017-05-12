package MyDBIC::Schema::FooGoo;

use strict;
use warnings;

use base 'MyDBIC::Base::DBIC';

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('foo_goos');
__PACKAGE__->add_columns(
    foo_id => {
        data_type         => 'int',
        is_auto_increment => 0,
        is_nullable       => 0,
    },
    goo_id => {
        data_type         => 'int',
        is_auto_increment => 0,
        is_nullable       => 0,
    },
);

__PACKAGE__->set_primary_key(qw(foo_id goo_id));
__PACKAGE__->belongs_to( foo => 'MyDBIC::Schema::Foo', 'foo_id' );
__PACKAGE__->belongs_to( goo => 'MyDBIC::Schema::Goo', 'goo_id' );

1;
