
package My::State;

use strict;
use warnings 'all';
use base 'My::Model';

__PACKAGE__->set_up_table('states');

__PACKAGE__->has_many(
  cities =>
    'My::City' =>
      'state_id'
);

1;# return true:

