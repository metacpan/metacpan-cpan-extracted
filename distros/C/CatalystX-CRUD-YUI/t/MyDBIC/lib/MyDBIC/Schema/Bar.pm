package MyDBIC::Schema::Bar;

use strict;
use warnings;

use base 'MyDBIC::Base::DBIC';

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('bars');
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
    foo_id => {
        data_type         => 'int',
        is_auto_increment => 0,
        is_nullable       => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( foo => 'MyDBIC::Schema::Foo' => 'foo_id' );
__PACKAGE__->add_unique_constraint([ qw/name/ ]);

1;
