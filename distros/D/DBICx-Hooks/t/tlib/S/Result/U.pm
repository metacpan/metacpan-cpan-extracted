package S::Result::U;

use strict;
use warnings;
use parent 'S::Base::Source';

__PACKAGE__->table('u');

__PACKAGE__->add_columns(
  'u_id' => {
    data_type         => 'integer',
    is_nullable       => 0,
    is_auto_increment => 1,
  },

  'u' => {
    data_type => 'varchar',
    size      => 100,
  },
);

__PACKAGE__->set_primary_key('u_id');

1;
