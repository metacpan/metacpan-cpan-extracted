use strict;
use warnings;

package TestSchema::MultiPK;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Tree::NestedSet Core/);
__PACKAGE__->table('multi_tree');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
    },
    id2 => {
        data_type         => 'text',
    },
    root_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    lft     => { data_type => 'integer' },
    rgt     => { data_type => 'integer' },
    level   => { data_type => 'integer' },
    content => { data_type => 'text'    },
);

__PACKAGE__->set_primary_key(qw/id id2/);

__PACKAGE__->tree_columns({
    root_column     => 'root_id',
    left_column     => 'lft',
    right_column    => 'rgt',
    level_column    => 'level',
});
1;
