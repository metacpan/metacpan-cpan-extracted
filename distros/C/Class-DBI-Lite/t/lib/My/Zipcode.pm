
package My::Zipcode;

use strict;
use warnings 'all';
use base 'My::Model';

__PACKAGE__->set_up_table('zipcodes');

__PACKAGE__->belongs_to(
  city  =>
    'My::City'  =>
      'city_id'
);

1;# return true:

