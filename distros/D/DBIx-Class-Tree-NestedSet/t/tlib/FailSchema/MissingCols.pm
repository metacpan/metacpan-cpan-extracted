use strict;
use warnings;

package FailSchema::MissingCols;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Tree::NestedSet Core/);
__PACKAGE__->table('zomtec');

__PACKAGE__->add_columns(qw/affe/);
__PACKAGE__->set_primary_key(qw/affe/);

__PACKAGE__->tree_columns({
    left_column => 'affe',
});

1;
