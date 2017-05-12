
package My::City;

use strict;
use warnings 'all';
use base 'My::Model';

__PACKAGE__->set_up_table('cities');


__PACKAGE__->belongs_to(
  state =>
    'My::State' =>
      'state_id'
);

__PACKAGE__->has_one(
  zipcode =>
    'My::Zipcode' =>
      'city_id'
);

1;# return true:

