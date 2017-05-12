package S::Result::B;

use strict;
use warnings;
use parent 'S::Base::Source';

__PACKAGE__->table('b');

__PACKAGE__->add_columns(
  'b_id' => {
    data_type         => 'integer',
    is_nullable       => 0,
    is_auto_increment => 1,
  },

  'b' => {
    data_type => 'varchar',
    size      => 100,
  },
);

__PACKAGE__->set_primary_key('b_id');

1;
