use strict;
use warnings;

package TestSchema::Table;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/ColumnDefault Core/);
__PACKAGE__->table('test');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_nullable       => 1,
    is_auto_increment => 1,
  },
  str => {
    data_type     => 'char',
    default_value => 'aaa',
    is_nullable   => 1,
    size          => 3
  },
  dt => {
    date_type     => 'datetime',
    is_nullable   => 1,
    default_value => \"(datetime('now'))",
  },

);

__PACKAGE__->set_primary_key(qw/id/);

1;
