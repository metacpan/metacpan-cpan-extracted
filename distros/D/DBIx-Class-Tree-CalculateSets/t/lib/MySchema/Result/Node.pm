package MySchema::Result::Node;

use base qw/DBIx::Class/;

use strict;
use warnings;

__PACKAGE__->load_components (qw/Tree::CalculateSets Core/);

__PACKAGE__->table ('node');

__PACKAGE__->add_columns (
  id => {
    is_auto_increment => 1,
    data_type         => 'integer',
  },
  parent => {
    data_type         => 'integer',
    is_nullable       => 1,
  },
  root => {
    data_type         => 'integer',
    is_nullable       => 1,
  },
  lft => {
    data_type         => 'integer',
    is_nullable       => 1,
  },
  rgt => {
    data_type         => 'integer',
    is_nullable       => 1,
  },
);

__PACKAGE__->set_primary_key ('id');

__PACKAGE__->belongs_to (parent => 'MySchema::Result::Node');

__PACKAGE__->belongs_to (root => 'MySchema::Result::Node');

__PACKAGE__->has_many (children => 'MySchema::Result::Node',{ 'foreign.parent' => 'self.id','foreign.root' => 'self.root' });

1;

