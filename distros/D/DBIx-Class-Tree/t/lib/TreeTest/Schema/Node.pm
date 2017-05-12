package TreeTest::Schema::Node;
use strict;
use warnings;

use base qw( DBIx::Class );

__PACKAGE__->load_components(qw(
    PK::Auto
    Core
));

__PACKAGE__->table('nodes');

__PACKAGE__->add_columns(
    node_id => { is_auto_increment => 1 },
  qw/
    name
    parent_id
    position
    lft
    rgt
  /
);

__PACKAGE__->set_primary_key( 'node_id' );

1;
