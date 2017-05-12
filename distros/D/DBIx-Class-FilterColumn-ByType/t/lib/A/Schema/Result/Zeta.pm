#
# This file is part of DBIx-Class-FilterColumn-ByType
#
# This software is copyright (c) 2012 by Matthew Phillips.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package A::Schema::Result::Zeta;

use strict;
use warnings;

use base 'A::Schema::Result';

# we want to ensure that if A::Schema::Result sets a filter on real datatype
# then in Artist it gets set for only artist, we receive the base class filter, not
# the Artist filter.

our $from_storage_ran = 0;
our $to_storage_ran = 0;

__PACKAGE__->table('zeta');

__PACKAGE__->load_components('FilterColumn::ByType');

__PACKAGE__->add_columns(
  id => {
    data_type => 'int',
    is_auto_increment => 1,
  },
  counter => {
    data_type => 'real',
    is_nullable => 1,
    is_auto_increment => 0,
  },
);

__PACKAGE__->set_primary_key('id');

1;
