use strict;
use warnings;

package TestSchema::MultiTree;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Tree::NestedSet Core/);
__PACKAGE__->table('tree');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    root_id => {
        data_type   => 'text',
        is_nullable => 1,
    },
    lft     => { data_type => 'integer' },
    rgt     => { data_type => 'integer' },
    level   => { data_type => 'integer' },
    content => { data_type => 'text'    },
);

__PACKAGE__->set_primary_key(qw/id/);

__PACKAGE__->tree_columns({
    root_column     => 'root_id',
    left_column     => 'lft',
    right_column    => 'rgt',
    level_column    => 'level',
});

1;
